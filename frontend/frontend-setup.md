```bash
$ cd reddit
$ ng new frontend --style=scss --routing=true
$ cd frontend/
$ ng serve # ^C to stop
```

[Navigate to frontend](http://localhost:4200/)

## Style Setup

```bash
$ npm install bootstrap@latest --save
$ npm install \
  @fortawesome/fontawesome-svg-core@latest \
  @fortawesome/free-solid-svg-icons@latest \
  @fortawesome/free-brands-svg-icons@latest \
  @fortawesome/angular-fontawesome@latest \
  --save
$ mkdir src/assets/styles
$ touch src/assets/styles/{buttons,colors,fonts}.scss
```

###### frontend/src/assets/styles/buttons.scss

```scss
button, .btn {
  &:hover {
    cursor: pointer;
  }

  &:hover, &:focus, &:active, &:active:focus {
    box-shadow: none !important;
    outline: none !important;
  }
}

.btn {
  text-transform: uppercase;
  letter-spacing: 0.05em;
  line-height: 1;
  font-weight: bold;
  padding: 1rem 2rem;
}

.btn-round {
  border-radius: 2em;
}

```

###### frontend/src/assets/styles/colors.scss

```scss
$primary: #4484CE;
$secondary: #D9D9D9;
$success: #14D24D;
$info: #75B5FF;
$warning: #F9CF00;
$danger: #FF291D;
$light: #F8F9FA;
$dark: #343A40;

$maroon: #800000;
$dark-red: #8B0000;
$brown: #A52A2A;
$firebrick: #B22222;
$crimson: #DC143C;
$red: #FF0000;
$tomato: #FF6347;
$coral: #FF7F50;
$indian-red: #CD5C5C;
$light-coral: #F08080;
$dark-salmon: #E9967A;
$salmon: #FA8072;
$light-salmon: #FFA07A;
$orange-red: #FF4500;
$dark-orange: #FF8C00;
$orange: #FFA500;
$gold: #FFD700;
$dark-golden-rod: #B8860B;
$golden-rod: #DAA520;
$pale-golden-rod: #EEE8AA;
$dark-khaki: #BDB76B;
$khaki: #F0E68C;
$olive: #808000;
$yellow: #FFFF00;
$yellow-green: #9ACD32;
$dark-olive-green: #556B2F;
$olive-drab: #6B8E23;
$lawn-green: #7CFC00;
$chart-reuse: #7FFF00;
$green-yellow: #ADFF2F;
$dark-green: #006400;
$green: #008000;
$forest-green: #228B22;
$lime: #00FF00;
$lime-green: #32CD32;
$light-green: #90EE90;
$pale-green: #98FB98;
$dark-sea-green: #8FBC8F;
$medium-spring-green: #00FA9A;
$spring-green: #00FF7F;
$sea-green: #2E8B57;
$medium-aqua-marine: #66CDAA;
$medium-sea-green: #3CB371;
$light-sea-green: #20B2AA;
$dark-slate-gray: #2F4F4F;
$teal: #008080;
$dark-cyan: #008B8B;
$aqua: #00FFFF;
$cyan: #00FFFF;
$light-cyan: #E0FFFF;
$dark-turquoise: #00CED1;
$turquoise: #40E0D0;
$medium-turquoise: #48D1CC;
$pale-turquoise: #AFEEEE;
$aqua-marine: #7FFFD4;
$powder-blue: #B0E0E6;
$cadet-blue: #5F9EA0;
$steel-blue: #4682B4;
$corn-flower-blue: #6495ED;
$deep-sky-blue: #00BFFF;
$dodger-blue: #1E90FF;
$light-blue: #ADD8E6;
$sky-blue: #87CEEB;
$light-sky-blue: #87CEFA;
$midnight-blue: #191970;
$navy: #000080;
$dark-blue: #00008B;
$medium-blue: #0000CD;
$blue: #0000FF;
$royal-blue: #4169E1;
$blue-violet: #8A2BE2;
$indigo: #4B0082;
$dark-slate-blue: #483D8B;
$slate-blue: #6A5ACD;
$medium-slate-blue: #7B68EE;
$medium-purple: #9370DB;
$dark-magenta: #8B008B;
$dark-violet: #9400D3;
$dark-orchid: #9932CC;
$medium-orchid: #BA55D3;
$purple: #800080;
$thistle: #D8BFD8;
$plum: #DDA0DD;
$violet: #EE82EE;
$magenta: #FF00FF;
$fuchsia: #FF00FF;
$orchid: #DA70D6;
$medium-violet-red: #C71585;
$pale-violet-red: #DB7093;
$deep-pink: #FF1493;
$hot-pink: #FF69B4;
$light-pink: #FFB6C1;
$pink: #FFC0CB;
$antique-white: #FAEBD7;
$beige: #F5F5DC;
$bisque: #FFE4C4;
$blanched-almond: #FFEBCD;
$wheat: #F5DEB3;
$corn-silk: #FFF8DC;
$lemon-chiffon: #FFFACD;
$light-golden-rod-yellow: #FAFAD2;
$light-yellow: #FFFFE0;
$saddle-brown: #8B4513;
$sienna: #A0522D;
$chocolate: #D2691E;
$peru: #CD853F;
$sandy-brown: #F4A460;
$burly-wood: #DEB887;
$tan: #D2B48C;
$rosy-brown: #BC8F8F;
$moccasin: #FFE4B5;
$navajo-white: #FFDEAD;
$peach-puff: #FFDAB9;
$misty-rose: #FFE4E1;
$lavender-blush: #FFF0F5;
$linen: #FAF0E6;
$old-lace: #FDF5E6;
$papaya-whip: #FFEFD5;
$sea-shell: #FFF5EE;
$mint-cream: #F5FFFA;
$slate-gray: #708090;
$light-slate-gray: #778899;
$light-steel-blue: #B0C4DE;
$lavender: #E6E6FA;
$floral-white: #FFFAF0;
$alice-blue: #F0F8FF;
$ghost-white: #F8F8FF;
$honeydew: #F0FFF0;
$ivory: #FFFFF0;
$azure: #F0FFFF;
$snow: #FFFAFA;
$black: #000000;
$dim-gray: #696969;
$gray: #808080;
$dark-gray: #A9A9A9;
$silver: #C0C0C0;
$light-gray: #D3D3D3;
$gainsboro: #DCDCDC;
$white-smoke: #F5F5F5;
$white: #FFFFFF;

```

###### frontend/src/assets/styles/fonts.scss

```scss
@import url('https://fonts.googleapis.com/css?family=Roboto:400,700');
@import '~assets/styles/colors';

body {
  font-family: 'Roboto', sans-serif;
  color: $black;
}

```

###### frontend/src/styles.scss

```scss
@import "../node_modules/bootstrap/scss/bootstrap";

@import '~assets/styles/buttons';
@import '~assets/styles/colors';
@import '~assets/styles/fonts';

```

## Api Setup

```bash
$ ng add apollo-angular
```

<!-- add logging interceptor, https://angular.io/guide/http#logging -->

###### frontend/src/environments/environment.ts

```ts
export const environment = {
  ...,
  apiUrl: 'http://localhost:3000/graphql'
};

```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    "baseUrl": "src",
    ...,

    "paths": {
      "@env/*": [ "environments/*" ],
      "@app/*": [ "app/*" ]
    }
  }
}

