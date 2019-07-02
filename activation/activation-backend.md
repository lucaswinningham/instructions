## Model

<!-- this file needs rarranged i think -->

```bash
$ cd backend/
```

###### backend/Gemfile

```ruby
...

# Use RabbitMQ and Bunny for background processing
gem 'bunny'

```

```bash
$ bundle
```

```bash
$ rails g model activation user:references digest:string
$ rails db:migrate
```

###### backend/spec/factories/activations.rb

```ruby
FactoryBot.define do
  factory :activation do
    user
  end
end

```

###### backend/spec/models/activation_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Activation, type: :model do
  it { should belong_to(:user) }

  describe 'digest' do
    context 'on create' do
      it 'should populate' do
        activation = create :activation, digest: nil
        expect(activation.digest).to be_truthy
      end
    end
  end

  describe '#token' do
    context 'on create' do
      it 'should exist' do
        activation = create :activation, digest: nil
        expect(activation.token).to be_truthy
      end

      it 'should match digest' do
        activation = create :activation, digest: nil
        expect(BCrypt::Password.new(activation.digest).is_password?(activation.token)).to be true
      end
    end
  end

  describe '#authenticate' do
    it 'should return a truthy value for correct token' do
      activation = create :activation
      expect(activation.authenticate(activation.token)).to be_truthy
    end

    it 'should return a falsy value for incorrect token' do
      activation = create :activation
      expect(activation.authenticate('bogus')).to be_falsy
    end
  end
end

```

<!-- go through other before_x actions that affect columns directly and swap set_x with assign_x -->

###### backend/app/models/activation.rb

```ruby
class Activation < ActiveRecord::Base
  ...

  attr_reader :token
  before_create :set_token

  before_create :assign_digest

  def authenticate(token)
    BCrypt::Password.new(digest).is_password?(token) && self
  end

  private

  def set_token
    @token = SecureRandom.hex
  end

  def assign_digest
    self.digest = BCrypt::Password.create token
  end
end

```

```bash
$ rspec
$ rubocop
```

## User Association

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  ...

  it { should have_one(:activation) }
  describe 'activation' do
    context 'on create' do
      it 'should create associated activation' do
        expect { create :user, activation: nil }.to change { Activation.count }.by(1)
      end
    end
  end
end

```

###### backend/app/models/user.rb

```ruby
class User < ActiveRecord::Base
  ...

  has_one :activation
  after_create :create_activation

  private

  ...
end

```

```bash
$ rspec
$ rubocop
```

## Bunny

```bash
$ rm app/jobs/application_job.rb
$ touch app/jobs/job.rb
```

<!-- test here -->

###### backend/app/jobs/job.rb

```ruby
module Job
  def enqueue(**kwargs)
    return if Rails.env.test?

    queue_name = kwargs[:queue]
    payload = kwargs[:payload].to_json

    connection = Bunny.new.tap(&:start)
    channel = connection.create_channel
    queue = channel.queue queue_name, durable: true

    puts " [APP_INFO] #{queue_name}:"
    ap JSON.parse(payload)
    queue.publish payload
    connection.close
  end
end

```

```bash
$ mkdir -p app/jobs/mailers/user
$ touch app/jobs/mailers/user/activation_job.rb
```

<!-- test here -->

###### backend/app/jobs/mailers/user/activation_job.rb

```ruby
module Mailers
  module User
    class ActivationJob
      include Job

      def initialize(user)
        @user = user
      end

      def deliver
        enqueue queue: queue, payload: payload
      end

      private

      attr_reader :user

      def queue
        'mailers.user.activation'
      end

      def payload
        { email: user.email, activation_link: activation_link }
      end

      def activation_link
        "#{ENV['CLIENT_URL']}/u/#{user.name}/activate/#{user.activation.token}"
      end
    end
  end
end

```

###### backend/config/application.yml

```yaml
...

CLIENT_URL: http://localhost:4200

```

###### backend/spec/routing/users_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  ...

  it 'routes to #create' do
    expect(post: collection_route).to route_to('users#create')
  end

  ...
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :users, only: %i[show create], ...

  ...
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/controllers/users_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  ...

  describe 'POST #create' do
    context 'with valid params' do
      let(:request_create) do
        new_user = build :user
        params = new_user.as_json.symbolize_keys.slice(:name, :email)
        post :create, params: params
      end

      it 'returns a success response' do
        expect_response(:created) { request_create }
      end

      it 'creates the requested user' do
        expect { request_create }.to change { User.count }.by(1)
      end
    end

    context 'with invalid params' do
      it 'returns an error response' do
        expect_response(:unprocessable_entity) do
          new_user = build :user, name: '', email: ''
          params = new_user.as_json.symbolize_keys.slice(:name, :email)
          post :create, params: params
        end
      end
    end
  end
end

```

###### backend/app/controllers/users_controller.rb

```ruby
class UsersController < ApplicationController
  ...

  def create
    user = User.new user_params

    if user.save
      Mailers::User::ActivationJob.new(user).deliver
      render json: UserSerializer.new(user), status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  ...

  private

  ...

  def user_params
    params.permit(:name, :email)
  end
