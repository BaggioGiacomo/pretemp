namespace :forecast do
  desc "Set issue_date to updated_at for existing forecasts without issue_date"
  task backfill_issue_dates: :environment do
    count = 0

    Forecast.where(issue_date: nil).find_each do |forecast|
      forecast.update_columns(issue_date: forecast.updated_at)
      count += 1
    end

    puts "\n" + "="*60
    puts "BACKFILL COMPLETE"
    puts "="*60
    puts "Updated #{count} forecasts"
    puts "All forecasts now have an issue_date"
    puts "="*60
  end
end
