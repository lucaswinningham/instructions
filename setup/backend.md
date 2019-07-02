```bash
$ rails new backend --api --database=postgresql --skip-test
$ cd backend/
```

###### backend/Gemfile

```ruby
...

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

...

group :development, :test do
  # Use awesome print for debugging readability
  gem 'awesome_print'

  # Use rubocop for static code analyzation
  gem 'rubocop'
end

# Use figaro for environment variables
gem 'figaro'

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
    - 'Gemfile'
    - 'Rakefile'
    - 'bin/*'
    - 'config/environments/*'
    - 'config/application.rb'
    - 'config/puma.rb'
    - 'config/initializers/*'
Metrics/LineLength:
  Max: 100
Metrics/MethodLength:
  Max: 15
Style/FrozenStringLiteralComment:
  Enabled: false
Style/Documentation:
  Enabled: false

```

###### backend/.rubocop.yml

```yaml
AllCops:
  Exclude:
    ...
    - 'Guardfile'
    ...
...

```

###### backend/.rubocop.yml

```yaml
AllCops:
  Exclude:
    ...
    - 'spec/*_helper.rb'
    ...
...
Metrics/BlockLength:
  Exclude:
    - 'spec/**/*_spec.rb'
...

```

```bash
$ echo '' > db/seeds.rb
$ rubocop
```

```bash
$ bundle exec figaro install
```

###### backend/config/application.yml

```yaml
DB_ROLE_NAME: redditapp

DEVS_DB_NAME: redditdevsdb
DEVS_DB_PASS: devs

TEST_DB_NAME: reddittestdb
TEST_DB_PASS: test

PROD_DB_NAME: redditproddb
PROD_DB_PASS: prod

```

###### backend/config/database.yml

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV.fetch("DB_ROLE_NAME") %>
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

```bash
$ mkdir spec/support
$ touch spec/support/validatable.rb
```

###### backend/spec/support/validation_helper.rb

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
  end
end

```

###### backend/spec/rails_helper.rb

```ruby
...

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  ...

  config.include FactoryBot::Syntax::Methods

  config.include Helpers::Validatable, type: :model
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
    - 'spec/rails_helper.rb'
    - 'spec/spec_helper.rb'
...

```

