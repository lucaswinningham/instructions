```bash
$ rails g model sub name:string
$ rails db:migrate
```

###### backend/spec/models/sub_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Sub, type: :model do
  describe 'name' do
    invalid_names = ['sub-name', 'sub_name', '_subname_', '-subname-', 'subname!', 'subname?',
                     'subname*', 'subname#']
    valid_names = %w[subname sub1name 1subname1 SUBNAME]

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(21) }
    it { should_not allow_values(*blank_values).for(:name) }
    it { should_not allow_values(*invalid_names).for(:name) }
    it { should allow_values(*valid_names).for(:name) }
  end
end

```

###### backend/app/models/sub.rb

```ruby
class Sub < ApplicationRecord
  VALID_NAME_REGEX = /\A[a-zA-Z0-9]+\Z/.freeze
  validates :name, presence: true, allow_blank: false, format: { with: VALID_NAME_REGEX },
                   length: { minimum: 3, maximum: 21 }
  validates_uniqueness_of :name, case_sensitive: false
end

```

```bash
$ rspec
$ rubocop
```

###### backend/spec/factories/subs.rb

```ruby
FactoryBot.define do
  factory :sub do
    sequence(:name) { Faker::Internet.unique.username(3..21, ['']) }
  end
end

```

```bash
$ rubocop
```

