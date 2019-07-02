```bash
$ cd frontend/
```

```bash
$ ng g class models/comment --type=model
```

###### frontend/src/app/models/comment.model.ts

```ts
import { Base } from '@models/base.model';

export class Comment extends Base {
  readonly userName: string;
  readonly content: string;
  readonly active: boolean;
  readonly token: string;
  readonly comments: Comment[];

  protected afterConstruction(): void {
    const { userName, content, active, token } = this.params;
    const comments = (this.params.comments || []).map(comment => new Comment(comment));
    Object.assign(this, { userName, content, active, token, comments });
  }

  protected localSerialize(): any {
    const { userName, content } = this;
    return { userName, content };
  }
}

```

```bash
$ ng g s services/models/comment
```

###### frontend/src/app/services/models/comment.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '../utils/api.service';

import { Comment } from '@models/comment.model';

...
export class CommentService {

  constructor(private api: ApiService) { }

  list(args: { postToken: string }): Observable<Comment[]> {
    const { postToken } = args;
    const route = `posts/${postToken}/comments`;
    return this.api.list({ route }).pipe(
      map(comments => comments.map(comment => new Comment(comment)))
    );
  }
}

```

<!-- make so module import only those components they want -->
<!-- move this somewhere else -->

```bash
$ ng g m components/icon --module=app
$ ng g c components/icon --module=components/icon --export
```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "paths": {
      ...,
      "@components/*": [ "app/components/*" ]
    }
  }
}

```

###### frontend/src/app/components/components.module.ts

```ts
...

import { FontAwesomeModule } from '@fortawesome/angular-fontawesome';

...

@NgModule({
  ...
  imports: [
    ...,
    FontAwesomeModule
  ],
  ...
})
export class ComponentsModule { }

```

###### frontend/src/app/components/icon/icon.component.ts

```ts
import { Component, OnInit, Input } from '@angular/core';

import * as BrandIcons from '@fortawesome/free-brands-svg-icons';
import * as SolidIcons from '@fortawesome/free-solid-svg-icons';

...
export class IconComponent implements OnInit {
  icon: BrandIcons.IconDefinition | SolidIcons.IconDefinition;
  @Input() iconName: string;
  @Input() size: number;

  ngOnInit() {
    if (BrandIcons[this.iconName]) {
      this.icon = BrandIcons[this.iconName];
    } else if (SolidIcons[this.iconName]) {
      this.icon = SolidIcons[this.iconName];
    }
  }

  get sizeClass(): string {
    return this.size ? `fa-${this.size}x` : null;
  }
}

```

###### frontend/src/app/components/icon/icon.component.html

```xml
<fa-icon [ngClass]="sizeClass" [icon]="icon"></fa-icon>

```

<!-- move these to post component and not in subreddit/post -->

```bash
$ ng g c pages/subreddit/post/post-comment --module=pages/subreddit/post
```

###### frontend/src/app/pages/subreddit/post/post.module.ts

```ts
...

...
import { IconsModule } from '@components/icons/icons.module';

...

@NgModule({
  ...,
  imports: [
    ...,
    IconsModule
  ]
})
export class SubredditModule { }

```

###### frontend/src/app/pages/subreddit/post/post-comment/post-comment.component.ts

```ts
import { Component, OnInit, Input } from '@angular/core';

import { Comment } from '@models/comment.model';

...
export class PostCommentComponent implements OnInit {
  @Input() comment: Comment;

  ...

}

```

###### frontend/src/app/pages/subreddit/post/post-comment/post-comment.component.html

```xml
<ng-container *ngIf="comment">
  <div class="my-2 pl-3 border-left">
    <span class="text-muted small">
      <span [routerLink]="['/u', comment.userName]" appHoverPointer>
        {{ comment.userName }}
      </span>
      • {{ comment.createdAt | amTimeAgo }}
    </span>

    <div>
      {{ comment.content }}
    </div>

    <app-post-comment *ngFor="let child of comment.comments" [comment]="child"></app-post-comment>
  </div>
</ng-container>

```

###### frontend/src/app/pages/subreddit/post/post.component.ts

```ts
...
import { Subject, Observable, of, Subscription } from 'rxjs';
import { switchMap, tap, finalize } from 'rxjs/operators';

import { AutoUnsubscribe } from '@app/decorators/auto-unsubscribe.decorator';

import { CommentService } from '@services/models/comment.service';

...
import { Comment } from '@models/comment.model';

...
@AutoUnsubscribe()
export class PostComponent implements OnInit {
  ...

  showComments = false;
  commentsWaiting = false;
  commentStream: Subject<void> = new Subject<void>();
  comments: Comment[];

  private commentStreamSubscription: Subscription;

  constructor(private commentApi: CommentService) { }

  ngOnInit() {
    this.commentStreamSubscription = this.listenToCommentStream();
  }

  toggleComments(): void {
    this.commentStream.next();
  }

  private listenToCommentStream(): Subscription {
    return this.commentStream.pipe(
      tap(() => this.commentsWaiting = true),
      switchMap(() => {
        if (!this.comments) {
          this.commentsWaiting = true;
          const postToken = this.post.token;
          return this.commentApi.list({ postToken }).pipe(
            tap(comments => this.comments = comments),
            finalize(() => this.commentsWaiting = false)
          );
        } else {
          return of(this.comments);
        }
      }),
      tap(() => this.commentsWaiting = false)
    ).subscribe(() => this.showComments = !this.showComments);
  }
}

```

<!-- add number of comments? -->

###### frontend/src/app/pages/subreddit/post/post.component.html

```xml
<div class="row" ...>
  <div class="col-12 ...">
    ...

    <div class="container mt-3">
      <div class="row">
        <div class="col-12 btn text-center comments-btn" (click)="toggleComments()" appHoverPointer
          [class.show-comments]="showComments">
          <app-icon *ngIf="!commentsWaiting" [iconName]="'faComment'"></app-icon>
          <app-icon *ngIf="commentsWaiting" [iconName]="'faDatabase'"></app-icon>
        </div>
      </div>
    </div>

    <div *ngIf="showComments" class="container mt-3">
      <div class="row">
        <div class="col-12">
          <div *ngFor="let comment of comments">
            <app-post-comment [comment]="comment"></app-post-comment>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

```

###### frontend/src/app/pages/subreddit/post/post.component.scss

```scss
@import '~assets/styles/colors';

.comments-btn {
  color: $white;
  background: $green;

  &.show-comments:not(:hover) {
    color: $green;
    background: $white;
    border-color: $green;
  }
}

```

