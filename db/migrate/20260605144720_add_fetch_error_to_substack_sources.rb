class AddFetchErrorToSubstackSources < ActiveRecord::Migration[8.1]
  def change
    add_column :substack_sources, :fetch_error, :string
  end
end
