

<!-- all kinds of modifications to controller specs here for authentication -->
<!-- explanations of why these modifications need to happen -->
<!-- bash proof of these backend modifications -->

rails c
user = User.new name: 'reddituser', email: 'reddituser@email.com', password: 'secret_password'
user.save
user.authenticate 'secret_password'
user.destroy

user life cycle
  get user's salt
    client
      requests user's salt
    server
      responds with a generated new salt if the user does not exist
      otherwise responds with the user's salt
  post to users
    client
      requests user's salt
    server
      responds with the user's salt
    client
      uses the salt to hash the plain text password
      encrypts hashed password using mutual key and initialization vector
      sends user's name, email and encrypted hashed password
    server
      whitelists params of user's name, email and encrypted hashed password
      decrypts the encrypted hashed password getting the hashed password
      initializes a new user
      saves user salt associated with hashed password
      saves user
      creates and responds with a new user session giving auth jwt
  post to sessions
    client
      requests user's salt
    server
      responds with the user's salt
    client
      requests a new nonce associated with user
        verifies user exists
    server
      responds with a generated nonce associated to user
    client
      uses the salt to hash the plain text password
      encrypts a message consisting of "nonce||hashed_password" using mutual key and initialization vector
      requests a new session with user's name and encrypted message
    server
      whitelists params of user's name and encrypted  message
        verifies user exists
      retrieves nonce associated to user
      decrypts message getting nonce and client hashed password
        verifies nonce retrieved is the same as in message
        verifies nonce exists for user and is not expired
        authenticates user with client hash password
        destroys nonce associated with user
      creates and responds with a new user session giving auth jwt
  get user
    client
      requests user
    server
      responds with the user
  delete user
    client
      requests user to be deleted
    server
      authenticates user with auth jwt
      deletes user






<!-- explanation somewhere above all the frontend work, mostly mirroring these links -->
<!-- https://stackoverflow.com/questions/3391242/should-i-hash-the-password-before-sending-it-to-the-server-side -->
<!-- https://security.stackexchange.com/questions/3001/what-is-the-use-of-a-client-nonce -->

the reason the methodology is not strictly followed in the second link (stackexchange), is that the user's password could not be hashed before saving to the database for the purposes of login hash recalculation. simply for the fact that any password could be transmitted during sign up, it's imperative to hash the user's password before saving. the methodology in the first link is followed save the fact that it mistakenly mentions "serving a nonce to hash with the hashed password such that the nonce could be reversed on the server" which is supposed to read "serving a nonce to encrypt with the hashed password such that the encrypted message could be decrypted on the server to retrieve the hashed password". except this means that there are no calculations to check against. after revisiting the second link, it seems that it is getting at the fact that the server database is saving plain text passwords, at which point it's necessary to follow its methodology. this application nor any application i ever create will save passwords in plain text. for this reason, the second link seems irrelevant.

so im tinking what you do is on sign up, hash the password, then encrypt it with jwt just like it is now.
then decrypt the jwt to get the original hashed password,
but on log in, follow what the second link says which is to actually hash the combination not just encrypt it
then check on the other side the hashing of the nonce, cnonce, and hashed password

this differs from how it is now which is at both sign up and login,
  the nonce cnonce and hashed password are encrypted then decrypted then the password is then again hashed

which one is better?
  one only stores the original hashed password into the database
    if the database is compromised, an attacker would gain access as users
  the other hashes the hashed password again.
    if the database is compromised, an attacker couldn't gain access from a "plain text" hashed password
    but the hashed password is plain if the jwt is intercepted and the attacker could gain user's access that way

let p: plain text password
let h: hashing algorithm
let e: encryption algorithm
let e': decryption algorithm
let n: server provided nonce (challenge)
let c: client provided cnonce

in order of security

option 1:
client sends p
server saves p
database reveals all users' p
man in the middle reveals user's p
replay gives user's access

So don't save passwords in plain text

option 2:
client sends p
server saves h(p)
man in the middle reveals user's p
replay gives user's access

So don't send the user's password in plain text

option 2:
client sends h(p)
server saves h(h(p))
replay gives user's access

So supply a nonce that the server checks against and expires

option 3:
server sends n
client sends e(n || h(p))
server saves h(h(p)) for h(p) of e'(n || h(p))
man in the middle + supplied nonce + rainbow table gives user's access

So supply a client nonce

option 4:
server sends n
client sends c || e(n || c || h(p))
server saves h(h(p)) for h(p) of e'(n || c || h(p))


secret key for frontend and backend

SecureRandom.base64

touch backend/.env
touch frontend/src/environments/environment.ts

JWT::VerificationError (Signature verification raised):

lib/jwt_service.rb:11:in `decode'
app/controllers/sessions_controller.rb:31:in `decode_token'
app/controllers/sessions_controller.rb:9:in `create'

^^^ mismatched keys (forgot to match them or possible attack)



User shouldn't be able to perform any user actions until they have a role of 'user'
User gets role of 'user' when email is authenticated, more to come on that '/reddituser/confirmation' ?
ideas...
generate a nonce for email authentication to be included in a link in an email sent to the user
the nonce will be a param to the user's registration route which will check equality
user needs two new columns - confirmation_token, confirmed_at
user now needs roles

