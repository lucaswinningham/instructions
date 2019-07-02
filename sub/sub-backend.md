## Model

```bash
$ cd backend/
```

```bash
$ rails g model sub name:string:uniq active:boolean
$ rails db:migrate
```

###### backend/spec/factories/subs.rb

```ruby
FactoryBot.define do
  factory :sub do
    sequence(:name) { Faker::Internet.unique.username(3..21, ['']) }
  end
end

```

###### backend/spec/models/sub_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'

RSpec.describe Sub, type: :model do
  it_behaves_like 'an activatable'

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).case_insensitive }
  it { should validate_length_of(:name).is_at_least(3).is_at_most(21) }
  it { should_not allow_values(*blank_values).for(:name) }
  it { should_not allow_values(*invalid_sub_names).for(:name) }
  it { should allow_values(*valid_sub_names).for(:name) }
end

```

###### backend/app/models/sub.rb

```ruby
class Sub < ApplicationRecord
  include Activatable

  VALID_NAME_REGEX = /\A[a-zA-Z0-9]+\Z/.freeze
  validates :name, presence: true, allow_blank: false, format: { with: VALID_NAME_REGEX },
                   length: { minimum: 3, maximum: 21 }
  validates_uniqueness_of :name, case_sensitive: false

  has_many :posts
end

```

```bash
$ rspec
$ rubocop
```

<!-- ## Controller

```bash
$ touch app/serializers/sub_serializer.rb
```

###### backend/app/serializers/sub_serializer.rb

```ruby
class SubSerializer < BaseSerializer
  attributes :name
end

```

```bash
$ rails g scaffold_controller sub
```

###### backend/spec/routing/subs_routing_spec.rb

```ruby

  let(:existing_sub) { create :sub }
  let(:collection_route) { '/subs' }
  let(:member_route) { "/subs/#{existing_sub.to_param}" }
  let(:member_params) { { name: existing_sub.to_param } }

  it 'routes to #index' do
    expect(get: collection_route).to route_to('subs#index')
  end

  it 'does not route to #show' do
    expect(get: member_route).to route_to('subs#show', member_params)
  end

  it 'does not route to #create' do
    expect(post: collection_route).not_to be_routable
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
```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :subs, only: %i[], param: :name
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/models/sub_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Sub, type: :model do  
  ...

  describe 'to_param' do
    it 'overrides #to_param with name attribute' do
      sub = create :sub
      expect(sub.to_param).to eq(sub.name)
    end
  end
end

```

###### backend/app/models/sub.rb

```ruby
class Sub < ActiveRecord::Base
  ...

  def to_param
    name
  end
end
```

```bash
$ rspec spec/models/
```

###### backend/spec/controllers/subs_controller_spec.rb

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

  # describe 'POST #create' do
  #   context 'with valid params' do
  #     let(:request_create) do
  #       new_sub = build :sub
  #       params = { sub: new_sub.as_json }
  #       post :create, params: params
  #     end

  #     it 'returns a success response' do
  #       expect_response(:created) { request_create }
  #     end

  #     it 'creates the requested sub' do
  #       expect { request_create }.to change { Sub.count }.by(1)
  #     end
  #   end

  #   context 'with invalid params' do
  #     it 'returns an error response' do
  #       expect_response(:unprocessable_entity) do
  #         new_sub = build :sub, name: ''
  #         params = { sub: new_sub.as_json }
  #         post :create, params: params
  #       end
  #     end
  #   end
  # end

  # describe 'PUT #update' do
  #   context 'with valid indentifier' do
  #     context 'with valid params' do
  #       let(:new_name) { 'other' }
  #       let(:request_update) do
  #         sub_patch = build :sub, name: new_name
  #         params = { name: created_sub.to_param, sub: sub_patch.as_json }
  #         put :update, params: params
  #       end

  #       it 'returns a success response' do
  #         expect_response(:ok) { request_update }
  #       end

  #       it 'updates the requested sub' do
  #         request_update

  #         created_sub.reload
  #         assert_equal new_name, created_sub.name
  #       end
  #     end

  #     context 'with invalid params' do
  #       it 'returns an error response' do
  #         expect_response(:unprocessable_entity) do
  #           sub_patch = build :sub, name: ''
  #           params = { name: created_sub.to_param, sub: sub_patch.as_json }
  #           put :update, params: params
  #         end
  #       end
  #     end
  #   end

  #   context 'with invalid indentifier' do
  #     it 'returns an error response' do
  #       expect_response(:not_found) do
  #         new_sub = build :sub
  #         params = { name: new_sub.to_param }
  #         put :update, params: params
  #       end
  #     end
  #   end
  # end

  # describe 'DELETE #destroy' do
  #   context 'with valid identifier' do
  #     it 'returns a success response' do
  #       expect_response(:no_content, content_type: nil) do
  #         params = { name: created_sub.to_param }
  #         delete :destroy, params: params
  #       end
  #     end

  #     it 'destroys the requested sub' do
  #       params = { name: created_sub.to_param }
  #       expect { delete :destroy, params: params }.to change { Sub.count }.by(-1)
  #     end
  #   end

  #   context 'with invalid identifier' do
  #     it 'returns an error response' do
  #       expect_response(:not_found) do
  #         new_sub = build :sub
  #         params = { name: new_sub.to_param }
  #         delete :destroy, params: params
  #       end
  #     end
  #   end
  # end
