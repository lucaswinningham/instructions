```bash
$ cd backend/
```

## Salt Model

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

#### Salt User Association

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

```bash
$ rspec
$ rubocop
```

## Salts Controller

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

###### backend/spec/routing/salts_routing_spec.rb

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

  resources :users, only: %i[show], param: :name do
    resource :salt, only: %i[show]
  end
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
  before_action :set_user, only: %i[show]

  def show
    render json: SaltSerializer.new(@user.salt)
  end

  private

  def set_user
    @user = User.find_by_name! params[:user_name]
  rescue ActiveRecord::RecordNotFound
    render json: { user_name: params[:user_name] }, status: :not_found
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

## Nonce Model

```bash
$ rails g model nonce user:references value:string expires_at:datetime
$ rails db:migrate
```

###### backend/spec/factories/nonces.rb

```ruby
FactoryBot.define do
  factory :nonce do
    user
  end
end

```

###### backend/spec/models/nonce_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Nonce, type: :model do
  it { should belong_to(:user) }

  let!(:nonce) { create :nonce, value: nil, expires_at: nil }

  context 'on create' do
    it 'should populate value' do
      expect(nonce.value).to be_truthy
    end

    it 'should populate expires_at' do
      expect(nonce.expires_at).to be_truthy
    end
  end

  it 'should determine expiration' do
    Timecop.travel Nonce::EXPIRATION_DURATION.from_now
    expect(nonce.expired?).to be_truthy
  end
end

```

###### backernd/app/models/nonce.rb

```ruby
class Nonce < ApplicationRecord
  EXPIRATION_DURATION = 5.minutes

  belongs_to :user

  before_create :set_value
  before_create :set_expires_at

  def expired?
    Time.now > Time.at(expires_at)
  end

  private

  def set_value
    self.value = SecureRandom.base64
  end

  def set_expires_at
    self.expires_at = EXPIRATION_DURATION.from_now
  end
end

```

```bash
$ rspec
$ rubocop
```

#### Nonce User Association

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  ...

  it { should have_one(:nonce) }
end

```

###### backend/app/models/user.rb

```ruby
class User < ActiveRecord::Base
  ...

  has_one :nonce

  private

  ...
end

```

```bash
$ rspec
$ rubocop
```

## Nonces Controller

```bash
$ touch app/serializers/nonce_serializer.rb
```

###### backend/app/serializers/nonce_serializer.rb

```ruby
class NonceSerializer < BaseSerializer
  attributes :value

  attribute :user_name do |nonce|
    nonce.user.name
  end
end

```

```bash
$ rails g scaffold_controller nonce
```

###### backend/spec/routing/nonces_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe NoncesController, type: :routing do
  let(:existing_nonce) { create :nonce }
  let(:user_name) { existing_nonce.user.name }
  let(:member_route) { "/users/#{user_name}/nonce" }

  it 'does not route to #show' do
    expect(get: member_route).not_to be_routable
  end

  it 'routes to #create' do
    expect(post: member_route).to route_to('nonces#create', user_name: user_name)
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

  resources :users, ... do
    ...
    resource :nonce, only: %i[create]
  end

  ...
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/controllers/nonces_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe NoncesController, type: :controller do
  describe 'POST #create' do
    it 'returns a success response' do
      user = create :user
      params = { user_name: user.to_param }
      expect_response(:created) { post :create, params: params }
    end
  end
end

