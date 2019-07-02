```bash
$ rails g model user name:string email:string
$ rails db:migrate
```

<!-- add email validations -->
###### backend/spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'name' do
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
end

```

<!-- add email validations -->
###### backend/app/models/user.rb

```ruby
class User < ActiveRecord::Base
  VALID_NAME_REGEX = /\A[A-Za-z0-9_\-]+\Z/.freeze
  validates :name, presence: true, allow_blank: false, uniqueness: true,
                   format: { with: VALID_NAME_REGEX }, length: { minimum: 3, maximum: 20 }
end

```

```bash
$ rspec
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

###### backend/.rubocop.yml

```yaml
AllCops:
  Exclude:
    ...
    - 'db/schema.rb'
    ...
Metrics/BlockLength:
  Exclude:
    - 'spec/**/*_spec.rb'
...

```

```bash
$ rubocop
```

