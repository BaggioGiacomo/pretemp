class RenameForecastBodyToDiscussion < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE action_text_rich_texts
      SET name = 'discussion'
      WHERE record_type = 'Forecast' AND name = 'body'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE action_text_rich_texts
      SET name = 'body'
      WHERE record_type = 'Forecast' AND name = 'discussion'
    SQL
  end
end
