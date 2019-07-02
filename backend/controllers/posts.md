```bash
$ rails g scaffold_controller post
```

###### spec/routing/posts_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :routing do
  describe 'routing' do
    let(:existing_post) { create :post }
    let(:collection_route) { '/posts' }
    let(:member_route) { "/posts/#{existing_post.to_param}" }
    let(:member_params) { { token: existing_post.to_param } }

    it 'routes to #index' do
      expect(get: collection_route).to route_to('posts#index')
    end

    it 'routes to #show' do
      expect(get: member_route).to route_to('posts#show', member_params)
    end

    it 'routes to #create' do
      expect(post: collection_route).to route_to('posts#create')
    end

    it 'routes to #update via PUT' do
      expect(put: member_route).to route_to('posts#update', member_params)
    end

    it 'routes to #update via PATCH' do
      expect(patch: member_route).to route_to('posts#update', member_params)
    end

    it 'routes to #destroy' do
      expect(delete: member_route).to route_to('posts#destroy', member_params)
    end
  end
end

```

###### config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :posts, param: :token
end

```

```bash
$ rspec
```

###### spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'to_param' do
    it 'overrides #to_param with name attribute' do
      post = create :post
      expect(post.to_param).to eq(post.token)
    end
  end

  ...
end

```

###### app/models/post.rb

```ruby
class Post < ActiveRecord::Base
  ...

  def to_param
    token
  end

  private

  ...
end

```

<!-- ###### config/routes.rb

```ruby
Rails.application.routes.draw do
  concern(:postable) { resources :posts }

  user_concerns = [:postable]
  resources :users, param: :name, concerns: user_concerns

  sub_concerns = [:postable]
  resources :subs, param: :name, concerns: sub_concerns
end

``` -->

###### spec/controllers/posts_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:created_post) { create :post }

  describe 'GET #index' do
    it 'returns a success response' do
      expect_response(:ok) { get :index }
    end
  end

  describe 'GET #show' do
    context 'with valid indentifier' do
      it 'returns a success response' do
        expect_response(:ok) do
          params = { token: created_post.to_param }
          get :show, params: params
        end
      end
    end

    context 'with invalid indentifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          params = { token: '' }
          get :show, params: params
        end
      end
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:request_create) do
        new_post = build :post
        params = { post: new_post.as_json }
        post :create, params: params
      end

      it 'blah' do
        request_create
      end

      it 'returns a success response' do
        expect_response(:created) { request_create }
      end

      it 'creates the requested post' do
        expect { request_create }.to change { Post.count }.by(1)
      end
    end

    context 'with invalid params' do
      it 'returns an error response' do
        expect_response(:unprocessable_entity) do
          new_post = build :post, title: '', url: ''
          params = { post: new_post.as_json }
          post :create, params: params
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid indentifier' do
      context 'with valid params' do
        let(:new_title) { 'other' }
        let(:new_url) { 'http://www.other.com' }
        let(:request_update) do
          post_patch = build :post, title: new_title, url: new_url
          params = { token: created_post.to_param, post: post_patch.as_json }
          put :update, params: params
        end

        it 'returns a success response' do
          expect_response(:ok) { request_update }
        end

        it 'updates the requested post' do
          request_update

          created_post.reload
          assert_equal new_title, created_post.title
          assert_equal new_url, created_post.url
        end
      end

      context 'with invalid params' do
        it 'returns an error response' do
          expect_response(:unprocessable_entity) do
            post_patch = build :post, title: '', url: ''
            params = { token: created_post.to_param, post: post_patch.as_json }
            put :update, params: params
          end
        end
      end
    end

    context 'with invalid indentifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          params = { token: '' }
          put :update, params: params
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with valid identifier' do
      it 'returns a success response' do
        expect_response(:no_content, content_type: nil) do
          params = { token: created_post.to_param }
          delete :destroy, params: params
        end
      end

      it 'destroys the requested post' do
        params = { token: created_post.to_param }
        expect { delete :destroy, params: params }.to change { Post.count }.by(-1)
      end
    end

    context 'with invalid identifier' do
      it 'returns an error response' do
        expect_response(:not_found) do
          params = { token: '' }
          delete :destroy, params: params
        end
      end
    end
  end
end

```

```bash
$ rails g serializer Post title url body active token created_at
```

###### app/serializers/post_serializer.rb

```ruby
class PostSerializer
  ...

  attribute :sub_name do |post|
    post.sub.name
  end

  attribute :user_name do |post|
    post.user.name
  end
end

```

###### app/controllers/posts_controller.rb

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: %i[show update destroy]

  def index
    posts = Post.all
    render json: PostSerializer.new(posts)
  end

  def show
    render json: PostSerializer.new(@post)
  end

  def create
    post = Post.new(post_params)

    if post.save
      render json: PostSerializer.new(post), status: :created
    else
      render json: post.errors, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      render json: PostSerializer.new(@post)
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
  end

  private

  def set_post
    @post = Post.find_by_token!(params[:token])
  rescue ActiveRecord::RecordNotFound
    render json: { token: params[:token] }, status: :not_found
  end

  def post_params
    params.require(:post).permit(:user_id, :sub_id, :title, :url, :body)
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails c
> 4.times { FactoryBot.create :post }
> User.all.sample.id # remember this, mine was 20
> Sub.all.sample.id # remember this, mine was 21
> quit
$ rails s # ^C to stop
```

in another terminal

```bash
$ curl -X GET http://localhost:3000/posts | jq
$ curl -X POST \
  -H Content-Type:application/json -H Accept:application/json \
  http://localhost:3000/posts \
  -d '{"post":{"user_id":20,"sub_id":21,"title":"title","url":"http://google.com"}}' | jq \
  # remember token, mine was "5baebfb6e2837da6"
$ curl -X GET http://localhost:3000/posts | jq
$ curl -X GET http://localhost:3000/posts/5baebfb6e2837da6 | jq
$ curl -X PATCH \
  -H Content-Type:application/json -H Accept:application/json \
  http://localhost:3000/posts/5baebfb6e2837da6 \
  -d '{"post":{"title":"other title"}}' | jq
$ curl -X GET http://localhost:3000/posts | jq
$ curl -X DELETE http://localhost:3000/posts/5baebfb6e2837da6 | jq
$ curl -X GET http://localhost:3000/posts | jq
```

