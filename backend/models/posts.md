```bash
$ rails g model post user:belongs_to sub:belongs_to title:text url:string body:text active:boolean token:string
$ rails db:migrate
```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'user' do
    it { should belong_to(:user) }
  end

  describe 'sub' do
    it { should belong_to(:sub) }
  end

  describe 'title' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(256) }
    it { should_not allow_values(*blank_values).for(:title) }
  end

  describe 'body' do
    it { should validate_length_of(:body).is_at_most(10_000) }
  end

  describe 'url' do
    it { should validate_uniqueness_of(:url) }
    it { should_not allow_values(*invalid_urls).for(:url) }
    it { should allow_values(*valid_urls).for(:url) }
  end
end

```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :sub

  validates :title, presence: true, allow_blank: false, length: { maximum: 256 }

  validates :body, length: { maximum: 10_000 }

  validates :url, uniqueness: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
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
    sub
    title { Faker::Lorem.sentence }
    url { Faker::Internet.unique.url }
  end
end

```

```bash
$ rubocop
```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  ...

  describe 'active' do
    context 'on create' do
      it 'should be true' do
        post = create :post
        expect(post.active).to be true
      end
    end
  end
end

```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  ...

  before_create :activate

  private

  def activate
    self.active = true
  end
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/models/post_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Post, type: :model do
  ...

  describe 'token' do
    context 'on create' do
      it 'should populate' do
        post = create :post
        expect(post.token).to be_truthy
      end
    end
  end
end

```

###### backend/app/models/post.rb

```ruby
class Post < ApplicationRecord
  ...

  before_create :assign_token

  private

  ...

  def assign_token
    self.token = SecureRandom.hex(8) until unique_token?
  end

  def unique_token?
    token && self.class.find_by_token(token).nil?
  end
end

```

```bash
$ rspec
$ rubocop
```

