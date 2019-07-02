```bash
$ cd backend/
```

## Authenticator

```bash
$ touch app/services/auth_services/jwt_authenticator.rb
```

###### backend/app/services/auth_services/jwt_authenticator.rb

```ruby
# require 'jwt_service'

module AuthServices
  class JwtAuthenticator
    attr_reader :authorization_header, :claims

    def initialize(headers:)
      @authorization_header = headers['Authorization']

      return unless authorization_header

      strategy, token = authorization_header.split(' ')
      return unless strategy && strategy.casecmp('bearer').zero?

      @claims = JwtService.decode token: token
    end

    def invalid_token?
      authorization_header.nil? || invalid_claims?
    end

    private

    def invalid_claims?
      !claims || !claims.sub || expired? || premature?
    end

    def expired?
      claims.exp && Time.now > Time.at(claims['exp'])
    end

    def premature?
      claims.nbf && Time.now < Time.at(claims['nbf'])
    end
  end
end

```

###### backend/app/controllers/application_controller.rb

```ruby
class ApplicationController < ActionController::API
  ...

  def authenticate_user!
    render_unauthorized error: 'Unauthorized' unless current_user
  end

  def current_user
    @current_user ||= begin
      jwt_authenticator = AuthServices::JwtAuthenticator.new headers: request.headers
      User.find_by_name jwt_authenticator.claims.sub unless jwt_authenticator.invalid_token?
    end
  end
end

```

## Post Create

###### backend/spec/routing/posts_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :routing do
  ...

  it 'routes to #create' do
    expect(post: collection_route).to route_to('posts#create', collection_params)
  end

  ...
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...
  concern(:postable) { resources :posts, only: %i[index create] }
  ...
end

```

```bash
$ rspec spec/routing/
$ rubocop
```

```bash
$ touch spec/support/authenticatable.rb
```

###### backend/spec/support/authenticatable.rb

```ruby
module Helpers
  module Authenticatable
    def login(user)
      payload = { sub: user.name }
      token = AuthServices::JwtService.encode(payload: payload)
      @request.headers['Authorization'] = "Bearer #{token}"
      user
    end
  end
end

```

###### backend/spec/rails_helper.rb

```ruby
...

RSpec.configure do |config|
  ...

  config.include Helpers::Authenticatable, type: :controller
end

...

```

###### backend/spec/controllers/posts_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  ...

  describe 'POST #create' do
    let!(:created_user) { create :user }
    let!(:created_sub) { create :sub }
    let(:create_request) do
      new_post = build :post, user: nil, sub: nil
      params = new_post.attributes.merge sub_name: created_sub.name
      post :create, params: params
    end

    it 'requires authentication' do
      expect_response(:unauthorized) { create_request }
    end

    it 'returns a success response' do
      expect_response(:created) { login(created_user) && create_request }
    end

    it 'should create post' do
      login created_user
      expect { create_request }.to change { Post.count }.by(1)
    end
  end
end

```

###### backend/app/controllers/posts_controller.rb

```ruby
class PostsController < ApplicationController
  before_action :set_sub, only: %i[index create]
  before_action :set_posts, only: %i[index]
  before_action :authenticate_user!, only: %i[create]

  def index
    ...
  end

  def create
    post = Post.new post_params.merge(user: current_user, sub: @sub)

    if post.save
      render json: PostSerializer.new(post), status: :created
    else
      render json: post.errors, status: :unprocessable_entity
    end
  end

  private

  ...

  def post_params
    params.permit(:title, :url)
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails c
> user = User.find_by_name 'reddituser'
> AuthServices::JwtService.encode(payload: { sub: user.name })
 => "some_token"
> Sub.last.name # remember this, mine was "charlyn"
> quit
$ rails s # ^C to stop
```

In another terminal:

```bash
$ cd backend/
$ rails c
> Sub.last.posts.count
> quit
$ curl -X POST -H Content-Type:application/json -H Accept:application/json -H "Authorization:Bearer FILL_IN_token_from_above" http://localhost:3000/subs/charlyn/posts -d '{"user_name":"reddituser","title":"my first api post title","url":"https://bogus.com"}' | jq
$ rails c
> Sub.last.posts.count
> quit
```

## Comment Create

