```bash
$ cd reddit
$ rails new backend --api --database=postgresql --skip-test
$ cd backend/
$ rails s # ^C to stop
```

[Navigate to backend](http://localhost:3000/)

###### backend/Gemfile

```ruby
...

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

...

group :development, :test do
  # Use rubocop for static code analyzation
  gem 'rubocop-rails'
end

# Use awesome print for debugging readability
gem 'awesome_print'

# Use dotenv for environment variables
gem 'dotenv-rails'

```

```bash
$ bundle
```

###### backend/config/initializers/cors.rb

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*',
             headers: :any,
             expose: ['access-token', 'expiry', 'token-type', 'uid', 'client'],
             methods: %i[get post put patch delete options head]
  end
end

```

```bash
$ touch .rubocop.yml
```

###### backend/.rubocop.yml

```yaml
AllCops:
  Exclude:
    - 'bin/*'
    - 'config/initializers/backtrace_silencers.rb'
    - 'db/schema.rb'
    - 'db/migrate/*'
Metrics/LineLength:
  Max: 100
Metrics/MethodLength:
  Max: 15
Style/FrozenStringLiteralComment:
  Enabled: false
Style/Documentation:
  Enabled: false

```

```bash
$ echo '' > db/seeds.rb
$ rubocop -a
$ rubocop
```

###### backend/.gitignore

```
...

.env

```

```bash
$ touch .env
```

###### backend/.env

```
DB_ROLE_NAME=redditapp

DEVS_DB_NAME=redditdevsdb
DEVS_DB_PASS=devs

TEST_DB_NAME=reddittestdb
TEST_DB_PASS=test

PROD_DB_NAME=redditproddb
PROD_DB_PASS=prod

```

###### backend/config/application.rb

```ruby
...

Dotenv::Railtie.load

module Api
  ...
end

```

###### backend/config/database.yml

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV['DB_ROLE_NAME'] %>
  timeout: 5000


development:
  <<: *default
  database: <%= ENV['DEVS_DB_NAME'] %>
  password: <%= ENV['DEVS_DB_PASS'] %>

test:
  <<: *default
  database: <%= ENV['TEST_DB_NAME'] %>
  password: <%= ENV['TEST_DB_PASS'] %>

production:
  <<: *default
  database: prod_db
  username: <%= ENV['PROD_DB_NAME'] %>
  password: <%= ENV['PROD_DB_PASS'] %>

```

```bash
$ createuser -d redditapp
$ rails db:create
```

## Model Setup

<!-- think about making a not deleteable concern as well -->
<!-- https://www.tigraine.at/2012/02/03/removing-delete-and-destroy-in-rails-models -->

```bash
$ touch app/models/concerns/activatable.rb
```

###### backend/app/models/concerns/activatable.rb

```ruby
module Activatable
  extend ActiveSupport::Concern
  extend ActiveModel::Callbacks

  included do
    define_model_callbacks :activate
    define_model_callbacks :deactivate
  end

  def activate
    run_callbacks :activate do
      update activated_at: Time.now.utc, active: true
    end
  end

  def deactivate
    run_callbacks :deactivate do
      update deactivated_at: Time.now.utc, active: false
    end
  end
end

```

<!-- token service? -->

```bash
$ touch app/models/concerns/tokenable.rb
```

###### backend/app/models/concerns/tokenable.rb

```ruby
module Tokenable
  extend ActiveSupport::Concern

  included do
    before_create :assign_token
  end

  private

  def assign_token
    self.token = SecureRandom.hex until unique_token?
  end

  def unique_token?
    token && self.class.find_by_token(token).nil?
  end
end

```

## Model Setup

<!-- for guarding against AbstractController::DoubleRenderError -->

###### backend/app/controllers/application_controller.rb

```ruby
class ApplicationController < ActionController::API
  # # use before_action's instead
  # def render(*args)
  #   super(*args) unless performed?
  # end

  # Rack::Utils::SYMBOL_TO_STATUS_CODE.keys.each do |status|
  #   define_method "render_#{status}" do |json|
  #     render json: json, status: status
  #   end
  # end

  # private

  # def find_user!
  #   render_not_found user_name: user_name unless user
  # end

  # def user
  #   @user ||= User.find_by_name user_name
  # end

  # def user_name
  #   params[:user_name]
  # end

  # def render_session
  #   payload = { sub: user.name }
  #   token = AuthServices::JwtService.encode(payload: payload)
  #   session = OpenStruct.new id: nil, user: user, token: token
  #   render_created SessionSerializer.new session
  # end
end

```

## Test Setup

###### backend/Gemfile

```ruby
...

group :development, :test do
  ...

  # Use Factory Bot for model generation
  gem 'factory_bot_rails'

  # Use Faker for model attribute generation
  gem 'faker'

  # Use Guard for running tests
  gem 'guard-rspec'

  # Use RSpec for testing
  gem 'rspec-rails'

  # Use Shoulda-Matchers for clear tests
  gem 'shoulda-matchers'
end

...

```

```bash
$ rails g serializer Base created_at updated_at
```

```bash
$ bundle
$ bundle exec guard init rspec
$ rails g rspec:install
```

To start guard:

```bash
$ guard # `quit` to stop
```

Or just run the suite once:

```bash
$ rspec
```

###### backend/.rspec

```
--require rails_helper

```

###### backend/config/application.rb

```ruby
...

module Api
  class Application < Rails::Application
    ...

    config.generators do |g|
      g.test_framework :rspec, request_specs: false
    end
  end
end

```

```bash
$ mkdir spec/support
```
<!-- 
```bash
$ touch spec/support/validatable.rb
``` -->

<!-- this is a dumb helper that includes too much -->
<!-- figure out how to include in tests by bringing this in through require -->
<!-- 
###### backend/spec/support/validatable.rb

```ruby
module Helpers
  module Validatable
    def blank_values
      ['', ' ', "\n", "\r", "\t", "\f"]
    end

    def valid_urls # rubocop:disable Metrics/MethodLength
      [
        'http://foo.com/blah_blah',
        'http://foo.com/blah_blah/',
        'http://www.example.com/wpstyle/?p=364',
        'https://www.example.com/foo/?bar=baz&inga=42&quux',
        'http://userid:password@example.com:8080',
        'http://userid:password@example.com:8080/',
        'http://userid@example.com',
        'http://userid@example.com/',
        'http://userid@example.com:8080',
        'http://userid@example.com:8080/',
        'http://userid:password@example.com',
        'http://userid:password@example.com/',
        'http://142.42.1.1/',
        'http://142.42.1.1:8080/',
        'http://code.google.com/events/#&product=browser',
        'http://j.mp',
        'http://foo.bar/?q=Test%20URL-encoded%20stuff',
        'http://1337.net',
        'http://a.b-c.de'
      ]
    end

    def invalid_urls
      ['//', '//a', '///a', '///', 'foo.com', ':// should fail']
    end

    def valid_sub_names
      %w[subname sub1name 1subname1 SUBNAME]
    end

    def invalid_sub_names
      ['one-two', 'one_two', '_onetwo_', '-onetwo-', 'onetwo!', 'onetwo?', 'onetwo*', 'onetwo#']
    end
  end
end

```

```bash
$ touch spec/support/respondable.rb
``` -->

<!-- maybe move the response_body out of here and to a different helper module so it's single responsibility -->
<!-- call it response_data too unless you can think of a reason to also keep response_body -->

###### backend/spec/support/respondable.rb

```ruby
module Helpers
  module Respondable
    # def expect_response(status, content_type: 'application/json')
    #   yield
    #   expect(response).to have_http_status(status)
    #   expect(response.content_type).to eq(content_type)
    # end

    # def response_body
    #   JSON.parse(response.body, object_class: OpenStruct)
    # end

    # def response_data
    #   response_body.data
    # end

    # fill in with actual code here
  end
end

```

###### backend/spec/rails_helper.rb

```ruby
...

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  ...

  config.include FactoryBot::Syntax::Methods

  # config.include Helpers::Validatable, type: :model

  config.include Helpers::Respondable, type: :request
end

...

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

```

###### backend/.rubocop.yml

```yaml
AllCops:
  Exclude:
    ...
    - 'Guardfile'
    ...
Metrics/BlockLength:
  Exclude:
    - 'spec/**/*_spec.rb'
...

```

```bash
$ rubocop -a
$ rubocop
```

```bash
$ mkdir spec/lint
$ touch spec/lint/rubocop_spec.rb
```

###### backend/spec/lint/rubocop_spec.rb

```ruby
RSpec.describe 'rubocop analysis' do
  subject(:report) { `rubocop` }

  it 'has no offenses' do
    expect(report).to match(/no offenses detected/)
  end
end

```

###### backend/Guardfile

```ruby
...

guard :rspec, cmd: "bundle exec rspec" do
  ...

  watch(/.*/) { 'spec/lint/rubocop_spec.rb' }

  # watch(%r{^app/models/concerns/(.+)_concerns/(.+)\.rb$}) do |m|
  #   "spec/models/#{m[1]}/#{m[2]}_spec.rb"
  # end
end

```

```bash
$ rspec
```

```bash
$ mkdir spec/shared
$ mkdir spec/shared/concerns
$ touch spec/shared/concerns/a_tokenable.rb
$ touch spec/shared/concerns/an_activatable.rb
```

###### backend/spec/shared/concerns/a_tokenable.rb

```ruby
RSpec.shared_examples 'a tokenable' do
  let(:model) { described_class }
  let(:model_sym) { model.to_s.underscore.to_sym }

  describe 'token' do
    context 'on create' do
      it 'should populate' do
        resource = create model_sym, token: nil
        expect(resource.token).to be_truthy
      end
    end
  end
end

```

###### backend/spec/shared/concerns/an_activatable.rb

```ruby
RSpec.shared_examples 'an activatable' do
  let(:model) { described_class }
  let(:model_sym) { model.to_s.underscore.to_sym }

  describe 'active' do
    context 'on create' do
      it 'should be true' do
        resource = create model_sym, active: nil
        expect(resource.active).to be true
      end
    end
  end
end

```

```bash
$ rubocop
```

### Paper Trail

###### backend/Gemfile

```ruby
...

# Use paper_trail for lossless data changes
gem 'paper_trail'

```

```bash
$ rails generate paper_trail:install
```

###### backend/db/migrate/TIMESTAMP_create_versions.rb

```ruby
class CreateVersions < ActiveRecord::Migration[5.1]
  def change
    create_table :versions do |t|
      ...
      t.json     :object
      t.json     :object_changes

      ...
    end
    ...
  end
end

```

```bash
$ rails db:migrate
```

###### backend/app/models/application_record.rb

```ruby
class ApplicationRecord < ActiveRecord::Base
  ...

  has_paper_trail
end

```

### GraphQL

### Paper Trail

###### backend/Gemfile

```ruby
...

group :development do
  # Use graphiql for graphql development
  gem 'graphiql-rails'
end

...

# Use GraphQL for api data
gem 'graphql'

```

```bash
$ bundle
$ rails g graphql:install --api
$ rubocop -a
$ rubocop
```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: 'graphql#execute'
  end

  ...
end

```

###### backend/config/application.rb

```ruby
...
require 'sprockets/railtie'
...

```

```bash
$ rails s # ^C to stop
```

[Navigate to graphiql](http://localhost:3000/graphiql)

###### backend/app/graphql/types/query_type.rb

```ruby
module Types
  class QueryType < Types::BaseObject
  end
end

```

###### backend/app/graphql/types/mutation_type.rb

```ruby
module Types
  class MutationType < Types::BaseObject
  end
end

```

###### backend/app/controllers/graphql_controller.rb

```ruby
class GraphqlController < ApplicationController
  def execute
    ...
    # result = ApiSchema.execute(
    #   query,
    #   variables: variables,
    #   context: context,
    #   operation_name: operation_name
    # )
    # ...
  end

  private

  ...

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    error_json = { error: { message: error.message, backtrace: error.backtrace }, data: {} }
    render json: error_json, status: :internal_server_error
  end
end

```

```bash
$ rspec
```

