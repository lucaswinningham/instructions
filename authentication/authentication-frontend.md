```bash
$ cd frontend/
```

## Jwt Interceptor

```bash
$ mkdir src/app/interceptors
$ touch src/app/interceptors/jwt.interceptor.ts
```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "paths": {
      ...,
      "@interceptors/*": [ "app/interceptors/*" ]
    }
  }
}

```

###### frontend/src/app/interceptors/jwt.interceptor.ts

```ts
import { Injectable } from '@angular/core';
import { HttpRequest, HttpHandler, HttpEvent, HttpInterceptor } from '@angular/common/http';
import { Observable } from 'rxjs';
import { mergeMap } from 'rxjs/operators';

import { StorageService } from '@services/utils/storage.service';

@Injectable()
export class JwtInterceptor implements HttpInterceptor {
  constructor(private storager: StorageService) { }

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return this.storager.session$.pipe(
      mergeMap(session => {
        if (session.isValid) {
          request = request.clone({
            setHeaders: { Authorization: `Bearer ${session.token}` }
          });
        }

        return next.handle(request);
      })
    );
  }
}

```

###### frontend/src/app/app.module.ts

```ts
...
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';

import { JwtInterceptor } from '@interceptors/jwt.interceptor';

...

@NgModule({
  ...,
  providers: [
    { provide: HTTP_INTERCEPTORS, useClass: JwtInterceptor, multi: true }
  ],
  ...
})
export class AppModule { }

```

## Post Create

###### frontend/src/app/services/models/post.service.ts

```ts
...
export class PostService {

  ...

  create(args: { post: Post }): Observable<Post> {
    const { post } = args;
    const route = `subs/${post.subName}/posts`;
    return this.api.create({ route, body: post }).pipe(
      map(post => new Post(post))
    );
  }
}

```

```bash
$ ng g m pages/create-post --module=pages
$ ng g c pages/create-post --module=pages/create-post
```

###### frontend/src/app/app-routing.module.ts

```ts
...
import { CreatePostComponent } from '@pages/create-post/create-post.component';

const routes: Routes = [
  ...,
  { path: 'posts/create', component: CreatePostComponent }
];

...

```

<!-- only import the icons module -->
<!-- if abstracting out forms, only import app forms module, apply to all others importing FormsModule -->

###### frontend/src/app/create-post/create-post.module.ts

```ts
...
import { FormsModule } from '@angular/forms';

import { ComponentsModule } from '@components/components.module';

...

@NgModule({
  ...,
  imports: [
    ...,
    FormsModule,
    ComponentsModule
  ],
  ...
})
export class CreatePostModule { }

```

###### frontend/src/app/create-post/create-post.component.ts

```ts
...
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { finalize, catchError } from 'rxjs/operators';

import { AutoUnsubscribe } from '@decorators/auto-unsubscribe.decorator';

import { PostService } from '@services/models/post.service';

import { Post } from '@models/post.model';
import { LogService } from '@services/utils/log.service';

...
@AutoUnsubscribe()
export class CreatePostComponent {
  post: Post = new Post();
  waiting = false;

  private subscription: Subscription = new Subscription();

  constructor(private postApi: PostService, private router: Router, private logger: LogService) { }

  handleSubmit(): void {
    const { post } = this;

    this.waiting = true;
    this.subscription = this.postApi.create({ post }).pipe(
      finalize(() => this.waiting = false),
      catchError(this.logger.catchError())
    ).subscribe(() => {
      this.router.navigate(['/']);
    });
  }
}

```

<!-- abstract out form stuff to an app forms module -->
<!-- add validations, error messages -->

###### frontend/src/app/create-post/create-post.component.html

```xml
<div class="row">
  <div class="col-12">
    <form>
      <div class="form-group mt-3">
        <input type="text" class="form-control" id="subName" placeholder="Sub"
          [(ngModel)]="post.subName" [ngModelOptions]="{ standalone: true }" />
      </div>

      <div class="form-group mt-3">
        <input type="text-area" class="form-control" id="title" placeholder="Title"
          [(ngModel)]="post.title" [ngModelOptions]="{ standalone: true }" />
      </div>

      <div class="form-group mt-3">
        <input type="url" class="form-control" id="url" placeholder="Url"
          [(ngModel)]="post.url" [ngModelOptions]="{ standalone: true }" />
      </div>

      <div class="form-group mt-3">
        <textarea class="form-control" id="body" placeholder="Body"
          [(ngModel)]="post.body" [ngModelOptions]="{ standalone: true }">
        </textarea>
      </div>

      <button type="submit" class="btn col-12 text-center float-right"
        (click)="handleSubmit()" [disabled]="waiting"
        [ngClass]="waiting ? 'btn-outline-primary' : 'btn-primary'">
        <span *ngIf="!waiting">Submit</span>
        <app-icon *ngIf="waiting" [iconName]="'faDatabase'"></app-icon>
      </button>
    </form>
  </div>
