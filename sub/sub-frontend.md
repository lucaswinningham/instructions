```bash
$ cd frontend/
```

<!-- clean this up re: rootSubNames, just don't like it but it works -->

###### frontend/src/app/services/models/post.service.ts

```ts
...
import { map } from 'rxjs/operators';

...

const rootSubNames = ['all'];

...
export class PostService {

  constructor(private api: ApiService) { }

  list(args: { subName: string }): Observable<Post[]> {
    const { subName } = args;
    const route = rootSubNames.includes(subName) ? 'posts' : `subs/${subName}/posts`;
    return this.api.list({ route }).pipe(
      map(posts => posts.map(post => new Post(post)))
    );
  }
}

```

###### frontend/src/app/pages/subreddit/subreddit.component.ts

```ts
...
import { ActivatedRoute, ParamMap } from '@angular/router';
import { Observable } from 'rxjs';
import { switchMap } from 'rxjs/operators';

...
export class SubredditComponent implements OnInit {
  ...

  constructor(..., private route: ActivatedRoute) { }

  ngOnInit() {
    this.posts = this.route.paramMap.pipe(
      switchMap((params: ParamMap) => {
        const subName = params.get('name');
        return this.postApi.list({ subName });
      })
    );
  }

}

```

###### frontend/src/app/models/post.model.ts

```ts
import { Base } from '@models/base.model';

export class Post extends Base {
  readonly subName: string;
  ...

  protected afterConstruction(): void {
    const { subName, ... } = this.params;
    Object.assign(this, { subName, ... });
  }

  protected localSerialize(): any {
    const { subName, ... } = this;
    return { subName, ... };
  }
}

```

###### frontend/src/app/pages/subreddit/post/post.component.html

```xml
<div class="row" ...>
  <div class="col-12 ...">
    <div class="row d-flex small mb-2">
      <div [routerLink]="['/r', post.subName]" class="d-flex align-items-center">
        <div class="col text-center font-weight-bold" appHoverPointer>
          r/{{ post.subName }}
        </div>
      </div>
    </div>

    ...
  </div>
</div>

```

