require "nokogiri"
require "date"
require "cgi"
require "fileutils"

module ForecastUserSyncTask
  module_function

  def run(year:, archive_html_path: nil)
    report = {
      year: year,
      archive_html_path: nil,
      total_archive_candidates: 0,
      parsed_archive_entries: 0,
      total_forecasts: 0,
      total_tendenze: 0,
      total_forecast_updates: 0,
      updated: 0,
      unchanged: 0,
      unresolved: 0,
      missing_archive_entry: 0,
      errors: [],
      warnings: []
    }

    archive_path = resolve_archive_path(year, archive_html_path)
    report[:archive_html_path] = archive_path

    unless archive_path && File.exist?(archive_path)
      raise ArgumentError, "Archive HTML file not found. Pass it as second argument or set ARCHIVE_HTML_PATH."
    end

    html = File.read(archive_path, encoding: "UTF-8")
    doc = Nokogiri::HTML(html)

    users_by_last_name = build_users_index
    previsori_by_kind = parse_previsori_by_kind(doc, year, report, users_by_last_name.keys)

    date_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

    sync_forecasts(previsori_by_kind[:forecast], tendenza: false, date_range: date_range,
                   users_by_last_name: users_by_last_name, report: report)
    sync_forecasts(previsori_by_kind[:tendenza], tendenza: true, date_range: date_range,
                   users_by_last_name: users_by_last_name, report: report)
    sync_forecast_updates(previsori_by_kind[:aggiornamento], date_range: date_range,
                          users_by_last_name: users_by_last_name, report: report)

    report
  end

  # The archive lists three kinds of entries per day, each backed by a different record:
  # - "Previsione"/"Previsioni": the main Forecast (tendenza: false)
  # - "Tendenza": a separate Forecast (tendenza: true) for the same date
  # - "Aggiornamento": a ForecastUpdate belonging to that day's main Forecast
  def sync_forecasts(previsori_by_date, tendenza:, date_range:, users_by_last_name:, report:)
    forecasts = Forecast.where(date: date_range, tendenza: tendenza).order(:date)
    label = tendenza ? "tendenza" : "forecast"
    report[tendenza ? :total_tendenze : :total_forecasts] += forecasts.count

    forecasts.find_each do |forecast|
      names = previsori_by_date[forecast.date]

      if names.nil?
        report[:missing_archive_entry] += 1
        report[:errors] << "No archive previsore found for #{label} ##{forecast.id} on #{forecast.date}"
        next
      end

      context = "#{label} ##{forecast.id} on #{forecast.date}"
      resolved_users = resolve_users(names, users_by_last_name, report, context)
      apply_users(forecast, resolved_users, report)
    end
  end

  def sync_forecast_updates(previsori_by_date, date_range:, users_by_last_name:, report:)
    updates = ForecastUpdate.joins(:forecast)
                            .where(forecasts: { date: date_range })
                            .order("forecasts.date ASC, forecast_updates.created_at DESC")

    updates_by_date = updates.group_by { |update| update.forecast.date }
    report[:total_forecast_updates] += updates_by_date.size

    updates_by_date.each do |date, date_updates|
      if date_updates.size > 1
        report[:warnings] << "Multiple forecast updates found on #{date}; syncing only the most recent (##{date_updates.first.id})"
      end

      update = date_updates.first
      names = previsori_by_date[date]

      if names.nil?
        report[:missing_archive_entry] += 1
        report[:errors] << "No archive previsore found for forecast update ##{update.id} on #{date}"
        next
      end

      context = "forecast update ##{update.id} on #{date}"
      resolved_users = resolve_users(names, users_by_last_name, report, context)
      apply_users(update, resolved_users, report)
    end
  end

  def resolve_users(names, users_by_last_name, report, context)
    resolved = []

    names.each do |name|
      matches = users_by_last_name[normalize_name(name)]

      if matches.blank?
        report[:errors] << "No user found with last name '#{name}' (#{context})"
        next
      end

      resolved.concat(matches)
    end

    resolved.uniq
  end

  def apply_users(record, resolved_users, report)
    if resolved_users.empty?
      report[:unresolved] += 1
      return
    end

    current_user_ids = record.user_ids.sort
    desired_user_ids = resolved_users.map(&:id).sort

    if current_user_ids == desired_user_ids
      report[:unchanged] += 1
      return
    end

    begin
      record.users = resolved_users
      report[:updated] += 1
    rescue StandardError => e
      report[:errors] << "Failed updating users for #{record.class.name} ##{record.id}: #{e.message}"
    end
  end

  def build_users_index
    User.all.each_with_object(Hash.new { |h, k| h[k] = [] }) do |user, index|
      index[normalize_name(user.last_name)] << user
    end
  end

  def normalize_name(name)
    ActiveSupport::Inflector.transliterate(name.to_s).strip.upcase.gsub(/\s+/, " ")
  end

  def resolve_archive_path(year, explicit_path)
    return explicit_path if explicit_path.present?
    return ENV["ARCHIVE_HTML_PATH"] if ENV["ARCHIVE_HTML_PATH"].present?

    download_matches = Dir.glob(File.expand_path("~/Downloads/*ARCHIVIO*#{year}*.html"))
    return download_matches.first if download_matches.any?

    nil
  end

  def parse_previsori_by_kind(doc, year, report, known_last_names = [])
    maps = { forecast: {}, tendenza: {}, aggiornamento: {} }
    sources = { forecast: {}, tendenza: {}, aggiornamento: {} }

    doc.css("#content .widget.widget-link a").each do |anchor|
      href = anchor["href"].to_s.strip
      text = normalize_text(anchor.text)

      next if text.blank?

      candidate = archive_candidate?(href, text, year)
      next unless candidate

      report[:total_archive_candidates] += 1

      date = extract_date(href, text)

      if date.nil?
        report[:errors] << "Could not parse date from archive entry: '#{text}' (href: #{href})"
        next
      end

      if date.year != year
        report[:warnings] << "Skipping entry outside target year #{year}: '#{text}' (parsed #{date})"
        next
      end

      names = extract_previsori(text, known_last_names)

      if names.blank?
        report[:errors] << "No previsore found in archive entry: '#{text}'"
        next
      end

      kind = classify_entry(text)
      map = maps[kind]
      source = sources[kind]

      existing_names = map[date]

      if existing_names.nil? && !map.key?(date)
        map[date] = names
        source[date] = text
        report[:parsed_archive_entries] += 1
        next
      end

      next if existing_names == names

      report[:warnings] << "Conflicting #{kind} previsore for #{date}: kept #{existing_names.inspect} from '#{source[date]}', ignored #{names.inspect} from '#{text}'"
    end

    maps
  end

  def classify_entry(text)
    up = text.upcase
    return :tendenza if up.include?("TENDENZA")
    return :aggiornamento if up.include?("AGGIORNAMENTO")

    :forecast
  end

  def archive_candidate?(href, text, year)
    text_up = text.upcase
    href_has_year = href.include?("/#{year}/") || href.include?("_#{year}") || href.include?("-#{year}")
    text_has_year = text_up.match?(/\b#{year}\b/)
    looks_like_forecast_row = text_up.match?(/PREVISION|TENDENZA|AGGIORNAMENTO/) || text_up.include?("LIVELLO")

    looks_like_forecast_row && (href_has_year || text_has_year)
  end

  def normalize_text(text)
    CGI.unescape_html(text.to_s).gsub(/\s+/, " ").strip
  end

  def extract_date(href, text)
    date_from_href = parse_date_fragment(href)
    return date_from_href if date_from_href

    parse_date_fragment(text)
  end

  def parse_date_fragment(raw)
    return nil if raw.blank?

    # Supports DD_MM_YYYY and DD-MM-YYYY inside full URLs/text.
    match = raw.match(/(\d{2})[_-](\d{2})[_-](\d{4})/)
    return nil unless match

    day = match[1].to_i
    month = match[2].to_i
    year = match[3].to_i

    Date.new(year, month, day)
  rescue ArgumentError
    nil
  end

  # Resolves the previsori for an entry by scanning its text for surnames that
  # exist in the DB, regardless of the entry's wording (labelled with
  # "Previsore:"/"Revisore:" or not, e.g. "... GIUGNO (3) - NEGRO"). Longer,
  # overlapping matches win (keeps "DE MARTIN" over a stray "MARTIN") and results
  # are returned in the order they appear. Returns [] when nothing matches.
  def extract_previsori(text, known_last_names = [])
    return [] if known_last_names.blank?

    normalized = normalize_name(text)

    spans = known_last_names.uniq.reject(&:blank?).filter_map do |last_name|
      match = normalized.match(/\b#{Regexp.escape(last_name)}\b/)
      { name: last_name, start: match.begin(0), finish: match.end(0) } if match
    end

    spans
      .reject { |span| spans.any? { |o| !o.equal?(span) && o[:start] <= span[:start] && o[:finish] >= span[:finish] } }
      .sort_by { |span| span[:start] }
      .map { |span| span[:name] }
  end

  def write_report(report)
    report_dir = Rails.root.join("tmp")
    FileUtils.mkdir_p(report_dir)

    report_path = report_dir.join("user_sync_report_#{report[:year]}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt")

    File.open(report_path, "w", encoding: "UTF-8") do |f|
      f.puts "=" * 90
      f.puts "FORECAST USER SYNC REPORT"
      f.puts "Generated at: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
      f.puts "Year: #{report[:year]}"
      f.puts "Archive HTML: #{report[:archive_html_path]}"
      f.puts "=" * 90
      f.puts
      f.puts "SUMMARY"
      f.puts "-" * 90
      f.puts "Archive candidates found: #{report[:total_archive_candidates]}"
      f.puts "Archive entries parsed: #{report[:parsed_archive_entries]}"
      f.puts "Forecasts in year: #{report[:total_forecasts]}"
      f.puts "Tendenze in year: #{report[:total_tendenze]}"
      f.puts "Forecast updates in year: #{report[:total_forecast_updates]}"
      f.puts "Updated: #{report[:updated]}"
      f.puts "Unchanged: #{report[:unchanged]}"
      f.puts "Unresolved (no matching users found): #{report[:unresolved]}"
      f.puts "Missing archive entry: #{report[:missing_archive_entry]}"
      f.puts "Warnings: #{report[:warnings].count}"
      f.puts "Errors: #{report[:errors].count}"
      f.puts

      if report[:warnings].any?
        f.puts "WARNINGS"
        f.puts "-" * 90
        report[:warnings].each { |warning| f.puts warning }
        f.puts
      end

      if report[:errors].any?
        f.puts "ERRORS"
        f.puts "-" * 90
        report[:errors].each { |error| f.puts error }
        f.puts
      end
    end

    report_path
  end
end

namespace :forecast do
  desc "Sync forecast users (previsori) for a given year using an archive HTML page"
  task :sync_users, [ :year, :archive_html_path ] => :environment do |_t, args|
    year = args[:year].to_i

    if year <= 0
      puts "Usage: rake forecast:sync_users[YYYY,/absolute/path/to/archive.html]"
      puts "Or set ARCHIVE_HTML_PATH=/absolute/path/to/archive.html"
      exit 1
    end

    report = ForecastUserSyncTask.run(year: year, archive_html_path: args[:archive_html_path])
    report_path = ForecastUserSyncTask.write_report(report)

    puts "\n" + "=" * 70
    puts "USER SYNC COMPLETED"
    puts "=" * 70
    puts "Year: #{report[:year]}"
    puts "Forecasts in year: #{report[:total_forecasts]}"
    puts "Tendenze in year: #{report[:total_tendenze]}"
    puts "Forecast updates in year: #{report[:total_forecast_updates]}"
    puts "Updated: #{report[:updated]}"
    puts "Unchanged: #{report[:unchanged]}"
    puts "Unresolved: #{report[:unresolved]}"
    puts "Missing archive entry: #{report[:missing_archive_entry]}"
    puts "Warnings: #{report[:warnings].count}"
    puts "Errors: #{report[:errors].count}"
    puts "Report: #{report_path}"
    puts "=" * 70
  rescue StandardError => e
    fallback_report = {
      year: year,
      archive_html_path: args[:archive_html_path] || ENV["ARCHIVE_HTML_PATH"],
      total_archive_candidates: 0,
      parsed_archive_entries: 0,
      total_forecasts: 0,
      total_tendenze: 0,
      total_forecast_updates: 0,
      updated: 0,
      unchanged: 0,
      unresolved: 0,
      missing_archive_entry: 0,
      errors: [ "Task failed: #{e.class} - #{e.message}" ],
      warnings: []
    }

    report_path = ForecastUserSyncTask.write_report(fallback_report)

    puts "Task failed: #{e.message}"
    puts "Error report written to: #{report_path}"
    raise
  end
end
