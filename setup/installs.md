```bash
$ cat ~/.ssh/id_rsa.pub
$ ssh-keygen -t rsa # ↵
$ cat ~/.ssh/id_rsa.pub
$ touch ~/.ssh/config
```

###### ~/.ssh/config

```
Host *
 AddKeysToAgent yes
 UseKeychain yes
 IdentityFile ~/.ssh/id_rsa
 User <your_username>

```

### Initialize Git

```bash
$ git config --global user.name = "First Last"
$ git config --global user.email = "your.email@example.com"
```

[Install Homebrew](https://brew.sh/)

[Install RVM](https://usabilityetc.com/articles/ruby-on-mac-os-x-with-rvm/)

### Install latest Ruby

```bash
$ \curl -L https://get.rvm.io | bash -s stable --ruby
```

[Gemset stuff](https://www.digitalocean.com/community/tutorials/how-to-use-rvm-to-manage-ruby-installations-and-environments-on-a-vps)

```bash
$ rvm gemset create reddit
$ rvm gemset use reddit
```

###### some_dir/.rvmrc

```
rvm ruby_version@gemset
```

Skip documentation with gem installation

###### ~/.gemrc

```
gem: --no-document 

```

Install Bundler

```bash
$ gem install bundler
```

#### [Install PostgreSQL](https://www.moncefbelyamani.com/how-to-install-postgresql-on-a-mac-with-homebrew-and-lunchy/)

Don't forget to start and autostart:

```bash
$ brew services start postgresql
```

### Install pgcli

```bash
$ brew install pgcli
```

Install Angular CLI

```bash
$ brew install node
$ npm install -g @angular/cli@latest
```

Install jq

```bash
brew install jq
```

