# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a 
# newer version of cucumber-rails. Consider adding your own code to a new file 
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.


ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')

require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support
require 'cucumber/rails/rspec'
require 'cucumber/rails/world'
require 'cucumber/rails/active_record'
require 'cucumber/web/tableish'

require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'


# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css

require 'capybara/poltergeist'
Capybara.register_driver :poltergeist do |app|
  options = {
  }
  Capybara::Poltergeist::Driver.new(app, options)
end
Capybara.javascript_driver = :poltergeist

# If you set this to false, any error raised from within your app will bubble 
# up to your step definition and out to cucumber unless you catch it somewhere
# on the way. You can make Rails rescue errors and render error pages on a
# per-scenario basis by tagging a scenario or feature with the @allow-rescue tag.
#
# If you set this to true, Rails will rescue all errors and render error
# pages, more or less in the same way your application would behave in the
# default production environment. It's not recommended to do this for all
# of your scenarios, as this makes it hard to discover errors in your application.
ActionController::Base.allow_rescue = false

# If you set this to true, each scenario will run in a database transaction.
# You can still turn off transactions on a per-scenario basis, simply tagging 
# a feature or scenario with the @no-txn tag. If you are using Capybara,
# tagging with @culerity or @javascript will also turn transactions off.
#
# If you set this to false, transactions will be off for all scenarios,
# regardless of whether you use @no-txn or not.
#
# Beware that turning transactions off will leave data in your database 
# after each scenario, which can lead to hard-to-debug failures in 
# subsequent scenarios. If you do this, we recommend you create a Before
# block that will explicitly put your database in a known state.
Cucumber::Rails::World.use_transactional_fixtures = false

# How to clean your database when transactions are turned off. See
# http://github.com/bmabey/database_cleaner for more info.
require 'database_cleaner'
require 'database_cleaner/cucumber'
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean_with(:truncation)

Before do
  DatabaseCleaner.start
  Fixtures.reset_cache
  fixtures_folder = File.join(RAILS_ROOT, 'spec', 'fixtures')
  fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
  Fixtures.create_fixtures(fixtures_folder, fixtures)
  load File.join(RAILS_ROOT, 'db', 'seeds.rb') # load static seed data that isn't fixtured
  # make rspec mocks/stubs work
  require 'spec/stubs/cucumber'
  $rspec_mocks ||= Spec::Mocks::Space.new
  # Allow testing of emails
  ActionMailer::Base.delivery_method = :test
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.deliveries.clear
end

After do
  begin
    $rspec_mocks.verify_all
  ensure
    $rspec_mocks.reset_all
    DatabaseCleaner.clean
  end
end

# It is always 1/1/2010, except for tests that specifically manipulate time
Before('~@time') do
  @base_time = Time.parse('January 1, 2010')
  Timecop.travel @base_time
end

# Stub Stripe for certain scenarios
Before('@stubs_successful_credit_card_payment') do
  Store.stub(:pay_with_credit_card) do |order|
    order.update_attribute(:authorization, 'ABC123')
  end
end

Before('@stubs_failed_credit_card_payment') do
  Store.stub(:pay_with_credit_card) do |order|
    order.authorization = nil
    order.errors.add_to_base "Credit card payment error: Forced failure in test mode"
    nil
  end
end

Before('@stubs_successful_refund') do
  Store.stub(:refund_credit_card).and_return(true)
end

Before('@stubs_failed_refund') do
  Store.stub(:refund_credit_card).and_raise(Stripe::StripeError.new("Refund failed in test mode"))
end

World(FactoryGirl::Syntax::Methods)
World(ActionView::Helpers::NumberHelper)
World(ActionView::Helpers::TextHelper)

