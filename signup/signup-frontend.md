```bash
$ cd frontend/
```

```bash
$ npm install \
  bcryptjs@latest \
  random-string@latest \
  crypto-js@latest \
  # @ngrx/store@latest \
  --save
# $ npm install \
#   ngrx-store-freeze \
#   --save-dev
```

```bash
$ ng g class models/user/user-auth --type=model
$ ng g class models/user/user-signup --type=model
```

###### frontend/src/app/models/user/user-auth.model.ts

```ts

```

###### frontend/src/app/models/user/user-signup.model.ts

```ts

```

```bash
$ ng g s services/queries/user-signup
```

###### frontend/src/app/services/queries/user-signup.service.spec.ts

```ts

```

###### frontend/src/app/services/queries/user-signup.service.ts

```ts

```

```bash
$ ng g m pages/signup --module=pages
$ ng g c pages/signup --module=pages/signup
```

###### frontend/src/app/app-routing.module.ts

```ts
...

import { SignupComponent } from '@pages/signup/signup.component';

const routes: Routes = [
  { path: 'signup', component: SignupComponent }
];

...

```

```bash
$ ng serve # ^C to stop
```

[Navigate to frontend](http://localhost:4200/signup)

