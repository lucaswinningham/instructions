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
$ rm mailer.gemspec
$ rm Rakefile
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
```

```bash
$ touch config/setup.rb
```

###### mailer/config/setup.rb

```ruby
require 'bundler/setup'

$ROOT_PATH = File.expand_path '../../lib', __FILE__
$LOAD_PATH.unshift $ROOT_PATH

```

```bash
$ mkdir lib/mailer/workers
$ touch lib/mailer/workers/worker.rb
```

###### mailer/app/workers/worker.rb

```ruby

```

```bash
$ mkdir lib/mailer/workers/user
$ touch lib/mailer/workers/user/activation_worker.rb
```

<!-- add to worker.rb an abstraction for Mailer -->

###### mailer/app/workers/mailers/user/activation_worker.rb

```ruby

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

