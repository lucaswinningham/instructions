```bash
$ cd frontend/
```

```bash
$ ng g s services/models/heartbeat
```

###### frontend/src/app/services/models/heartbeat.service.ts

```ts
...
import { Observable } from 'rxjs';

import { ApiService } from '@services/utils/api.service';

...
export class HeartbeatService {

  constructor(private api: ApiService) { }

  read(): Observable<any> {
    const route = 'heartbeat';
    return this.api.read({ route });
  }
}

```

###### frontend/src/app/app.component.ts

```ts
import { Component, OnInit } from '@angular/core';

import { LogService } from '@services/utils/log.service';
import { HeartbeatService } from '@services/models/heartbeat.service';

...
export class AppComponent implements OnInit {
  constructor(private logger: LogService, private heartbeatApi: HeartbeatService) { }

  ngOnInit() {
    this.logger.log('app started');
    this.heartbeatApi.read().subscribe(_ => this.logger.log('heartbeat ok'));
  }
}

```

```bash
$ cd backend/
$ rails s
```

In another terminal:

```bash
$ ng serve # ^C to stop
```

[Navigate to app](http://localhost:4200/)