end

```

```bash
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X POST -H Content-Type:application/json -H Accept:application/json http://localhost:3000/users -d '{"name":"itsame","email":"itsame@example.com"}' | jq
```

<!-- stuff about when activated -->

## Controller

```bash
$ rails g scaffold_controller activation
```

###### backend/spec/routings/activations_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe ActivationsController, type: :routing do
  let(:existing_activation) { create :activation }
  let(:user_name) { existing_activation.user.name }
  let(:member_route) { "/users/#{user_name}/activation" }

  it 'does not route to #show' do
    expect(get: member_route).not_to be_routable
  end

  it 'routes to #update via PUT' do
    expect(put: member_route).to route_to('activations#update', user_name: user_name)
  end

  it 'routes to #update via PATCH' do
    expect(patch: member_route).to route_to('activations#update', user_name: user_name)
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

  resources :users, ... do
    ...
    resource :activation, only: %i[update]
  end
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/controllers/activations_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe ActivationsController, type: :controller do
  describe 'POST #create' do
    let(:created_activation) do
      create :activation
    end

    let(:hashed_password) do
      BCrypt::Engine.hash_secret 'password', created_activation.user.salt.value
    end

    let!(:params) do
      nonce = created_activation.user.create_nonce.value
      token = created_activation.token
      message = "#{nonce}||#{token}||#{hashed_password}"
      encrypted_message = AuthServices::CipherService.encrypt message
      { user_name: created_activation.user.to_param, message: encrypted_message }
    end

    context 'with valid params' do
      it 'returns a success response' do
        expect_response(:created) { put :update, params: params }
      end

      it 'destroys the user activation' do
        expect { put :update, params: params }.to change { Activation.count }.by(-1)
      end

      it 'updates the user password_digest' do
        put :update, params: params
        authentication = created_activation.user.reload.authenticate hashed_password
        expect(authentication).to be_truthy
      end
    end

    context 'with invalid user name' do
      it 'renders an error response' do
        new_user = build :user
        invalid_params = params.merge(user_name: new_user.to_param)
        expect_response(:not_found) { put :update, params: invalid_params }
      end
    end

    context 'with invalid nonce' do
      it 'renders an error response' do
        Timecop.travel Nonce::EXPIRATION_DURATION.from_now
        expect_response(:unauthorized) { put :update, params: params }
      end
    end

    context 'with invalid token' do
      it 'renders an error response' do
        user = created_activation.user
        user.activation.destroy && user.create_activation
        expect_response(:unauthorized) { put :update, params: params }
      end
    end
  end
end

```

```bash
$ touch app/services/controller_services/activations_service.rb
```

###### backend/app/services/controller_services/activations_service.rb

```ruby
module ControllerServices
  class ActivationsService
    attr_reader :user, :nonce, :token, :password

    def initialize(user:, params:)
      @user = user
      @nonce, @password, @token = AuthServices::CipherService.decrypt(params[:message]).split('||')
    end

    def valid_nonce?
      user.nonce && !user.nonce.expired? && user.nonce.value == nonce
    end

    def authentic_token?
      user.activation.authenticate token
    end

    def make_session
      payload = { sub: user.name }
      token = AuthServices::JwtService.encode(payload: payload)
      OpenStruct.new id: nil, user: user, token: token
    end
  end
end

```

###### backend/app/controllers/activations_controller.rb

```ruby
class ActivationsController < ApplicationController
  before_action :find_user!, :validate_nonce!, :authenticate_token!

  def update
    if user.update hashed_password: service.password
      user.activation.destroy
      render_created SessionSerializer.new(session)
    else
      render_unprocessable_entity user.errors
    end
  end

  private

  def find_user!
    render_not_found user_name: params[:user_name] unless user
  end

  def validate_nonce!
    render_unauthorized nonce: 'invalid' unless service.valid_nonce?
  end

  def authenticate_token!
    render_unauthorized token: 'invalid' unless service.authentic_token?
  end

  def user
    @user ||= User.find_by_name params[:user_name]
  end

  def service
    @service ||= ControllerServices::ActivationsService.new user: user, params: params
  end

  def session
    @session ||= service.make_session
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails db:reset
$ rails c
```

```ruby
> user = User.create name: 'anotherreddituser', email: 'anotherreddituser@example.com'
> token = user.activation.token
> quit
```

```bash
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/users/anotherreddituser/salt | jq
$ curl -X POST http://localhost:3000/users/anotherreddituser/nonce | jq
$ cd backend/
$ rails c
```

```ruby
> salt = 'FILL_IN_salt_value_from_above'
> nonce = 'FILL_IN_nonce_value_from_above'
> token = 'FILL_IN_token_value_from_above'
> hashed_password = BCrypt::Engine.hash_secret('secret_password', salt)
> message = AuthServices::CipherService.encrypt("#{nonce}||#{token}||#{hashed_password}")
> quit
```

```bash
$ curl -X PUT -H Content-Type:application/json -H Accept:application/json http://localhost:3000/users/anotherreddituser/activation  -d '{"message":"FILL_IN_message_from_above"}' | jq
```

