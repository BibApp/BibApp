require 'rubygems'
require 'active_record'
require 'test/unit'

$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../lib')
require File.dirname(__FILE__) + '/../init'

class YamlDbTest < Test::Unit::TestCase
	def fixture_db
		File.dirname(__FILE__) + '/fixture.db'
	end

	def work_db
		File.dirname(__FILE__) + '/load.db'
	end

	def prepare_database
		require 'ftools'
		File.copy(fixture_db, work_db)

		ActiveRecord::Base.establish_connection({
			:adapter => 'sqlite3',
			:dbfile => work_db
		})
	end

	def setup
		prepare_database

		@table = 'test_table'
		@columns = %w(id name)

		@con = ActiveRecord::Base.connection
		@con.execute "DELETE FROM #{@table}"
	end

	def teardown
		File.delete(work_db) rescue Errno::ENOENT
	end

	def assert_record_exists(name)
		assert_equal 1, @con.select_all("SELECT count(*) FROM #{@table} WHERE name='#{name}'")[0].values[0].to_i
	end

	def test_yamldb_load_records
		@con.yamldb_load_records(@table, @columns, [ %w(100 record_load) ])
		assert_record_exists('record_load')
	end

	def test_yamldb_load_table
		input = { 'columns' => @columns, 'records' => [ %w(200 table_load) ] }
		@con.yamldb_load_table(@table, input)
		assert_record_exists('table_load')
	end

	def test_yamldb_load_structure
		@con.yamldb_load_structure({ 'test_table' => { 'columns' => @columns, 'records' => [ %w(300 struct_load) ] } })
		assert_record_exists('struct_load')
	end
end
