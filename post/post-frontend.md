<!-- start adding headers with ## -->
<!-- start adding `$ ng lint` and `$ ng test # ^C to stop` -->

```bash
$ cd frontend/
```

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
    const { title, url, body } = this;
    return { title, url, body };
  }
}

```

```bash
$ ng g s services/models/post
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
    const route = 'posts';
    return this.api.list({ route }).pipe(
      map(posts => posts.map(post => new Post(post)))
    );
  }
}

```

<!-- move post into components to be able to share -->

```bash
$ ng g m pages/subreddit --module=pages
$ ng g c pages/subreddit --module=pages/subreddit
$ ng g m pages/subreddit/post --module=pages/subreddit
$ ng g c pages/subreddit/post --module=pages/subreddit/post --export
```

###### frontend/src/app/app-routing.module.ts

```ts
...

import { SubredditComponent } from '@pages/subreddit/subreddit.component';

const routes: Routes = [
  { path: '', redirectTo: '/r/all', pathMatch: 'full' },
  { path: 'r/:name', component: SubredditComponent }
];

...
```

###### frontend/src/app/pages/subreddit/post/post.module.ts

```ts
...
import { AppRoutingModule } from '@app/app-routing.module';
import { MomentModule } from 'ngx-moment';

import { DirectivesModule } from '@directives/directives.module';

...

@NgModule({
  ...,
  imports: [
    ...,
    AppRoutingModule,
    MomentModule,
    DirectivesModule
  ]
})
export class SubredditModule { }

```

###### frontend/src/app/pages/subreddit/subreddit.component.ts

```ts
...
import { Observable } from 'rxjs';

import { PostService } from '@services/models/post.service';

import { Post } from '@models/post.model';

...
export class SubredditComponent implements OnInit {
  posts: Observable<Post[]>;

  constructor(private postApi: PostService) { }

  ngOnInit() {
    this.posts = this.postApi.list();
  }

}

```

###### frontend/src/app/pages/subreddit/subreddit.component.html

```xml
<app-post *ngFor="let post of posts | async" [post]="post"></app-post>

```

###### frontend/src/app/pages/subreddit/post/post.component.ts

```ts
import { Component, OnInit, Input } from '@angular/core';

import { Post } from '@models/post.model';

...
export class PostPreviewComponent implements OnInit {
  @Input() post: Post;

  ...

}

```

###### frontend/src/app/pages/subreddit/post/post.component.html

```xml
<div class="row" *ngIf="post.active">
  <div class="col-12 my-3 py-3 border border-dark rounded">
    <div>
      <h6>{{ post.title }}</h6>
    </div>

    <div *ngIf="post.url">
      <a [href]="post.url" target="_blank" rel="noopener noreferrer">
        {{ post.url }}
      </a>
    </div>

    <div class="container mt-3" *ngIf="post.body">
      <div class="row">
        <div class="col-10 offset-1">
          <p class="text-muted">{{ post.body }}</p>
        </div>
      </div>
    </div>
  </div>
</div>

```

