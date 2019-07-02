```bash
$ cd frontend/
```

<!-- ```bash
$ ng g class models/activation --type=model
```

###### frontend/src/app/models/activation.model.ts

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

``` -->

```bash
$ ng g s services/models/auth/activation
```

###### frontend/src/app/services/models/auth/activation.service.ts

```ts
...
import { Observable } from 'rxjs';

...
export class ActivationService {
}

```

###### frontend/src/app/services/auth/auth.service.ts

```ts
...
import { ActivationService } from '@services/models/auth/activation.service';

export class AuthService {
  constructor(
    ...,
    private activationApi: ActivationService
  ) { }

  ...

  activate(credentials: {  }): Observable<Session> {
  }
}

```

###### frontend/src/app/services/utils/api.service.ts

```ts
...
export class ApiService {
  ...

  read(...) ...

  update(args: { route: string, body?: any }): Observable<any> {
    const route = args.route;
    const body = args.body ? this.snakeifyKeys(args.body) : {};
    const url = `${apiUrl}/${route}`;
    return this.process(this.http.put(url, body));
  }

  ...
}

```

```bash
$ ng g m pages/activation --module=pages
$ ng g c pages/activation --module=pages/activation
```

###### frontend/src/app/app-routing.module.ts

```ts
...
import { ActivationComponent } from '@pages/activation/activation.component';

...

const routes: Routes = [
  ...,
  { path: 'u/:userName/activation/:token', component: ActivationComponent }
];

...

```

###### frontend/src/app/activation/activation.module.ts

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
export class ActivationModule { }

```

###### frontend/src/app/activation/activation.component.ts

```ts
...
import { ActivatedRoute, Router, ParamMap } from '@angular/router';
import { Subscription } from 'rxjs';
import { switchMap, finalize, catchError } from 'rxjs/operators';

import { AutoUnsubscribe } from '@decorators/auto-unsubscribe.decorator';

import { AuthService } from '@services/auth/auth.service';
import { LogService } from '@services/utils/log.service';

...
@AutoUnsubscribe()
export class ActivationComponent {
}

```

###### frontend/src/app/activation/activation.component.html

```xml

```

