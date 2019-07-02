## Model

```bash
$ cd backend/
```

```bash
$ rails g model vote user:references direction:boolean voteable:references{polymorphic}
$ rails db:migrate
```

<!-- figure out how to sample the post or comment factory for voteable polymorphic association -->

###### backend/spec/factories/votes.rb

```ruby
FactoryBot.define do
  factory :vote do
    user
    association :voteable, factory: :post
  end
end

```

###### backend/spec/models/vote_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Vote, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:voteable) }

  it { should allow_values(nil, true, false).for(:direction) }
end

```

```bash
$ rspec
$ rubocop
```

<!-- copy this structure to previous iterations of seeds as well as all tests that use factorybot -->

###### backend/db/seeds.rb

```ruby
...

votes = 1024.times do
  FactoryBot.create(
    :vote,
    user: users.sample,
    direction: Faker::Boolean.boolean(0.8),
    voteable: (Post.all + Comment.all).sample
  )
end

redditvote = FactoryBot.create(
  :vote,
  user: reddituser,
  direction: true,
  voteable: redditpost
)

```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

<!-- look into creating a vote migration custom generator -->

## Post and Comment Associations

```bash
$ rails g migration AddVotesCountsToPosts up_votes_count:integer dn_votes_count:integer
$ rails g migration AddVotesCountsToComments up_votes_count:integer dn_votes_count:integer
$ rails db:migrate
$ touch spec/shared/concerns/a_sortable.rb
$ touch app/models/concerns/sortable.rb
$ touch spec/shared/concerns/a_voteable.rb
$ touch app/models/concerns/voteable.rb
```

###### backend/spec/shared/concerns/a_sortable.rb

```ruby
RSpec.shared_examples 'a sortable' do
  let(:model) { described_class }
  let(:model_sym) { model.to_s.underscore.to_sym }

  it 'should sort collection' do
    resources_up_votes = [1, 2, 3]
    resources_dn_votes = [4, 6, 5]
    resources = resources_up_votes.zip(resources_dn_votes).map do |up_votes, dn_votes|
      create(model_sym).tap do |resource|
        resource.update up_votes_count: up_votes
        resource.update dn_votes_count: dn_votes
      end
    end

    expected_id_order = [resources.third.id, resources.first.id, resources.second.id]
    expect(model.sort.pluck(:id)).to eq(expected_id_order)
  end
end

```

###### backend/app/models/concerns/sortable.rb

```ruby
module Sortable
  extend ActiveSupport::Concern

  module ClassMethods
    def sort
      order('up_votes_count - dn_votes_count DESC')
    end
  end
end

```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'
require 'shared/concerns/a_sortable'
require 'shared/concerns/a_tokenable'

RSpec.describe Post, type: :model do
  it_behaves_like 'an activatable'
  it_behaves_like 'a sortable'
  it_behaves_like 'a tokenable'

  ...
end

```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  include Activatable
  include Sortable
  include Tokenable

  ...
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/models/comment_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'
require 'shared/concerns/a_sortable'
require 'shared/concerns/a_tokenable'

RSpec.describe Comment, type: :model do
  it_behaves_like 'an activatable'
  it_behaves_like 'a sortable'
  it_behaves_like 'a tokenable'

  ...
end

```

###### backend/app/models/comment.rb

```ruby
class Comment < ApplicationRecord
  include Activatable
  include Sortable
  include Tokenable

  ...
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/shared/concerns/a_voteable.rb

```ruby
RSpec.shared_examples 'a voteable' do
  let(:model) { described_class }
  let(:model_sym) { model.to_s.underscore.to_sym }
  let(:resource) { create model_sym, up_votes_count: nil, dn_votes_count: nil }

  context 'on create' do
    it 'should initialize up_votes_count and dn_votes_count' do
      expect(resource.up_votes_count).to be(0)
      expect(resource.dn_votes_count).to be(0)
    end
  end

  it 'should increment up_votes' do
    expect { resource.inc_up_votes }.to change { resource.up_votes_count }.by(1)
  end

  it 'should decrement up_votes' do
    expect { resource.dec_up_votes }.to change { resource.up_votes_count }.by(-1)
  end

  it 'should increment dn_votes' do
    expect { resource.inc_dn_votes }.to change { resource.dn_votes_count }.by(1)
  end

  it 'should decrement dn_votes' do
    expect { resource.dec_dn_votes }.to change { resource.dn_votes_count }.by(-1)
  end
end

```

###### app/models/concerns/voteable.rb

```ruby
module Voteable
  extend ActiveSupport::Concern

  alias_attribute :upvotes, :up_votes_count
  alias_attribute :dnvotes, :dn_votes_count

  included do
    before_create :initialize_votes_counts
  end

  def inc_up_votes
    increment! :up_votes_count
  end

  def dec_up_votes
    decrement! :up_votes_count
  end

  def inc_dn_votes
    increment! :dn_votes_count
  end

  def dec_dn_votes
    decrement! :dn_votes_count
  end

  private

  def initialize_votes_counts
    self.up_votes_count = 0
    self.dn_votes_count = 0
  end
end

```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'
require 'shared/concerns/a_sortable'
require 'shared/concerns/a_tokenable'
require 'shared/concerns/a_voteable'

