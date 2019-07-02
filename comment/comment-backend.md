## Model

```bash
$ cd backend/
```

```bash
$ rails g model comment user:references content:text active:boolean token:string:uniq commentable:references{polymorphic}
$ rails db:migrate
```

<!-- figure out how to sample either post or comment for association :commentable -->

###### backend/spec/factories/comments.rb

```ruby
FactoryBot.define do
  factory :comment do
    user
    content { Faker::Lorem.sentence }
    association :commentable, factory: :post
  end
end

```

###### backend/spec/models/comment_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'
require 'shared/concerns/a_tokenable'

RSpec.describe Comment, type: :model do
  it_behaves_like 'an activatable'
  it_behaves_like 'a tokenable'

  it { should belong_to(:user) }
  it { should belong_to(:commentable) }

  it { should have_many(:comments) }

  it { should validate_presence_of(:content) }
  it { should validate_length_of(:content).is_at_most(10_000) }
  it { should_not allow_values(*blank_values).for(:content) }
end

```

###### backend/app/models/comment.rb

```ruby
class Comment < ApplicationRecord
  include Activatable
  include Tokenable

  ...

  has_many :comments, as: :commentable

  validates :content, presence: true, allow_blank: false, length: { maximum: 10_000 }
end

```

```bash
$ rspec
$ rubocop
```

## Controller

```bash
$ touch app/serializers/comment_serializer.rb
```

###### backend/app/serializers/comment_serializer.rb

```ruby
class CommentSerializer < BaseSerializer
  attributes :content, :active, :token

  attribute :comments do |comment|
    new comment.comments
  end

  attribute :user_name do |comment|
    comment.user.name
  end
end

```

```bash
$ rails g scaffold_controller comment
```

###### backend/db/seeds.rb

```ruby
...

comments = 64.times { FactoryBot.create :comment, user_id: users.sample.id, commentable: (Post.all + Comment.all).sample }
redditcomment = FactoryBot.create :comment, user_id: reddituser.id, content: 'reddit comment', commentable: redditpost

```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/comments | jq
```

## User Association

###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  ...

  it { should have_many(:comments) }
  describe 'comments' do
    context 'on deactivate' do
      it 'should deactivate associated comments' do
        comment = create :comment
        comment.user.deactivate
        comment.reload
        expect(comment.active).to be false
      end
    end
  end
end

```

###### backend/app/models/user.rb

```ruby
class User < ApplicationRecord
  ...

  has_many :comments
  before_deactivate :deactivate_comments

  private

  ...

  def deactivate_comments
    comments.each(&:deactivate)
  end
end

```

```bash
$ rspec
$ rubocop
```

## Post Association

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  ...

  it { should have_many(:comments) }
end

```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  ...

  has_many :comments, as: :commentable
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/routing/comments_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe CommentsController, type: :routing do
  let(:existing_post) { create :post }
  let(:existing_comment) { create :comment, commentable: existing_post }

  let(:collection_route) { "/posts/#{post_token}/comments" }
  let(:collection_params) { { post_token: existing_post.token } }

  let(:member_route) { "/posts/#{post_token}/comments/#{existing_comment.to_param}" }_param }
  # let(:member_params) { collection_params.merge token: existing_comment.to

  it 'routes to #index' do
    expect(get: collection_route).to route_to('comments#index', collection_params)
  end

  it 'does not route to #show' do
    expect(get: member_route).not_to be_routable
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
  concern(:commentable) { resources :comments, only: %i[index] }
  ...

  post_concerns = %i[commentable]
  resources :posts, only: [], param: :token, concerns: post_concerns

  ...
end

```

```bash
$ rspec spec/routing/
```

<!-- start nesting comments under post, comment, and user -->
<!-- also start nesting posts under sub and user -->
<!-- also nest votes under post, comment, and user -->
<!-- when we come in contact with each of those -->

###### backend/spec/controllers/comments_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:created_comment) { create :comment }

  describe 'GET #index' do
    let(:request_index) { get :index, params: { post_token: created_comment.commentable.token } }

    it 'returns a success response' do
      expect_response(:ok) { request_index }
    end

    it 'renders only comments for the post of given token' do
      create :comment, commentable: create(:post)
      request_index
      expect(response_body.data.count).to eq(1)
      expect(response_body.data.first.id.to_i).to eq(created_comment.id)
    end
  end
end

```

###### backend/app/controllers/comments_controller.rb

```ruby
class CommentsController < ApplicationController
  before_action :set_post, only: %i[index]
  before_action :set_comments, only: %i[index]

  def index
    render json: CommentSerializer.new(@comments)
  end

  private

  def set_post
    @post = Post.find_by_token! params[:post_token] if params[:post_token]
  rescue ActiveRecord::RecordNotFound
    render json: { post_token: params[:post_token] }, status: :not_found
  end

  def set_comments
    @comments = Comment.all
    @comments = @comments.where commentable: @post if @post
  end
end

```

```bash
$ rails c
> Post.last.token # remember this, mine was ade1b2faef8e633f
> quit
$ rails s # ^C to stop
```

In another terminal:

```bash
$ curl -X GET http://localhost:3000/comments?post_token=ade1b2faef8e633f | jq
```

