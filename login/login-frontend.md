```bash
$ cd frontend/
```

```bash
$ ng g class models/auth/salt --type=model
```

###### frontend/src/app/models/auth/salt.model.ts

```ts
import { Base } from '@models/base.model';

export class Salt extends Base {
  readonly value: string;

  protected afterConstruction(): void {
    const { value } = this.params;
    Object.assign(this, { value });
  }
}

```

```bash
$ ng g s services/models/auth/salt
```

###### frontend/src/app/services/models/auth/salt.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '@services/utils/api.service';

import { Salt } from '@models/auth/salt.model';

...
export class SaltService {

  constructor(private api: ApiService) { }

  read(userName: string): Observable<Salt> {
    const route = `users/${userName}/salt`;
    return this.api.read({ route }).pipe(
      map(salt => new Salt(salt))
    );
  }
}

```

```bash
$ ng g class models/auth/nonce --type=model
```

###### frontend/src/app/models/auth/nonce.model.ts

```ts
import { Base } from '@models/base.model';

export class Nonce extends Base {
  readonly userName: string;
  readonly value: string;

  protected afterConstruction(): void {
    const { userName, value } = this.params;
    Object.assign(this, { userName, value });
  }
}

```

```bash
$ ng g s services/models/auth/nonce
```

###### frontend/src/app/services/models/auth/nonce.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '@services/utils/api.service';

import { Nonce } from '@models/auth/nonce.model';

...
export class NonceService {

  constructor(private api: ApiService) { }

  create(userName: string): Observable<Nonce> {
    const route = `users/${userName}/nonce`;
    return this.api.create({ route }).pipe(
      map(nonce => new Nonce(nonce))
    );
  }
}

```

```bash
$ ng g class models/auth/session --type=model
```

###### frontend/src/app/models/auth/session.model.ts

```ts
import { Base } from '@models/base.model';

export class Session extends Base {
  readonly userName: string;
  readonly token: string;

  protected afterConstruction(): void {
    const { userName, token } = this.params;
    Object.assign(this, { userName, token });
  }

  get isValid(): boolean {
    return this.token && !this.tokenExpired;
  }

  private get tokenExpired(): boolean {
    const now = Math.floor(new Date().getTime() / 1000);
    return now > this.tokenPayload.exp;
  }

  private get tokenPayload(): { exp: number } {
    if (!this.token) { return { exp: Infinity }; }

    const payloadString = this.token.split('.')[1];
    return JSON.parse(atob(payloadString));
  }
}

```

```bash
$ ng g s services/models/auth/session
```

###### frontend/src/app/services/models/auth/session.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '@services/utils/api.service';
import { CipherService } from '@services/auth/cipher.service';

import { Nonce } from '@models/auth/nonce.model';
import { Session } from '@models/auth/session.model';

...
export class SessionService {
  constructor(private api: ApiService, private cipher: CipherService) { }

  create(args: { nonce: Nonce; hashedPassword: string, cnonce: Nonce }): Observable<Session> {
    const { nonce, hashedPassword, cnonce } = args;

    const message = this.cipher.encrypt([nonce.value, hashedPassword, cnonce.value].join('||'));

    const route = `users/${nonce.userName}/session`;
    const body = { message };

    return this.api.create({ route, body }).pipe(
      map(session => new Session(session))
    );
  }
}

```

###### frontend/src/app/services/utils/api.service.ts

```ts
...
export class ApiService {
  ...

  list(...) ...

  create(args: { route: string, body?: any }): Observable<any> {
    const route = args.route;
    const body = args.body ? this.snakeifyKeys(args.body) : {};
    const url = `${apiUrl}/${route}`;
    return this.process(this.http.post(url, body));
  }

  read(...) ...

  ...
}

```

```bash
$ ng g s services/auth/cipher
```

###### frontend/src/environments/environment.ts

```ts
export const environment = {
  ...,
  cipherKey: 'r/7G4sNX+OpZwQ4LT/1/yg==\n',
  cipherIv: 'Qh0mpEcb9waVAVPOeJX71Q==\n'
};

```

###### frontend/src/app/services/auth/cipher.service.ts

```ts
...

import { environment } from '@env/environment';

import * as crypto from 'crypto-js';

...
export class CipherService {
  encrypt(secret: string): string {
    return crypto.AES.encrypt(secret, this.cipherKey, { iv: this.cipherIv }).toString();
  }

  decrypt(secret: string): string {
    return crypto.AES.decrypt(secret, this.cipherKey, { iv: this.cipherIv }).toString(crypto.enc.Utf8);
  }

  private get cipherKey(): string {
    return crypto.enc.Base64.parse(environment.cipherKey);
  }

  private get cipherIv(): string {
    return crypto.enc.Base64.parse(environment.cipherIv);
  }
}