```

###### frontend/src/app/graphql.module.ts

```ts
...

import { environment } from '@env/environment';
const { apiUrl } = environment;
const uri = apiUrl; // <-- add the URL of the GraphQL server here
...

```

```bash
$ npm install \
  apollo-angular \
  apollo-angular-link-http \
  apollo-link \
  apollo-client \
  apollo-cache-inmemory \
  graphql-tag \
  graphql \
  --save
```

###### frontend/src/app/graphql.module.ts

```ts
...

import { ApolloModule, APOLLO_OPTIONS } from 'apollo-angular';
import { HttpLinkModule, HttpLink } from 'apollo-angular-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';

import { environment } from '@env/environment';
const { apiUrl } = environment;

@NgModule({
  ...,
  providers: [{
    provide: APOLLO_OPTIONS,
    useFactory: (httpLink: HttpLink) => {
      return {
        cache: new InMemoryCache(),
        link: httpLink.create({
          uri: apiUrl
        })
      }
    },
    deps: [HttpLink]
  }],
  ...
})
export class AppModule { }

```

###### frontend/src/app/app.module.ts

```ts
...

import { ApolloModule, APOLLO_OPTIONS } from 'apollo-angular';
import { HttpLinkModule, HttpLink } from 'apollo-angular-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';

import { environment } from '@env/environment';
const { apiUrl } = environment;

