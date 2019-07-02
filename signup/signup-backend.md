## Model

```bash
$ cd backend/
```

###### backend/Gemfile

```ruby
...

group :development, :test do
  ...

  # Use timecop for time manipulation
  gem 'timecop'
end

...

# Use BCrypt for hashing
gem 'bcrypt'

# Use JWT for auth
gem 'jwt'

# Use RabbitMQ and Bunny for background processing
gem 'bunny'

```

```bash
$ bundle
```

```bash
$ rails g model user name:string:uniq email:string:uniq active:boolean activated_at:datetime deactivated_at:datetime password_digest:string salt:string nonce:string civ:string ckey:string auth_expires_at:datetime
$ rails db:migrate
```

###### backend/spec/factories/users.rb

```ruby
FactoryBot.define do
  factory :user do
    sequence(:name) { Faker::Internet.unique.username(3..20, %w[_ -]) }
    sequence(:email) { Faker::Internet.unique.safe_email }
  end
end

```

###### backend/spec/models/user_spec.rb

```ruby
RSpec.describe User, type: :model do
  blank_values = ['', ' ', "\n", "\r", "\t", "\f"]

  describe 'name' do
    it { should validate_presence_of(:name) }
    it { should_not allow_values(*blank_values).for(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(20) }

    it do
      should_not allow_values(
        'username!',
        'username?',
        'username*',
        'username#',
        'user name'
      ).for(:name)
    end

    it do
      should allow_values(
        'username',
        'user-name',
        'user_name',
        'user1name',
        '_username_',
        '-username-',
        '1username1',
        'USERNAME'
      ).for(:name)
    end
  end

  describe 'email' do
    it { should validate_presence_of(:email) }
    it { should_not allow_values(*blank_values).for(:email) }
    it { should validate_uniqueness_of(:email) }

    it do
      should_not allow_values(
        'plainaddress',
        '#@%^%#$@#$@#.com',
        '@domain.com',
        'Joe Smith <email@domain.com>',
        'email.domain.com',
        'email@domain@domain.com',
        'あいうえお@domain.com',
        'email@domain.com (Joe Smith)',
        'email@-domain.com',
        'email@domain..com'
      ).for(:email)
    end

    it do
      should allow_values(
        'email@domain.com',
        'firstname.lastname@domain.com',
        'email@subdomain.domain.com',
        'firstname+lastname@domain.com',
        'email@123.123.123.123',
        '1234567890@domain.com',
        'email@domain-one.com',
        '_______@domain.com',
        'email@domain.name',
        'email@domain.co.jp',
        'firstname-lastname@domain.com'
      ).for(:email)
    end
  end
end

```

```bash
$ mkdir -p spec/services/auth_services
$ touch spec/services/auth_services/cipher_service_spec.rb
$ mkdir -p app/services/auth_services
$ touch app/services/auth_services/cipher_service.rb
```

###### backend/spec/services/auth_services/cipher_service_spec.rb

```ruby

```

###### backend/app/services/auth_services/cipher_service.rb

```ruby
module AuthServices
  class CipherService
    def self.encrypt(message:, key:, iv:) # rubocop:disable Naming/UncommunicativeMethodParamName
      cipher = new_cipher.tap(&:encrypt)
      key = Base64.decode64 key
      iv = Base64.decode64 iv
      cipher.key = Base64.decode64 key
      cipher.iv = Base64.decode64 iv
      encrypted = cipher.update(message) + cipher.final
      encrypted_and_encoded = Base64.encode64 encrypted
      encrypted_and_encoded
    end

    def self.decrypt(message:, key:, iv:) # rubocop:disable Naming/UncommunicativeMethodParamName
      decoded = Base64.decode64 message
      cipher = new_cipher.tap(&:decrypt)
      cipher.key = Base64.decode64 key
      cipher.iv = Base64.decode64 iv
      decoded_and_decrypted = cipher.update(decoded) + cipher.final
      decoded_and_decrypted
    end

    def self.random_key
      Base64.encode64 new_cipher.tap(&:encrypt).random_key
    end

    def self.random_iv
      Base64.encode64 new_cipher.tap(&:encrypt).random_iv
    end

    def self.new_cipher
      OpenSSL::Cipher::AES128.new(:CBC)
    end
  end
end

```

```bash
$ mkdir app/models/concerns/user_concerns
$ touch app/models/concerns/user_concerns/user_{validations,callbacks,auth,activatable}.rb
```

