## Model

```bash
$ cd backend/
```

```bash
$ rails g model post title:text url:string:uniq body:text active:boolean token:string:uniq
$ rails db:migrate
```

###### backend/spec/factories/posts.rb

```ruby
FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    url { Faker::Internet.unique.url }
  end
end

```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'
require 'shared/concerns/a_tokenable'

RSpec.describe Post, type: :model do
  it_behaves_like 'an activatable'
  it_behaves_like 'a tokenable'

  it { should validate_presence_of(:title) }
  it { should validate_length_of(:title).is_at_most(256) }
  it { should_not allow_values(*blank_values).for(:title) }

  it { should validate_length_of(:body).is_at_most(10_000) }

  it { should validate_uniqueness_of(:url) }
  it { should_not allow_values(*invalid_urls).for(:url) }
  it { should allow_values(*valid_urls).for(:url) }
end

```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  include Activatable
  include Tokenable

  validates :title, presence: true, allow_blank: false, length: { maximum: 256 }

  validates :body, length: { maximum: 10_000 }

  validates :url, uniqueness: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
end

```

```bash
$ rspec
$ rubocop
```

## Controller

<!-- look into creating custom generator that brings in the base serializer AND uses the default serializer generator -->

```bash
$ touch app/serializers/post_serializer.rb
```

###### backend/app/serializers/post_serializer.rb

```ruby
class PostSerializer < BaseSerializer
  attributes :title, :url, :body, :active, :token
end

```

```bash
$ rails g scaffold_controller post
```

###### backend/spec/routing/posts_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :routing do
  let(:existing_post) { create :post }

  let(:collection_route) { '/posts' }

  let(:member_route) { "/posts/#{existing_post.to_param}" }
  # let(:member_params) { { token: existing_post.to_param } }

  it 'routes to #index' do
    # expect(get: collection_route).not_to be_routable
    expect(get: collection_route).to route_to('posts#index')
  end

  it 'does not route to #show' do
    expect(get: member_route).not_to be_routable
    # expect(get: member_route).to route_to('posts#show', member_params)
  end

  it 'does not route to #create' do
    expect(post: collection_route).not_to be_routable
    # expect(post: collection_route).to route_to('posts#create')
  end

  it 'does not route to #update via PUT' do
    expect(put: member_route).not_to be_routable
    # expect(put: member_route).to route_to('posts#update', member_params)
  end

  it 'does not route to #update via PATCH' do
    expect(patch: member_route).not_to be_routable
    # expect(patch: member_route).to route_to('posts#update', member_params)
  end

  it 'does not route to #destroy' do
    expect(delete: member_route).not_to be_routable
    # expect(delete: member_route).to route_to('posts#destroy', member_params)
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :posts, only: %i[index]#, param: :token
end

```

```bash
$ rspec spec/routing/
```

<!-- ###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  ...

  describe 'to_param' do
    it 'overrides #to_param with name attribute' do
      post = create :post
      expect(post.to_param).to eq(post.token)
    end
  end
end

```

###### backend/app/models/post.rb

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

```bash
$ rspec spec/models/
``` -->

