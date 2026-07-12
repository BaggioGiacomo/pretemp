require "nokogiri"
require "date"
require "open-uri"

namespace :forecast do
  desc "Migrate old forecast HTML files to the new database"
  task :migrate, [ :folder_path ] => :environment do |t, args|
    folder_path = args[:folder_path]

    if folder_path.blank?
      puts "Usage: rake forecast:migrate[/path/to/folder]"
      exit 1
    end

    unless Dir.exist?(folder_path)
      puts "Folder does not exist: #{folder_path}"
      exit 1
    end

    # Get the first user (used as a fallback when no forecaster is found)
    first_user = User.first
    if first_user.nil?
      puts "No users found in the database. Please create a user first."
      exit 1
    end

    # Index all users by last name so we can match forecasters mentioned in
    # each forecast page (same approach as forecast:sync_users).
    users_by_last_name = ForecastUserSyncTask.build_users_index

    # Initialize report
    report = {
      total_files: 0,
      successful: 0,
      skipped: 0,
      errors: [],
      details: []
    }

    # Get all HTML files
    html_files = Dir.glob(File.join(folder_path, "**/*.html"))
    report[:total_files] = html_files.count

    html_files.each do |file_path|
      begin
        result = migrate_single_file(file_path, first_user, users_by_last_name)
        if result[:status] == :success
          report[:successful] += 1
          report[:details] << "✓ #{File.basename(file_path)}: #{result[:message]}"
        elsif result[:status] == :skipped
          report[:skipped] += 1
          report[:details] << "⊘ #{File.basename(file_path)}: #{result[:message]}"
        else
          report[:errors] << "✗ #{File.basename(file_path)}: #{result[:message]}"
        end
      rescue StandardError => e
        report[:errors] << "✗ #{File.basename(file_path)}: #{e.message}"
      end
    end

    # Write report to file
    write_report(folder_path, report)

    # Print summary
    puts "\n" + "="*60
    puts "MIGRATION REPORT"
    puts "="*60
    puts "Total files: #{report[:total_files]}"
    puts "Successful: #{report[:successful]}"
    puts "Skipped: #{report[:skipped]}"
    puts "Errors: #{report[:errors].count}"
    puts "="*60
    puts "\nDetailed report saved to: #{report_file_path(folder_path)}"
  end

  private

  def migrate_single_file(file_path, fallback_user, users_by_last_name)
    content = File.read(file_path, encoding: "UTF-8")
    doc = Nokogiri::HTML(content)

    if update_file?(file_path, doc)
      return migrate_update_file(doc, fallback_user, users_by_last_name)
    end

    is_tendenza = tendenza_file?(file_path, doc)

    # Parse date from filename or HTML content
    date = parse_date(file_path, doc)
    return { status: :error, message: "Could not parse date" } if date.nil?

    # Check if forecast already exists for this date and type
    if Forecast.exists?(date: date, tendenza: is_tendenza)
      label = is_tendenza ? "Tendenza" : "Forecast"
      return { status: :skipped, message: "#{label} already exists for #{date.strftime('%d/%m/%Y')}" }
    end

    # Extract issue datetime
    issue_datetime = extract_issue_datetime(doc)

    # Extract short_text (optional for legacy files)
    short_text = extract_section(doc, [ "TESTO BREVE", "In breve" ])

    # Extract discussion
    discussion = extract_section(doc, [ "DISCUSSIONE" ])

    # Extract image URL
    image_url = extract_image_url(doc)

    # Create the forecast
    forecast = Forecast.new(
      date: date,
      summary: Forecast::DEFAULT_SUMMARY,
      status: "published",
      risk_level: nil,
      tendenza: is_tendenza,
      issue_date: issue_datetime
    )

    forecast.created_at = issue_datetime if issue_datetime.present?

    # Set rich text fields with HTML content preserved
    forecast.short_text = ActionText::RichText.new(body: "<div>#{short_text}</div>") if short_text.present?
    forecast.discussion = ActionText::RichText.new(body: "<div>#{discussion}</div>") if discussion.present?

    # Attach the forecasters mentioned on the forecast page
    forecast.users = resolve_users_from_doc(doc, fallback_user, users_by_last_name)

    # Attach image if found
    if image_url.present?
      begin
        download_and_attach_image(forecast, image_url)
      rescue StandardError => e
        puts "Warning: Could not download image from #{image_url}: #{e.message}"
      end
    end

    if forecast.save
      # Update created_at after save if needed (since ActionText might interfere)
      forecast.update_columns(created_at: issue_datetime) if issue_datetime.present?
      label = is_tendenza ? "tendenza" : "forecast"
      { status: :success, message: "Created #{label} for #{date.strftime('%d/%m/%Y')}" }
    else
      { status: :error, message: "Validation failed: #{forecast.errors.full_messages.join(', ')}" }
    end
  rescue Nokogiri::SyntaxError => e
    { status: :error, message: "Invalid HTML: #{e.message}" }
  end

  def migrate_update_file(doc, fallback_user, users_by_last_name)
    forecast_date = extract_forecast_date_from_validity(doc)
    return { status: :error, message: "Could not parse forecast date for update" } if forecast_date.nil?

    forecast = Forecast.find_by(date: forecast_date)
    return { status: :error, message: "Forecast not found for #{forecast_date.strftime('%d/%m/%Y')}" } if forecast.nil?

    valid_until = extract_valid_until(doc)
    return { status: :error, message: "Could not parse valid_until for update" } if valid_until.nil?

    issue_datetime = extract_issue_datetime(doc)

    existing_scope = forecast.forecast_updates.where(valid_until: valid_until)
    existing_scope = existing_scope.where(created_at: issue_datetime) if issue_datetime.present?
    if existing_scope.exists?
      return { status: :skipped, message: "Update already exists for forecast #{forecast_date.strftime('%d/%m/%Y')}" }
    end

    short_text = extract_update_content(doc)

    discussion = extract_section(doc, [ "DISCUSSIONE" ])
    image_url = extract_image_url(doc)

    update = ForecastUpdate.new(
      forecast: forecast,
      status: "published",
      valid_until: valid_until
    )

    update.created_at = issue_datetime if issue_datetime.present?

    update.short_text = ActionText::RichText.new(body: "<div>#{short_text}</div>") if short_text.present?
    update.discussion = ActionText::RichText.new(body: "<div>#{discussion}</div>") if discussion.present?

    update.users = resolve_users_from_doc(doc, fallback_user, users_by_last_name)

    if image_url.present?
      begin
        download_and_attach_image(update, image_url)
      rescue StandardError => e
        puts "Warning: Could not download image from #{image_url}: #{e.message}"
      end
    end

    if update.save
      update.update_columns(created_at: issue_datetime) if issue_datetime.present?
      { status: :success, message: "Created update for forecast #{forecast_date.strftime('%d/%m/%Y')}" }
    else
      { status: :error, message: "Validation failed: #{update.errors.full_messages.join(', ')}" }
    end
  end

  # Search the forecast page text for the last names of known users and return
  # every matching user. Falls back to the given user when no forecaster is
  # found so the record still has an author. Reuses the matching logic from
  # forecast:sync_users.
  def resolve_users_from_doc(doc, fallback_user, users_by_last_name)
    names = ForecastUserSyncTask.extract_previsori(doc.text.to_s, users_by_last_name.keys)
    matched = names.flat_map { |name| users_by_last_name[name] }.compact.uniq

    matched.presence || [ fallback_user ]
  end

  def update_file?(file_path, doc)
    filename = File.basename(file_path, ".html").downcase
    return true if filename.start_with?("agg_")

    title = doc.css("p#Titolo strong#title-date, strong#title-date, title#window-title").first&.text.to_s
    CGI.unescape_html(title).upcase.include?("AGGIORNAMENTO")
  end

  def tendenza_file?(file_path, doc)
    filename = File.basename(file_path, ".html").downcase
    return true if filename.start_with?("tend_")

    title = doc.css("p#Titolo strong#title-date, strong#title-date, title#window-title").first&.text.to_s
    CGI.unescape_html(title).upcase.include?("TENDENZA")
  end

  def parse_date(file_path, doc)
    # Try to parse from filename first
    filename = File.basename(file_path, ".html")

    # Remove known prefixes used in legacy archives
    filename = filename.sub(/\A(?:tend|agg|prev)_/i, "")

    # Normalize filename variations: 01_04_2026, 01-04-2026
    normalized_filename = filename.gsub("-", "_")

    # Try DD_MM_YYYY format
    if normalized_filename =~ /^(\d{2})_(\d{2})_(\d{4})$/
      day = $1.to_i
      month = $2.to_i
      year = $3.to_i
      begin
        return Date.new(year, month, day)
      rescue ArgumentError
        # Invalid date, fall through to HTML parsing
      end
    end

    # Try to parse from HTML title: "Previsione per <day> <number> <italian_month> <year>"
    title = doc.css("p#Titolo strong#title-date, strong#title-date").first&.text
    return nil if title.blank?

    parse_date_from_title(title)
  end

  def parse_date_from_title(title)
    # Example: "PREVISIONE PER MERCOLEDI' 8 APRILE 2026"
    # Or: "PREVISIONE PER MARTED&Igrave; 7 APRILE 2026"

    title = title.upcase.gsub(/&[A-Z]+;/, "").strip

    # Extract components using regex
    # Pattern: "PREVISIONE PER <day_name> <number> <month_name> <year>"
    match = title.match(/PER\s+\w+[''']?\s+(\d{1,2})\s+(\w+)\s+(\d{4})/)
    return nil if match.nil?

    day = match[1].to_i
    month_name = match[2]
    year = match[3].to_i

    month = italian_month_to_number(month_name)
    return nil if month.nil?

    begin
      Date.new(year, month, day)
    rescue ArgumentError
      nil
    end
  end

  def italian_month_to_number(month_name)
    months = {
      "GENNAIO" => 1,
      "FEBBRAIO" => 2,
      "MARZO" => 3,
      "APRILE" => 4,
      "MAGGIO" => 5,
      "GIUGNO" => 6,
      "LUGLIO" => 7,
      "AGOSTO" => 8,
      "SETTEMBRE" => 9,
      "OTTOBRE" => 10,
      "NOVEMBRE" => 11,
      "DICEMBRE" => 12
    }
    months[month_name.upcase]
  end

  def extract_issue_datetime(doc)
    # Find "Emessa" line: "Emessa martedì 07 aprile 2026 alle ore 15:00 UTC"
    issue_element = doc.css("p#issue-date").first || doc.css("p").find { |p| p.text =~ /Emessa/ }
    return nil if issue_element.nil?

    # Decode HTML entities to get clean text
    issue_text = CGI.unescape_html(issue_element.text)
    return nil if issue_text.blank?

    # Extract date and time
    # Pattern: "Emessa <day_name> <number> <month_name> <year> alle ore <HH>:<MM> UTC"
    # More flexible: skip day name entirely and just capture the numbers
    match = issue_text.match(/Emessa\s+.+?\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+alle ore\s+(\d{2}):(\d{2})/)
    return nil if match.nil?

    day = match[1].to_i
    month_name = match[2]
    year = match[3].to_i
    hour = match[4].to_i
    minute = match[5].to_i

    month = italian_month_to_number(month_name)
    return nil if month.nil?

    begin
      DateTime.new(year, month, day, hour, minute, 0)
    rescue ArgumentError
      nil
    end
  end

  def extract_forecast_date_from_validity(doc)
    validity_text = extract_primary_validity_text(doc)
    return nil if validity_text.blank?

    # Example: "Valida ... UTC di martedi' 17 marzo 2026"
    match = validity_text.match(/di\s+.+?\s+(\d{1,2})\s+(\w+)\s+(\d{4})/i)
    return nil if match.nil?

    day = match[1].to_i
    month_name = match[2]
    year = match[3].to_i

    month = italian_month_to_number(month_name)
    return nil if month.nil?

    Date.new(year, month, day)
  rescue ArgumentError
    nil
  end

  def extract_valid_until(doc)
    validity_text = extract_primary_validity_text(doc)
    return nil if validity_text.blank?

    # Example: "Valida dalle ore 00:00 alle 24:00 UTC di martedi' 17 marzo 2026"
    match = validity_text.match(/alle ore\s+(\d{1,2}):(\d{2})\s+alle\s+(\d{1,2}):(\d{2})\s+UTC\s+di\s+.+?\s+(\d{1,2})\s+(\w+)\s+(\d{4})/i)
    return nil if match.nil?

    end_hour = match[3].to_i
    end_minute = match[4].to_i
    day = match[5].to_i
    month_name = match[6]
    year = match[7].to_i

    month = italian_month_to_number(month_name)
    return nil if month.nil?

    if end_hour == 24 && end_minute == 0
      return DateTime.new(year, month, day, 0, 0, 0) + 1
    end

    return nil if end_hour > 23

    DateTime.new(year, month, day, end_hour, end_minute, 0)
  rescue ArgumentError
    nil
  end

  def extract_primary_validity_text(doc)
    text = doc.css("#forecast-time-range").first&.text
    return CGI.unescape_html(text).strip if text.present?

    candidate = doc.css("p, span").find do |node|
      parsed = CGI.unescape_html(node.text.to_s)
      parsed.match?(/Valida dalle ore/i) && parsed.match?(/UTC\s+di/i)
    end

    return nil if candidate.nil?

    CGI.unescape_html(candidate.text.to_s).strip
  end

  def extract_update_content(doc)
    issue_element = doc.css("p#issue-date").first || doc.css("p").find { |p| p.text =~ /Emessa/ }
    paragraphs = doc.css("p").to_a
    return nil if paragraphs.empty?

    validity_index = paragraphs.index { |p| CGI.unescape_html(p.text.to_s).match?(/Valida dalle ore/i) }
    return nil if validity_index.nil?

    issue_index = issue_element.present? ? paragraphs.index(issue_element) : nil
    end_index = issue_index || paragraphs.length

    content_parts = []
    paragraphs[(validity_index + 1)...end_index].to_a.each do |paragraph|
      parsed_text = CGI.unescape_html(paragraph.text.to_s).strip
      next if parsed_text.blank?
      next if parsed_text.match?(/\AValida dalle ore/i)

      content_parts << paragraph.inner_html
    end

    result = content_parts.join("\n").strip
    return result if result.present?

    extract_section(doc, [ "TESTO BREVE", "In breve" ])
  end

  def extract_section(doc, section_titles)
    # Find the section by looking for the title in the document
    section_titles.each do |title|
      # Search for any element containing the title
      section = doc.xpath("//text()[contains(translate(., 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), '#{title.upcase}')]").first
      next if section.nil?

      # Navigate up to find the parent <p> tag
      title_element = section.parent
      while title_element && title_element.name != "p"
        title_element = title_element.parent
      end
      next if title_element.nil?

      # Get the content after this section until the next section or issue-date
      content_parts = []
      current = title_element

      # Move to next relevant element
      loop do
        current = current.next_sibling
        break if current.nil?

        # Skip text nodes
        next if current.is_a?(Nokogiri::XML::Text)

        if current.is_a?(Nokogiri::XML::Element)
          text = current.text.upcase

          # Stop if we hit another section title or issue-date
          break if text.include?("DISCUSSIONE") || text.include?("TESTO BREVE") || text.include?("IN BREVE") || text.include?("EMESSA") || current.css("p#issue-date").any?

          # Extract text content
          if current.name == "p"
            inner_html = current.inner_html
            content_parts << inner_html if inner_html.present?
          end
        end
      end

      result = content_parts.join("\n").strip
      return result if result.present?
    end

    nil
  end

  def write_report(folder_path, report)
    report_file = report_file_path(folder_path)

    File.open(report_file, "w", encoding: "UTF-8") do |f|
      f.puts "=" * 80
      f.puts "FORECAST MIGRATION REPORT"
      f.puts "Generated at: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
      f.puts "=" * 80
      f.puts
      f.puts "SUMMARY"
      f.puts "-" * 80
      f.puts "Total files processed: #{report[:total_files]}"
      f.puts "Successful: #{report[:successful]}"
      f.puts "Skipped: #{report[:skipped]}"
      f.puts "Errors: #{report[:errors].count}"
      f.puts
      f.puts "DETAILS"
      f.puts "-" * 80
      report[:details].each { |detail| f.puts detail }
      f.puts
      if report[:errors].any?
        f.puts "ERRORS"
        f.puts "-" * 80
        report[:errors].each { |error| f.puts error }
      end
    end

    puts "\nReport written to: #{report_file}"
  end

  def report_file_path(folder_path)
    File.join(folder_path, "migration_report_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt")
  end

  def extract_image_url(doc)
    # Find the first img tag and extract its src attribute
    img = doc.css("img").first
    img&.attr("src")
  end

  def download_and_attach_image(record, image_url)
    require "open-uri"
    require "tempfile"

    # Download the image data
    image_data = URI.open(image_url).read
    filename = File.basename(URI.parse(image_url).path)

    # If filename is empty or just an extension, generate one
    if filename.blank? || !filename.include?(".")
      base_date = if record.respond_to?(:date) && record.date.present?
        record.date
      elsif record.respond_to?(:forecast) && record.forecast.present?
        record.forecast.date
      else
        Date.current
      end

      filename = "forecast_#{base_date.strftime('%Y%m%d')}.png"
    end

    # Attach directly from downloaded data
    record.image.attach(io: StringIO.new(image_data), filename: filename, content_type: "image/png")
  end
end
