rename backend repo to `api` and the frontend repo to `client`
  also change the instructions
get rid of setup for individual instructions and place respective setup first in corresponding files?
version namespace api v1.0
graph api - apprehensive about this, not the rails way / actual benefits?
  would no doubt change curl instructions
  would no doubt change api service and all other services

controller before actions without erroring see activations controller

make cipher key and iv user specific
  this way, the sensitive key and iv aren't stored in the frontend
  more secure?
  rotate cipher key and iv per user exactly like nonce
  requires additional call for login and activation

add uniqueness on user email

no components module, instead import AppIcons, AppHover etc.
frontend testing
change model service suffix from `.service.ts` to `.api.ts`
rename transform service to json api service or the like
relocate client services specific to user under a directory `app/services/user/*`
relocate api services to a directory `app/services/api`
error messages on forms

abstract `#make_session` from `ActivationsService` and `SessionsService`
[add logging interceptor](https://angular.io/guide/http#logging)
auto unsubcribe can predefine a subscriptions property, then just use +add
  maybe call it Subscriber instead of AutoUnsubscribe