###### backend/app/models/concerns/user_concerns/user_validations.rb

```ruby
module UserConcerns
  module UserValidations
    extend ActiveSupport::Concern

    VALID_NAME_REGEXP = /\A[A-Za-z0-9_\-]+\Z/.freeze
    VALID_EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP

    included do
      validates(
        :name,
        presence: true,
        allow_blank: false,
        uniqueness: true,
        length: { minimum: 3, maximum: 20 },
        format: { with: VALID_NAME_REGEXP }
      )

      validates(
        :email,
        presence: true,
        allow_blank: false,
        uniqueness: true,
        format: { with: VALID_EMAIL_REGEXP }
      )
    end
  end
end

```

###### backend/app/models/concerns/user_concerns/user_callbacks.rb

```ruby
module UserConcerns
  module UserCallbacks
    extend ActiveSupport::Concern

    included do
      after_create :send_activation_email
    end

    private

    def send_activation_email; end
  end
end

```

###### backend/app/models/concerns/user_concerns/user_auth.rb

```ruby
module UserConcerns
  module UserAuth
    extend ActiveSupport::Concern

    AUTH_EXPIRATION_DURATION = 5.minutes

    included do
      before_create :assign_salt
    end

    # def reset_auth
    #   update nonce: nil, ckey: nil, civ: nil, auth_expires_at: nil
    # end

    def refresh_auth
      new_nonce = SecureRandom.base64
      new_ckey = AuthServices::CipherService.random_key
      new_civ = AuthServices::CipherService.random_iv
      expiration = AUTH_EXPIRATION_DURATION.from_now

      update nonce: new_nonce, ckey: new_ckey, civ: new_civ, auth_expires_at: expiration
    end

    # def valid_signup_auth?(message)
    #   return unless valid_auth_attributes?

    #   decrypted_message = AuthServices::CipherService.decrypt message: message, key: ckey, iv: civ
    #   server_nonce, _client_nonce = decrypted_message.split('||')

    #   server_nonce == nonce
    # rescue OpenSSL::Cipher::CipherError => e
    #   return
    # end

    private

    def assign_salt
      self.salt = BCrypt::Engine.generate_salt
    end

    # def valid_auth_attributes?
    #   Time.now < Time.at auth_expires_at.to_i && nonce && ckey && civ
    # end
  end
end

```

###### backend/app/models/concerns/user_concerns/user_activatable.rb

```ruby
module UserConcerns
  module UserActivatable
    extend ActiveSupport::Concern

    included do
      include Activatable

      before_deactivate :deactivate_associations
    end

    private

    def deactivate_associations; end
  end
end

```

###### backend/app/models/user.rb

```ruby
class User < ApplicationRecord
  include UserConcerns::UserValidations
  include UserConcerns::UserCallbacks
  include UserConcerns::UserActivatable
  include UserConcerns::UserAuth
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ mkdir -p spec/graphql/mutations/users/
$ touch spec/graphql/mutations/users/user_signup_spec.rb
$ mkdir app/graphql/types/auth/
$ touch app/graphql/types/auth/user_auth_type.rb
$ touch app/graphql/mutations/base_mutation.rb
$ mkdir app/graphql/mutations/users/
$ touch app/graphql/mutations/users/user_signup.rb
```

###### backend/spec/graphql/mutations/users/user_signup_spec.rb

```ruby

```

###### backend/app/graphql/types/auth/user_auth_type.rb

```ruby
module Types
  module Auth
    class UserAuthType < BaseObject
      field :salt, String, null: false
      field :nonce, String, null: false
      field :ckey, String, null: false
      field :civ, String, null: false
    end
  end
end

```

###### backend/app/graphql/mutations/base_mutation.rb

```ruby

```

###### backend/app/graphql/mutations/users/user_signup.rb

```ruby

```

###### backend/app/graphql/types/mutation_type.rb

```ruby
module Types
  class MutationType < Types::BaseObject
    field :user_signup, mutation: Mutations::Users::UserSignup
  end
end

```








## Model

<!-- this file needs rarranged i think -->

```bash
$ cd backend/
```

###### backend/Gemfile

```ruby
...

group :development, :test do
  ...

  # Use timecop for time manipulation
  gem 'timecop'
end

...

# Use BCrypt for hashing
gem 'bcrypt'

# Use JWT for auth
gem 'jwt'

# Use RabbitMQ and Bunny for background processing
gem 'bunny'

```

