require 'test_helper'

class NestedClassTest < ActiveSupport::TestCase  # :nodoc:
  include RGeo::ActiveRecord::AdapterTestHelper

  module Foo
    def self.table_name_prefix
      'foo_'
    end
    class Bar < ::ActiveRecord::Base
    end
  end

  define_test_methods do

    def test_nested_model
      Foo::Bar.class_eval do
        establish_connection(DATABASE_CONFIG)
      end
      Foo::Bar.connection.create_table(:foo_bars, force: true) do |t|
        t.column 'latlon', :point, :srid => 3785
      end
      Foo::Bar.all
      Foo::Bar.connection.drop_table(:foo_bars, force: true)
    end

  end

end
