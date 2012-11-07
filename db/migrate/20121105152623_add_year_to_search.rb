class AddYearToSearch < ActiveRecord::Migration
  def change
    add_column :searches, :year, :integer
  end
end
