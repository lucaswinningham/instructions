```bash
$ cd backend/
```

###### Gemfile

```ruby
...

# Use BCrypt for hashing
gem 'bcrypt'

# Use JWT for auth
gem 'jwt'

```

```bash
$ bundle
```

#### Auth Salt Model

```bash
$ rails g model salt user:belongs_to salt_string:string
$ rails db:migrate
```

###### spec/factories/salts.rb

###### spec/models/salt_spec.rb

###### app/models/salt.rb

```ruby
class Salt < ApplicationRecord
  belongs_to :user

  def self.generate_salt
    BCrypt::Engine.generate_salt
  end
end

```

```bash
$ rspec
$ rubocop
```

#### Auth Salts Controller

```bash
$ rails g scaffold_controller salt
```

###### spec/routings/salts_routing_spec.rb

###### config/routes.rb

```ruby
Rails.application.routes.draw do
  ...
  concern(:saltable) { resource :salt, only: :show }

  user_concerns = %i[... saltable]
  ...
end

```

```bash
$ rspec
$ rubocop
```

###### spec/controllers/salts_controller_spec.rb

```bash
$ rails g serializer Salt salt_string
```

<!-- figure out how to return user name and not its id using the fast json api -->
###### app/serializers/salt_serializer.rb

```ruby
class SaltSerializer
  ...

  belongs_to :user
end

```

###### app/controllers/salts_controller.rb

```ruby
class SaltsController < ApplicationController
  before_action :set_user

  def show
    if @user
      render json: SaltSerializer.new(@user.salt)
    else
      salt = Salt.new(salt_string: Salt.generate_salt)
      render json: SaltSerializer.new(salt)
    end
  end

  private

  def set_user
    @user = User.find_by_name params[:user_name]
  end
end

```

```bash
$ rspec
$ rubocop
```

<!-- move this to somewhere before here -->
#### Auth Cipher

```bash
$ touch lib/cipher_service.rb
```

###### lib/cipher_service.rb

```ruby
class CipherService
  def self.encrypt(plain_text)
    cipher = new_cipher
    cipher.encrypt
    cipher.key = key
    cipher.iv = iv
    encrypted = cipher.update(plain_text) + cipher.final
    encoded = Base64.encode64(encrypted)
  end

  def self.decrypt(encoded)
    decoded = Base64.decode64(encoded)
    cipher = new_cipher
    cipher.decrypt
    cipher.key = key
    cipher.iv = iv
    decrypted = cipher.update(decoded) + cipher.final
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

```

Remember this key and iv for the frontend

```bash
$ rails c
> cipher = OpenSSL::Cipher::AES128.new(:CBC)
> cipher.encrypt
> raw_key = cipher.random_key
> raw_iv = cipher.random_iv
> encoded_key = Base64.encode64(raw_key)
 => "secret_encyption_key"
> encoded_iv = Base64.encode64(raw_iv)
 => "secret_encyption_iv"
```

###### config/application.yml

```yaml
...

CIPHER_KEY: 'secret_encryption_key'
CIPHER_IV: 'secret_encryption_iv'

```

#### Auth Sessions Controller

```bash
$ rails g scaffold_controller session
```

###### spec/routings/sessions_routing_spec.rb

###### config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :sessions, only: :create
end

```

```bash
$ rspec
$ rubocop
```

###### spec/controllers/sessions_controller_spec.rb

```bash
$ rails g serializer Session user_name token
```

###### app/controllers/sessions_controller.rb

```ruby

```

<!-- serializers -->

```bash
$ rspec
$ rubocop
```

#### Auth Nonce Model

```bash
$ rails g model nonce user:belongs_to nonce_string:string expiration_at:datetime
$ rails db:migrate
```

###### spec/factories/nonces.rb

###### spec/models/nonce_spec.rb

###### app/models/nonce.rb

```ruby
class Nonce < ApplicationRecord
  belongs_to :user

  validates :nonce_string, presence: true, allow_blank: false, length: { minimum: 24, maximum: 24 }

  def self.generate_nonce
    SecureRandom.base64
  end

  def expired?
    Time.now > Time.at(expiration_at)
  end
end

```

```bash
$ rspec
$ rubocop
```

#### Auth Nonces Controller

```bash
$ rails g scaffold_controller nonce
```

###### spec/routings/nonces_routing_spec.rb

###### config/routes.rb

```ruby
Rails.application.routes.draw do
  ...
  concern(:nonceable) { resource :nonce, only: :create }

  user_concerns = %i[... nonceable]
  ...
end

```

```bash
$ rspec
$ rubocop
```

###### spec/controllers/nonces_controller_spec.rb

```bash
$ rails g serializer Nonce nonce_string
```

<!-- figure out how to return user name and not its id using the fast json api -->
###### app/serializers/nonce_serializer.rb

```ruby
class NonceSerializer
  ...

  belongs_to :user
end

```

###### app/controllers/nonces_controller.rb

```ruby
class NoncesController < ApplicationController
  before_action :set_user

  def create
    return render_unauthorized "Username #{params[:user_name]} does not exist" unless @user

    nonce = @user.build_nonce(nonce_creation_attributes)

    if nonce.save
      render json: NonceSerializer.new(nonce), status: :created
    else
      render json: nonce.errors, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by_name params[:user_name]
  end

  def nonce_creation_attributes
    { user_id: @user.id, nonce_string: Nonce.generate_nonce, expiration_at: 5.minutes.from_now }
  end

  # TODO: move up a level since this is shared with sessions controller
  # maybe make an auth controller that this and sessions and maybe other controllers can inherit from
  # application_controller can use this as well
  def render_unauthorized(error)
    json = { error: error }
    render json: json, status: :unauthorized
  end
