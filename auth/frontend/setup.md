<!-- TODO: step by step all this, clean up too, don't make so monumental services -->
<!-- try to mirror backend services for a one-to-one interaction between backend and frontend -->

###### src/app/shared/services/api.service.ts

```ts
import { Injectable } from '@angular/core';
import { HttpHeaders, HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Rx';
import { catchError, map, tap } from 'rxjs/operators';

import * as _ from 'lodash';

import { environment } from '../../../environments/environment';
import { LoggerService } from '@services/logger.service';

@Injectable()
export class ApiService {
  private apiUrl: string = environment.apiUrl;
  private localStorageTokenName: string = 'token';
  private currentUserAuthToken: string;

  constructor(private http: HttpClient, private loggerService: LoggerService) { }

  create<T>(route: string, body: T | {} = {}): Observable<T> {
    const endpoint = `${this.apiUrl}/${route}`;
    const observable = this.http.post<T>(endpoint, body, { headers: this.headers });
    return this.process(observable, 'POST', `/${route}`);
  }

  list<T>(route: string, params: any = {}): Observable<T> {
    const endpoint = `${this.apiUrl}/${route}`;
    const observable = this.http.get<T>(endpoint, { params, headers: this.headers });
    return this.process(observable, 'GET', `/${route}`, { resultOnError: [] });
  }

  read<T>(route: string, param: string | number = ''): Observable<T> {
    const endpoint = `${this.apiUrl}/${route}/${param}`;
    const observable = this.http.get<T>(endpoint, { headers: this.headers });
    return this.process(observable, 'GET', `/${route}/${param}`);
  }

  // update<T>(route: string, param: string, body: T): Observable<T> {
  //   const endpoint = `${this.apiUrl}/${route}/${param}`;
  //   return this.http.put<T>(endpoint, body).;
  // }

  destroy<T>(route: string, param: string): Observable<T> {
    const endpoint = `${this.apiUrl}/${route}/${param}`;
    const observable = this.http.delete<T>(endpoint, { headers: this.headers });
    return this.process(observable, 'DELETE', `/${route}/${param}`);
  }

  get authToken(): string {
    this.currentUserAuthToken = localStorage.getItem(this.localStorageTokenName);
    return this.currentUserAuthToken;
  }

  set authToken(token_string: string) {
    this.currentUserAuthToken = token_string;
    localStorage.setItem(this.localStorageTokenName, this.currentUserAuthToken);
  }

  private process<T>(observable: Observable<T>, method: string, route: string, { resultOnError } = { resultOnError: { } }): Observable<T> {
    return observable.pipe(
      catchError(this.catchError(`ApiService: -process(): [${method}] "${route}"`)),
      tap(json => this.loggerService.log(`ApiService: -process(): [${method}] "${route}" raw json response: `, json)),
      map(json => this.deserialize(json)),
      tap(json => this.loggerService.log(`ApiService: -process(): [${method}] "${route}" deserialized json: `, json))
    );
  }

  private catchError<T>(...messages: any[]): (error: any) => Observable<T> {
    return (error: any): Observable<T> => {
      this.loggerService.error(...messages, error);
      return Observable.throw(error);
    };
  }

  private deserialize<T>(json: T) {
    if (!json) {
      return {};
    }

    const data = json['data'] || json;

    if (_.isArray(data)) {
      return data.map(resource => this.deserialize(resource));
    }

    const { id, type, attributes } = data;

    let { relationships } = data;
    relationships = _.mapValues(relationships, value => this.deserialize(value));

    return { id, type, ...attributes, ...relationships };
  }

  private get headers(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': `Bearer ${this.authToken}`
      // 'Access-Control-Allow-Origin': environment.cdnUrl
    });
  }
}

```

###### src/app/shared/services/auth.service.ts

