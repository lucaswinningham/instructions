## Model

```bash
$ cd backend/
```

```bash
$ rails g model user name:string:uniq email:string:uniq active:boolean
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

<!-- add email validations -->

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'

RSpec.describe User, type: :model do
  it_behaves_like 'an activatable'

  invalid_names = ['username!', 'username?', 'username*', 'username#', 'user name']
  valid_names = ['username', 'user-name', 'user_name', 'user1name', '_username_', '-username-',
                 '1username1', 'USERNAME']

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_length_of(:name).is_at_least(3).is_at_most(20) }
  it { should_not allow_values(*blank_values).for(:name) }
  it { should_not allow_values(*invalid_names).for(:name) }
  it { should allow_values(*valid_names).for(:name) }
end

```

<!-- add email validations -->

###### backend/app/models/user.rb

```ruby
class User < ActiveRecord::Base
  include Activatable

  VALID_NAME_REGEX = /\A[A-Za-z0-9_\-]+\Z/.freeze
  validates :name, presence: true, allow_blank: false, uniqueness: true,
                   format: { with: VALID_NAME_REGEX }, length: { minimum: 3, maximum: 20 }
end

```

```bash
$ rspec
$ rubocop
```

## Controller

```bash
$ touch app/serializers/user_serializer.rb
```

###### backend/app/serializers/user_serializer.rb

```ruby
class UserSerializer < BaseSerializer
  attributes :name, :email
end

```

```bash
$ rails g scaffold_controller user
```

###### backend/spec/routing/users_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  let(:existing_user) { create :user }

  let(:collection_route) { '/users' }

  let(:member_route) { "/users/#{existing_user.to_param}" }
  let(:member_params) { { name: existing_user.to_param } }

  it 'does not route to #index' do
    expect(get: collection_route).not_to be_routable
  end

  it 'routes to #show' do
    expect(get: member_route).to route_to('users#show', member_params)
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
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resources :users, only: %i[show], param: :name
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  ...

  describe 'to_param' do
    it 'overrides #to_param with name attribute' do
      existing_user = create :user
      expect(existing_user.to_param).to eq(existing_user.name)
    end
  end
end

```

###### backend/app/models/user.rb

```ruby
class User < ActiveRecord::Base
  ...

  def to_param
    name
  end
end

```

```bash
$ rspec spec/models/
```

###### backend/spec/controllers/users_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  # describe 'GET #index' do
  #   it 'returns a success response' do
  #     expect_response(:ok) { get :index }
  #   end
  # end

  describe 'GET #show' do
    let(:created_user) { create :user }

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

  # describe 'PUT #update' do
  #   context 'with valid indentifier' do
  #     context 'with valid params' do
  #       let(:new_name) { 'other' }
  #       let(:new_email) { 'other@email.com' }
  #       let(:request_update) do
  #         user_patch = build :user, name: new_name, email: new_email
  #         params = { name: created_user.to_param, user: user_patch.as_json }
  #         put :update, params: params
  #       end

  #       it 'returns a success response' do
  #         expect_response(:ok) { request_update }
  #       end

  #       it 'updates the requested user' do
  #         request_update

  #         created_user.reload
  #         assert_equal new_name, created_user.name
  #         assert_equal new_email, created_user.email
  #       end
  #     end

  #     context 'with invalid params' do
  #       it 'returns an error response' do
  #         expect_response(:unprocessable_entity) do
  #           user_patch = build :user, name: '', email: ''
  #           params = { name: created_user.to_param, user: user_patch.as_json }
  #           put :update, params: params
  #         end
  #       end
  #     end
  #   end

  #   context 'with invalid indentifier' do
  #     it 'returns an error response' do
  #       expect_response(:not_found) do
  #         new_user = build :user
  #         params = { name: new_user.to_param }
  #         put :update, params: params
  #       end
  #     end
  #   end
  # end

  # describe 'DELETE #destroy' do
  #   context 'with valid identifier' do
  #     it 'returns a success response' do
  #       expect_response(:no_content, content_type: nil) do
  #         params = { name: created_user.to_param }
  #         delete :destroy, params: params
  #       end
  #     end

  #     it 'destroys the requested user' do
  #       params = { name: created_user.to_param }
  #       expect { delete :destroy, params: params }.to change { User.count }.by(-1)
  #     end
  #   end

  #   context 'with invalid identifier' do
  #     it 'returns an error response' do
  #       expect_response(:not_found) do
  #         new_user = build :user
  #         params = { name: new_user.to_param }
  #         delete :destroy, params: params
  #       end
  #     end
  #   end
  # end
end

```

