```bash
$ cd frontend/
```

###### frontend/src/app/models/post.model.ts

```ts
import { Base } from '@models/base.model';

export class Post extends Base {
  ...
  readonly votesCount: number;

  protected afterConstruction(): void {
    const { ..., votesCount } = this.params;
    Object.assign(this, { ..., votesCount });
  }

  get karma(): number {
    return this.votesCount;
  }

  ...
}

```

###### frontend/src/app/models/comment.model.ts

```ts
import { Base } from '@models/base.model';

export class Comment extends Base {
  ...
  readonly votesCount: number;

  protected afterConstruction(): void {
    const { ..., votesCount } = this.params;
    ...
    Object.assign(this, { ..., votesCount });
  }

  get karma(): number {
    return this.votesCount;
  }

  ...
}

```

###### frontend/src/app/pages/subreddit/post/post.component.html

```xml
<div class="row" ...>
  <div class="col-12 ...">
    <div class="row ...">
      ...

      <div class="col text-right">
        {{ post.karma }} points
      </div>
    </div>

    ...
  </div>
</div>

```

###### frontend/src/app/pages/subreddit/post/post-comment/post-comment.component.html

```xml
<ng-container ...>
  <div class="my-2 ...">
    <span class="text-muted ...">
      ...
      {{ comment.karma }} points • {{ comment.createdAt | amTimeAgo }}
    </span>

    ...
  </div>
</ng-container>

```

