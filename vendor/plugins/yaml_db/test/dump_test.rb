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
		File.dirname(__FILE__) + '/dump.db'
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

		@con = ActiveRecord::Base.connection

		@table = 'test_table'
		@columns = %w(id name)
		@records = [ %w(1 one), %w(2 two) ]

		@dumped_table = { 'columns' => @columns, 'records' => @records }
		@dumped_structure = { @table => @dumped_table }
	end

	def teardown
		File.delete(work_db) rescue Errno::ENOENT
	end

	def test_unhash
		assert_equal %w(a b), @con.unhash({ '1' => 'a', '2' => 'b' }, %w(1 2))
	end

	def test_column_names
		assert_equal @columns, @con.table_column_names(@table)
	end

	def test_yamldb_dump_table_records
		assert_equal @records, @con.yamldb_dump_table_records(@table)
	end

	def test_yamldb_dump_table
		assert_equal @dumped_table, @con.yamldb_dump_table(@table)
	end

	def test_yamldb_dump_structure
		assert_equal @dumped_structure, @con.yamldb_dump_structure
	end
end
