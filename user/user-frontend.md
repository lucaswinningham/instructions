```bash
$ cd frontend/
```

```bash
$ ng g class models/user --type=model
```

###### frontend/src/app/models/user.model.ts

```ts
import { Base } from '@models/base.model';

export class User extends Base {
  readonly name: string;
  readonly email: string;

  protected afterConstruction(): void {
    const { name, email } = this.params;
    Object.assign(this, { name, email });
  }

  protected localSerialize(): any {
    const { name, email } = this;
    return { name, email };
  }
}

```

<!-- i question whether this is necessary at this point, should move to auth section -->

```bash
$ ng g s services/models/user
```

###### frontend/src/app/services/models/user.service.ts

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
    const route = 'users';
    const param = name;
    return this.api.read({ route, param }).pipe(
      map(user => new User(user))
    );
  }
}

```

```bash
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

<!-- look at AutoUnsubscribe -->

###### frontend/src/app/pages/user/user.component.ts

```ts
import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute, ParamMap } from '@angular/router';
import { Subscription } from 'rxjs';
import { switchMap } from 'rxjs/operators';

import { UserService } from '@services/models/user.service';

import { User } from '@models/user.model';

...
export class UserComponent implements OnInit, OnDestroy {
  user: User;

  private paramSubscription: Subscription;

  constructor(private userApi: UserService, private route: ActivatedRoute) { }

  ngOnInit() {
    this.paramSubscription = this.route.paramMap.pipe(
      switchMap((params: ParamMap) => this.userApi.read(params.get('name')))
    ).subscribe(user => this.user = user);
  }

  ngOnDestroy() {
    this.paramSubscription.unsubscribe();
  }
}

```

###### frontend/src/app/pages/user/user.component.html

```xml
<div *ngIf="user">
  {{ user.name }}
</div>

```

## Post Association

###### frontend/src/app/models/post.model.ts

```ts
import { Base } from '@models/base.model';

export class Post extends Base {
  readonly userName: string;
  ...

  protected afterConstruction(): void {
    const { userName, ... } = this.params;
    Object.assign(this, { userName, ... });
  }

  protected localSerialize(): any {
    const { userName, ... } = this;
    return { userName, ... };
  }
}

```

###### frontend/src/app/pages/subreddit/post/post.component.html

```xml
<div class="row" ...>
  <div class="col-12 ...">
    <div class="row ...">
      <div class="col text-left text-muted">
        <span [routerLink]="['/u', post.userName]" appHoverPointer>
          u/{{ post.userName }}
        </span>
        {{ post.createdAt | amTimeAgo }}
      </div>

      ...
    </div>

    ...
  </div>
</div>

```