</div>

```

###### frontend/src/app/navigation/user-hud/user-hud.component.html

```xml
<span *ngIf="...">
  <button type="button" class="btn btn-primary px-3 mr-3" routerLink="/posts/create">
    <app-icon [iconName]="'faPencilAlt'"></app-icon>
  </button>

  ...
</span>

...

```

## Comment Create

```bash
$ mkdir src/app/models/helpers
$ touch src/app/models/helpers/commentable.helper.ts
```

###### frontend/src/app/models/helper/commentable.helper.ts

```ts
import { Comment } from '@models/comment.model';
import { Post } from '@models/post.model';

export type Commentable = Comment | Post;

export class CommentableHelper {
  static isComment(commentable: Commentable): boolean {
    return commentable.type === 'comment';
  }

  static isPost(commentable: Commentable): boolean {
    return commentable.type === 'post';
  }
}

```

###### frontend/src/app/services/models/comment.service.ts

```ts
...

import { CommentableHelper, Commentable } from '@models/helpers/commentable.helper';

...
export class CommentService {

  ...

  create(args: { commentable: Commentable, comment: Comment }): Observable<Comment> {
    const { commentable, comment } = args;
    const route = this.commentableCommentsRoute(commentable);

    return this.api.create({ route, body: comment }).pipe(
      map(comment => new Comment(comment))
    );
  }

  private commentableCommentsRoute(commentable: Commentable): string {
    if (CommentableHelper.isComment(commentable)) {
      return `comments/${commentable.token}/comments`;
    } else if (CommentableHelper.isPost(commentable)) {
      return `posts/${commentable.token}/comments`;
    }
  }
}

```

## Vote Create

```bash
$ ng g class models/vote --type=model
```

###### frontend/src/app/models/vote.model.ts

```ts
import { Base } from '@models/base.model';

export class Vote extends Base {
  readonly direction: boolean;

  protected afterConstruction(): void {
    const { direction } = this.params;
    Object.assign(this, { direction });
  }

  protected localSerialize(): any {
    const { direction } = this;
    return { direction };
  }
}

```

```bash
$ ng g s services/models/vote
```

<!-- do the same thing for comment service, createForComment && createForPost -->

###### frontend/src/app/services/models/vote.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '../utils/api.service';

import { Vote } from '@models/vote.model';

...
export class VoteService {

  constructor(private api: ApiService) { }

  createForComment(args: { token: string, vote: Vote }): Observable<Vote> {
    const { token, vote } = args;
    const route = `comments/${token}/vote`;

    return this.api.create({ route, body: vote }).pipe(
      map(vote => new Vote(vote))
    );
  }

  createForPost(args: { token: string, vote: Vote }): Observable<Vote> {
    const { token, vote } = args;
    const route = `posts/${token}/vote`;

    return this.api.create({ route, body: vote }).pipe(
      map(vote => new Vote(vote))
    );
  }
}

```

<!-- move these to post component and not in subreddit/post -->
<!-- do we really need ngmodule? i dont think so -->

###### frontend/src/app/pages/subreddit/post/post.module.ts

```ts
...
import { FormsModule } from '@angular/forms';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

...

@NgModule({
  ...,
  imports: [
    ...,
    FormsModule,
    NgbModule
  ],
  ...
})
export class PostModule { }

```

<!-- change -subscription to commentSubscription OR change auto unsubscribe to check for subscription arrays and map through those and unsubscribe -->

###### frontend/src/app/pages/subreddit/post/post-comment/post-comment.component.ts

