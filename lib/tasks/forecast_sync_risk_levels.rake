require "nokogiri"
require "date"
require "cgi"
require "fileutils"

module ForecastRiskSyncTask
  module_function

  def run(year:, archive_html_path: nil)
    report = {
      year: year,
      archive_html_path: nil,
      total_archive_candidates: 0,
      parsed_archive_entries: 0,
      total_forecasts: 0,
      updated: 0,
      unchanged: 0,
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

    risk_by_date = parse_risk_map_from_archive(doc, year, report)

    date_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)
    forecasts = Forecast.where(date: date_range).order(:date)
    report[:total_forecasts] = forecasts.count

    forecasts.find_each do |forecast|
      desired_risk_level = risk_by_date[forecast.date]

      if desired_risk_level.nil? && !risk_by_date.key?(forecast.date)
        report[:missing_archive_entry] += 1
        report[:errors] << "No archive risk found for forecast ##{forecast.id} on #{forecast.date}"
        next
      end

      current_risk_level = forecast.risk_level_before_type_cast

      if current_risk_level == desired_risk_level
        report[:unchanged] += 1
        next
      end

      begin
        forecast.update_column(:risk_level, desired_risk_level)
        report[:updated] += 1
      rescue StandardError => e
        report[:errors] << "Failed updating forecast ##{forecast.id} on #{forecast.date}: #{e.message}"
      end
    end

    report
  end

  def resolve_archive_path(year, explicit_path)
    return explicit_path if explicit_path.present?
    return ENV["ARCHIVE_HTML_PATH"] if ENV["ARCHIVE_HTML_PATH"].present?

    download_matches = Dir.glob(File.expand_path("~/Downloads/*ARCHIVIO*#{year}*.html"))
    return download_matches.first if download_matches.any?

    nil
  end

  def parse_risk_map_from_archive(doc, year, report)
    risk_by_date = {}
    source_by_date = {}

    doc.css("#content .widget.widget-link a").each do |anchor|
      href = anchor["href"].to_s.strip
      text = normalize_text(anchor.text)

      next if text.blank?

      candidate = archive_candidate?(href, text, year)
      next unless candidate

      report[:total_archive_candidates] += 1

      date = extract_date(href, text)
      risk_level = extract_risk_level(text)

      if date.nil?
        report[:errors] << "Could not parse date from archive entry: '#{text}' (href: #{href})"
        next
      end

      if date.year != year
        report[:warnings] << "Skipping entry outside target year #{year}: '#{text}' (parsed #{date})"
        next
      end

      if risk_level == :invalid
        report[:errors] << "Invalid risk level in archive entry: '#{text}'"
        next
      end

      if risk_level.nil?
        report[:errors] << "No risk level found in archive entry: '#{text}'"
        next
      end

      existing_risk = risk_by_date[date]
      existing_source = source_by_date[date]

      if existing_risk.nil? && !risk_by_date.key?(date)
        risk_by_date[date] = risk_level
        source_by_date[date] = text
        report[:parsed_archive_entries] += 1
        next
      end

      if existing_risk == risk_level
        next
      end

      if source_priority(text) > source_priority(existing_source)
        report[:warnings] << "Replacing risk for #{date}: #{existing_risk.inspect} -> #{risk_level.inspect} using '#{text}'"
        risk_by_date[date] = risk_level
        source_by_date[date] = text
      else
        report[:errors] << "Conflicting risk for #{date}: kept #{existing_risk.inspect} from '#{existing_source}', ignored #{risk_level.inspect} from '#{text}'"
      end
    end

    risk_by_date
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

  def extract_risk_level(text)
    up = text.upcase

    return nil unless up.include?("LIVELLO")

    return nil if up.match?(/LIVELLO\s*ASSENTE/)

    match = up.match(/LIVELLO\s*[:\-]?\s*([0-3])\b/)
    return match[1].to_i if match

    :invalid
  end

  def source_priority(text)
    up = text.to_s.upcase
    return 3 if up.include?("PREVISION")
    return 2 if up.include?("AGGIORNAMENTO")
    return 1 if up.include?("TENDENZA")

    0
  end

  def write_report(report)
    report_dir = Rails.root.join("tmp")
    FileUtils.mkdir_p(report_dir)

    report_path = report_dir.join("risk_level_update_report_#{report[:year]}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt")

    File.open(report_path, "w", encoding: "UTF-8") do |f|
      f.puts "=" * 90
      f.puts "FORECAST RISK LEVEL UPDATE REPORT"
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
      f.puts "Updated: #{report[:updated]}"
      f.puts "Unchanged: #{report[:unchanged]}"
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
  desc "Update forecast risk levels for a given year using an archive HTML page"
  task :sync_risk_levels, [ :year, :archive_html_path ] => :environment do |_t, args|
    year = args[:year].to_i

    if year <= 0
      puts "Usage: rake forecast:sync_risk_levels[YYYY,/absolute/path/to/archive.html]"
      puts "Or set ARCHIVE_HTML_PATH=/absolute/path/to/archive.html"
      exit 1
    end

    report = ForecastRiskSyncTask.run(year: year, archive_html_path: args[:archive_html_path])
    report_path = ForecastRiskSyncTask.write_report(report)

    puts "\n" + "=" * 70
    puts "RISK LEVEL SYNC COMPLETED"
    puts "=" * 70
    puts "Year: #{report[:year]}"
    puts "Forecasts in year: #{report[:total_forecasts]}"
    puts "Updated: #{report[:updated]}"
    puts "Unchanged: #{report[:unchanged]}"
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
      updated: 0,
      unchanged: 0,
      missing_archive_entry: 0,
      errors: [ "Task failed: #{e.class} - #{e.message}" ],
      warnings: []
    }

    report_path = ForecastRiskSyncTask.write_report(fallback_report)

    puts "Task failed: #{e.message}"
    puts "Error report written to: #{report_path}"
    raise
  end
end
