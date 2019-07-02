###### app/models/sub.rb

```ruby
class Sub < ApplicationRecord
  ...

  class Filters
    CONTROVERSIAL = 'controversial'.freeze
    HOT           = 'hot'.freeze
    NEW           = 'new'.freeze
    TOP           = 'top'.freeze
  end

  def apply_filter(filter_to_apply)
    filter_to_apply ||= Filters::HOT
    filter_to_apply.downcase!

    case filter_to_apply
    when Filters::CONTROVERSIAL
      filter_by_controversial
    when Filters::HOT
      filter_by_hot
    when Filters::NEW
      filter_by_new
    when Filters::TOP
      filter_by_top
    end
  end

  private

  def filter_by_controversial
    posts.sort_by(&:votes)
  end

  def filter_by_hot
    posts.sort_by(&:votes)
  end

  def filter_by_new
    posts.sort_by(&:created_at)
  end

  def filter_by_top
    posts.sort_by(&:votes)
  end
end

```

## Controllers

```bash
$ touch app/controllers/subs_controller.rb
```

###### app/controllers/subs_controller.rb

```ruby
class SubsController < ApplicationController
  class Defaults
    ALL = 'all'
    FRONT = 'front'
    POPULAR = 'popular'
  end

  def show
    case params[:name].downcase!
      when Defaults::ALL
        all
      when Defaults::FRONT
        front
      when Defaults::POPULAR
        popular
      else
        specific
    end
  end

  def all
    @sub = Sub.find_by_name('all')
    @sub.posts = Post.all
    @sub.apply_filter params[:filter]
    @sub.save
    render json: @sub, include: :posts
  end

  private
    def popular
      # filter hot subs
    end

    def front
      # filter user saved subs
    end

    def specific
      @sub = Sub.find_by_name(params[:name])
      @sub.apply_filter params[:filter]
      render json: @sub, include: :posts
    end
end
```

```bash
$ touch app/controllers/posts_controller.rb
```

###### app/controllers/posts_controller.rb

```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :set_post, except: :create

  def show
    render json: @post
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      render json: @post, include: :comments, status: :created, location: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      render json: @post, include: :comments
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
  end

  private
    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:user_id, :sub_id, :title, :url, :body)
                           .merge(user_id: current_user.id)
    end
end
```

###### config/routes.rb

```ruby
Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'

  root to: 'subs#all'
  
  get '/r/*name/*filter', to: 'subs#show'

  resources :posts, except: [:index]
end
```

###### db/seeds.rb