<!-- abstract out the find_by_xxx! maybe to application controller or module -->

###### backend/app/controllers/users_controller.rb

```ruby
class UsersController < ApplicationController
  # before_action :find_user!, only: %i[show update destroy]
  before_action :find_user!, only: %i[show]

  # def index
  #   users = User.all
  #   render json: UserSerializer.new(users)
  # end

  def show
    render json: UserSerializer.new(user)
  end

  # def update
  #   if user.update(user_params)
  #     render json: UserSerializer.new(user)
  #   else
  #     render json: user.errors, status: :unprocessable_entity
  #   end
  # end

  # def destroy
  #   user.destroy
  # end

  private

  def find_user!
    render_not_found user_name: params[:name] unless user
  end

  def user
    @user ||= User.find_by_name params[:name]
  end
end

```

```bash
$ rspec
$ rubocop
```

###### backend/db/seeds.rb

```ruby
reddituser = FactoryBot.create :user, name: 'reddituser', email: 'reddituser@emample.com'
users = 4.times.map { FactoryBot.create :user }

...

```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/users/reddituser | jq
```

## Post Association

```bash
$ rails g migration AddUserToPosts user:references
$ rails db:migrate
```

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  ...

  it { should have_many(:posts) }
  describe 'posts' do
    context 'on deactivate' do
      it 'should deactivate associated posts' do
        post = create :post
        post.user.deactivate
        post.reload
        expect(post.active).to be false
      end
    end
  end

  ...
end

```

###### backend/app/models/user.rb

```ruby
class User < ApplicationRecord
  ...

  has_many :posts
  before_deactivate :deactivate_posts

  private

  def deactivate_posts
    posts.each(&:deactivate)
  end
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
    user
    ...
  end
end

```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  ...

  it { should belong_to(:user) }
end
```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  ...

  belongs_to :user
end

```

###### backend/app/serializers/post_serializer.rb

```ruby
class PostSerializer < BaseSerializer
  ...

  attribute :user_name do |post|
    post.user.name
  end
end

```

```bash
$ rspec
$ rubocop
```

<!-- ###### backend/spec/routing/posts_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :routing do
  let(:existing_post) { create :post }

  let(:sub_name) { existing_post.sub.name }
  let(:sub_collection_route) { "/subs/#{sub_name}/posts" }
  let(:sub_member_route) { "/subs/#{sub_name}/posts/#{existing_post.to_param}" }
  let(:sub_collection_params) { { sub_name: sub_name } }

  let(:user_name) { existing_post.user.name }
  let(:user_collection_route) { "/users/#{user_name}/posts" }
  let(:user_member_route) { "/users/#{user_name}/posts/#{existing_post.to_param}" }
  let(:user_collection_params) { { user_name: user_name } }

  it 'routes to #index' do
    expect(get: sub_collection_route).to route_to('posts#index', sub_collection_params)
    expect(get: user_collection_route).to route_to('posts#index', user_collection_params)
  end

  it 'does not route to #show' do
    expect(get: sub_member_route).not_to be_routable
    expect(get: user_member_route).not_to be_routable
  end

  it 'does not route to #create' do
    expect(post: sub_collection_route).not_to be_routable
    expect(post: user_collection_route).not_to be_routable
  end

  it 'does not route to #update via PUT' do
    expect(put: sub_member_route).not_to be_routable
    expect(put: user_member_route).not_to be_routable
  end

  it 'does not route to #update via PATCH' do
    expect(patch: sub_member_route).not_to be_routable
    expect(patch: user_member_route).not_to be_routable
  end

  it 'does not route to #destroy' do
    expect(delete: sub_member_route).not_to be_routable
    expect(delete: user_member_route).not_to be_routable
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  user_concerns = %i[postable]
  resources :users, only: %i[index show], param: :name, concerns: user_concerns
end

```

```bash
$ rspec
$ rubocop
``` -->

###### backend/db/seeds.rb

```ruby
...

posts = 16.times { FactoryBot.create :post, user_id: users.sample.id, sub_id: subs.sample.id }
redditpost = FactoryBot.create :post, user_id: reddituser.id, sub_id: redditsub.id, title: 'reddit title', url: 'https://reddit.com', body: 'reddit body'

```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/subs/redditsub/posts | jq
```

