```bash
$ cd ../backend/
$ rails g scaffold_controller heartbeat
```

###### backend/spec/routing/heartbeats_routing_spec.rb

```ruby
require 'rails_helper'

RSpec.describe HeartbeatsController, type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/heartbeat').to route_to('heartbeats#show')
    end
  end
end

```

###### backend/config/routes.rb

```ruby
Rails.application.routes.draw do
  ...

  resource :heartbeat, only: :show
end

```

###### backend/spec/controllers/heartbeats_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe HeartbeatsController, type: :controller do
  describe 'GET #show' do
    it 'returns a success response' do
      expect_response(:no_content, content_type: nil) { get :show }
    end
  end
end

```

###### backend/app/controllers/heartbeats_controller.rb

```ruby
class HeartbeatsController < ApplicationController
  def show; end
end

```


```bash
$ rspec
$ rubocop
$ rails s
```

In another terminal:

```bash
$ curl http://localhost:3000/heartbeat | jq
...
{
  "data": {
    "id": "1",
    "type": "user",
    "attributes": {
      "name": "reddituser",
      "email": "reddituser@email.com"
    }
  }
}
```

```bash
$ cd ../frontend/
$ ng g class models/heartbeat --type=model
```

###### frontend/src/app/models/heartbeat.model.ts

```ts
import { Base } from '@models/base.model';

export class Heartbeat extends Base { }

```

```bash
$ ng g s services/models/heartbeat
```

###### frontend/src/app/services/models/heartbeat.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '../utils/api.service';

import { Heartbeat } from '@models/heartbeat.model';

...
export class HeartbeatService {

  constructor(private api: ApiService) { }

  read(): Observable<Heartbeat> {
    return this.api.read('heartbeat').pipe(
      map(heartbeat => new Heartbeat(heartbeat))
    );
  }
}

```

###### frontend/src/app/app.component.ts

```ts
import { Component, OnInit } from '@angular/core';

import { LogService } from '@services/utils/log.service';
import { HeartbeatService } from '@services/models/heartbeat.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  constructor(private logger: LogService, private heartbeatService: HeartbeatService) { }

  ngOnInit() {
    this.logger.log('app started');
    this.heartbeatService.read().subscribe(_ => this.logger.log('heartbeat ok'));
  }
}

```

```bash
$ cd ../backend/
$ rails s
```

In another terminal:

```bash
$ ng serve # ^C to stop
```

[Navigate to app](http://localhost:4200/)

