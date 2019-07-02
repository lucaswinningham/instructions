## Service

```bash
$ cd backend/
```

<!-- move jwt gem in Gemfile to appropriate file -->

###### backend/Gemfile

```ruby
...

# Use JWT for auth
gem 'jwt'

```

```bash
$ touch app/services/jwt_service.rb
```

###### backend/app/services/jwt_service.rb

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

## Authenticator

```bash
$ touch app/services/jwt_authenticator.rb
```

###### backend/app/services/jwt_authenticator.rb

```ruby
# require 'jwt_service'

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

###### backend/app/controllers/application_controller.rb

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








```bash
$ touch lib/session_service.rb
```

<!-- rename #make_session to reflect purpose of creating open struct with id nil for netflix fast json api -->
###### lib/session_service.rb

```ruby
class SessionService
  def self.make_session(user)
    payload = { sub: user.name }
    token = JwtService.encode(payload: payload)
    OpenStruct.new({ id: nil, user_name: user.name, token: token })
  end
end

```

###### backend/app/controllers/sessions_controller.rb

```ruby
class SessionsController < ApplicationController
  before_action :set_user

  def create
    return render_unauthorized "Username #{create_params[:user_name]} does not exist" unless @user
    return render_unauthorized 'Missing or invalid login nonce' unless valid_nonce?
    return render_unauthorized 'Incorrect password' unless authentic_user?

    @user.nonce.destroy
    session = SessionService.make_session @user
    render json: SessionSerializer.new(session), status: :created
  end

  private

  # def create_params
  #   params.require(:session).permit(:user_name, :hash)
  # end

  def set_user
    # @user = User.find_by_name create_params[:user_name]
    @user = User.find_by_name session_params[:user_name]
  end

  def raw_params
    params.require(:session).permit(:user_name, :message)
  end

  def session_params
    @session_params ||= raw_params.merge password: decrypted_password
  end

  def decrypted_message
    return @decrypted_message if @decrypted_message
    nonce, password = CipherService.decrypt(raw_params[:message]).split('||')
    @decrypted_message = { nonce: nonce, password: password }
  end

  def decrypted_password
    @decrypted_password ||= decrypted_message[:password]
  end

  def nonce
    @nonce ||= @user.nonce
  end

  def valid_nonce?
    nonce && !nonce.expired? && nonce.value == decrypted_message[:nonce]
  end

  def authentic_user?
    @user && @user.authenticate(decrypted_password)
  end

  def render_unauthorized(error)
    json = { error: error }
    render json: json, status: :unauthorized
  end
end

```

