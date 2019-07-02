###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    //
    // Added
    //

    "paths": {
      "@env/*": [ "environments*" ],
      ...,
      "@services/*": [ "app/services/*" ]
    }
  }
}

```

###### frontend/src/app/app.module.ts

```ts
...
import { HttpClientModule } from '@angular/common/http';


...

@NgModule({
  ...,
  imports: [
    ...,
    HttpClientModule
  ],
  ...
})

...
```

```bash
$ cd ../backend/
$ rails c
> User.create name: 'reddituser', email: 'reddituser@email.com'
> quit
$ rails s
```

In another terminal:

```bash
$ curl http://localhost:3000/users/reddituser | jq
...
{
  "data": {
    "id": "1",
    "type": "user",
    "attributes": {
      "name": "reddituser",
      "email": "reddituser@email.com"
    }
  }
}
```

```bash
$ cd frontend/
$ ng g s services/utils/log
```

###### frontend/src/app/services/utils/log.service.ts

```ts
...

import { environment } from '@env/environment';

...
export class LogService {
  error(...messages: any[]): void {
    this.toConsole('error', messages);
    this.toLogger('error', messages);
  }

  info(...messages: any[]): void {
    this.toConsole('info', messages);
  }

  log(...messages: any[]): void {
    this.toConsole('log', messages);
  }

  warn(...messages: any[]): void {
    this.toConsole('warn', messages);
    this.toLogger('warn', messages);
  }

  private toConsole(method: string, messages: any[]): void {
    if (!environment.production) {
      console[method](...messages);
    }
  }

  private toLogger(method: string, messages: any[]): void {
    if (environment.production) {
      // log to external logging service
    }
  }
}

```

###### frontend/src/app/app.component.ts

```ts
import { Component, OnInit } from '@angular/core';

import { LogService } from '@services/utils/log.service';

...
export class AppComponent implements OnInit {
  constructor(private logger: LogService) { }

  ngOnInit() {
    this.logger.log('app started');
  }
}

```

```bash
$ ng serve # ^C to stop
```

```bash
$ ng g s services/utils/transform
```

###### frontend/src/app/services/utils/transform.service.ts

```ts
...

import * as _ from 'lodash';

...
@Injectable()
export class TransformService {
  deserialize(json: any): any {
    if (!json) {
      return;
    }

    const data = json['data'] || json;

    if (_.isArray(data)) {
      return data.map(resource => this.deserialize(resource));
    }

    const { id, type, attributes } = data;
    const relationships = _.mapValues(data.relationships, value => this.deserialize(value));

    return { id, type, ...attributes, ...relationships };
  }
}

```

```bash
$ ng g s services/utils/api
```

###### frontend/src/environments/environment.ts

```ts
export const environment = {
  ...,
  apiUrl: 'http://localhost:3000'
};

```

###### frontend/src/app/services/utils/api.service.ts

```ts
...
import { HttpClient } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { environment } from '@env/environment';
import { LogService } from '@services/utils/log.service';
import { TransformService } from '@services/utils/transform.service';

import * as _ from 'lodash';

const { apiUrl } = environment;

...
export class ApiService {
  constructor(private http: HttpClient, private logger: LogService, private transformer: TransformService) { }

  read(route: string, param: string | number = '', params: any = {}): Observable<any> {
    const endpoint = `${apiUrl}/${route}/${param}`;
    params = this.snakeifyKeys(params);
    const observable = this.http.get(endpoint, { params });
    return this.process(observable).pipe(
      catchError(this.catchError(`GET ${endpoint}`))
    );
  }

  private snakeifyKeys(obj: any): any {
    return _.mapKeys(obj, (__: any, key: string) => _.snakeCase(key));
  }

  private process(observable: Observable<any>): Observable<any> {
    return observable.pipe(
      map(json => this.transformer.deserialize(json)),
    );
  }

  private catchError(message: string): (error: any) => Observable<any> {
    return (error: any): Observable<any> => {
      this.logger.error(`${message} error: ${error}`);
      return throwError(error);
    };
  }
}

```

```bash
$ cd ../backend/
```

###### backend/db/seeds.rb

```ruby
4.times { FactoryBot.create :user }
FactoryBot.create :user, name: 'reddituser', email: 'reddituser@example.com'

```

```bash
$ rails db:drop db:create db:migrate db:seed
$ rails c
> ap User.all
> quit
$ cd ../frontend/
```

###### frontend/src/app/app.component.ts

```ts
...

import { ApiService } from '@services/utils/api.service';
import { LogService } from '@services/utils/log.service';

...
export class AppComponent implements OnInit {
  constructor(private api: ApiService, private logger: LogService) { }

  ngOnInit() {
    ...
    this.api.read<any>('users', 'reddituser').subscribe(user => this.logger.log('user: ', user));
  }
}

```

```bash
$ ng serve # ^C to stop
```

