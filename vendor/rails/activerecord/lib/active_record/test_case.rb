require "active_support/test_case"

module ActiveRecord 
  class TestCase < ActiveSupport::TestCase #:nodoc:
    self.fixture_path               = FIXTURES_ROOT
    self.use_instantiated_fixtures  = false
    self.use_transactional_fixtures = true

    def create_fixtures(*table_names, &block)
      Fixtures.create_fixtures(FIXTURES_ROOT, table_names, {}, &block)
    end

    def assert_date_from_db(expected, actual, message = nil)
      # SQL Server doesn't have a separate column type just for dates,
      # so the time is in the string and incorrectly formatted
      if current_adapter?(:SQLServerAdapter)
        assert_equal expected.strftime("%Y/%m/%d 00:00:00"), actual.strftime("%Y/%m/%d 00:00:00")
      elsif current_adapter?(:SybaseAdapter)
        assert_equal expected.to_s, actual.to_date.to_s, message
      else
        assert_equal expected.to_s, actual.to_s, message
      end
    end

    def assert_queries(num = 1)
      $query_count = 0
      yield
    ensure
      assert_equal num, $query_count, "#{$query_count} instead of #{num} queries were executed."
    end

    def assert_no_queries(&block)
      assert_queries(0, &block)
    end
  end
end