###### Post man GET http://www.reddit.com/.json
response looks like
```json
{
    "kind": "Listing",
    "data": {
        "after": "t3_7t5qzy",
        "dist": 25,
        "modhash": "",
        "whitelist_status": "all_ads",
        "children": [
            {
                "kind": "t3",
                "data": {
                    "domain": "i.redd.it",
                    "approved_at_utc": null,
                    "mod_reason_by": null,
                    "banned_by": null,
                    "num_reports": null,
                    "subreddit_id": "t5_2qh33",
                    "thumbnail_width": 140,
                    "subreddit": "funny",
                    "selftext_html": null,
                    "selftext": "",
                    "likes": null,
                    "suggested_sort": null,
                    "user_reports": [],
                    "secure_media": null,
                    "is_reddit_media_domain": true,
                    "link_flair_text": null,
                    "id": "7t7hu0",
                    "banned_at_utc": null,
                    "mod_reason_title": null,
                    "view_count": null,
                    "archived": false,
                    "clicked": false,
                    "media_embed": {},
                    "report_reasons": null,
                    "author": "Jewfarts",
                    "num_crossposts": 0,
                    "saved": false,
                    "mod_reports": [],
                    "can_mod_post": false,
                    "is_crosspostable": false,
                    "pinned": false,
                    "score": 52618,
                    "approved_by": null,
                    "over_18": false,
                    "hidden": false,
                    "preview": {
                        "images": [
                            {
                                "source": {
                                    "url": "https://i.redditmedia.com/yYoWoi2eN4wRYr8qlOvMHzsvzKwz2mAEfbn5FfYugno.jpg?s=83eb82bf0fa7fecbecd0b723ee916e02",
                                    "width": 640,
                                    "height": 596
                                },
                                "resolutions": [
                                    {
                                        "url": "https://i.redditmedia.com/yYoWoi2eN4wRYr8qlOvMHzsvzKwz2mAEfbn5FfYugno.jpg?fit=crop&amp;crop=faces%2Centropy&amp;arh=2&amp;w=108&amp;s=6f7909c6267d35b168ac3e516395bbda",
                                        "width": 108,
                                        "height": 100
                                    },
                                    {
                                        "url": "https://i.redditmedia.com/yYoWoi2eN4wRYr8qlOvMHzsvzKwz2mAEfbn5FfYugno.jpg?fit=crop&amp;crop=faces%2Centropy&amp;arh=2&amp;w=216&amp;s=6bdfd493da9a35a27db5631aab258e37",
                                        "width": 216,
                                        "height": 201
                                    },
                                    {
                                        "url": "https://i.redditmedia.com/yYoWoi2eN4wRYr8qlOvMHzsvzKwz2mAEfbn5FfYugno.jpg?fit=crop&amp;crop=faces%2Centropy&amp;arh=2&amp;w=320&amp;s=d0dd4a2e31d0f53be84b570774fdaa9f",
                                        "width": 320,
                                        "height": 298
                                    },
                                    {
                                        "url": "https://i.redditmedia.com/yYoWoi2eN4wRYr8qlOvMHzsvzKwz2mAEfbn5FfYugno.jpg?fit=crop&amp;crop=faces%2Centropy&amp;arh=2&amp;w=640&amp;s=2d36a60e94667f713925aef5f8766f57",
                                        "width": 640,
                                        "height": 596
                                    }
                                ],
                                "variants": {},
                                "id": "7xjTcQnjuKJj8RLFAArZniAnc584GbUcI96qBJBtvQs"
                            }
                        ],
                        "enabled": true
                    },
                    "thumbnail": "https://b.thumbs.redditmedia.com/uTud-37gayYLzhu1p1ZkhfbwKwncBPa5Mk_sSstWLkY.jpg",
                    "edited": false,
                    "link_flair_css_class": null,
                    "author_flair_css_class": null,
                    "contest_mode": false,
                    "gilded": 0,
                    "downs": 0,
                    "brand_safe": true,
                    "secure_media_embed": {},
                    "removal_reason": null,
                    "post_hint": "image",
                    "author_flair_text": null,
                    "stickied": false,
                    "can_gild": false,
                    "thumbnail_height": 130,
                    "parent_whitelist_status": "all_ads",
                    "name": "t3_7t7hu0",
                    "spoiler": false,
                    "permalink": "/r/funny/comments/7t7hu0/the_more_you_know/",
                    "subreddit_type": "public",
                    "locked": false,
                    "hide_score": false,
                    "created": 1517028091,
                    "url": "https://i.redd.it/cj48aaf84hc01.jpg",
                    "whitelist_status": "all_ads",
                    "quarantine": false,
                    "title": "The more you know",
                    "created_utc": 1516999291,
                    "subreddit_name_prefixed": "r/funny",
                    "ups": 52618,
                    "media": null,
                    "num_comments": 724,
                    "is_self": false,
                    "visited": false,
                    "mod_note": null,
                    "is_video": false,
                    "distinguished": null
                }
            },
            ...
        ],
        "before": null
    }
}
```

```ruby
Sub.create!([
  {name: "all"},
  {name: "front"},
  {name: "popular"},
  {name: "pics"},
])

User.create!([
  {email: "user1@example.com", name: "user1", password: "changeme", password_confirmation: "changeme"},
  {email: "user2@example.com", name: "user2", password: "changeme", password_confirmation: "changeme"},
  {email: "user3@example.com", name: "user3", password: "changeme", password_confirmation: "changeme"},
  {email: "user4@example.com", name: "user4", password: "changeme", password_confirmation: "changeme"},
  {email: "user5@example.com", name: "user5", password: "changeme", password_confirmation: "changeme"}
])

Post.create!([
  {user_id: 1, sub_id: 1, title: "link to google",  url: "google.com",  body: "google body"},
  {user_id: 2, sub_id: 2, title: "link to imgur",   url: "imgur.com"},
  {user_id: 3, sub_id: 3, title: "link to gfycat",  url: "gfycat.com",  body: "gfycat body"},
  {user_id: 4, sub_id: 4, title: "link to twitter", url: "twitter.com"},
])
```

```bash
$ rails db:seed
```

```bash
$ rails s
```

###### http://localhost:3000/products.json

```json
[{"id":1,"name":"Product 001","created_at":"2018-01-03T23:35:06.560Z","updated_at":"2018-01-03T23:35:06.560Z"},
{"id":2,"name":"Product 002","created_at":"2018-01-03T23:35:06.568Z","updated_at":"2018-01-03T23:35:06.568Z"},
{"id":3,"name":"Product 003","created_at":"2018-01-03T23:35:06.570Z","updated_at":"2018-01-03T23:35:06.570Z"},
{"id":4,"name":"Product 004","created_at":"2018-01-03T23:35:06.572Z","updated_at":"2018-01-03T23:35:06.572Z"}]
```
