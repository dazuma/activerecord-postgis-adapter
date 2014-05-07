require 'minitest/autorun'
require 'rgeo/active_record/adapter_test_helper'

module RGeo
  module ActiveRecord  # :nodoc:
    module PostGISAdapter  # :nodoc:
      module Tests  # :nodoc:
        class TestDDL < ::MiniTest::Test  # :nodoc:
          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
          OVERRIDE_DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database_local.yml'
          include AdapterTestHelper

          define_test_methods do
            def test_create_simple_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :geometry
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(true, col_.has_spatial_constraints?)
              assert_equal(false, col_.geographic?)
              assert_equal(0, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

            # no_constraints no longer supported in PostGIS 2.0
            def _test_create_no_constraints_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'geom', :geometry, :limit => {:no_constraints => true}
              end
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(false, col_.has_spatial_constraints?)
              assert_nil(col_.srid)
              assert(klass_.cached_attributes.include?('geom'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

            def test_create_simple_geography
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :geometry, :geographic => true
              end
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(true, col_.has_spatial_constraints?)
              assert_equal(true, col_.geographic?)
              assert_equal(4326, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

            def test_create_point_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :point
              end
              assert_equal(::RGeo::Feature::Point, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end

            def test_create_geometry_with_index
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :geometry
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.index([:latlon], :spatial => true)
              end
              assert(klass_.connection.indexes(:spatial_test).last.spatial)
            end

            def test_add_geometry_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.column('geom2', :point, :srid => 4326)
                t_.column('name', :string)
              end
              assert_equal(2, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
              assert_equal(0, cols_[-3].srid)
              assert_equal(true, cols_[-3].has_spatial_constraints?)
              assert_equal(::RGeo::Feature::Point, cols_[-2].geometric_type)
              assert_equal(4326, cols_[-2].srid)
              assert_equal(false, cols_[-2].geographic?)
              assert_equal(true, cols_[-2].has_spatial_constraints?)
              assert_nil(cols_[-1].geometric_type)
              assert_equal(false, cols_[-1].has_spatial_constraints?)
            end

            # no_constraints no longer supported in PostGIS 2.0
            def _test_add_no_constraints_geometry_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.column('geom2', :geometry, :no_constraints => true)
                t_.column('name', :string)
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
              assert_equal(0, cols_[-3].srid)
              assert_equal(true, cols_[-3].has_spatial_constraints?)
              assert_equal(::RGeo::Feature::Geometry, cols_[-2].geometric_type)
              assert_nil(cols_[-2].srid)
              assert_equal(false, cols_[-2].geographic?)
              assert_equal(false, cols_[-2].has_spatial_constraints?)
              assert_nil(cols_[-1].geometric_type)
              assert_equal(false, cols_[-1].has_spatial_constraints?)
            end

            def test_add_geography_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.column('geom2', :point, :srid => 4326, :geographic => true)
                t_.column('name', :string)
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-3].geometric_type)
              assert_equal(0, cols_[-3].srid)
              assert_equal(true, cols_[-3].has_spatial_constraints?)
              assert_equal(::RGeo::Feature::Point, cols_[-2].geometric_type)
              assert_equal(4326, cols_[-2].srid)
              assert_equal(true, cols_[-2].geographic?)
              assert_equal(true, cols_[-2].has_spatial_constraints?)
              assert_nil(cols_[-1].geometric_type)
              assert_equal(false, cols_[-1].has_spatial_constraints?)
            end

            def test_drop_geometry_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
                t_.column('geom2', :point, :srid => 4326)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.remove('geom2')
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Geometry, cols_[-1].geometric_type)
              assert_equal('latlon', cols_[-1].name)
              assert_equal(0, cols_[-1].srid)
              assert_equal(false, cols_[-1].geographic?)
            end

            def test_drop_geography_column
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column('latlon', :geometry)
                t_.column('geom2', :point, :srid => 4326, :geographic => true)
                t_.column('geom3', :point, :srid => 4326)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.remove('geom2')
              end
              assert_equal(2, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              cols_ = klass_.columns
              assert_equal(::RGeo::Feature::Point, cols_[-1].geometric_type)
              assert_equal('geom3', cols_[-1].name)
              assert_equal(false, cols_[-1].geographic?)
              assert_equal(::RGeo::Feature::Geometry, cols_[-2].geometric_type)
              assert_equal('latlon', cols_[-2].name)
              assert_equal(false, cols_[-2].geographic?)
            end

            def test_create_simple_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.geometry 'latlon'
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(0, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

            # no_constraints no longer supported in PostGIS 2.0
            def _test_create_no_constraints_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.spatial 'geom', :no_constraints => true
              end
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_nil(col_.srid)
              assert(klass_.cached_attributes.include?('geom'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

            def test_create_simple_geography_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.geometry 'latlon', :geographic => true
              end
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Geometry, col_.geometric_type)
              assert_equal(true, col_.geographic?)
              assert_equal(4326, col_.srid)
              assert(klass_.cached_attributes.include?('latlon'))
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

            def test_create_point_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.point 'latlon'
              end
              assert_equal(::RGeo::Feature::Point, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end

            def test_create_geometry_with_options
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'region', :polygon, :has_m => true, :srid => 3785
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Polygon, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(false, col_.has_z?)
              assert_equal(true, col_.has_m?)
              assert_equal(3785, col_.srid)
              assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col_.limit)
              assert(klass_.cached_attributes.include?('region'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

            def test_create_geometry_using_limit
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.spatial 'region', :limit => {:has_m => true, :srid => 3785, :type => :polygon}
              end
              assert_equal(1, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
              col_ = klass_.columns.last
              assert_equal(::RGeo::Feature::Polygon, col_.geometric_type)
              assert_equal(false, col_.geographic?)
              assert_equal(false, col_.has_z)
              assert_equal(true, col_.has_m)
              assert_equal(3785, col_.srid)
              assert_equal({:has_m => true, :type => 'polygon', :srid => 3785}, col_.limit)
              assert(klass_.cached_attributes.include?('region'))
              klass_.connection.drop_table(:spatial_test)
              assert_equal(0, klass_.connection.select_value("SELECT COUNT(*) FROM geometry_columns WHERE f_table_name='spatial_test'").to_i)
            end

          end
        end
      end
    end
  end
end
