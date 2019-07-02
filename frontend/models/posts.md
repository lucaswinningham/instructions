```bash
$ ng g class models/post --type=model
```

###### frontend/src/app/models/post.model.ts

```ts
import { Base } from '@models/base.model';

export class Post extends Base {
  readonly title: string;
  readonly url: string;
  readonly body: string;
  readonly active: boolean;
  readonly token: string;

  protected afterConstruction(): void {
    const { title, url, body, active, token } = this.params;
    Object.assign(this, { title, url, body, active, token });
  }

  protected localSerialize(): any {
    const { title, url, body, active, token } = this;
    return { title, url, body, active, token };
  }
}

```

```bash
$ ng g s services/models/post
```

###### frontend/src/app/services/utils/api.service.ts

```ts
...
export class ApiService {
  ...

  list(route: string, params: any = {}): Observable<any> {
    const endpoint = `${apiUrl}/${route}`;
    params = this.snakeifyKeys(params);
    const observable = this.http.get(endpoint, { params });
    return this.process(observable).pipe(
      catchError(this.catchError(`GET ${endpoint}`))
    );
  }

  private ...
}

```

###### frontend/src/app/services/models/post.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '../utils/api.service';

import { Post } from '@models/post.model';

...
export class PostService {

  constructor(private api: ApiService) { }

  list(): Observable<Post[]> {
    return this.api.list('posts').pipe(
      map(posts => posts.map(post => new Post(post)))
    );
  }

  read(token: string): Observable<Post> {
    return this.api.read('posts', token).pipe(
      map(post => new Post(post))
    );
  }
}

```

```bash
$ cd ../backend/
```

###### backend/db/seeds.rb

```ruby
4.times { FactoryBot.create :post }
FactoryBot.create :post, title: 'reddit title', url: 'https://reddit.com', body: 'reddit body'

```

```bash
$ rails db:drop db:create db:migrate db:seed
```

```bash
$ cd ../frontend/
```

```bash
$ ng g m pages --module=app
$ ng g m pages/front --module=pages
$ ng g c pages/front --module=pages/front
$ ng g c pages/front/post-list --module=pages/front
$ ng g c pages/front/post-preview --module=pages/front
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
      "@pages/*": [ "app/pages/*" ]
    }
  }
}

```

###### frontend/src/app/pages/front/front.module.ts

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
export class FrontModule { }

```

###### frontend/src/app/pages/front/front.component.html

```xml
<section>
  <app-post-list></app-post-list>
</section>

```

###### frontend/src/app/app-routing.module.ts

```ts
...

import { FrontComponent } from '@pages/front/front.component';

const routes: Routes = [
  { path: '', redirectTo: '/r/all', pathMatch: 'full' },
  { path: 'r/:name', component: FrontComponent },
  { path: 'post/:token', component: PostComponent }
];

...

```

###### frontend/src/app/pages/front/post-list/post-list.component.ts

```ts
import { Component, OnInit, Input } from '@angular/core';
import { Observable } from 'rxjs';

import { PostService } from '@app/services/models/post.service';

import { Post } from '@models/post.model';

...
export class PostListComponent implements OnInit {
  posts: Observable<Post[]>;

  constructor(private postService: PostService) { }

  ngOnInit() {
    this.posts = this.postService.list();
  }

}

```

###### frontend/src/app/pages/front/post-list/post-list.component.html

```xml

```

###### frontend/src/app/pages/front/post-preview/post-preview.component.ts

```ts

```

###### frontend/src/app/pages/front/post-preview/post-preview.component.html

```xml

```

###### frontend/src/app/pages/front/post-preview/post-preview.component.scss

```scss
.pointer:hover {
  cursor: pointer;
}

```

```bash
$ ng g m pages/post --module=pages
$ ng g c pages/post --module=pages/post
```

###### frontend/src/app/pages/post/post.module.ts

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
export class PostModule { }

```

###### frontend/src/app/app-routing.module.ts

```ts

```

###### frontend/src/app/pages/post/post.component.ts

```ts
...
import { ActivatedRoute, ParamMap } from '@angular/router';

import { PostService } from '@app/services/models/post.service';

import { Post } from '@models/post.model';

...
export class PostComponent implements OnInit {
  post: Observable<Post>;

  constructor(private postService: PostService, private route: ActivatedRoute) { }

  ngOnInit() {
    this.post = this.route.paramMap.pipe(
      switchMap((params: ParamMap) => this.postService.read(params.get('token')))
    );
  }

}

```

###### frontend/src/app/pages/post/post.component.html

```xml

```