```

###### backend/app/controllers/nonces_controller.rb

```ruby
class NoncesController < ApplicationController
  before_action :set_user, only: %i[create]

  def create
    nonce = @user.tap { |user| user.nonce.destroy if user.nonce }.build_nonce

    if nonce.save
      render json: NonceSerializer.new(nonce), status: :created
    else
      render json: nonce.errors, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by_name! params[:user_name]
  rescue ActiveRecord::RecordNotFound
    render json: { user_name: params[:user_name] }, status: :not_found
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X POST http://localhost:3000/users/reddituser/nonce | jq
```

## Cipher Service

<!-- add test? -->

```bash
$ mkdir -p app/services/auth_services
$ touch app/services/auth_services/cipher_service.rb
```

###### backend/app/services/auth_services/cipher_service.rb

```ruby
module AuthServices
  class CipherService
    def self.encrypt(plain_text)
      cipher = new_cipher
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv
      encrypted = cipher.update(plain_text) + cipher.final
      encoded = Base64.encode64(encrypted)
      encoded
    end

    def self.decrypt(encoded)
      decoded = Base64.decode64(encoded)
      cipher = new_cipher
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      decrypted = cipher.update(decoded) + cipher.final
      decrypted
    end

    def self.new_cipher
      OpenSSL::Cipher::AES128.new(:CBC)
    end

    def self.key
      Base64.decode64(ENV['CIPHER_KEY'])
    end

    def self.iv
      Base64.decode64(ENV['CIPHER_IV'])
    end
  end
end

```

```bash
$ rails c
> cipher = AuthServices::CipherService.new_cipher
> cipher.encrypt
> Base64.encode64(cipher.random_key) # remember this, mine was "r/7G4sNX+OpZwQ4LT/1/yg==\n"
> Base64.encode64(cipher.random_iv) # remember this, mine was "Qh0mpEcb9waVAVPOeJX71Q==\n"
> quit
```

###### config/application.yml

```yaml
...

CIPHER_KEY: "r/7G4sNX+OpZwQ4LT/1/yg==\n"
CIPHER_IV: "Qh0mpEcb9waVAVPOeJX71Q==\n"

```

## JSON Web Token Service

<!-- add test? -->

```bash
$ touch app/services/auth_services/jwt_service.rb
```

###### backend/app/services/auth_services/jwt_service.rb

```ruby
module AuthServices
  class JwtService
    def self.encode(payload:)
      now = Time.now.to_i
      payload[:iat] = now
      payload[:nbf] = now
      payload[:exp] = 2.hours.from_now.to_i
      JWT.encode(payload, secret)
    end

    def self.decode(token:)
      OpenStruct.new JWT.decode(token, secret).first
    rescue JWT::DecodeError
      nil
    end

    def self.secret
      ENV['JWT_KEY']
    end
  end
end

```

```bash
$ rails c
> SecureRandom.hex # remember this, mine was "b5373c6e0ae794cd2b34ad2aa82d3290"
> quit
```

###### backend/config/application.yml

```yaml
...

JWT_KEY: "b5373c6e0ae794cd2b34ad2aa82d3290"

```

## User Password

```bash
$ rails g migration AddPasswordDigestToUsers password_digest:string
$ rails db:migrate
```

<!-- can you just use has_secure_password instead of redefining #authenticate and #password= ? -->
<!-- i think not because its PITA to override the authenticate_user! method in application_controller.rb -->
<!-- revisit and reconfirm above -->

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'

RSpec.describe User, type: :model do
  ...

  describe '#authenticate' do
    # TODO: fill out
  end

  describe '#hashed_password=' do
    # TODO: fill out
  end

  describe '#password=' do
    # TODO: fill out
  end
end

```

###### backend/app/models/user.rb

```ruby
class User < ApplicationRecord
  ...

  # password validations

  def authenticate(hashed_password)
    BCrypt::Password.new(password_digest).is_password?(hashed_password) && self
  end

  def hashed_password=(hashed_password)
    self.password_digest = BCrypt::Password.create hashed_password
  end

  def password=(plain_password)
    hashed_password = BCrypt::Engine.hash_secret plain_password, salt.value
    self.password_digest = BCrypt::Password.create hashed_password
  end

  private

  ...
end

```

```bash
$ rspec
$ rubocop
```

## Sessions Controller

```bash
$ touch app/serializers/session_serializer.rb
```

###### backend/app/serializers/session_serializer.rb

```ruby
class SessionSerializer < BaseSerializer
  attributes :token

  attribute :user_name do |session|
    session.user.name
  end
end

```

```bash
$ rails g scaffold_controller session
```

