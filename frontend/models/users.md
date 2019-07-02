```bash
$ ng g class models/user --type=model
```

###### frontend/src/app/models/user.model.ts

```ts
import { Base } from '@models/base.model';

export class User extends Base {
  readonly name: string;

  protected afterConstruction(): void {
    const { name } = this.params;
    Object.assign(this, { name });
  }

  protected localSerialize(): any {
    const { name } = this;
    return { name };
  }
}

```

```bash
$ ng g s services/models/user
```

###### frontend/src/app/services/user.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '../utils/api.service';

import { User } from '@models/user.model';

...
export class UserService {

  constructor(private api: ApiService) { }

  read(name: string): Observable<User> {
    return this.api.read('users', name).pipe(
      map(user => new User(user))
    );
  }
}

```

```bash
$ cd ../backend/
```

###### backend/db/seeds.rb

```ruby
users = 4.times.map { FactoryBot.create :user }
reddit_user = FactoryBot.create :user, name: 'all'

subs = 4.times.map { FactoryBot.create :sub }
all = FactoryBot.create :sub, name: 'all'

posts = 16.times { FactoryBot.create :post, user_id: users.sample.id, sub_id: subs.sample.id }
redditpost = FactoryBot.create :post, user_id: reddit_user.id, sub_id: all.id, title: 'reddit title', url: 'https://reddit.com', body: 'reddit body'

```

```bash
$ rails db:drop db:create db:migrate db:seed
$ cd ../frontend/
$ ng g m pages/user --module=pages
$ ng g c pages/user --module=pages/user
```

###### frontend/src/app/app-routing.module.ts

```ts
...

import { UserComponent } from '@pages/user/user.component';

const routes: Routes = [
  ...,
  { path: 'u/:name', component: UserComponent }
];

...

```

###### frontend/src/app/pages/user/user.module.ts

```ts
...
import { AppRoutingModule } from '@app/app-routing.module';

...

@NgModule({
  ...,
  imports: [
    ...,
    AppRoutingModule
  ]
})
export class UserModule { }

```

###### frontend/src/app/pages/user/user.component.ts

```ts
...
import { ActivatedRoute, ParamMap } from '@angular/router';
import { switchMap } from 'rxjs/operators';

import { UserService } from '@services/models/user.service';

import { User } from '@models/user.model';

...
export class UserComponent implements OnInit {
  user: User;

  constructor(private userService: UserService, private route: ActivatedRoute) { }

  ngOnInit() {
    this.route.paramMap.pipe(
      switchMap((params: ParamMap) => this.userService.read(params.get('name')))
    ).subscribe(user => this.user = user);
  }

}

```

###### frontend/src/app/pages/user/user.component.html

```xml
<section *ngIf="user">
  {{ user.name }}
</section>

```

###### frontend/src/app/models/post.model.ts

```ts
import { Base } from '@models/base.model';

export class Post extends Base {
  readonly userName: string;
  ...
  readonly createdAt: string;

  protected afterConstruction(): void {
    const { userName, ..., createdAt } = this.params;
    Object.assign(this, { userName, ..., createdAt });
  }

  protected localSerialize(): any {
    const { userName, ..., createdAt } = this;
    return { userName, ..., createdAt };
  }
}

```

```bash
$ npm install moment ngx-moment --save
```

```bash
$ ng g m directives --module=app
```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    //
    // Added
    //

    "paths": {
      ...,
      "@directives/*": [ "app/directives/*" ]
    }
  }
}

```

###### frontend/src/app/directives/stop-propagation.directive.ts

```ts

```

###### frontend/src/app/pages/front/front.module.ts

```ts
...

import { MomentModule } from 'ngx-moment';
import { DirectivesModule } from '@directives/directives.module';

...

@NgModule({
  ...,
  imports: [
    ...,
    MomentModule,
    DirectivesModule
  ]
})
export class FrontModule { }

```

###### frontend/src/app/pages/front/post-preview/post-preview.component.html

```xml
<div class="row" ...>
  <div class="col-12 ...">
    <div class="small mb-">
      ...

      <span class="text-muted">
        • Posted by:
        <span [routerLink]="['/u', post.userName]">u/{{ post.userName }}</span>
        {{ post.createdAt | amTimeAgo }}
      </span>
    </div>

    ...
  </div>
</div>

```

###### frontend/src/app/pages/post/post.module.ts

```ts
...

import { MomentModule } from 'ngx-moment';

...

@NgModule({
  ...
  imports: [
    ...,
    MomentModule
  ]
})
export class PostModule { }

```

###### frontend/src/app/pages/post/post.component.html

```xml
<section ...>
  <div class="container">
    <div class="row" ...>
      <div class="col-12 ...">
        <div class="small mb-2">
          ...

          <span class="text-muted">
            • Posted by:
            <span [routerLink]="['/u', post.userName]">u/{{ post.userName }}</span>
            {{ post.createdAt | amTimeAgo }}
          </span>
        </div>

        ...
      </div>
    </div>

    ...
  </div>
</section>

```

