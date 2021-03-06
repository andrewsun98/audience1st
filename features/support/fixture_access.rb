module FixtureAccess

  def self.extended(base)

    Fixtures.reset_cache
    fixtures_folder = File.join(RAILS_ROOT, 'spec', 'fixtures')
    fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
    fixtures += Dir[File.join(fixtures_folder, '*.csv')].map {|f| File.basename(f, '.csv') }

    Fixtures.create_fixtures(fixtures_folder, fixtures)    # This will populate the test database tables

    (class << base; self; end).class_eval do
      @@fixture_cache = {}
      fixtures.each do |table_name|
        table_name = table_name.to_s.tr('.', '_')
        define_method(table_name) do |*fixture_symbols|
          @@fixture_cache[table_name] ||= {}

          instances = fixture_symbols.map do |fixture_symbol|
            if fix = Fixtures.cached_fixtures(ActiveRecord::Base.connection, table_name)[fixture_symbol.to_s]
              @@fixture_cache[table_name][fixture_symbol] ||= fix.find  # find model.find's the instance
            else
              raise StandardError, "No fixture with name '#{fixture_symbol}' found for table '#{table_name}'"
            end
          end
          instances.size == 1 ? instances.first : instances
        end
      end
    end
  end

end
