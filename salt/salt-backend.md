## Model

```bash
$ cd backend/
```

###### backend/Gemfile

```ruby
...

# Use BCrypt for hashing
gem 'bcrypt'

```

```bash
$ bundle
```

```bash
$ rails g model salt user:references value:string
$ rails db:migrate
```

###### backend/spec/factories/salts.rb

```ruby
FactoryBot.define do
  factory :salt do
    user
  end
end

```

###### backend/spec/models/salt_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Salt, type: :model do
  it { should belong_to(:user) }

  context 'on create' do
    it 'should populate value' do
      salt = create :salt, value: nil
      expect(salt.value).to be_truthy
    end
  end
end

```

###### backend/app/models/salt.rb

```ruby
class Salt < ApplicationRecord
  belongs_to :user

  before_create :set_value

  private

  def set_value
    self.value = BCrypt::Engine.generate_salt
  end
end

```

```bash
$ rspec
$ rubocop
```

#### User Association

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  ...

  it { should have_one(:salt) }
  describe 'salt' do
    context 'on create' do
      it 'should create associated salt' do
        expect { create :user, salt: nil }.to change { Salt.count }.by(1)
      end
    end
  end
end

```

###### backend/app/models/user.rb

```ruby
class User < ActiveRecord::Base
  ...

  has_one :salt
  after_create :create_salt

  private

  ...
end

```

## Controller

```bash
$ touch app/serializers/salt_serializer.rb
```

###### backend/app/serializers/salt_serializer.rb

```ruby
class SaltSerializer < BaseSerializer
  attributes :value
end

```

```bash
$ rails g scaffold_controller salt
```

###### backend/spec/routings/salts_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe SaltsController, type: :routing do
  let(:existing_salt) { create :salt }
  let(:user_name) { existing_salt.user.name }
  let(:member_route) { "/users/#{user_name}/salt" }

  it 'routes to #show' do
    expect(get: member_route).to route_to('salts#show', user_name: user_name)
  end

  it 'does not route to #update via PUT' do
    expect(put: member_route).not_to be_routable
  end

  it 'does not route to #update via PATCH' do
    expect(patch: member_route).not_to be_routable
  end

  it 'does not route to #destroy' do
    expect(delete: member_route).not_to be_routable
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...
  concern(:saltable) { resource :salt, only: %i[show] }

  ...

  user_concerns = %i[saltable]
  resources :users, only: %i[show], param: :name, concerns: user_concerns
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/controllers/salts_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe SaltsController, type: :controller do
  let(:created_salt) { create :salt }

  describe 'GET #show' do
    it 'returns a success response' do
      user = create :user
      params = { user_name: user.to_param }
      expect_response(:ok) { get :show, params: params }
    end
  end
end

```

###### backend/app/controllers/salts_controller.rb

```ruby
class SaltsController < ApplicationController
  before_action :set_user

  def show
    render json: SaltSerializer.new(@user.salt)
  end

  private

  def set_user
    @user = User.find_by_name! params[:user_name]
  rescue ActiveRecord::RecordNotFound
    render json: { name: params[:user_name] }, status: :not_found
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/users/reddituser/salt | jq
```