```

```bash
$ ng g s services/auth/hash
```

###### frontend/src/app/services/auth/hash.service.ts

```ts
...

import randomString from 'random-string';
import * as bcryptjs from 'bcryptjs';

import { CipherService } from '@services/auth/cipher.service';

...
export class HashService {
  constructor(private cipher: CipherService) { }

  hashSecret(secret: string, salt: string): string {
    return bcryptjs.hashSync(secret, salt);
  }

  randomHash(): string {
    return this.cipher.encrypt(randomString({ length: 32 }));
  }
}

```

```bash
$ ng g s services/utils/storage
```

<!-- revisit with angular models -->
<!-- any consumer can next a value -->

###### frontend/src/app/services/utils/storage.service.ts

```ts
...
import { BehaviorSubject } from 'rxjs';

import { Session } from '@models/auth/session.model';

...
export class StorageService {
  private storageKey = 'redditSession';
  readonly session$: BehaviorSubject<Session> = new BehaviorSubject<Session>(new Session());

  constructor() {
    const session = JSON.parse(localStorage.getItem(this.storageKey));
    if (session) { this.session$.next(new Session(session)); }
  }

  set session(session: Session) {
    localStorage.setItem(this.storageKey, JSON.stringify(session));
    this.session$.next(session);
  }
}

```

```bash
$ ng g s services/auth/auth
```

###### frontend/src/app/services/auth/auth.service.ts

```ts
...
import { Observable, combineLatest } from 'rxjs';
import { mergeMap, tap } from 'rxjs/operators';

import { HashService } from '@services/auth/hash.service';
import { SaltService } from '@services/models/auth/salt.service';
import { NonceService } from '@services/models/auth/nonce.service';
import { SessionService } from '@services/models/auth/session.service';
import { StorageService } from '@services/utils/storage.service';

import { Salt } from '@models/auth/salt.model';
import { Nonce } from '@models/auth/nonce.model';
import { Session } from '@models/auth/session.model';

...
export class AuthService {
  constructor(
    private hasher: HashService,
    private nonceApi: NonceService,
    private saltApi: SaltService,
    private sessionApi: SessionService,
    private storager: StorageService
  ) { }

  login(creds: { userName: string; password: string }): Observable<Session> {
    const { userName, password } = creds;
    const saltObs = this.saltApi.read(userName);
    const nonceObs = this.nonceApi.create(userName);

    return combineLatest(saltObs, nonceObs).pipe(
      mergeMap(([salt, nonce]: [Salt, Nonce]): Observable<Session> => {
        const hashedPassword = this.hasher.hashSecret(password, salt.value);
        const cnonce = new Nonce({ value: this.hasher.randomHash() });
        return this.sessionApi.create({ nonce, hashedPassword, cnonce });
      }),
      tap((session: Session) => this.storager.session = session)
    );
  }
}

```

<!-- move to somewhere before here, setup? -->

## AutoUnsubscribe

```bash
$ mkdir src/app/decorators
$ touch src/app/decorators/auto-unsubscribe.decorator.ts
```

###### frontend/src/app/decorators/auto-unsubscribe.decorator.ts

```ts
export function AutoUnsubscribe(options: { except: string[] } = { except: [] }) {
  return function (constructor) {
    const original = constructor.prototype.ngOnDestroy;

    constructor.prototype.ngOnDestroy = function () {
      for ( const prop of Object.keys(this) ) {
        const property = this[ prop ];
        if ( !options.except.includes(prop) ) {
          if ( property && typeof property.unsubscribe === 'function' ) {
            property.unsubscribe();
          }
        }
      }

      if (original && typeof original === 'function') {
        original.apply(this, arguments);
      }
    };
  };
}

```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "paths": {
      ...,
      "@decorators/*": [ "app/decorators/*" ]
    }
  }
}

```

## Login

```bash
$ ng g m pages/login --module=pages
$ ng g c pages/login --module=pages/login
```

###### frontend/src/app/app-routing.module.ts

```ts
...
import { LoginComponent } from '@pages/login/login.component';

const routes: Routes = [
  ...,
  { path: 'login', component: LoginComponent }
];

...

```

<!-- if abstracting, only import app forms module -->

###### frontend/src/app/login/login.module.ts

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
export class LoginModule { }

```

###### frontend/src/app/pages/login/login.component.ts

```ts
...
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { finalize, catchError } from 'rxjs/operators';

import { AutoUnsubscribe } from '@decorators/auto-unsubscribe.decorator';

import { AuthService } from '@services/auth/auth.service';
import { LogService } from '@services/utils/log.service';

...
@AutoUnsubscribe()
export class LoginComponent implements OnInit {
  userName: string;
  password: string;
  waiting = false;

