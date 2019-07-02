```bash
$ rails g scaffold_controller sub
```

###### spec/routing/subs_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe SubsController, type: :routing do
  describe 'routing' do
    let(:existing_sub) { create :sub }
    let(:collection_route) { '/subs' }
    let(:member_route) { "/subs/#{existing_sub.to_param}" }
    let(:member_params) { { name: existing_sub.to_param } }

    it 'routes to #index' do
      expect(get: collection_route).to route_to('subs#index')
    end

    it 'routes to #show' do
      expect(get: member_route).to route_to('subs#show', member_params)
    end

    it 'routes to #create' do
      expect(post: collection_route).to route_to('subs#create')
    end

    it 'routes to #update via PUT' do
      expect(put: member_route).to route_to('subs#update', member_params)
    end

    it 'routes to #update via PATCH' do
      expect(patch: member_route).to route_to('subs#update', member_params)
    end

    it 'routes to #destroy' do
      expect(delete: member_route).to route_to('subs#destroy', member_params)
    end
  end
end

```

###### config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :subs, param: :name
end

```

```bash
$ rspec
```

###### spec/models/sub_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Sub, type: :model do
  describe 'to_param' do
    it 'overrides #to_param with name attribute' do
      sub = create :sub
      expect(sub.to_param).to eq(sub.name)
    end
  end
  
  ...
end

```

###### app/models/sub.rb

```ruby
class Sub < ActiveRecord::Base
  ...

  def to_param
    name
  end
end
```

```bash
$ rspec
```

###### spec/controllers/subs_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe SubsController, type: :controller do
  let(:created_sub) { create :sub }

  describe 'GET #index' do
    it 'returns a success response' do
      expect_response(:ok) { get :index }
    end
  end

  describe 'GET #show' do
    context 'with valid indentifier' do
      it 'returns a success response' do
        expect_response(:ok) do
          params = { name: created_sub.to_param }
          get :show, params: params
        end
      end
    end

    context 'with invalid indentifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          new_sub = build :sub
          params = { name: new_sub.to_param }
          get :show, params: params
        end
      end
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:request_create) do
        new_sub = build :sub
        params = { sub: new_sub.as_json }
        post :create, params: params
      end

      it 'returns a success response' do
        expect_response(:created) { request_create }
      end

      it 'creates the requested sub' do
        expect { request_create }.to change { Sub.count }.by(1)
      end
    end

    context 'with invalid params' do
      it 'returns an error response' do
        expect_response(:unprocessable_entity) do
          new_sub = build :sub, name: ''
          params = { sub: new_sub.as_json }
          post :create, params: params
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid indentifier' do
      context 'with valid params' do
        let(:new_name) { 'other' }
        let(:request_update) do
          sub_patch = build :sub, name: new_name
          params = { name: created_sub.to_param, sub: sub_patch.as_json }
          put :update, params: params
        end

        it 'returns a success response' do
          expect_response(:ok) { request_update }
        end

        it 'updates the requested sub' do
          request_update

          created_sub.reload
          assert_equal new_name, created_sub.name
        end
      end

      context 'with invalid params' do
        it 'returns an error response' do
          expect_response(:unprocessable_entity) do
            sub_patch = build :sub, name: ''
            params = { name: created_sub.to_param, sub: sub_patch.as_json }
            put :update, params: params
          end
        end
      end
    end

    context 'with invalid indentifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          new_sub = build :sub
          params = { name: new_sub.to_param }
          put :update, params: params
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with valid identifier' do
      it 'returns a success response' do
        expect_response(:no_content, content_type: nil) do
          params = { name: created_sub.to_param }
          delete :destroy, params: params
        end
      end

      it 'destroys the requested sub' do
        params = { name: created_sub.to_param }
        expect { delete :destroy, params: params }.to change { Sub.count }.by(-1)
      end
    end

    context 'with invalid identifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          new_sub = build :sub
          params = { name: new_sub.to_param }
          delete :destroy, params: params
        end
      end
    end
  end
end

```

```bash
$ rails g serializer Sub name
```

###### app/controllers/subs_controller.rb

```ruby
class SubsController < ApplicationController
  before_action :set_sub, only: %i[show update destroy]

  def index
    subs = Sub.all
    render json: SubSerializer.new(subs)
  end

  def show
    render json: SubSerializer.new(@sub)
  end

  def create
    sub = Sub.new(sub_params)

    if sub.save
      render json: SubSerializer.new(sub), status: :created
    else
      render json: sub.errors, status: :unprocessable_entity
    end
  end

  def update
    if @sub.update(sub_params)
      render json: SubSerializer.new(@sub)
    else
      render json: @sub.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @sub.destroy
  end

  private

  def set_sub
    @sub = Sub.find_by_name!(params[:name])
  rescue ActiveRecord::RecordNotFound
    render json: { name: params[:name] }, status: :not_found
  end

  def sub_params
    params.require(:sub).permit(:name)
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails c
> 4.times { FactoryBot.create :sub }
> quit
$ rails s # ^C to stop
```

in another terminal

```bash
$ curl -X GET http://localhost:3000/subs | jq
$ curl -X POST -H \
  Content-Type:application/json -H Accept:application/json \
  http://localhost:3000/subs \
  -d '{"sub":{"name":"redditsub"}}' | jq
$ curl -X GET http://localhost:3000/subs | jq
$ curl -X GET http://localhost:3000/subs/redditsub | jq
$ curl -X PATCH -H \
  Content-Type:application/json -H Accept:application/json \
  http://localhost:3000/subs/redditsub \
  -d '{"sub":{"name":"othersub"}}' | jq
$ curl -X GET http://localhost:3000/subs | jq
$ curl -X DELETE http://localhost:3000/subs/othersub | jq
$ curl -X GET http://localhost:3000/subs | jq
```

