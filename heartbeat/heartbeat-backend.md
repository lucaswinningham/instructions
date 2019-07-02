## Controller

```bash
$ cd backend/
```

```bash
$ rails g scaffold_controller heartbeat
```

###### backend/spec/routing/heartbeats_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe HeartbeatsController, type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/heartbeat').to route_to('heartbeats#show')
    end
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  resource :heartbeat, only: %i[show]
end

```

###### backend/spec/controllers/heartbeats_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe HeartbeatsController, type: :controller do
  describe 'GET #show' do
    it 'returns a success response' do
      expect_response(:no_content, content_type: nil) { get :show }
    end
  end
end

```

###### backend/app/controllers/heartbeats_controller.rb

```ruby
class HeartbeatsController < ApplicationController
  def show; end
end

```


```bash
$ rspec
$ rubocop
```

