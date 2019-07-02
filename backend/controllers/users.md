```bash
$ rails g scaffold_controller user
```

###### backend/spec/routing/users_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  describe 'routing' do
    let(:existing_user) { create :user }
    let(:collection_route) { '/users' }
    let(:member_route) { "/users/#{existing_user.to_param}" }
    let(:member_params) { { name: existing_user.to_param } }

    it 'routes to #index' do
      expect(get: collection_route).to route_to('users#index')
    end

    it 'routes to #show' do
      expect(get: member_route).to route_to('users#show', member_params)
    end

    it 'routes to #create' do
      expect(post: collection_route).to route_to('users#create')
    end

    it 'routes to #update via PUT' do
      expect(put: member_route).to route_to('users#update', member_params)
    end

    it 'routes to #update via PATCH' do
      expect(patch: member_route).to route_to('users#update', member_params)
    end

    it 'routes to #destroy' do
      expect(delete: member_route).to route_to('users#destroy', member_params)
    end
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  resources :users, param: :name
end

```

```bash
$ rspec
```

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'to_param' do
    it 'overrides #to_param with name attribute' do
      existing_user = create :user
      expect(existing_user.to_param).to eq(existing_user.name)
    end
  end

  ...
end

```

###### backend/app/models/user.rb

```ruby
class User < ActiveRecord::Base
  ...

  def to_param
    name
  end

  private

  ...
end
```

```bash
$ rspec
```

###### backend/spec/controllers/users_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:created_user) { create :user }

  describe 'GET #index' do
    it 'returns a success response' do
      expect_response(:ok) { get :index }
    end
  end

  describe 'GET #show' do
    context 'with valid indentifier' do
      it 'returns a success response' do
        expect_response(:ok) do
          params = { name: created_user.to_param }
          get :show, params: params
        end
      end
    end

    context 'with invalid indentifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          new_user = build :user
          params = { name: new_user.to_param }
          get :show, params: params
        end
      end
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:request_create) do
        new_user = build :user
        params = { user: new_user.as_json }
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
          params = { user: new_user.as_json }
          post :create, params: params
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid indentifier' do
      context 'with valid params' do
        let(:new_name) { 'other' }
        let(:new_email) { 'other@email.com' }
        let(:request_update) do
          user_patch = build :user, name: new_name, email: new_email
          params = { name: created_user.to_param, user: user_patch.as_json }
          put :update, params: params
        end

        it 'returns a success response' do
          expect_response(:ok) { request_update }
        end

        it 'updates the requested user' do
          request_update

          created_user.reload
          assert_equal new_name, created_user.name
          assert_equal new_email, created_user.email
        end
      end

      context 'with invalid params' do
        it 'returns an error response' do
          expect_response(:unprocessable_entity) do
            user_patch = build :user, name: '', email: ''
            params = { name: created_user.to_param, user: user_patch.as_json }
            put :update, params: params
          end
        end
      end
    end

    context 'with invalid indentifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          new_user = build :user
          params = { name: new_user.to_param }
          put :update, params: params
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with valid identifier' do
      it 'returns a success response' do
        expect_response(:no_content, content_type: nil) do
          params = { name: created_user.to_param }
          delete :destroy, params: params
        end
      end

      it 'destroys the requested user' do
        params = { name: created_user.to_param }
        expect { delete :destroy, params: params }.to change { User.count }.by(-1)
      end
    end

    context 'with invalid identifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          new_user = build :user
          params = { name: new_user.to_param }
          delete :destroy, params: params
        end
      end
    end
  end
end

```

```bash
$ rails g serializer User name email
```

###### backend/app/controllers/users_controller.rb

```ruby
class UsersController < ApplicationController
  before_action :set_user, only: %i[show update destroy]

  def index
    users = User.all
    render json: UserSerializer.new(users)
  end

  def show
    render json: UserSerializer.new(@user)
  end

  def create
    user = User.new(user_params)

    if user.save
      render json: UserSerializer.new(user), status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: UserSerializer.new(@user)
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
  end

  private

  def set_user
    @user = User.find_by_name!(params[:name])
  rescue ActiveRecord::RecordNotFound
    render json: { name: params[:name] }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails c
> 4.times { FactoryBot.create :user }
> quit
$ rails s # ^C to stop
```

in another terminal

```bash
$ curl -X GET http://localhost:3000/users | jq
$ curl -X POST -H \
  Content-Type:application/json -H Accept:application/json \
  http://localhost:3000/users \
  -d '{"user":{"name":"reddituser","email":"reddituser@example.com"}}' | jq
$ curl -X GET http://localhost:3000/users | jq
$ curl -X GET http://localhost:3000/users/reddituser | jq
$ curl -X PATCH -H \
  Content-Type:application/json -H Accept:application/json \
  http://localhost:3000/users/reddituser \
  -d '{"user":{"name":"otheruser"}}' | jq
$ curl -X GET http://localhost:3000/users | jq
$ curl -X DELETE http://localhost:3000/users/otheruser | jq
$ curl -X GET http://localhost:3000/users | jq
```