###### backend/spec/routing/comments_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe CommentsController, type: :routing do
  ...

  let(:post_collection_route) { "/posts/#{existing_post.token}/comments" }
  let(:post_collection_params) { { post_token: existing_post.token } }

  let(:comment_collection_route) { "/comments/#{existing_comment.token}/comments" }
  let(:comment_collection_params) { { comment_token: existing_comment.token } }

  ...

  it 'routes to #index' do
    expect(get: post_collection_route).to route_to('comments#index', post_collection_params)
    expect(get: comment_collection_route).to route_to('comments#index', comment_collection_params)
  end

  it 'does not route to #show' do
    ...
  end

  it 'routes to #create' do
    expect(post: post_collection_route).to route_to('comments#create', post_collection_params)
    expect(post: comment_collection_route).to route_to('comments#create', comment_collection_params)
  end

  ...
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  concern(:commentable) { resources :comments, only: %i[index create] }
  ...

  comment_concerns = %i[commentable]
  resources :comments, only: %i[], param: :token, concerns: comment_concerns
end

```

```bash
$ rspec spec/routing/
$ rubocop
```

###### backend/spec/controllers/comments_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  ...

  describe 'POST #create' do
    let!(:created_user) { create :user }
    let!(:created_post) { create :post }
    let!(:created_comment) { create :comment }
    let(:post_create_request) do
      new_comment = build :comment, user: nil, commentable: nil
      params = new_comment.attributes.merge post_token: created_post.token
      post :create, params: params
    end
    let(:comment_create_request) do
      new_comment = build :comment, user: nil, commentable: nil
      params = new_comment.attributes.merge comment_token: created_comment.token
      post :create, params: params
    end

    it 'requires authentication' do
      expect_response(:unauthorized) { post_create_request }
      expect_response(:unauthorized) { comment_create_request }
    end

    it 'returns a success response' do
      expect_response(:created) { login(created_user) && post_create_request }
      expect_response(:created) { login(created_user) && comment_create_request }
    end

    it 'should create comment' do
      login created_user
      expect { post_create_request }.to change { Comment.count }.by(1)
      expect { comment_create_request }.to change { Comment.count }.by(1)
    end
  end
end

```

###### backend/app/controllers/comments_controller.rb

```ruby
class CommentsController < ApplicationController
  before_action :set_post, only: %i[index]
  before_action :set_comments, only: %i[index]
  before_action :set_commentable, only: %i[create]
  before_action :authenticate_user!, only: %i[create]

  def index
    ...
  end

  def create
    comment = Comment.new comment_params.merge(user: current_user, commentable: @commentable)

    if comment.save
      render json: CommentSerializer.new(comment), status: :created
    else
      render json: comment.errors, status: :unprocessable_entity
    end
  end

  private

  ...

  def set_commentable
    @commentable = Post.find_by_token! params[:post_token]
  rescue ActiveRecord::RecordNotFound
    @commentable = Comment.find_by_token! params[:comment_token]
  rescue ActiveRecord::RecordNotFound
    render json: { token: params[:post_token] || params[:comment_token] }, status: :not_found
  end

  def comment_params
    params.permit(:content)
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails c
> user = User.find_by_name 'reddituser'
> AuthServices::JwtService.encode(payload: { sub: user.name })
 => "some_token"
> Post.first.token # remember this, mine was "ce8ef427cea9187e"
> quit
$ rails s # ^C to stop
```

In another terminal:

```bash
$ cd backend/
$ rails c
> Post.first.comments.count
> quit
$ curl -X POST -H Content-Type:application/json -H Accept:application/json -H "Authorization:Bearer FILL_IN_token_from_above" http://localhost:3000/posts/ce8ef427cea9187e/comments -d '{"user_name":"reddituser","content":"my first api comment content"}' | jq
$ rails c
> Post.first.comments.count
> quit
```

## Vote Create / Update

```bash
$ touch app/serializers/vote_serializer.rb
```

###### backend/app/serializers/vote_serializer.rb

```ruby
class VoteSerializer < BaseSerializer
  attributes :direction
end

```

```bash
$ rails g scaffold_controller vote
```

