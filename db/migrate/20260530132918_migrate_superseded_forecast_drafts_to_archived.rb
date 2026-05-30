class MigrateSupersededForecastDraftsToArchived < ActiveRecord::Migration[8.1]
  def up
    # Convert draft forecasts that were auto-demoted when a newer published
    # forecast was created for the same date. These are identifiable as drafts
    # that share a date with at least one published (or now archived) forecast.
    execute <<~SQL
      UPDATE forecasts
      SET status = 'archived', updated_at = CURRENT_TIMESTAMP
      WHERE status = 'draft'
        AND date IN (
          SELECT DISTINCT date FROM forecasts WHERE status = 'published'
        )
    SQL
  end

  def down
    execute <<~SQL
      UPDATE forecasts
      SET status = 'draft', updated_at = CURRENT_TIMESTAMP
      WHERE status = 'archived'
    SQL
  end
end