```ts
...
import { Observable, Subscription, Subject } from 'rxjs';
import { finalize, switchMap, tap } from 'rxjs/operators';

import { AutoUnsubscribe } from '@app/decorators/auto-unsubscribe.decorator';

import { StorageService } from '@services/utils/storage.service';
import { CommentService } from '@services/models/comment.service';
import { VoteService } from '@services/models/vote.service';

...
import { Session } from '@models/auth/session.model';
import { Vote } from '@models/vote.model';

@Component({
  selector: 'app-post-comment',
  templateUrl: './post-comment.component.html',
  styleUrls: ['./post-comment.component.scss']
})
@AutoUnsubscribe()
export class PostCommentComponent implements OnInit {
  ...

  session$: Observable<Session>;

  reply: Comment;
  replyWaiting = false;

  voteStream: Subject<Vote> = new Subject<Vote>();
  upvoted = false;
  dnvoted = false;

  private commentCreateSubscription: Subscription = new Subscription();

  private voteStreamSubscription: Subscription;

  private vote: Vote = new Vote();

  constructor(
    private storager: StorageService,
    private commentApi: CommentService,
    private voteApi: VoteService
  ) { }

  ngOnInit() {
    this.session$ = this.storager.session$;

    this.voteStreamSubscription = this.listenToVoteStream();
  }

  newReply(): void {
    this.reply = new Comment();
  }

  clearReply(): void {
    this.reply = null;
  }

  handleReplySubmit(): void {
    const commentable = this.comment;
    const comment = this.reply;

    this.replyWaiting = true;
    this.commentCreateSubscription = this.commentApi.create({ commentable, comment }).pipe(
      finalize(() => this.replyWaiting = false),
    ).subscribe(() => this.clearReply());
  }

  handleVote(newDirection: boolean): void {
    if (newDirection == this.vote.direction) {
      this.voteStream.next(new Vote({ direction: null }));
    } else {
      this.voteStream.next(new Vote({ direction: newDirection }));
    }
  }

  private listenToVoteStream(): Subscription {
    const token = this.comment.token;
    return this.voteStream.pipe(
      switchMap((vote: Vote) => {
        return this.voteApi.createForComment({ token, vote }).pipe(
          tap((vote: Vote) => this.upvoted = vote.direction === true),
          tap((vote: Vote) => this.dnvoted = vote.direction === false),
          tap((vote: Vote) => this.vote = vote)
        )
      })
    ).subscribe();
  }
}

```

<!-- clean up vote design -->

###### frontend/src/app/pages/subreddit/post/post-comment/post-comment.component.html

```xml
<ng-container *ngIf="comment">
  <div class="my-2 ...">
    ...

    <div *ngIf="!reply && (session$ | async).isValid" class="small" (click)="newReply()"
      appHoverPointer>
      <app-icon [iconName]="'faReply'"></app-icon>
      Reply
    </div>

    <div *ngIf="reply" class="container">
      <div class="row">
        <div class="col-12">
          <textarea class="w-100" rows="3" [(ngModel)]="reply.content"></textarea>
        </div>

        <div class="btn btn-white col-3" (click)="clearReply()" appHoverPointer>
          Cancel
        </div>

        <div class="btn btn-primary col-3 ml-auto" (click)="handleReplySubmit()" appHoverPointer>
          <app-icon *ngIf="!waiting" [iconName]="'faReply'"></app-icon>
          <app-icon *ngIf="waiting" [iconName]="'faDatabase'"></app-icon>
        </div>
      </div>
    </div>

    <div *ngIf="(session$ | async).isValid" class="container mt-3">
      <div class="row justify-content-between">
        <div class="col-5 btn text-center dnvote-btn" (click)="handleVote(false)" appHoverPointer
          [class.dnvoted]="dnvoted">
          <app-icon [iconName]="'faArrowDown'"></app-icon>
        </div>

        <div class="col-5 btn text-center upvote-btn" (click)="handleVote(true)" appHoverPointer
          [class.upvoted]="upvoted">
          <app-icon [iconName]="'faArrowUp'"></app-icon>
        </div>
      </div>
    </div>

    <app-post-comment ...></app-post-comment>
  </div>
</ng-container>

```

<!-- abstract out the voting and commenting mechanisms here and in the post comment -->

###### frontend/src/app/pages/subreddit/post/post.component.ts

