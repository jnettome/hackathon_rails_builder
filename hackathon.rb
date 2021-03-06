class AppBuilder < Rails::AppBuilder
  def readme
    create_file "README.md", "TODO"
  end
  
  def gemfile
    # Keep this empty so Rails does not generate a default Gemfile
  end

  def test
    # Keep this empty so Rails does not generate unit_test
  end
  
  def leftovers
    create_file 'Gemfile', <<-TXT
source 'https://rubygems.org'

gem 'rails', '3.2.13'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'compass-rails'
  gem 'coffee-rails'
  gem 'bootstrap-sass'
  gem 'font-awesome-rails'
  gem 'uglifier'
end

gem 'jquery-rails'

group :development, :test do
  gem "rspec-rails"
  gem "jasminerice"
end

group :development do
  gem "better_errors"
  gem "binding_of_caller"
  gem "letter_opener"
  gem "annotate"
  gem "sextant"
end

group :test do
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'shoulda-matchers'
  gem 'capybara-email'
  gem 'terminal-notifier-guard', require: false
  gem 'rb-fsevent', require: false
  gem 'vcr'
  gem 'fakeweb'
  gem 'poltergeist'
  gem 'validates_timeliness'
end

gem "slim"
gem "simple_form"
gem "ember-rails"
gem "use_js_please"
gem "sendgrid"
gem "pg"
gem "draper"
gem "figaro"

# User models and authorization
gem "devise"
gem "cancan"
gem "rolify", git: "git://github.com/EppO/rolify.git"

# For Social Media
gem "omniauth-twitter"
gem "omniauth-facebook"
gem "koala"
gem "twitter"
gem "twitter-text"

# For $$$
gem "stripe", git: 'https://github.com/stripe/stripe-ruby'

# For File Uploads
gem 'carrierwave'
gem 'rmagick'
gem 'fog'
gem 'carrierwave_direct'

# For Queueing and Background Jobs
gem 'redis'
gem 'sidekiq'
TXT
    appname = ask("What is the name of your app? (all lowercase please)")

  # Set up Postgres Locally
    remove_file 'config/database.yml'
    create_file 'config/database.yml', <<-YML
development:
  adapter: postgresql
  database: #{appname}_development
  host: localhost
  pool: 5
  timeout: 5000
  host_names:
    - "localhost"

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: postgresql
  database: #{appname}_test
  host: localhost
  pool: 5
  timeout: 5000
  host_names:
    - test.localhost

YML
    # Ask Questions to be used later
    # domain = ask("What is your domain going to be? (in format http://example.com)")
    # sendgrid_username = ask("What is your sendgrid username?")
    # sendgrid_password = ask("What is your sendgrid password?")
    # twitter_key = ask("What is your twitter api key?")
    # twitter_secret = ask("What is your twitter secret key?")
    # stripe_test_secret_key = ask("What is your Stripe test secret key?")
    # stripe_test_publishable_key = ask("What is your Stripe test publishable key?")
    # stripe_live_secret_key = ask("What is your Stripe live secret key?")
    # stripe_live_publishable_key = ask("What is your Stripe live publishable key?")
    # facebook_key = ask("What is your facebook key?")
    # facebook_secret = ask("What is your facebook secret key?")

    # Get the gems
    run 'bundle install'
    run 'rake db:create'

    # Require Javascript
    generate 'usejsplease:install'
    
    # Add Bootstrap
    gsub_file 'app/assets/stylesheets/application.css', /^$/, '@import "bootstrap";'

    # Add Ember
    generate 'ember:bootstrap'
    gsub_file 'config/environments/development.rb', /^end$/, "  config.ember.variant = :development
end"
    gsub_file 'config/environments/test.rb', /^end$/, "  config.ember.variant = :development
end"
    gsub_file 'config/environments/production.rb', /^end$/, "  config.ember.variant = :production
end"

    # Add Simple Form
    generate 'simple_form:install --bootstrap'

    # Setting up the Testing Environment
    generate 'rspec:install'
    generate 'jasminerice:install'
    run 'spork rspec --bootstrap'
    run 'guard init rspec'
    run 'guard init livereload'
    run 'guard init annotate'
    run 'guard init jasmine'
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
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'rack/test'
require 'capybara/rspec'
require 'capybara/email/rspec'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Modules from spec/support
  config.include(MailerMacros)
  config.include(FactoryGirl::Syntax::Methods)
  config.include(Rack::Test::Methods)

  config.before(:each) do 
    reset_email
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:transaction)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
RUBY

    # Create API Helper
    create_file "spec/support/api_helper.rb", <<-RUBY
module ApiHelper
  include Rack::Test::Methods

  def app
    Rails.application
  end
end

RSpec.configure do |c|
  c.include ApiHelper, :type => :api
end
RUBY

    # Generic Splash Page
    generate :controller, "pages index about"
    route "root to: 'pages\#index'"
    remove_file "public/index.html"

    # Create a place for API Keys
    generate 'figaro:install'
    remove_file 'config/application.yml'
    
    create_file 'config/application-sample.yml', <<-TXT
# Add application configuration variables here, as shown below.
DOMAIN:
SENDGRID_USERNAME: 
SENDGRID_PASSWORD:
TWITTER_KEY:
TWITTER_SECRET:
FACEBOOK_KEY:
FACEBOOK_SECRET:
STRIPE_TEST_SECRET_KEY: 
STRIPE_TEST_PUBLISHABLE_KEY: 
STRIPE_LIVE_SECRET_KEY:
STRIPE_LIVE_PUBLISHABLE_KEY: 
TXT

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

    # Create Users
    generate "devise:install"
    gsub_file "config/initializers/devise.rb", /# config.omniauth :github, 'APP_ID', 'APP_SECRET', :scope => 'user,public_repo'/, "config.omniauth :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET'], :strategy_class => OmniAuth::Strategies::Twitter
  config.omniauth :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'], :strategy_class => OmniAuth::Strategies::Facebook"
    generate "devise User"
    generate "devise:views users"
    generate "migration AddNameToUsers first_name:string last_name:string"
    remove_file 'app/models/user.rb'
    create_file 'app/models/user.rb', <<-RUBY
class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable


  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name
  # attr_accessible :title, :body

  validates :email, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true

end
RUBY
    # Add authorization
    generate 'cancan:ability'
    generate 'rolify Role User'
    remove_file 'app/models/ability.rb'
    create_file 'app/models/ability.rb', <<-RUBY
class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)

    alias_action :create, :read, :update, :destroy, :to => :crud

    if user.has_role? :admin
      can :manage, :all
    else
      can :crud, User
      can :read, :all
    end

  end
end
RUBY


    run 'rake db:migrate'

    # Add Database to .gitignore
    append_file ".gitignore", "config/database.yml"
    run "cp config/database.yml config/example_database.yml"

    # Add initialization to application.rb
    gsub_file 'config/application.rb', /^end$/, "# Compile assets without touching the database
  config.assets.initialize_on_precompile = false
end"

    # Initialize Git
    git :init
    git add: ".", commit: "-m 'initial commit'"

    # Add to Heroku - You should already have the Heroku Toolbelt installed
    # run 'heroku create #{appname}'
    # run 'git push heroku master'
    # run 'rake figaro:heroku'
    # run 'heroku run rake db:migrate'

  end
end