###### backend/spec/routing/votes_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe VotesController, type: :routing do
  let(:existing_post) { create :post }
  let(:existing_comment) { create :comment }

  let(:post_member_route) { "/posts/#{existing_post.token}/vote" }
  let(:post_member_params) { { post_token: existing_post.token } }

  let(:comment_member_route) { "/comments/#{existing_comment.token}/vote" }
  let(:comment_member_params) { { comment_token: existing_comment.token } }

  it 'does not route to #show' do
    expect(get: post_member_route).not_to be_routable
    expect(get: comment_member_route).not_to be_routable
  end

  it 'routes to #create' do
    expect(post: post_member_route).to route_to('votes#create', post_member_params)
    expect(post: comment_member_route).to route_to('votes#create', comment_member_params)
  end

  it 'does not route to #update via PUT' do
    expect(put: post_member_route).not_to be_routable
    expect(put: comment_member_route).not_to be_routable
  end

  it 'does not route to #update via PATCH' do
    expect(patch: post_member_route).not_to be_routable
    expect(patch: comment_member_route).not_to be_routable
  end

  it 'does not route to #destroy' do
    expect(delete: post_member_route).not_to be_routable
    expect(delete: comment_member_route).not_to be_routable
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...
  concern(:voteable) { resource :vote, only: %i[create] }
  
  ...

  post_concerns = %i[... voteable]

  ...

  comment_concerns = %i[... voteable]
end

```

```bash
$ rspec spec/routing/
```

###### backend/spec/controllers/votes_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe VotesController, type: :controller do
  describe 'POST #create' do
    let!(:created_user) { create :user }
    let!(:created_post) { create :post }
    let!(:created_comment) { create :comment }

    context 'with a new vote' do
      let(:post_create_request) do
        new_vote = build :vote, user: nil, voteable: nil
        params = new_vote.attributes.merge post_token: created_post.token
        post :create, params: params
      end
      let(:comment_create_request) do
        new_vote = build :vote, user: nil, voteable: nil
        params = new_vote.attributes.merge comment_token: created_comment.token
        post :create, params: params
      end

      it 'requires authentication' do
        expect_response(:unauthorized) { post_create_request }
        expect_response(:unauthorized) { comment_create_request }
      end

      it 'returns a success response' do
        expect_response(:created) { login(created_user) && post_create_request }
        expect_response(:created) { login(created_user) && comment_create_request }
      end

      it 'should create vote' do
        login created_user
        expect { post_create_request }.to change { Vote.count }.by(1)
        expect { comment_create_request }.to change { Vote.count }.by(1)
      end
    end

    context 'with an existing vote' do
      let(:new_direction) { true }
      let!(:created_post_vote) { create :vote, user: created_user, voteable: created_post }
      let!(:created_comment_vote) { create :vote, user: created_user, voteable: created_comment }
      let(:post_create_request) do
        params = { post_token: created_post.token, direction: new_direction }
        post :create, params: params
      end
      let(:comment_create_request) do
        params = { comment_token: created_comment.token, direction: new_direction }
        post :create, params: params
      end

      it 'should not create vote' do
        login created_user
        expect { post_create_request }.to change { Vote.count }.by(0)
        expect { comment_create_request }.to change { Vote.count }.by(0)
      end

      it 'should update existing vote' do
        login created_user
        post_create_request
        comment_create_request
        expect(created_post_vote.reload.direction).to be true
        expect(created_comment_vote.reload.direction).to be true
      end
    end
  end
end

```

###### backend/app/controllers/votes_controller.rb

```ruby
class VotesController < ApplicationController
  before_action :set_voteable, only: %i[create]
  before_action :authenticate_user!, only: %i[create]

  def create
    vote = Vote.find_or_initialize_by user: current_user, voteable: @voteable

    if vote.update vote_params
      render json: VoteSerializer.new(vote), status: :created
    else
      render json: vote.errors, status: :unprocessable_entity
    end
  end

  private

  def set_voteable
    @voteable = Post.find_by_token! params[:post_token]
  rescue ActiveRecord::RecordNotFound
    @voteable = Comment.find_by_token! params[:comment_token]
  rescue ActiveRecord::RecordNotFound
    render json: { token: params[:post_token] || params[:comment_token] }, status: :not_found
  end

  def vote_params
    params.permit(:direction)
  end
end

```

```bash
$ rspec
$ rubocop
```

```bash
$ rails c
> user = User.find_by_name 'reddituser'
> AuthServices::JwtService.encode(payload: { sub: user.name })
 => "some_token"
> Post.first.token # remember this, mine was "ce8ef427cea9187e"
> Vote.find_by!(user: user, voteable: Post.first).destroy
> quit
$ rails s # ^C to stop
```

In another terminal:

```bash
$ cd backend/
$ rails c
> Post.first.dnvotes
> quit
$ curl -X POST -H Content-Type:application/json -H Accept:application/json -H "Authorization:Bearer FILL_IN_token_from_above" http://localhost:3000/posts/ce8ef427cea9187e/vote -d '{"direction":false}' | jq
$ rails c
> Post.first.dnvotes
> quit
```