```ts
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs/Rx';
import { map, mergeMap, tap } from 'rxjs/operators';

import { ApiService } from '@services/api.service';
import { HashService } from '@services/hash.service';
import { LoggerService } from '@services/logger.service';

import { Salt } from '@models/salt.model';
import { Nonce } from '@models/nonce.model';
import { User } from '@models/user.model';
import { Session } from '@models/session.model';
import { JsonWebToken } from '@models/json-web-token.model';

@Injectable()
export class AuthService {

  constructor(private apiService: ApiService, private hashService: HashService, private loggerService: LoggerService) { }

  isAuthenticated(): boolean {
    const token = this.apiService.authToken;
    const jwt: JsonWebToken = new JsonWebToken(token);
    return jwt.isValidExp && jwt.isValidNbf;
  }

  signup(credentials: { name: string; email: string; password: string }): Observable<Session> {
    const { name, email, password } = credentials;
    return this.readSalt(name).pipe(
      mergeMap((userSalt: Salt) => {
        const key = this.hashService.irreversiblySalt(password, userSalt.toString());
        const token = this.buildSignupToken({ key });
        return this.createUser({ user: new User({ name, email }), token });
      }),
      tap(
        success => this.loggerService.log('AuthService: +signup() successful'),
        error => this.loggerService.error('AuthService: +signup(): ', error)
      )
    );
  }

  login(credentials: { name: string; password: string }): Observable<Session> {
    const { name, password } = credentials;
    return this.readSalt(name).pipe(
      mergeMap((userSalt: Salt) => {
        const key = this.hashService.irreversiblySalt(password, userSalt.toString());
        return this.createNonce(name).pipe(
          mergeMap((serverNonce: Nonce) => {
            const token = this.buildLoginToken({ nonce: serverNonce.toString(), cnonce: this.hashService.randomHash(), key });
            return this.createSession(new Session({ userName: name, token }));
          })
        );
      }),
      tap(
        success => this.loggerService.log('AuthService: +login() successful'),
        error => this.loggerService.error('AuthService: +login(): ', error)
      )
    );
  }

  private readSalt(userName: string): Observable<Salt> {
    return this.apiService.read<Salt>(`users/${userName}/salt`).pipe(
      map(saltResponse => new Salt(saltResponse)),
      tap(
        (salt: Salt) => this.loggerService.log('AuthService: -readSalt(): salt ', salt),
        error => this.loggerService.error('AuthService: -readSalt(): ', error)
      )
    )
  }

  private createNonce(userName: string): Observable<Nonce> {
    return this.apiService.create<Nonce>(`users/${userName}/nonce`).pipe(
      map(nonceResponse => new Nonce(nonceResponse)),
      tap(
        (nonce: Nonce) => this.loggerService.log('AuthService: -createNonce(): nonce ', nonce),
        error => this.loggerService.error('AuthService: -createNonce(): ', error)
      )
    );
  }

  private buildSignupToken(args: { key: string }): string {
    const { key } = args;
    const payload = { sub: key };
    return JsonWebToken.toToken(payload);
  }

  private createUser(args: { user: User, token: string }): Observable<Session> {
    const { user, token } = args;
    const { name, email } = user;
    return this.apiService.create<Session>('users', { user: { name, email, token } }).pipe(
      map(sessionResponse => new Session(sessionResponse)),
      tap(
        (session: Session) => {
          this.loggerService.log('AuthService: -createUser(): session ', session);
          this.apiService.authToken = session.token;
        },
        error => this.loggerService.error('AuthService: -createUser(): ', error)
      )
    );
  }

  private buildLoginToken(args: { nonce: string, cnonce: string, key: string }): string {
    const { nonce, cnonce, key } = args;
    const hash: string = this.hashService.digest(`${nonce}.${cnonce}.${key}`);
    const payload = { key, cnonce, hash };
    return JsonWebToken.toToken(payload);
  }

  private createSession(session: Session): Observable<Session> {
    return this.apiService.create<Session>('sessions', { session: session.asJson() }).pipe(
      map(sessionResponse => new Session(sessionResponse)),
      tap(
        (session: Session) => {
          this.loggerService.log('AuthService: -createSession(): session ', session);
          this.apiService.authToken = session.token;
        },
        error => this.loggerService.error('AuthService: -createSession(): ', error)
      )
    );
  }
}

```

###### src/app/shared/services/user.service.ts

