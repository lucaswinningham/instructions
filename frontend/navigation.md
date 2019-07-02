```bash
$ ng g m navigation --module=app
```

###### frontend/src/app/shared/navigation/navigation.module.ts

```ts
...
import { AppRoutingModule } from '@app/app-routing.module';

import { NgbModule } from '@ng-bootstrap/ng-bootstrap';

@NgModule({
  ...,
  imports: [
    ...,
    AppRoutingModule,
    NgbModule
  ],
  ...
})
...

```

```bash
$ ng g c navigation --module=navigation --export
$ ng g c navigation/hamburger --module=navigation
$ ng g c navigation/logo --module=navigation
$ ng g c navigation/signin --module=navigation
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

###### frontend/src/app/app.component.ts

```ts
...
export class AppComponent { }

```

###### frontend/src/app/navigation/navigation.html

```xml
<div class="container-fluid">
  <div class="d-flex my-3 justify-content-between align-items-center">
    <app-hamburger></app-hamburger>
    <app-logo></app-logo>
    <app-signin></app-signin>
  </div>
</div>
  
```

```bash
$ ng g m components --module=app
```

###### frontend/src/app/navigation/navigation.module.ts

```ts
...

import { ComponentsModule } from '@app/components/components.module';

@NgModule({
  ...,
  imports: [
    ...,
    ComponentsModule
  ],
  ...
})
export class NavigationModule { }

```

```bash
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

```

###### frontend/src/app/navigation/hamburger/hamburger.component.ts

```ts
...

import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

...
export class HamburgerComponent implements OnInit {

  constructor(private modalService: NgbModal) { }

  ...

  open(content): void {
    this.modalService.open(content);
  }

  close(modal): void {
    modal.close();
  }
}

```

###### frontend/src/app/navigation/hamburger/hamburger.component.html

```xml
<div class="wrapper">
  <a href="#" (click)="open(menu)">
    <span class="d-block my-1"></span>
    <span class="d-block my-1"></span>
    <span class="d-block my-1"></span>
  </a>
</div>

<ng-template #menu let-modal>
  <app-modal (close)="close(modal)">
    <div class="modal-title">
      My Title
    </div>

    <div class="modal-body">
      <a routerLink="/">
        Some Link
      </a>
    </div>
  </app-modal>
</ng-template>

```

###### frontend/src/app/navigation/hamburger/hamburger.component.scss

```scss
@import '~assets/styles/colors';

.wrapper {
  span {
    height: 3px;
    width: 30px;
    background: $black;
  }
}

```

```bash
$ ng g c components/icon --module=components --export
```

###### frontend/src/app/components/components.module.ts

```ts
...
import { CommonModule } from '@angular/common';

import { FontAwesomeModule } from '@fortawesome/angular-fontawesome';

import { ModalComponent } from './modal/modal.component';
...

@NgModule({
  ...,
  imports: [
    ...,
    FontAwesomeModule
  ]
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

###### frontend/src/app/navigation/logo/logo.component.html

```xml
<a routerLink="/">
  <app-icon class="logo-icon" [iconName]="'faReddit'" [size]="2"></app-icon>
</a>

```

###### frontend/src/app/navigation/logo/logo.component.scss

```scss
@import '~assets/styles/colors';

.logo-icon {
  color: $orange;
}

```

###### frontend/src/app/navigation/signin/signin.component.html

```xml
<button type="button" class="btn btn-primary px-4">
  <app-icon class="signin-icon" [iconName]="'faUserCircle'"></app-icon>
</button>

```

###### frontend/src/app/navigation/signin/signin.component.scss

```scss
@import '~assets/styles/colors';

.signin-icon {
  color: $white;
}

```

```bash
$ ng serve # ^C to stop
```

