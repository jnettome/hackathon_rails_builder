class AppBuilder < Rails::AppBuilder
  def readme
    create_file "README.md", "TODO"
  end
  
  def gemfile
    super
    @generator.gem "bootstrap-sass"
    @generator.gem "simple_form"
    @generator.gem "ember-rails"
    @generator.gem "use_js_please"
    @generator.gem "sendgrid"
    @generator.gem "pg"
    @generator.gem "heroku"
    @generator.gem "slim"
    @generator.gem "draper"
    # For Environment Keys
    @generator.gem "figaro"
    # User records
    @generator.gem "devise"
    @generator.gem "omniauth-twitter"
    # Social Media
    @generator.gem "twitter"
    @generator.gem "twitter-text"
    # Money
    @generator.gem "stripe"
    # Development tools
    @generator.gem "rspec-rails", group: [:development, :test]
    @generator.gem "capybara", group: [:test]
    @generator.gem "fabrication", group: [:test]
    @generator.gem "spork", group: [:test] 
    @generator.gem "shoulda-matchers", group: [:test]
    @generator.gem "better_errors", group: [:development]
    @generator.gem "binding_of_caller", group: [:development]
    @generator.gem "letter_opener", group: [:development]
    @generator.gem "rb-fsevent", group: [:development]
    @generator.gem "guard-rspec", group: [:test]
    @generator.gem "guard-spork", group: [:test]
    @generator.gem "guard-jasmine", group: [:test]
    @generator.gem "guard-livereload", group: [:test]
  end

  def test
    # Keep this empty so Rails does not generate unit_test
  end
  
  def leftovers
    # Get the gems
    run 'bundle install'
    # Require Javascript
    generate 'usejsplease:install'
    
    # Add Ember
    gsub_file 'config/environments/development.rb', /^end$/, "  config.ember.variant = :development
end"
    gsub_file 'config/environments/production.rb', /^end$/, "  config.ember.variant = :production
end"
    generate 'ember:bootstrap'

    # Add Bootstrap
    gsub_file 'app/assets/stylesheets/application.css', /^$/, '@import "bootstrap";'
    gsub_file 'app/assets/javascripts/application.js', /\/\/= require_tree/, "//= require bootstrap
//= require_tree"

    # Add Simple Form
    generate 'simple_form:install --bootstrap'

    # Setting up the Testing Environment
    generate 'rspec:install'
    run 'spork rspec --bootstrap'
    run 'guard init rspec'
    run 'guard init spork'
    run 'guard init livereload'
    create_file 'spec/support/mailer_macros.rb', <<-RUBY
module MailerMacros
  def last_email
    ActionMailer::Base.deliveries.last
  end
  
  def reset_email
    ActionMailer::Base.deliveries = []
  end
end
    RUBY
    remove_file 'spec/spec_helper.rb'
    create_file 'spec/spec_helper.rb', <<-RUBY
require 'spork'
Spork.prefork do
  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'capybara/rspec'
  require 'capybara/email/rspec'
  require 'database_cleaner'

  Capybara.javascript_driver = :webkit
  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    # Modules from spec/support
    config.include(MailerMacros)
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true
    config.mock_with :rspec
    config.use_transactional_fixtures = true
    config.treat_symbols_as_metadata_keys_with_true_values = true


    config.before(:each) do 
      reset_email
    end

    config.before(:suite) do
      DatabaseCleaner.clean_with(:truncation)
      DatabaseCleaner.strategy = :transaction
    end
    
    config.before(:each, :js => true) do
      DatabaseCleaner.strategy = :truncation
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end

  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
    RUBY

    # Generic Splash Page
    generate :controller, "pages index about"
    route "root to: 'pages\#index'"
    remove_file "public/index.html"

    # Create a place for API Keys
    generate 'figaro:install'

    remove_file 'config/application.yml'

    # Sublime Text Support for Better Errors
    create_file "config/initializers/better_errors.rb", <<-RUBY
BetterErrors.editor = :sublime if defined? BetterErrors
    RUBY

    create_file "config/initializers/setup_mail.rb", <<-RUBY
ActionMailer::Base.smtp_settings = {
  enable_starttls_auto: true,
  address: "smtp.sendgrid.net",
  port: 25,
  domain: ENV["DOMAIN"],
  authentication: :plain,
  user_name: ENV["SENDGRID_USERNAME"],
  password: ENV["SENDGRID_PASSWORD"]
}
  RUBY

    generate "devise:install"
    # "config.scoped_views = true" inside "config/initializers/devise.rb".
    # config.omniauth :github, 'APP_ID', 'APP_SECRET', :scope => 'user,public_repo'
    generate "devise User"
    generate "devise:views users"
    generate "devise Admin"
    generate "devise:views admins"

    # Rake the DB
    run 'rake db:migrate'

    # Add Database and API keys to gitignore
    append_file ".gitignore", "config/database.yml"
    run "cp config/database.yml config/example_database.yml"

    # Initialize Git
    git :init
    git add: ".", commit: "-m 'initial commit'"

    # Add to Heroku - You should already have the Heroku Toolbelt installed
    # run 'heroku create'
    # run 'git push heroku master'

  end
end