end

```

<!-- serializers -->

```bash
$ rspec
$ rubocop
```

#### Auth Json Web Token

```bash
$ touch lib/jwt_service.rb
```

###### lib/jwt_service.rb

```ruby
class JwtService
  def self.encode(payload:)
    now = Time.now.to_i
    payload[:iat] = now
    payload[:nbf] = now
    payload[:exp] = 2.hours.from_now.to_i
    JWT.encode(payload, secret)
  end

  def self.decode(token:)
    JWT.decode(token, secret).first
  end

  def self.secret
    ENV['JWT_KEY']
  end
end

```

Remember this key for the frontend

```bash
$ rails c
> SecureRandom.hex # remember this for the frontend
 => "secret_jwt_key"
```

###### config/application.yml

```yaml
...

JWT_KEY: 'secret_jwt_key'

```

###### config/application.rb

```ruby
...

module Backend
  class Application < Rails::Application
    ...

    #
    # Added
    #

    ...

    # config.eager_load_paths << Rails.root.join('app/serializers')
    ['app/serializers', 'lib'].each do |path|
      config.eager_load_paths << Rails.root.join(path)
    end
  end
end

```

#### Auth Jwt Authenticator

```bash
$ touch config/initializers/jwt_authenticator.rb
```

###### config/initializers/jwt_authenticator.rb

```ruby
require 'jwt_service'

class JwtAuthenticator
  def initialize(headers)
    @headers = headers
  end

  def invalid_token?
    bearer_header.nil? || invalid_claims
  end

  def claims
    return @claims if @claims

    strategy, token = bearer_header.split(' ')
    return nil if (strategy || '').downcase != 'bearer'
    @claims = JwtService.decode(token: token) rescue nil
  end

  private

  def bearer_header
    @bearer_header ||= @headers['Authorization']&.to_s
  end

  def invalid_claims
    !claims || !claims['sub'] || expired || premature
  end

  def expired
    claims['exp'] && Time.now > Time.at(claims['exp'])
  end

  def premature
    claims['nbf'] && Time.now < Time.at(claims['nbf'])
  end
end

```

###### app/controllers/application_controller.rb

```ruby
class ApplicationController < ActionController::API
  def authenticate_user!
    json = { error: 'Unauthorized' }
    render json: json, status: :unauthorized unless current_user
  end

  def current_user
    return @current_user if @current_user

    jwt_authenticator = JwtAuthenticator.new request.headers
    return if jwt_authenticator.invalid_token?
    @current_user = User.find_by_name jwt_authenticator.claims['sub']
  end
end

```

#### Auth Session Service

```bash
$ touch lib/session_service.rb
```

<!-- rename #make_session to reflect purpose of creating open struct with id nil for netflix fast json api -->
###### lib/session_service.rb

```ruby

```

#### Auth User Model

```bash
$ rails g migration AddPasswordDigestToUsers password_digest:string
$ rails db:migrate
```

###### spec/factories/users.rb

###### spec/models/user_spec.rb

<!-- can you just use has_secure_password instead of redefining #authenticate and #password= ? -->
<!-- i think not because its PITA to override the authenticate_user! method in application_controller.rb -->
<!-- revisit and reconfirm above -->
###### app/models/user.rb

```ruby
class User < ApplicationRecord
  # before_action: :authenticate_user!, only: %i[update delete]
  ...

  # password validations

  has_one :salt, dependent: :destroy

  has_one :nonce, dependent: :destroy

  def authenticate(unencrypted_password)
    BCrypt::Password.new(password_digest).is_password?(unencrypted_password) && self
  end

  def password=(unencrypted_password)
    self.password_digest = BCrypt::Password.create(unencrypted_password)
  end

  private

  ...
end

```

#### Auth Users Controller

###### spec/controllers/users_controller_spec.rb

###### app/controllers/users_controller.rb

```ruby

```

<!-- serializers -->

<!-- TODO: make this cycle mock much prettier -->
Mock of the cycle

GET salt

curl -X GET http://localhost:3000/users/reddituser/salt | jq

POST to users

rails c
salt = 'FILL_IN_salt_string_from_above'
unencrypted_password = 'secret_password'
hashed_password = BCrypt::Engine.hash_secret(unencrypted_password, salt)
password = CipherService.encrypt(hashed_password)

curl -X POST -H Content-Type:application/json -H Accept:application/json http://localhost:3000/users -d '{"user":{"email":"reddituser@email.com","name":"reddituser","password":"FILL_IN_password_from_above"}}' | jq

GET salt

curl -X GET http://localhost:3000/users/reddituser/salt | jq

POST to nonce

curl -X POST -H Content-Type:application/json -H Accept:application/json http://localhost:3000/users/reddituser/nonce | jq

POST to sessions

rails c
salt = 'FILL_IN_salt_string_from_above'
nonce = 'FILL_IN_nonce_string_from_above'
unencrypted_password = 'secret_password'
hashed_password = BCrypt::Engine.hash_secret(unencrypted_password, salt)
message = CipherService.encrypt("#{nonce}||#{hashed_password}")

curl -X POST -H Content-Type:application/json -H Accept:application/json http://localhost:3000/sessions -d '{"session":{"user_name":"reddituser","message":"FILL_IN_message_from_above"}}' | jq

GET user

curl -X GET http://localhost:3000/users/reddituser | jq

DELETE user

curl -X DELETE -H Content-Type:application/json -H Accept:application/json -H "Authorization:Bearer some.token.here" http://localhost:3000/users/reddituser | jq

