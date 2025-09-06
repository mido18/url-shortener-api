class CreateShortLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :short_links do |t|
      t.text :original_url
      t.string :slug

      t.timestamps
    end
    add_index :short_links, :original_url, unique: true
    add_index :short_links, :slug, unique: true
  end
end