###### backend/spec/controllers/posts_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  # let(:created_post) { create :post }

  describe 'GET #index' do
    it 'returns a success response' do
      expect_response(:ok) { get :index }
    end
  end

  # describe 'GET #show' do
  #   context 'with valid indentifier' do
  #     it 'returns a success response' do
  #       expect_response(:ok) do
  #         params = { token: created_post.to_param }
  #         get :show, params: params
  #       end
  #     end
  #   end

  #   context 'with invalid indentifier' do
  #     it 'returns an error response' do
  #       expect_response(:not_found) do
  #         params = { token: '' }
  #         get :show, params: params
  #       end
  #     end
  #   end
  # end

  # describe 'POST #create' do
  #   context 'with valid params' do
  #     let(:request_create) do
  #       new_post = build :post
  #       params = { post: new_post.as_json }
  #       post :create, params: params
  #     end

  #     it 'blah' do
  #       request_create
  #     end

  #     it 'returns a success response' do
  #       expect_response(:created) { request_create }
  #     end

  #     it 'creates the requested post' do
  #       expect { request_create }.to change { Post.count }.by(1)
  #     end
  #   end

  #   context 'with invalid params' do
  #     it 'returns an error response' do
  #       expect_response(:unprocessable_entity) do
  #         new_post = build :post, title: '', url: ''
  #         params = { post: new_post.as_json }
  #         post :create, params: params
  #       end
  #     end
  #   end
  # end

  # describe 'PUT #update' do
  #   context 'with valid indentifier' do
  #     context 'with valid params' do
  #       let(:new_title) { 'other' }
  #       let(:new_url) { 'http://www.other.com' }
  #       let(:request_update) do
  #         post_patch = build :post, title: new_title, url: new_url
  #         params = { token: created_post.to_param, post: post_patch.as_json }
  #         put :update, params: params
  #       end

  #       it 'returns a success response' do
  #         expect_response(:ok) { request_update }
  #       end

  #       it 'updates the requested post' do
  #         request_update

  #         created_post.reload
  #         assert_equal new_title, created_post.title
  #         assert_equal new_url, created_post.url
  #       end
  #     end

  #     context 'with invalid params' do
  #       it 'returns an error response' do
  #         expect_response(:unprocessable_entity) do
  #           post_patch = build :post, title: '', url: ''
  #           params = { token: created_post.to_param, post: post_patch.as_json }
  #           put :update, params: params
  #         end
  #       end
  #     end
  #   end

  #   context 'with invalid indentifier' do
  #     it 'returns an error response' do
  #       expect_response(:not_found) do
  #         params = { token: '' }
  #         put :update, params: params
  #       end
  #     end
  #   end
  # end

  # describe 'DELETE #destroy' do
  #   context 'with valid identifier' do
  #     it 'returns a success response' do
  #       expect_response(:no_content, content_type: nil) do
  #         params = { token: created_post.to_param }
  #         delete :destroy, params: params
  #       end
  #     end

  #     it 'destroys the requested post' do
  #       params = { token: created_post.to_param }
  #       expect { delete :destroy, params: params }.to change { Post.count }.by(-1)
  #     end
  #   end

  #   context 'with invalid identifier' do
  #     it 'returns an error response' do
  #       expect_response(:not_found) do
  #         params = { token: '' }
  #         delete :destroy, params: params
  #       end
  #     end
  #   end
  # end
end

```

<!-- maybe move the token check to application controller or service? then change all other uses -->

###### backend/app/controllers/posts_controller.rb

```ruby
class PostsController < ApplicationController
  # before_action :set_post, only: %i[show update destroy]
  # before_action :set_post, only: %i[show]

  def index
    posts = Post.all
    render json: PostSerializer.new(posts)
  end

  # def show
  #   render json: PostSerializer.new(@post)
  # end

  # def create
  #   post = Post.new(post_params)

  #   if post.save
  #     render json: PostSerializer.new(post), status: :created
  #   else
  #     render json: post.errors, status: :unprocessable_entity
  #   end
  # end

  # def update
  #   if @post.update(post_params)
  #     render json: PostSerializer.new(@post)
  #   else
  #     render json: @post.errors, status: :unprocessable_entity
  #   end
  # end

  # def destroy
  #   @post.destroy
  # end

  # private

  # def set_post
  #   @post = Post.find_by_token!(params[:token])
  # rescue ActiveRecord::RecordNotFound
  #   render json: { token: params[:token] }, status: :not_found
  # end

  # def post_params
  #   params.require(:post).permit(:user_id, :sub_id, :title, :url, :body)
  # end
end

```

```bash
$ rspec
$ rubocop
```

###### backend/db/seeds.rb

```ruby
posts = 16.times { FactoryBot.create :post }

```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/posts | jq
```