  private subscription: Subscription = new Subscription();

  constructor(
    private authService: AuthService,
    private router: Router,
    private logger: LogService
  ) { }

  handleSubmit(): void {
    const { userName, password } = this;

    this.waiting = true;
    this.subscription = this.authService.login({ userName, password }).pipe(
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

###### frontend/src/app/login/login.component.html

```xml
<div class="row">
  <div class="col-12">
    <form>
      <div class="form-group mt-3">
        <input type="text" class="form-control" id="userName" placeholder="Username"
          [(ngModel)]="userName" [ngModelOptions]="{ standalone: true }" />
      </div>

      <div class="form-group mt-3">
        <input type="password" class="form-control" id="password" placeholder="Password"
          [(ngModel)]="password" [ngModelOptions]="{ standalone: true }" />
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

## Navigation

<!-- ```bash
$ ng g c components/modal --module=components --export
```

###### frontend/src/app/components/modal/modal.component.ts

```ts
import { Component, Output, EventEmitter } from '@angular/core';

...
export class ModalComponent {
  @Output() close: EventEmitter<any> = new EventEmitter<any>();

  dismiss(): void {
    this.close.emit();
  }
}

```

###### frontend/src/app/components/modal/modal.component.html

```xml
<div class="modal-header">
  <h4 class="modal-title" id="modal-basic-title">
    <ng-content select=".modal-title"></ng-content>
  </h4>

  <button type="button" class="close" aria-label="Close" (click)="dismiss()">
    <span aria-hidden="true">&times;</span>
  </button>
</div>

<div class="modal-body">
  <ng-content select=".modal-body"></ng-content>
</div>

``` -->

```bash
$ ng g m navigation --module=app
$ ng g c navigation --module=navigation --export
$ ng g c navigation/user-hud --module=navigation
```

###### frontend/src/app/app.component.html

```xml
<app-navigation></app-navigation>

<section>
  <div class="container">
    <div class="row">
      <div class="col-12">
        <router-outlet></router-outlet>
      </div>
    </div>
  </div>
</section>

```

<!-- only import icons module -->

###### frontend/src/app/navigation/navigation.module.ts

```ts
...
import { AppRoutingModule } from '@app/app-routing.module';

import { ComponentsModule } from '@components/components.module';

...

@NgModule({
  ...,
  imports: [
    ...,
    AppRoutingModule,
    ComponentsModule
  ],
  ...
})
export class NavigationModule { }

```

<!-- start using $ suffix for observables? -->
<!-- and on that note, start using _ prefix for private variables? -->

###### frontend/src/app/navigation/user-hud/user-hud.component.ts

```ts
...
import { Observable } from 'rxjs';

// import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

import { StorageService } from '@services/utils/storage.service';

import { Session } from '@models/auth/session.model';

...
export class UserHudComponent implements OnInit {
  session$: Observable<Session>;

  // constructor(private modalService: NgbModal, private sessionStore: SessionStoreService) { }
  constructor(private storager: StorageService, public authService: AuthService) { }

  ngOnInit() {
    this.session$ = this.storager.session$;
  }

  // open(content): void {
  //   this.modalService.open(content);
  // }

  // close(modal): void {
  //   modal.close();
  // }
}

```

###### frontend/src/app/navigation/user-hud/user-hud.component.html

```xml
<span *ngIf="(session$ | async).isValid; else loginCta">
  <button class="btn btn-outline-success px-3" [routerLink]="['/u', (session$ | async).userName]">
    <span class="mr-3">{{ (session$ | async).userName }}</span>
    <app-icon [iconName]="'faUserCircle'"></app-icon>
  </button>
</span>

<ng-template #loginCta>
  <!-- <button type="button" class="btn btn-outline-primary px-3" (click)="open(loginModal)"> -->
  <button type="button" class="btn btn-outline-primary px-3" routerLink="/login">
    Login
  </button>
</ng-template>

<!-- <ng-template #loginModal let-modal>
  <app-modal (close)="close(modal)">
    <div class="modal-title text-center">
      Login
    </div>

    <div class="modal-body">
      <app-login-form (success)="close(modal)"></app-login-form>
    </div>
  </app-modal>
</ng-template> -->

```

###### frontend/src/app/navigation/navigation.component.html

```xml
<div class="container-fluid">
  <div class="d-flex my-3 justify-content-between align-items-center">
    <a routerLink="/">
      <app-icon class="logo-icon" [iconName]="'faReddit'" [size]="2"></app-icon>
    </a>

    <app-user-hud></app-user-hud>
  </div>
</div>

```

###### frontend/src/app/navigation/navigation.component.scss

```scss
@import '~assets/styles/colors';

.logo-icon {
  color: $orange;
}

```

