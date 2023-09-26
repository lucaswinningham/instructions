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
$ ng g class models/jwt --type=model
$ ng g class models/user --type=model
```

###### frontend/src/app/models/jwt.model.ts

```ts

```

###### frontend/src/app/models/user.model.ts

```ts

```

```bash
$ ng g class spec/users/user-trait-generator
$ ng g s services/queries/users/user-create
$ ng g s services/queries/users/user-password-change
$ ng g s services/auth/users/cipher
$ ng g s services/auth/users/hash
$ ng g s services/auth/users/nonce
# $ ng g s services/queries/users/user-signup
```

###### frontend/src/app/spec/users/user-trait-generator.ts

```ts

```

###### frontend/src/app/services/queries/users/user-create.service.spec.ts

```ts

```

###### frontend/src/app/services/queries/users/user-create.service.ts

```ts

```

###### frontend/src/app/services/auth/users/cipher.service.spec.ts

###### frontend/src/app/services/auth/users/cipher.service.ts

```ts
...

...
export class CipherService {
}

```

###### frontend/src/app/services/auth/users/hash.service.spec.ts

###### frontend/src/app/services/auth/users/hash.service.ts

```ts
...

...
export class HashService {
}

```

###### frontend/src/app/services/auth/users/nonce.service.spec.ts

###### frontend/src/app/services/auth/users/nonce.service.ts

```ts
...

...
export class NonceService {
}

```

###### frontend/src/app/services/queries/users/user-password-change.service.spec.ts

```ts

```

###### frontend/src/app/services/queries/users/user-password-change.service.ts

```ts

```

<!-- ###### frontend/src/app/services/queries/users/user-signup.service.spec.ts

```ts

```

###### frontend/src/app/services/queries/users/user-signup.service.ts

```ts

``` -->

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