...

@NgModule({
  ...,
  providers: [{
    ...
    useFactory: ... => {
      return {
        ...,
        link: httpLink.create({
          uri: apiUrl
        })
      };
    },
    ...
  }],
  ....
})
export class AppModule { }

...
```

```bash
$ ng g s services/utils/api/data-transform
$ ng g s services/utils/api
```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "paths": {
      ...,
      "@services/*": [ "app/services/*" ]
    }
  }
}

```

###### frontend/src/app/services/utils/api.service.spec.ts

```ts

```

###### frontend/src/app/services/utils/api.service.ts

```ts
...
import { Apollo } from 'apollo-angular';
import gql from 'graphql-tag';

...
export class ApiService {
}

```

## Model Setup

<!-- ```bash
$ ng g class models/base --type=model
```

###### frontend/src/app/models/base.model.ts

```ts

``` -->

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "paths": {
      ...,
      "@models/*": [ "app/models/*" ]
    }
  }
}

```

## Component Setup

```bash
$ ng g m pages --module=app
```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "baseUrl": "src",
    "paths": {
      ...,
      "@pages/*": [ "app/pages/*" ]
    }
  }
}

```

###### frontend/src/app/app.component.html

```html
<h1>SPRINGBOARD</h1>

<router-outlet></router-outlet>

```

###### frontend/src/app/app.component.spec.ts

```ts
...

describe('AppComponent', () => {
  ...

  it('should render title in a h1 tag', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    const compiled = fixture.debugElement.nativeElement;
    expect(compiled.querySelector('h1').textContent).toContain('SPRINGBOARD');
  });
});

```














## View Setup

```bash
$ npm install moment ngx-moment --save
```

```bash
# $ ng g m directives --module=app
# $ ng g d directives/stop-propagation --module=directives --export
$ ng g d directives/hover-pointer --module=directives --export
```

<!-- ###### frontend/src/app/directives/stop-propagation.directive.ts

```ts
import { Directive, HostListener } from '@angular/core';

...
export class StopPropagationDirective {
  @HostListener('click', ['$event']) onClick(event: any): void {
    event.stopPropagation();
  }
}

``` -->

###### frontend/src/app/directives/hover-pointer.directive.ts

```ts
import { Directive, ElementRef } from '@angular/core';

...
export class HoverPointerDirective {

  constructor(el: ElementRef) {
    el.nativeElement.style.cursor = 'pointer';
  }

}

```

## Models Setup

```bash
$ ng g class models/base --type=model
```

###### frontend/src/app/models/base.model.ts

```ts
import * as _ from 'lodash';

export abstract class Base {
  readonly params: any;
  readonly id: number;
  readonly type: string;
  readonly createdAt: string;
  readonly updatedAt: string;

  constructor(params: any = {}) {
    this.params = params;
    const { id, type, createdAt, updatedAt } = this.params;
    Object.assign(this, { id, type, createdAt, updatedAt });
    this.afterConstruction();
  }

  protected afterConstruction(): void { }

  serialize(): any {
    const { id, type, createdAt, updatedAt } = this;
    return Object.assign({ id, type, createdAt, updatedAt }, this.localSerialize());
  }

  protected localSerialize(): any {
    return {};
  }
}

```