```bash
$ bundle
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

  before_create :assign_value

  private

  def assign_value
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
  describe 'GET #show' do
    let(:created_salt) { create :salt }

    it 'returns a success response' do
      user = create :user
      params = { user_name: user.to_param }
      expect_response(:ok) { get :show, params: params }
    end

    context 'with invalid user name' do
      it 'renders an error response' do
        new_user = build :user
        invalid_params = { user_name: new_user.to_param }
        expect_response(:not_found) { get :show, params: invalid_params }
      end
    end
  end
end

```

###### backend/app/controllers/salts_controller.rb

```ruby
class SaltsController < ApplicationController
  before_action :find_user!

  def show
    render json: SaltSerializer.new(user.salt)
  end

  private

  def find_user!
    render_not_found user_name: params[:user_name] unless user
  end

  def user
    @user ||= User.find_by_name params[:user_name]
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

  it '#expired?' do
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

  before_create :assign_value
  before_create :assign_expires_at

  def expired?
    Time.now > Time.at(expires_at)
  end

  private

  def assign_value
    self.value = SecureRandom.base64
  end

  def assign_expires_at
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

<!-- add test for unprocessable entity -->

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

    context 'with invalid user name' do
      it 'renders an error response' do
        new_user = build :user
        invalid_params = { user_name: new_user.to_param }
        expect_response(:not_found) { post :create, params: invalid_params }
      end
    end
  end
end

```

###### backend/app/controllers/nonces_controller.rb

```ruby
class NoncesController < ApplicationController
  before_action :find_user!

  def create
    nonce = user.tap { |user| user.nonce.destroy if user.nonce }.build_nonce

    if nonce.save
      render json: NonceSerializer.new(nonce), status: :created
    else
      render json: nonce.errors, status: :unprocessable_entity
    end
  end

  private

  def find_user!
    render_not_found user_name: params[:user_name] unless user
  end

  def user
    @user ||= User.find_by_name params[:user_name]
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

## Users Create Action

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

    context 'for a user name already taken' do
      it 'returns an error response' do
        create :user, name: 'username'
        same_user = build :user, name: 'username'
        params = same_user.as_json.symbolize_keys.slice(:name, :email)
        expect_response(:unprocessable_entity) { post :create, params: params }
      end
    end

    # context 'for a user email already taken' do
    #   it 'returns an error response' do
    #     create :user, email: 'user@example.com'
    #     same_user = build :user, email: 'user@example.com'
    #     params = same_user.as_json.symbolize_keys.slice(:name, :email)
    #     expect_response(:unprocessable_entity) { post :create, params: params }
    #   end
    # end

    context 'with invalid params' do
      it 'returns an error response' do
        new_user = build :user, name: '', email: ''
        params = new_user.as_json.symbolize_keys.slice(:name, :email)
        expect_response(:unprocessable_entity) { post :create, params: params }
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
    new_user = User.new new_user_params

    if new_user.save
      Mailers::User::ActivationJob.new(new_user).deliver
      render json: UserSerializer.new(new_user), status: :created
    else
      render json: new_user.errors, status: :unprocessable_entity
    end
  end

  ...

  private

  ...

  def new_user_params
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

<!-- ## Activation -->

### Cipher

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

### JWT

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

### User Password

###### backend/spec/routing/users_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  ...

  it 'routes to #password via PUT' do
    expect(put: "#{member_route}/password").to route_to('users#password', member_params)
  end

  it 'routes to #password via PATCH' do
    expect(patch: "#{member_route}/password").to route_to('users#password', member_params)
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :users, ... do
    ...
    put 'password', on: :member
    patch 'password', on: :member
  end

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

  describe 'PUT #update' do
  end
end

```

###### backend/app/controllers/users_controller.rb

```ruby
class UsersController < ApplicationController
  before_action :find_user!, only: %i[... password]
  before_action :validate_nonce!, only: %i[password]

  ...

  def password
  end

  ...

  private

  ...
  
  # other stuff
end

```

```bash
$ rails s # ^C to stop
```

In another terminal:

```bash
# $ curl -X POST -H Content-Type:application/json -H Accept:application/json http://localhost:3000/users -d '{"name":"itsame","email":"itsame@example.com"}' | jq
```

### Activation Model

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

### Activation User Association

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

### Jobs

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

<!-- stuff about when activated -->

### Activations Controller

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