```ts
...
import { Subject, of, Subscription, Observable } from 'rxjs';
...

...
import { StorageService } from '@app/services/utils/storage.service';
import { VoteService } from '@services/models/vote.service';

...
import { Session } from '@models/auth/session.model';
import { Vote } from '@models/vote.model';

...
export class PostComponent implements OnInit {
  ...

  session$: Observable<Session>;

  reply: Comment;
  replyWaiting = false;

  voteStream: Subject<Vote> = new Subject<Vote>();
  upvoted = false;
  dnvoted = false;

  private commentCreateSubscription: Subscription = new Subscription();

  ...
  private voteStreamSubscription: Subscription;

  private vote: Vote = new Vote();

  constructor(
    ...,
    private storager: StorageService,
    private voteApi: VoteService
  ) { }

  ngOnInit() {
    this.session$ = this.storager.session$;

    ...
    this.voteStreamSubscription = this.listenToVoteStream();
  }

  ...

  newReply(): void {
    this.reply = new Comment();
  }

  clearReply(): void {
    this.reply = null;
  }

  handleReplySubmit(): void {
    const commentable = this.post;
    const comment = this.reply;

    this.replyWaiting = true;
    this.commentCreateSubscription = this.commentApi.create({ commentable, comment }).pipe(
      finalize(() => this.replyWaiting = false),
    ).subscribe(() => this.clearReply());
  }

  handleVote(newDirection: boolean): void {
    if (newDirection == this.vote.direction) {
      this.voteStream.next(new Vote({ direction: null }));
    } else {
      this.voteStream.next(new Vote({ direction: newDirection }));
    }
  }

  private listenToCommentStream()...

  private listenToVoteStream(): Subscription {
    const token = this.post.token;
    return this.voteStream.pipe(
      switchMap((vote: Vote) => {
        return this.voteApi.createForPost({ token, vote }).pipe(
          tap((vote: Vote) => this.upvoted = vote.direction === true),
          tap((vote: Vote) => this.dnvoted = vote.direction === false),
          tap((vote: Vote) => this.vote = vote)
        )
      })
    ).subscribe();
  }
}

```

<!-- clean up reply design -->

###### frontend/src/app/pages/subreddit/post/post.component.html

```xml
<div class="row" ...>
  <div class="col-12 ...">
    ...

    <div *ngIf="!reply && (session$ | async).isValid" class="small" (click)="newReply()"
      appHoverPointer>
      <app-icon [iconName]="'faReply'"></app-icon>
      Reply
    </div>

    <div *ngIf="reply" class="container">
      <div class="row">
        <div class="col-12">
          <textarea class="w-100" rows="3" [(ngModel)]="reply.content"></textarea>
        </div>

        <div class="btn btn-white col-3" (click)="clearReply()" appHoverPointer>
          Cancel
        </div>

        <div class="btn btn-primary col-3 ml-auto" (click)="handleReplySubmit()" appHoverPointer>
          <app-icon *ngIf="!waiting" [iconName]="'faReply'"></app-icon>
          <app-icon *ngIf="waiting" [iconName]="'faDatabase'"></app-icon>
        </div>
      </div>
    </div>

    <div *ngIf="(session$ | async).isValid" class="container mt-3">
      <div class="row justify-content-between">
        <div class="col-5 btn text-center dnvote-btn" (click)="handleVote(false)" appHoverPointer
          [class.dnvoted]="dnvoted">
          <app-icon [iconName]="'faArrowDown'"></app-icon>
        </div>

        <div class="col-5 btn text-center upvote-btn" (click)="handleVote(true)" appHoverPointer
          [class.upvoted]="upvoted">
          <app-icon [iconName]="'faArrowUp'"></app-icon>
        </div>
      </div>
    </div>

    ...
  </div>
</div>

```

###### frontend/src/app/pages/subreddit/post/post.component.scss

```scss
...

.dnvote-btn {
  color: $blue;
  border-color: $blue;

  &:hover {
    color: $white;
    background: $blue;
  }

  &.dnvoted {
    color: $white;
    background: $blue;
  }
}

.upvote-btn {
  color: $orange;
  border-color: $orange;

  &:hover {
    color: $white;
    background: $orange;
  }

  &.upvoted {
    color: $white;
    background: $orange;
  }
}

```



