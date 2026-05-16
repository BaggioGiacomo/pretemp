class RenameForecastUpdateBodyToDiscussion < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE action_text_rich_texts
      SET name = 'discussion'
      WHERE record_type = 'ForecastUpdate' AND name = 'body'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE action_text_rich_texts
      SET name = 'body'
      WHERE record_type = 'ForecastUpdate' AND name = 'discussion'
    SQL
  end
end