end

```

###### backend/app/controllers/subs_controller.rb

```ruby
class SubsController < ApplicationController
  # before_action :set_sub, only: %i[show update destroy]
  before_action :set_sub, only: %i[show]

  def index
    subs = Sub.all
    render json: SubSerializer.new(subs)
  end

  def show
    render json: SubSerializer.new(@sub)
  end

  # def create
  #   sub = Sub.new(sub_params)

  #   if sub.save
  #     render json: SubSerializer.new(sub), status: :created
  #   else
  #     render json: sub.errors, status: :unprocessable_entity
  #   end
  # end

  # def update
  #   if @sub.update(sub_params)
  #     render json: SubSerializer.new(@sub)
  #   else
  #     render json: @sub.errors, status: :unprocessable_entity
  #   end
  # end

  # def destroy
  #   @sub.destroy
  # end

  private

  def set_sub
    @sub = Sub.find_by_name! params[:name]
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
``` -->

###### backend/db/seeds.rb

```ruby
redditsub = FactoryBot.create :sub, name: 'redditsub'
subs = 4.times.map { FactoryBot.create :sub }

...

```

```bash
$ rails db:reset
# $ rails s # ^C to stop
```

<!-- In another terminal:

```bash
$ curl -X GET http://localhost:3000/subs | jq
$ curl -X GET http://localhost:3000/subs/redditsub | jq
``` -->

## Post Association

```bash
$ rails g migration AddSubToPosts sub:references
$ rails db:migrate
```

###### backend/spec/models/sub_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Sub, type: :model do
  ...

  it { should have_many(:posts) }
end

```

###### backend/app/models/sub.rb

```ruby
class Sub < ApplicationRecord
  ...

  has_many :posts
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/factories/posts.rb

```ruby
FactoryBot.define do
  factory :post do
    sub
    ...
  end
end

```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  ...

  it { should belong_to(:sub) }
end
```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  ...

  belongs_to :sub
end

```

###### backend/app/serializers/post_serializer.rb

```ruby
class PostSerializer < BaseSerializer
  ...

  attribute :sub_name do |post|
    post.sub.name
  end
end

```

```bash
$ rspec
$ rubocop
```

<!-- fix this test, make the root posts index route and names make more sense -->

###### backend/spec/routing/posts_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :routing do
  let(:existing_post) { create :post }

  let(:collection_route) { "/subs/#{existing_post.sub.name}/posts" }
  let(:collection_params) { { sub_name: existing_post.sub.name } }

  let(:member_route) { "/subs/#{existing_post.sub.name}/posts/#{existing_post.to_param}" }
  # let(:member_params) { collection_params.merge token: existing_post.to_param }

  it 'routes to #index' do
    expect(get: '/posts').to route_to('posts#index')
    expect(get: collection_route).to route_to('posts#index', collection_params)
  end

  it 'does not route to #show' do
    expect(get: member_route).not_to be_routable
  end

  it 'routes to #create' do
    expect(post: collection_route).to route_to('posts#create', collection_params)
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

  resources :posts, only: %i[index]

  resources :subs, only: %i[], param: :name do
    resources :posts, only: %i[index create]
  end
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/controllers/posts_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let!(:created_post) { create :post }

  describe 'GET #index' do
    it 'returns a success response' do
      expect_response(:ok) { get :index, params: { sub_name: created_post.sub.name } }
    end

    it 'renders all posts' do
      create :post
      get :index
      expect(response_data.count).to eq(2)
    end

    context 'given a valid sub name' do
      it 'renders only posts for that sub' do
        create :post
        get :index, params: { sub_name: created_post.sub.name }
        expect(response_data.count).to eq(1)
        expect(response_data.first.id.to_i).to eq(created_post.id)
      end
    end

    context 'given an invalid sub name' do
      it 'renders an error' do
        expect_response(:not_found) { get :index, params: { sub_name: 'bogus' } }
      end
    end
  end
end

```

###### backend/app/controllers/posts_controller.rb

```ruby
class PostsController < ApplicationController
  before_action :set_sub, only: %i[index]
  # before_action :set_user, only: %i[index]
  before_action :set_posts, only: %i[index]

  def index
    render json: PostSerializer.new(@posts)
  end

  private

  def set_sub
    @sub = Sub.find_by_name! params[:sub_name] if params[:sub_name]
  rescue ActiveRecord::RecordNotFound
    render json: { sub_name: params[:sub_name] }, status: :not_found
  end

  # def set_user
  #   @user = User.find_by_name! params[:user_name] if params[:user_name]
  # rescue ActiveRecord::RecordNotFound
  #   render json: { user_name: params[:user_name] }, status: :not_found
  # end

  def set_posts
    @posts = Post.all
    @posts = @posts.where sub: @sub if @sub
  end
end

```

```bash
$ rspec
$ rubocop
```

###### backend/db/seeds.rb

```ruby
...

posts = 16.times { FactoryBot.create :post, sub_id: subs.sample.id }
redditpost = FactoryBot.create :post, sub_id: redditsub.id, title: 'reddit title', url: 'https://reddit.com', body: 'reddit body'

```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/subs/redditsub/posts | jq
```