RSpec.describe Post, type: :model do
  it_behaves_like 'an activatable'
  it_behaves_like 'a sortable'
  it_behaves_like 'a tokenable'
  it_behaves_like 'a voteable'

  ...
end

```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  include Activatable
  include Sortable
  include Tokenable
  include Voteable

  ...
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/models/comment_spec.rb

```ruby
require 'rails_helper'
require 'shared/concerns/an_activatable'
require 'shared/concerns/a_sortable'
require 'shared/concerns/a_tokenable'
require 'shared/concerns/a_voteable'

RSpec.describe Comment, type: :model do
  it_behaves_like 'an activatable'
  it_behaves_like 'a sortable'
  it_behaves_like 'a tokenable'
  it_behaves_like 'a voteable'

  ...
end

```

###### backend/app/models/comment.rb

```ruby
class Comment < ApplicationRecord
  include Activatable
  include Sortable
  include Tokenable
  include Voteable

  ...
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/models/vote_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Vote, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:voteable) }

  it { should allow_values(nil, true, false).for(:direction) }

  describe 'voteable votes counts' do
    context 'on create' do
      it 'should initialize up_votes_count and dn_votes_count' do
        vote = create :vote, direction: false
        expect(vote.voteable.upvotes).to eq(0)
        expect(vote.voteable.dnvotes).to eq(1)

        vote = create :vote
        expect(vote.voteable.upvotes).to eq(0)
        expect(vote.voteable.dnvotes).to eq(0)

        vote = create :vote, direction: true
        expect(vote.voteable.upvotes).to eq(1)
        expect(vote.voteable.dnvotes).to eq(0)
      end
    end

    context 'on update' do
      context 'when direction unchanged' do
        it 'should not change up_votes_count and dn_votes_count' do
          [false, nil, true].each do |dir|
            vote = create :vote, direction: dir
            expect { vote.update direction: dir }.to change { vote.voteable.upvotes }.by(0)
            expect { vote.update direction: dir }.to change { vote.voteable.dnvotes }.by(0)
          end
        end
      end

      context 'when direction was nil' do
        let(:vote) { create :vote }

        context 'when direction to update to false' do
          it 'should increment dn_votes_count' do
            expect { vote.update direction: false }.to change { vote.voteable.dnvotes }.by(1)
          end
        end

        context 'when direction to update to true' do
          it 'should increment up_votes_count' do
            expect { vote.update direction: true }.to change { vote.voteable.upvotes }.by(1)
          end
        end
      end

      context 'when direction was false' do
        let(:vote) { create :vote, direction: false }

        context 'when direction to update to nil' do
          it 'should decrement dn_votes_count' do
            expect { vote.update direction: nil }.to change { vote.voteable.dnvotes }.by(-1)
          end
        end

        context 'when direction to update to true' do
          it 'should decrement dn_votes_count' do
            expect { vote.update direction: true }.to change { vote.voteable.dnvotes }.by(-1)
          end

          it 'should increment up_votes_count' do
            expect { vote.update direction: true }.to change { vote.voteable.upvotes }.by(1)
          end
        end
      end

      context 'when direction was true' do
        let(:vote) { create :vote, direction: true }

        context 'when direction to update to nil' do
          it 'should decrement up_votes_count' do
            expect { vote.update direction: nil }.to change { vote.voteable.upvotes }.by(-1)
          end
        end

        context 'when direction to update to false' do
          it 'should decrement up_votes_count' do
            expect { vote.update direction: false }.to change { vote.voteable.upvotes }.by(-1)
          end

          it 'should increment dn_votes_count' do
            expect { vote.update direction: false }.to change { vote.voteable.dnvotes }.by(1)
          end
        end
      end
    end
  end
end

```

###### backend/app/models/vote.rb

```ruby
class Vote < ApplicationRecord
  ...

  before_save :update_votes_counts

  private

  def update_votes_counts
    return unless direction_changed?

    handle_up_votes
    handle_dn_votes
  end

  def handle_up_votes
    voteable.inc_up_votes if direction == true
    voteable.dec_up_votes if direction_was == true
  end

  def handle_dn_votes
    voteable.inc_dn_votes if direction == false
    voteable.dec_dn_votes if direction_was == false
  end
end

```

```bash
$ rails db:reset
$ rails s # ^C to stop
```

###### backend/app/controllers/posts_controller.rb

```ruby
class PostsController < ApplicationController
  ...

  private

  ...

  def set_posts
    @posts = Post.sort
    ...
  end
end

```

###### backend/app/controllers/comments_controller.rb

```ruby
class PostsController < ApplicationController
  ...

  private

  ...

  def set_comments
    @comments = Comment.sort
    ...
  end
end

```

###### backend/app/serializers/post_serializer.rb

```ruby
class PostSerializer < BaseSerializer
  ...

  attribute :votes_count do |post|
    post.upvotes - post.dnvotes
  end
end

```

###### backend/app/serializers/comment_serializer.rb

```ruby
class CommentSerializer < BaseSerializer
  ...

  attribute :votes_count do |comment|
    comment.upvotes - comment.dnvotes
  end
end

```

<!-- ## Controller -->

