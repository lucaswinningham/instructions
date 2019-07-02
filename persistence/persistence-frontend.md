```bash
$ cd frontend/
```

## Logout

###### frontend/src/app/services/utils/storage.service.ts

```ts
...
export class StorageService {
  ...

  clearSession(): void {
    localStorage.removeItem(this.storageKey);
    this.session$.next(new Session());
  }
}

```

###### frontend/src/app/services/auth/auth.service.ts

```ts
...
export class AuthService {

  ...

  logout(): void {
    this.storager.clearSession();
  }
}

```

###### frontend/src/app/navigation/user-hud/user-hud.component.ts

```ts
...

...
import { AuthService } from '@services/auth/auth.service';

...
export class UserHudComponent implements OnInit {
  ...

  constructor(private sessionStore: SessionStoreService, public authService: AuthService) { }

  ...

  logout(): void {
    this.authService.logout();
  }
}

```

###### frontend/src/app/navigation/user-hud/user-hud.component.html

```xml
<span *ngIf="...">
  <button type="button" class="btn btn-outline-dark px-3 mr-3" (click)="logout()">
    Logout
  </button>

  ...
</span>

...

```

## Unauthorized Interceptor

```bash
$ touch src/app/interceptors/unauthorized.interceptor.ts
```

###### frontend/src/app/interceptors/unauthorized.interceptor.ts

```ts
import { Injectable } from '@angular/core';
import { HttpRequest, HttpHandler, HttpEvent, HttpInterceptor } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { AuthService } from '@services/auth/auth.service';

@Injectable()
export class UnauthorizedInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService) { }

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(request).pipe(
      catchError(error => {
        if (error.status === 401) {
          this.authService.logout();
        }

        return throwError(error);
      })
    );
  }
}

```

###### frontend/src/app/app.module.ts

```ts
...

...
import { UnauthorizedInterceptor } from '@interceptors/unauthorized.interceptor';

...

@NgModule({
  ...,
  providers: [
    ...,
    { provide: HTTP_INTERCEPTORS, useClass: UnauthorizedInterceptor, multi: true }
  ],
  ...
})
export class AppModule { }

```

## Login Guard

```bash
$ ng g g guards/login
```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "paths": {
      ...,
      "@guards/*": [ "app/guards/*" ]
    }
  }
}

```

###### frontend/src/app/guards/login.guard.ts

```ts
...
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { StorageService } from '@services/utils/storage.service';

...
export class LoginGuard implements CanActivate {
  constructor(private storager: StorageService, private router: Router) { }

  canActivate(next: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<boolean> {
    return this.storager.session$.pipe(
      map(session => {
        if (session.isValid) { return true; }

        this.router.navigate(['/login'], { queryParams: { returnUrl: state.url } });
        return false;
      })
    );
  }
}

```

###### frontend/src/app/app-routing.module.ts

```ts
...

import { LoginGuard } from '@guards/login.guard';

const routes: Routes = [
  ...,
  { path: 'posts/create', component: CreatePostComponent, canActivate: [LoginGuard] }
];

...

```

###### frontend/src/app/pages/login/login.component.ts

```ts
...
import { Router, ActivatedRoute } from '@angular/router';
...
@AutoUnsubscribe()
export class LoginComponent implements OnInit {
  ...

  private returnUrl: string;
  ...

  constructor(
    private authService: AuthService,
    private route: ActivatedRoute,
    private router: Router,
    private logger: LogService
  ) { }

  ngOnInit() {
    this.authService.logout();
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/';
  }

  handleSubmit(): void {
    ...
    this.subscription = ...(
      ...
    ).subscribe(() => {
      this.router.navigate([this.returnUrl]);
    });
  }
}

```

