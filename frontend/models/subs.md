```bash
$ ng g class models/sub --type=model
```

###### frontend/src/app/models/sub.model.ts

```ts
import { Base } from '@models/base.model';

export class Sub extends Base {
  readonly name: string;

  protected afterConstruction(): void {
    const { name } = this.params;
    Object.assign(this, { name });
  }

  protected localSerialize(): any {
    const { name } = this;
    return { name };
  }
}

```

```bash
$ ng g s services/models/sub
```

###### frontend/src/app/services/sub.service.ts

```ts
...
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { ApiService } from '../utils/api.service';

import { Sub } from '@models/sub.model';

...
export class SubService {

  constructor(private api: ApiService) { }

  read(name: string): Observable<Sub> {
    return this.api.read('subs', name).pipe(
      map(sub => new Sub(sub))
    );
  }
}

```

```bash
$ cd ../backend/
```

###### backend/db/seeds.rb

```ruby
subs = 4.times.map { FactoryBot.create :sub }
all = FactoryBot.create :sub, name: 'all'

posts = 16.times { FactoryBot.create :post, sub_id: subs.sample.id }
redditpost = FactoryBot.create :post, sub_id: all.id, title: 'reddit title', url: 'https://reddit.com', body: 'reddit body'

```

```bash
$ rails db:drop db:create db:migrate db:seed
$ cd ../frontend/
```

###### frontend/src/app/models/post.model.ts

```ts
import { Base } from '@models/base.model';

export class Post extends Base {
  readonly subName: string;
  ...

  protected afterConstruction(): void {
    const { subName, ... } = this.params;
    Object.assign(this, { subName, ... });
  }

  protected localSerialize(): any {
    const { subName, ... } = this;
    return { subName, ... };
  }
}

```

###### frontend/src/app/pages/front/post-preview/post-preview.component.html

```xml
<div class="row" ...>
  <div class="col-12 ...">
    <div class="small mb-2">
      <span [routerLink]="['/r', post.subName]" class="font-weight-bold" appStopPropagation>
        r/{{ post.subName }}
      </span>
    </div>

    ...
  </div>
</div>

```

###### frontend/src/app/pages/post/post.component.html

```xml
<section ...>
  <div class="container">
    <div class="row" ...>
      <div class="col-12 ...">
        <div class="small mb-2">
          <span [routerLink]="['/r', post.subName]" class="font-weight-bold" appStopPropagation>
            r/{{ post.subName }}
          </span>
        </div>

        ...
      </div>
    </div>

    ...
  </div>
</section>

```

###### frontend/src/app/pages/post/post.component.scss

```scss
.pointer:hover {
  cursor: pointer;
}

```

###### frontend/src/app/pages/front/front.component.ts

```ts
...
import { ActivatedRoute, ParamMap } from '@angular/router';
import { switchMap } from 'rxjs/operators';

import { SubService } from '@services/models/sub.service';

import { Sub } from '@models/sub.model';

...
export class SubComponent implements OnInit {
  sub: Sub;

  constructor(private subService: SubService, private route: ActivatedRoute) { }

  ngOnInit() {
    this.route.paramMap.pipe(
      switchMap((params: ParamMap) => this.subService.read(params.get('name')))
    ).subscribe(sub => this.sub = sub);
  }

}

```

###### frontend/src/app/pages/front/front.component.html

```xml
<section *ngIf="sub">
  <app-post-list [subName]="sub.name"></app-post-list>
</section>

```

###### frontend/src/app/pages/front/post-list/post-list.component.ts

```ts
...
export class PostListComponent implements OnInit {
  @Input() private subName: string;
  ...

  ngOnInit() {
    const { subName } = this;
    this.posts = this.postService.list({ subName });
  }

}

```

<!-- do backend stuff to filter by sub name unless its 'all' -->






















```bash
$ ng g m shared/components --module=shared
```

We can even further have a separation of concerns specifically for resources.
There will be other shared components later such as a navbar.

```bash
$ ng g m shared/components/resources --module=shared/components
```

Now when we create a shared CRUD resource component, it will be properly imported separate from other shared services and components.
Let's go ahead and make a sub component.

```bash
$ ng g c shared/components/resources/sub --module=shared/components/resources --export
```

Finally we're about to see something on the screen.
Let's code our sub component.
It'll take an input that is the sub to display and display it.
Don't worry about styling for now, we'll tackle that later.

###### frontend/src/app/shared/components/resources/sub/sub.component.ts

```ts
import { Component, Input } from '@angular/core';

import { Sub } from '@models/sub.model';

...
export class SubComponent {
  @Input() sub: Sub;
}

```

And then we need to display it.
We need to name sure that the input sub is loaded before we can access properties on it.
For that, there is the elvis operator.

###### frontend/src/app/shared/components/resources/sub/sub.component.html

```ts
{{ sub?.name }}

```

Let's see this component in action.
Make the home component display a single sub.
Well need to import the sub service and the sub model to query the backend on initialization and save it such that we can display it in the home component markup.

###### frontend/src/app/pages/home/home.component.ts

```ts
import { Component, OnInit } from '@angular/core';

import { SubService } from '@services/models/sub.service';
import { Sub } from '@models/sub.model';

@Component({
  selector: 'home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
  sub: Sub;

  constructor(private subService: SubService) { }

  ngOnInit() {
    this.subService.read('redditsub').subscribe(sub => this.sub = sub)
  }
}

```

###### frontend/src/app/pages/home/home.component.html

```html
<sub [sub]="sub"></sub>

```

But the sub component isn't available yet.
We'll need to import the resources module into the home module in order for the sub component to be available.

###### frontend/src/app/pages/home/home.module.ts

```ts
import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { HomeRoutingModule } from './home-routing.module';
import { HomeComponent } from './home.component';

import { ResourcesModule } from '@resources/resources.module';

@NgModule({
  imports: [
    CommonModule,
    HomeRoutingModule,
    ResourcesModule
  ],
  declarations: [HomeComponent],
  exports: [HomeComponent]
})
export class HomeModule { }

```

In order for the relative path `@resources` to be available for use, we have to add it to the config file

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
      ...,
      "@resources/*": [ "app/shared/components/resources/*" ]
    }
  }
}

```

Now we should be able to see a sub name in the home component in the browser.

<!-- make @pages, show the app-routing.module.ts -->

