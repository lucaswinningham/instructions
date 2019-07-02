###### backend/Gemfile

```ruby
...

# Use Netflix's serializers
gem 'fast_jsonapi'

```

```bash
$ bundle
```

###### backend/config/application.rb

```ruby
...

module Backend
  class Application < Rails::Application
    ...

    #
    # Added
    #

    config.generators do |g|
      g.test_framework :rspec, request_specs: false
    end
  end
end

```

```bash
$ touch spec/support/respondable.rb
```

###### backend/spec/support/respondable.rb

```ruby
module Helpers
  module Respondable
    def expect_response(status, content_type: 'application/json')
      yield
      expect(response).to have_http_status(status)
      expect(response.content_type).to eq(content_type)
    end
  end
end

```

###### backend/spec/rails_helper.rb

```ruby
...

RSpec.configure do |config|
  ...

  config.include Helpers::Respondable, type: :controller
end

...

```

