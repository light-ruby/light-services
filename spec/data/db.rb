# frozen_string_literal: true

# Instead of loading all of Rails, load the
# particular Rails dependencies we need
require "sqlite3"
require "active_record"

# Set up a database that resides in RAM
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Set up database tables and columns
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
  end

  create_table :products, force: true do |t|
    t.string :name
    t.integer :price
  end

  create_table :orders, force: true do |t|
    t.belongs_to :user
    t.integer :status
    t.integer :discount
    t.integer :total_price
  end

  create_table :order_items, force: true do |t|
    t.belongs_to :order
    t.belongs_to :product
    t.integer :price
    t.integer :quantity
  end
end