```bash
$ ng g s services/utils/log
```

###### frontend/src/app/services/utils/log.service.ts

```ts
...
import { Observable, throwError } from 'rxjs';

import { environment } from '@env/environment';

...
export class LogService {
  catchError(): (error: any) => Observable<any> {
    return (error: any): Observable<any> => {
      console.log({ error })
      return throwError(error);
    };
  }

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

```bash
$ ng g s services/utils/transform
$ ng g s services/utils/api
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

    const data = json.data || json;

    if (_.isArray(data)) {
      return data.map(resource => this.deserialize(resource));
    }

    const { id, type } = data;
    const attributes = this.deserializeAttributes(data.attributes);
    const relationships = this.deserializeRelationships(data.relationships);

    return { id, type, ...attributes, ...relationships };
  }

  private deserializeAttributes(attributes: any): any {
    const deserializedAttributes = _.mapValues(attributes, value => {
      if (value && _.isPlainObject(value)) {
        return this.deserialize(value);
      } else {
        return value;
      }
    });
    return this.camelCaseKeys(deserializedAttributes);
  }

  private deserializeRelationships(relationships: any): any {
    const deserializedRelationships = _.mapValues(relationships, value => this.deserialize(value));
    return this.camelCaseKeys(deserializedRelationships);
  }

  private camelCaseKeys(obj: any) {
    return _.mapKeys(obj, (__: any, key: string) => _.camelCase(key));
  }
}

```

<!-- fix -process to use (endpoint, params) instead of (endpoint, { params }) -->
<!-- did that but need to revisit, get and delete methods don't have body for HttpClient -->
<!-- think about the body argument to httpclient, does it make sense for all methods? -->

###### frontend/src/app/services/utils/api.service.ts

```ts
...
import { HttpClient } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import * as _ from 'lodash';

import { environment } from '@env/environment';
import { TransformService } from '@services/utils/transform.service';

const { apiUrl } = environment;

...
export class ApiService {
  constructor(private http: HttpClient, private transformer: TransformService) { }

  list(args: { route: string, params?: any }): Observable<any> {
    const route = args.route;
    const params = args.params || {};
    const url = `${apiUrl}/${route}`;
    return this.process(this.http.get(url, { params }));
  }

  read(args: { route: string, param?: string | number, params?: any }): Observable<any> {
    const route = args.route;
    const param = args.param || '';
    const params = args.params || {};
    const url = `${apiUrl}/${route}/${param}`;
    return this.process(this.http.get(url, { params }));
  }

  private process(observable: Observable<any>): Observable<any> {
    return observable.pipe(
      catchError(this.catchError()),
      map(json => this.transformer.deserialize(json))
    );
  }

  private catchError(): (error: any) => Observable<any> {
    return (error: any): Observable<any> => {
      error.error = this.camelizeKeys(error.error);
      return throwError(error);
    };
  }

  private camelizeKeys(obj: any): any {
    return _.mapKeys(obj, (__: any, key: string) => _.camelCase(key));
  }

  private snakeifyKeys(obj: any): any {
    return _.mapKeys(obj, (__: any, key: string) => _.snakeCase(key));
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
  ....
})
export class AppModule { }

...
```

<!-- ###### frontend/src/app/app.component.html

```xml
<section>
  <div class="container">
    <div class="row">
      <div class="col-12">
        <app-post-list></app-post-list>
      </div>
    </div>
  </div>
</section>

``` -->

```bash
$ ng g m pages --module=app
```

###### frontend/tsconfig.json

```json
{
  ...,
  "compilerOptions": {
    ...,

    "baseUrl": "src",
    "paths": {
      ...,
      "@directives/*": [ "app/directives/*" ],
      "@models/*": [ "app/models/*" ],
      "@pages/*": [ "app/pages/*" ],
      "@services/*": [ "app/services/*" ]
    }
  }
}

```