```ts
import { Injectable } from '@angular/core';
import { Observable, Subject, Subscription } from 'rxjs/Rx';
import { map, tap } from 'rxjs/operators';

import { ApiService } from '@services/api.service';
import { AuthService } from '@services/auth.service';
import { LoggerService } from '@services/logger.service';

import { Session } from '@models/session.model';
import { User } from '@models/user.model';

@Injectable()
export class UserService {
  currentUserUpdate: Subject<User> = new Subject<User>();

  private currentUser: User;

  constructor(private apiService: ApiService, private authService: AuthService, private loggerService: LoggerService) { }

  signup(credentials: { name: string; email: string; password: string }): Observable<Session> {
    const { name, email, password } = credentials;
    return this.authService.signup({ name, email, password }).pipe(
      tap(
        (session: Session) => {
          this.loggerService.log('UserService: +signup() successful');
          this.setCurrentUser(new User({ name: session.userName }));
        },
        error => this.loggerService.error('UserService: +signup(): ', error)
      )
    );
  }

  login(credentials: { name: string; password: string }): Observable<Session> {
    const { name, password } = credentials;
    return this.authService.login({ name, password }).pipe(
      tap(
        (session: Session) => {
          this.loggerService.log('UserService: +login() successful');
          this.setCurrentUser(new User({ name: session.userName }));
        },
        error => this.loggerService.error('UserService: +login(): ', error)
      )
    );
  }

  read(name: string): Observable<User> {
    return this.apiService.read<User>('users', name).pipe(
      map(userResponse => new User(userResponse)),
      tap(
        success => this.loggerService.log('UserService: +read() successful'),
        error => this.loggerService.error('UserService: +read(): ', error)
      )
    );
  }

  destroy(): Observable<User> {
    return this.apiService.destroy<User>('users', this.currentUser.name).pipe(
      tap(
        (user: User) => {
          this.loggerService.log('UserService: +destroy() successful ');
          this.setCurrentUser(null);
        },
        error => this.loggerService.error('UserService: +destroy(): ', error)
      )
    );
  }

  private setCurrentUser(user: User) {
    this.currentUser = user;
    this.currentUserUpdate.next(this.currentUser);
  }
}

```

###### src/app/shared/components/nav/nav.component.ts

```ts
import { Component, OnInit } from '@angular/core';

import { ApiService } from '@services/api.service';
import { LoggerService } from '@services/logger.service';
import { Sub } from '@models/sub.model';

import { UserService } from '@services/user.service';

import * as _ from 'lodash';

@Component({
  selector: 'app-nav',
  templateUrl: './nav.component.html',
  styleUrls: ['./nav.component.scss']
})
export class NavComponent implements OnInit {
  specialSubs: Sub[] = ['Popular', 'All', 'Random'].map(name => new Sub({ name }));
  popularSubs: Sub[] = [];

  constructor(private apiService: ApiService, private loggerService: LoggerService, private userService: UserService) {
      this.userService.signup({ name: 'user1', email: 'user1@email.com', password: 'secret_password' }).subscribe(__ => {
        this.userService.signup({ name: 'user2', email: 'user2@email.com', password: 'secret_password' }).subscribe(__ => {
          this.userService.login({ name: 'user1', password: 'secret_password' }).subscribe(__ => {
            this.userService.read('user2').subscribe(__ => {
              this.userService.destroy().subscribe(__ => {
                this.userService.login({ name: 'user2', password: 'secret_password' }).subscribe(__ => {
                  this.userService.destroy().subscribe();
                });
              });
            });
          });
        });
      });
  }

  ngOnInit() {
    this.loggerService.log('NavComponent: ngOnInit()');

    // this.getPopularSubs();
  }

  private getPopularSubs(): void {
    this.apiService.list<Sub[]>('subs').subscribe(subs => {
      const mappedSubs = subs.map(sub => new Sub(sub));
      this.popularSubs = _.sortBy(mappedSubs, 'followCount').reverse();
      this.loggerService.log('NavComponent: getPopularSubs(): popularSubs;', this.popularSubs);
    }, error => this.loggerService.error(error));
  }
}

```