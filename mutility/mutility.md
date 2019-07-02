```bash
$ rails new myapp --api --database=postgresql --skip-test
$ cd myapp
$ rails g model user name:string
$ rails g model comment user:references content:text tagline:string
$ rails g model comment_change comment:references content:text tagline:string
$ rails db:migrate
$ touch app/models/concerns/mutility.rb
```

###### app/models/concerns/mutility.rb

```ruby
module Mutility
  extend ActiveSupport::Concern

  included do
    around_save :mutility_around_save
  end

  class_methods do
    def mutility_attrs(*mutility_attrs)
      @@mutility_attrs = mutility_attrs || []
    end
  end

  private

  def mutility_around_save
    new_attributes = attributes.symbolize_keys
    persisted_and_changed = persisted? && changed?
    return_of_yield = yield

    if persisted_and_changed && return_of_yield
      change_attributes = @@mutility_attrs.reduce({}) do |memo, column_sym|
        memo.merge column_sym => new_attributes[column_sym]
      end

      change_model = "#{self.class}Change".constantize
      reference_sym = self.class.to_s.underscore.to_sym
      change_model.create change_attributes.merge(reference_sym => self)
    end

    return_of_yield
  end
end

```

###### app/models/comment.rb

```ruby
class Comment < ApplicationRecord
  include Mutility
  mutility_attrs :content, :tagline

  ...
end

```

```bash
$ rails c
> user = User.create name: 'firstuser'
> comment = Comment.create user: user, content: 'some comment', tagline: 'check me out'
> CommentChange.count
> comment.update tagline: 'check me out'
> CommentChange.count
> comment.update tagline: 'a different tagline'
> CommentChange.count
> CommentChange.last
> quit
$ dropdb myapp_development
$ dropdb myapp_test
$ cd ..
$ rm -r myapp
```
