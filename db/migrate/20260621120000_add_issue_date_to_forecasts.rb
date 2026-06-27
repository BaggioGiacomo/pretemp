class AddIssueDateToForecasts < ActiveRecord::Migration[7.1]
  def change
    add_column :forecasts, :issue_date, :datetime
  end
end
