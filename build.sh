#! /bin/bash

# if\s\(.*\)\s\{\n.*\n\s+?\}

echo '' > instructions.md

echo '* [Setup](#setup)' >> instructions.md
echo '  * [Backend](#backend)' >> instructions.md
echo '  * [Frontend](#frontend)' >> instructions.md
echo '* [Heartbeat](#heartbeat)' >> instructions.md
echo '  * [Heartbeat Backend](#heartbeat-backend)' >> instructions.md
echo '  * [Heartbeat Frontend](#heartbeat-frontend)' >> instructions.md
echo '* [Post](#post)' >> instructions.md
echo '  * [Post Backend](#post-backend)' >> instructions.md
echo '  * [Post Frontend](#post-frontend)' >> instructions.md
echo '* [Sub](#sub)' >> instructions.md
echo '  * [Sub Backend](#sub-backend)' >> instructions.md
echo '  * [Sub Frontend](#sub-frontend)' >> instructions.md
echo '* [User](#user)' >> instructions.md
echo '  * [User Backend](#user-backend)' >> instructions.md
echo '  * [User Frontend](#user-frontend)' >> instructions.md
echo '* [Comment](#comment)' >> instructions.md
echo '  * [Comment Backend](#comment-backend)' >> instructions.md
echo '  * [Comment Frontend](#comment-frontend)' >> instructions.md
echo '* [Vote](#vote)' >> instructions.md
echo '  * [Vote Backend](#vote-backend)' >> instructions.md
echo '  * [Vote Frontend](#vote-frontend)' >> instructions.md
echo '* [Signup](#signup)' >> instructions.md
echo '  * [Signup Backend](#signup-backend)' >> instructions.md
echo '  * [Signup Mailer](#signup-mailer)' >> instructions.md
echo '  * [Signup Frontend](#signup-frontend)' >> instructions.md
echo '* [Login](#login)' >> instructions.md
echo '  * [Login Backend](#login-backend)' >> instructions.md
echo '  * [Login Frontend](#login-frontend)' >> instructions.md
echo '* [Authentication](#authentication)' >> instructions.md
echo '  * [Authentication Backend](#authentication-backend)' >> instructions.md
echo '  * [Authentication Frontend](#authentication-frontend)' >> instructions.md
echo '* [Persistence](#persistence)' >> instructions.md
echo '  * [Persistence Frontend](#persistence-frontend)' >> instructions.md
# echo '* [Activation](#activation)' >> instructions.md
# echo '  * [Activation Backend](#activation-backend)' >> instructions.md
# echo '  * [Activation Mailer](#activation-mailer)' >> instructions.md
# echo '  * [Activation Frontend](#activation-frontend)' >> instructions.md
echo '* [Deactivation](#deactivation)' >> instructions.md
echo '  * [Deactivation Backend](#deactivation-backend)' >> instructions.md
echo '  * [Deactivation Frontend](#deactivation-frontend)' >> instructions.md

# echo '* [Pagination](#pagination)' >> instructions.md

echo '' >> instructions.md

echo -e '# Reset\n' >> instructions.md
cat setup/reset.md >> instructions.md

echo -e '# Installs\n' >> instructions.md
cat setup/installs.md >> instructions.md

echo -e '# Updates\n' >> instructions.md
cat setup/updates.md >> instructions.md

echo -e '# Setup\n' >> instructions.md
cat setup/setup.md >> instructions.md

echo -e '# Backend\n' >> instructions.md
cat backend/backend-setup.md >> instructions.md

echo -e '# Frontend\n' >> instructions.md
cat frontend/frontend-setup.md >> instructions.md


echo -e '# Heartbeat\n' >> instructions.md
cat heartbeat/heartbeat-setup.md >> instructions.md

echo -e '# Heartbeat Backend\n' >> instructions.md
cat heartbeat/heartbeat-backend.md >> instructions.md

echo -e '# Heartbeat Frontend\n' >> instructions.md
cat heartbeat/heartbeat-frontend.md >> instructions.md


echo -e '# Post\n' >> instructions.md
cat post/post-setup.md >> instructions.md

echo -e '# Post Backend\n' >> instructions.md
cat post/post-backend.md >> instructions.md

echo -e '# Post Frontend\n' >> instructions.md
cat post/post-frontend.md >> instructions.md


echo -e '# Sub\n' >> instructions.md
cat sub/sub-setup.md >> instructions.md

echo -e '# Sub Backend\n' >> instructions.md
cat sub/sub-backend.md >> instructions.md

echo -e '# Sub Frontend\n' >> instructions.md
cat sub/sub-frontend.md >> instructions.md


echo -e '# User\n' >> instructions.md
cat user/user-setup.md >> instructions.md

echo -e '# User Backend\n' >> instructions.md
cat user/user-backend.md >> instructions.md

echo -e '# User Frontend\n' >> instructions.md
cat user/user-frontend.md >> instructions.md


echo -e '# Comment\n' >> instructions.md
cat comment/comment-setup.md >> instructions.md

echo -e '# Comment Backend\n' >> instructions.md
cat comment/comment-backend.md >> instructions.md

echo -e '# Comment Frontend\n' >> instructions.md
cat comment/comment-frontend.md >> instructions.md


echo -e '# Vote\n' >> instructions.md
cat vote/vote-setup.md >> instructions.md

echo -e '# Vote Backend\n' >> instructions.md
cat vote/vote-backend.md >> instructions.md

echo -e '# Vote Frontend\n' >> instructions.md
cat vote/vote-frontend.md >> instructions.md


echo -e '# Signup\n' >> instructions.md
cat signup/signup-setup.md >> instructions.md

echo -e '# Signup Mailer\n' >> instructions.md
cat signup/signup-mailer.md >> instructions.md

echo -e '# Signup Backend\n' >> instructions.md
cat signup/signup-backend.md >> instructions.md

echo -e '# Signup Frontend\n' >> instructions.md
cat signup/signup-frontend.md >> instructions.md


echo -e '# Login\n' >> instructions.md
cat login/login-setup.md >> instructions.md

echo -e '# Login Backend\n' >> instructions.md
cat login/login-backend.md >> instructions.md

echo -e '# Login Frontend\n' >> instructions.md
cat login/login-frontend.md >> instructions.md


echo -e '# Authentication\n' >> instructions.md
cat authentication/authentication-setup.md >> instructions.md

echo -e '# Authentication Backend\n' >> instructions.md
cat authentication/authentication-backend.md >> instructions.md

echo -e '# Authentication Frontend\n' >> instructions.md
cat authentication/authentication-frontend.md >> instructions.md


# auto logging out on window view
echo -e '# Persistence\n' >> instructions.md
cat persistence/persistence-setup.md >> instructions.md

echo -e '# Persistence Frontend\n' >> instructions.md
cat persistence/persistence-frontend.md >> instructions.md


# echo -e '# Activation\n' >> instructions.md
# cat activation/activation-setup.md >> instructions.md

# echo -e '# Activation Mailer\n' >> instructions.md
# cat activation/activation-mailer.md >> instructions.md

# echo -e '# Activation Backend\n' >> instructions.md
# cat activation/activation-backend.md >> instructions.md

# echo -e '# Activation Frontend\n' >> instructions.md
# cat activation/activation-frontend.md >> instructions.md


echo -e '# Deactivation\n' >> instructions.md
cat deactivation/deactivation-setup.md >> instructions.md

echo -e '# Deactivation Backend\n' >> instructions.md
cat deactivation/deactivation-backend.md >> instructions.md

echo -e '# Deactivation Frontend\n' >> instructions.md
cat deactivation/deactivation-frontend.md >> instructions.md
