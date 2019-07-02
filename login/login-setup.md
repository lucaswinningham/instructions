```bash
$ cd backend/
```

###### backend/Gemfile

```ruby
...

group :development, :test do
  ...

  # Use timecop for time manipulation
  gem 'timecop'
end

...

# Use BCrypt for hashing
gem 'bcrypt'

# Use JWT for auth
gem 'jwt'

```

```bash
$ bundle
```

```bash
$ cd backend/
```

```bash
$ npm install \
  bcryptjs@latest \
  random-string@latest \
  crypto-js@latest \
  @ngrx/store@latest \
  --save
$ npm install \
  ngrx-store-freeze \
  --save-dev
```

