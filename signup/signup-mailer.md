```bash
$ brew install rabbitmq
```

###### ~/.bash_profile

```bash
...

export PATH="$PATH:/usr/local/sbin"

```

```bash
$ source ~/.bash_profile
# $ brew services start rabbitmq
$ rabbitmq-server
```

```bash
$ cd reddit
$ bundle gem mailer --test=rspec --mit --coc
$ cd mailer/
$ rm Rakefile mailer.gemspec
```

###### mailer/Gemfile

```ruby
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Use Guard for running tests
  gem 'guard-rspec'

  # Use RSpec for testing
  gem 'rspec'

  # Use rubocop for static code analyzation
  gem 'rubocop'
end

# Use awesome print for debugging readability
gem 'awesome_print'

# Use dotenv for environment variables
gem 'dotenv'

# Use RabbitMQ, Bunny, and Sneakers for background processing
gem 'bunny'
gem 'sneakers'

# Use mail for sending email
gem 'mail'

```

```bash
$ bundle
$ bundle exec guard init rspec
```

```bash
$ touch .rubocop.yml
```

###### backend/.rubocop.yml

```yaml
AllCops:
  Exclude:
    - 'bin/*'
    - 'config/environments/*'
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
$ mkdir config
$ touch config/setup.rb
```

###### mailer/config/setup.rb

```ruby
require 'bundler/setup'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

```

```bash
$ touch lib/mailer/env.rb
```

###### mailer/lib/mailer/env.rb

```ruby

```

###### mailer/lib/mailer.rb

```ruby
require 'mailer/env'
...

```

###### mailer/spec/spec_helper.rb

```ruby
require 'byebug'
...

```

###### mailer/spec/mailer_spec.rb

```ruby
RSpec.describe Mailer do
  it 'has a version number' do
    expect(Mailer::VERSION).not_to be nil
  end
end

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
end

```

```bash
$ mkdir lib/mailer/workers
$ mkdir -p spec/mailer/workers
```

```bash
$ touch lib/mailer/workers/worker.rb
$ touch spec/mailer/workers/worker_spec.rb
```

###### mailer/lib/mailer/workers/worker.rb

```ruby

```

###### mailer/spec/mailer/workers/worker_spec.rb

```ruby

```

```bash
$ mkdir lib/mailer/workers/user_workers
$ mkdir spec/mailer/workers/user_workers
```

```bash
$ touch lib/mailer/workers/user_workers/confirmation_worker.rb
$ touch spec/mailer/workers/user_workers/confirmation_worker_spec.rb
```

<!-- add to worker.rb an abstraction for Mailer -->

###### mailer/lib/mailer/workers/user_workers/confirmation_worker.rb

```ruby

```

###### mailer/spec/mailer/workers/user_workers/confirmation_worker_spec.rb

```ruby

```

###### mailer/.gitignore

```
...

.env

```

```bash
$ touch .env
```

Go https://myaccount.google.com/security > Signing in to Google > Select app > Other, Select Device > Other, copy password

###### mailer/.env

```
ENVIRONMENT=developement

AMQP_URL=amqp://localhost:5672

GMAIL_USERNAME=lucas.winningham
GMAIL_PASSWORD=zkulxdcuhwzbpdra

```

```bash
$ touch bin/mailer
$ chmod +x bin/mailer
```

###### mailer/bin/mailer

```ruby

```

```bash
$ mkdir log
$ bin/mailer >> log/sneakers.log
```