###### backend/spec/routing/sessions_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe SessionsController, type: :routing do
  let(:user_name) { create(:user).name }
  let(:member_route) { "/users/#{user_name}/session" }

  it 'does not route to #show' do
    expect(get: member_route).not_to be_routable
  end

  it 'routes to #create' do
    expect(post: member_route).to route_to('sessions#create', user_name: user_name)
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

  resources :users, ... do
    ...
    resource :session, only: %i[create]
  end
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/controllers/sessions_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe 'POST #create' do
    let(:default_password) { 'secret_password' }

    let!(:created_user) do
      user = create :user
      user.create_nonce
      user.password = default_password
      user.tap(&:save)
    end

    let(:params) do
      hashed_password = BCrypt::Engine.hash_secret default_password, created_user.salt.value
      message = "#{created_user.nonce.value}||#{hashed_password}"
      encrypted_message = AuthServices::CipherService.encrypt message
      { user_name: created_user.to_param, message: encrypted_message }
    end

    context 'with valid params' do
      it 'returns a success response' do
        expect_response(:created) { post :create, params: params }
      end

      it 'destroys the user nonce' do
        expect { post :create, params: params }.to change { Nonce.count }.by(-1)
      end
    end

    # add this test to all other nested user resources
    context 'with invalid user name' do
      it 'renders an error response' do
        new_user = build :user
        invalid_params = params.merge(user_name: new_user.to_param)
        expect_response(:not_found) { post :create, params: invalid_params }
      end
    end

    context 'with invalid nonce' do
      it 'renders an error response' do
        Timecop.travel Nonce::EXPIRATION_DURATION.from_now
        expect_response(:unauthorized) { post :create, params: params }
      end
    end

    context 'with invalid password' do
      it 'renders an error response' do
        created_user.tap { |u| u.password = 'different_password' }.save
        expect_response(:unauthorized) { post :create, params: params }
      end
    end
  end
end

```

```bash
$ mkdir app/services/controller_services
$ touch app/services/controller_services/sessions_service.rb
```

###### backend/app/services/controller_services/sessions_service.rb

```ruby
module ControllerServices
  class SessionsService
    attr_reader :user, :nonce, :password

    def initialize(user:, params:)
      @user = user
      @nonce, @password = AuthServices::CipherService.decrypt(params[:message]).split('||')
    end

    def valid_nonce?
      user.nonce && !user.nonce.expired? && user.nonce.value == nonce
    end

    def valid_password?
      user.authenticate password
    end

    def make_session
      payload = { sub: user.name }
      token = AuthServices::JwtService.encode(payload: payload)
      OpenStruct.new id: nil, user: user, token: token
    end
  end
end

```

<!-- move find_user! to somewhere higher and reuse in other controllers -->

###### backend/app/controllers/sessions_controller.rb

```ruby
class SessionsController < ApplicationController
  before_action :find_user!, :validate_nonce!, :validate_password!

  def create
    user.nonce.destroy
    render_created SessionSerializer.new(session)
  end

  private

  def find_user!
    render_not_found user_name: params[:user_name] unless user
  end

  def validate_nonce!
    render_unauthorized nonce: 'invalid' unless service.valid_nonce?
  end

  def validate_password!
    render_unauthorized password: 'invalid' unless service.valid_password?
  end

  def user
    @user ||= User.find_by_name params[:user_name]
  end

  def service
    @service ||= ControllerServices::SessionsService.new user: user, params: params
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
$ cd backend/
$ rails c
```

```ruby
> user = User.find_by_name 'reddituser'
> user.password = 'secret_password'
> user.save
> quit
```

```bash
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/users/reddituser/salt | jq
$ curl -X POST http://localhost:3000/users/reddituser/nonce | jq
$ cd backend/
$ rails c
```

```ruby
> salt = 'FILL_IN_salt_value_from_above'
> nonce = 'FILL_IN_nonce_value_from_above'
> hashed_password = BCrypt::Engine.hash_secret('secret_password', salt)
> message = AuthServices::CipherService.encrypt("#{nonce}||#{hashed_password}")
> quit
```

```bash
$ curl -X POST -H Content-Type:application/json -H Accept:application/json http://localhost:3000/users/reddituser/session -d '{"message":"FILL_IN_message_from_above"}' | jq
```

