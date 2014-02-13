---
layout: post
published: true
title: Server
category: tutorial
---

# Setup Server (Ruby, Rails, MySQL, Nginx, Unicorn)


### Basic First Steps

SSH into server:

	ssh root@ip.address
	

Change (Root) Password:

	passwd


***
#### DigitalOcean 
Visit 'DNS' in Sidebar
Add your domain and the ip address of your server
Visit your domain host and set the domain namespaces to the correct values
```
NS1.DIGITALOCEAN.COM
NS2.DIGITALOCEAN.COM
NS3.DIGITALOCEAN.COM
```
***


**Once DNS Propogates (will take a couple minutes), you should domain should now point to your server.**

Create a new user for the server. Calling it developer for this case:

	adduser developer
	


Give user sudo permissions:
	
	visudo
	
	
Edit the file by adding the following to give the new user sudo rights. Hit ctrl+x, then y, then enter to save changes: 
	
	# User privilege specification
	root  ALL=(ALL:ALL) ALL
	developer ALL=(ALL:ALL) ALL
	

Config SSH settings:

	nano /etc/ssh/sshd_config
	
*Optional:* 
	- Change port (22 is default: choose between 1025..65536). 
	- Deny root login
	- Remove DNS
		
	Port [1025..65536]
	Protocol 2
	PermitRootLogin yes # You can change this to "no" if you don't want the root user to be able to ssh in anymore
	...
	...
	UseDNS no
	AllowUsers developer # Only add this line if you have changed PermitRootLogin to no, or you can do AllowUsers deployer root
	
Hit ctrl+x, then y, then enter to save changes.

Reload SSH:
	
	reload ssh
	

Open a new tab and ssh as new user:

	ssh [-p PORT_NUMBER] developer@ip.address
	

Update server and install essentials (curl, python components, git, node.js):

	sudo apt-get update
	sudo apt-get -y install curl python-software-properties git-core nodejs


### RVM

Download and Install RVM:

	curl -L get.rvm.io | bash -s stable
	
	
Load RVM: 
	
	source ~/.rvm/scripts/rvm
	
	
Install RVM requirements:

	rvm requirements

Install Ruby:
	
	rvm install 2.1.0

Use Ruby 2.1.0 as default:

	rvm use 2.1.0 --default

Install latest version of rubygems if rvm install didn't:
	
	rvm rubygems current
	

### Rails

Install Rails:
	
	gem install rails --no-ri --no-rdoc


Install Bundler:

	gem install bundler


### MySQL

Install MySQL:

	sudo apt-get install mysql-server php5-mysql

- Note: During the installation, MySQL will ask you to set a root password. If you miss the chance to set the password while the program is installing, it is very easy to set the password later from within the MySQL shell.
	
	
Activate MySQL:

	sudo mysql_install_db
	
Finish up by running the MySQL set up script:
	
	sudo /usr/bin/mysql_secure_installation
	

### Nginx

Install Nginx:
	
	sudo apt-get install nginx

Start Nginx:
	
	sudo service nginx start
	

### Preparing for Deployment locally with Unicorn, Nginx and Capistrano


If needed, install homebrew:
	
	brew #Check for homebrew. If no known command, then:
	ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
	

Install RVM locally:

	curl -L get.rvm.io | bash -s stable
	source ~/.rvm/scripts/rvm
	rvm requirements
	rvm install 2.1.0
	rvm rubygems current
	
	
Create RVM Gemset:
	
	rvm gemset create APP_NAME
	
Install Rails:
	
	sudo gem install rails --no-ri --no-rdoc

Install Bundler:
	
	gem install bundler
	
Create new Rails App:
	
	rails new TeacherTeams -d mysql
	
Create .ruby-version and .ruby-gemset file so that rvm will take care of automatically switching versions:

	rvm --ruby-version use 2.1.0@APP_NAME
	
Add Unicorn to gemfile
	
	gem "unicorn"
	
Create three files:

-config/nginx.conf
-config/unicorn.rb
-config/unicorn_init.sh

** Make sure to change out variables (*APP_NAME*, *URL*, *USER*)
nginx.conf:

	upstream unicorn {
	  server unix:/tmp/unicorn.*APP_NAME*.sock fail_timeout=0;
	}

	server {
	  listen 80 default deferred;
	  #server_name *URL*.com;
	  root /home/*USER*/apps/*APP_NAME*/current/public;

	  location ^~ /assets/ {
	    gzip_static on;
	    expires max;
	    add_header Cache-Control public;
	  }

	  try_files $uri/index.html $uri @unicorn;
	  location @unicorn {
	    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	    proxy_set_header Host $http_host;
	    proxy_redirect off;
	    proxy_pass http://unicorn;
	  }

	  error_page 500 502 503 504 /500.html;
	  client_max_body_size 4G;
	  keepalive_timeout 10;
	}

unicorn.rb:
	
	root = "/home/*USER*/apps/*APP_NAME*/current"
	working_directory root
	pid "#{root}/tmp/pids/unicorn.pid"
	stderr_path "#{root}/log/unicorn.log"
	stdout_path "#{root}/log/unicorn.log"

	listen "/tmp/unicorn.*APP_NAME*.sock"
	worker_processes 2
	timeout 30

	# Force the bundler gemfile environment variable to
	# reference the capistrano "current" symlink
	before_exec do |_|
	  ENV["BUNDLE_GEMFILE"] = File.join(root, 'Gemfile')
	end
	
unicorn_init.sh:

	#!/bin/sh
	### BEGIN INIT INFO
	# Provides:          unicorn
	# Required-Start:    $remote_fs $syslog
	# Required-Stop:     $remote_fs $syslog
	# Default-Start:     2 3 4 5
	# Default-Stop:      0 1 6
	# Short-Description: Manage unicorn server
	# Description:       Start, stop, restart unicorn server for a specific application.
	### END INIT INFO
	set -e

	# Feel free to change any of the following variables for your app:
	TIMEOUT=${TIMEOUT-60}
	APP_ROOT=/home/*USER*/apps/*APP_NAME*/current
	PID=$APP_ROOT/tmp/pids/unicorn.pid
	CMD="cd $APP_ROOT; bundle exec unicorn -D -c $APP_ROOT/config/unicorn.rb -E production"
	AS_USER=*USER*
	set -u

	OLD_PIN="$PID.oldbin"

	sig () {
	  test -s "$PID" && kill -$1 `cat $PID`
	}

	oldsig () {
	  test -s $OLD_PIN && kill -$1 `cat $OLD_PIN`
	}

	run () {
	  if [ "$(id -un)" = "$AS_USER" ]; then
	    eval $1
	  else
	    su -c "$1" - $AS_USER
	  fi
	}

	case "$1" in
	start)
	  sig 0 && echo >&2 "Already running" && exit 0
	  run "$CMD"
	  ;;
	stop)
	  sig QUIT && exit 0
	  echo >&2 "Not running"
	  ;;
	force-stop)
	  sig TERM && exit 0
	  echo >&2 "Not running"
	  ;;
	restart|reload)
	  sig HUP && echo reloaded OK && exit 0
	  echo >&2 "Couldn't reload, starting '$CMD' instead"
	  run "$CMD"
	  ;;
	upgrade)
	  if sig USR2 && sleep 2 && sig 0 && oldsig QUIT
	  then
	    n=$TIMEOUT
	    while test -s $OLD_PIN && test $n -ge 0
	    do
	      printf '.' && sleep 1 && n=$(( $n - 1 ))
	    done
	    echo

	    if test $n -lt 0 && test -s $OLD_PIN
	    then
	      echo >&2 "$OLD_PIN still exists after $TIMEOUT seconds"
	      exit 1
	    fi
	    exit 0
	  fi
	  echo >&2 "Couldn't upgrade, starting '$CMD' instead"
	  run "$CMD"
	  ;;
	reopen-logs)
	  sig USR1
	  ;;
	*)
	  echo >&2 "Usage: $0 <start|stop|restart|upgrade|force-stop|reopen-logs>"
	  exit 1
	  ;;
	esac
	
Make unicorn_init.sh executable:

	chmod +x config/unicorn_init.sh
	

### Capistrano

Add Capistrano and RVM-Capistrano to Gemfile

	gem 'capistrano'
	gem 'rvm-capistrano'
	
Install these gems:
	
	bundle install
	
Create Capfile & config/deploy.rb files by running:
	
	capify .
	
Edit deploy.rb. Replace *IP_ADDRESS*, *APP_NAME*, *USER*, *PORT*, *RESPOSTIORY_LOCATION*:

	require "bundler/capistrano"
	require "rvm/capistrano"

	server "*IP_ADDRESS*", :web, :app, :db, primary: true

	set :application, "*APP_NAME*"
	set :user, "*USER*"
	set :port, *PORT*
	set :deploy_to, "/home/#{user}/apps/#{application}"
	set :deploy_via, :remote_cache
	set :use_sudo, false

	set :scm, "git"
	set :repository, "git@github.com:*REPOSITORY_LOCATION*"
	set :branch, "master"

	default_run_options[:pty] = true
	ssh_options[:forward_agent] = true

	after "deploy", "deploy:cleanup" # keep only the last 5 releases

	namespace :deploy do
	  %w[start stop restart].each do |command|
	    desc "#{command} unicorn server"
	    task command, roles: :app, except: {no_release: true} do
	      run "/etc/init.d/unicorn_#{application} #{command}"
	    end
	  end

	  task :setup_config, roles: :app do
	    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
	    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
	    run "mkdir -p #{shared_path}/config"
	    put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
	  end
	  after "deploy:setup", "deploy:setup_config"

	  task :symlink_config, roles: :app do
	    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
	  end
	  after "deploy:finalize_update", "deploy:symlink_config"

	  desc "Make sure local git is in sync with remote."
	  task :check_revision, roles: :web do
	    unless `git rev-parse HEAD` == `git rev-parse origin/master`
	      puts "WARNING: HEAD is not the same as origin/master"
	      puts "Run `git push` to sync changes."
	      exit
	    end
	  end
	  before "deploy", "deploy:check_revision"
	end
	
	
Edit Capfile:

	load 'deploy'
	load 'deploy/assets'
	load 'config/deploy'
	

Next test if you are already set up with github:
	
	ssh -T git@github.com
	# If you see:
	"Hi username! You've successfully authenticated, but GitHub does not provide shell access."
	# then you're good to go.
	# Otherwise follow this tutorial:
	#  https://help.github.com/articles/generating-ssh-keys


Next add your ssh key to your server:
	
	cat ~/.ssh/id_rsa.pub | ssh [-p PORT] developer@123.123.123.123 'cat >> ~/.ssh/authorized_keys'
	
If you get an error like:
	
	bash: /home/developer/.ssh/authorized_keys: No such file or directory
	
then ssh to the server (as developer) and run the following:

	cd /home/developer
	mkdir .ssh
	chmod 775 .ssh
	

Create gitignore file and add the following (tweak as needed):
	
	# bundler state
	/.bundle
	/vendor/bundle/
	/vendor/ruby/

	# minimal Rails specific artifacts
	db/*.sqlite3
	/log/*
	/tmp/*

	# various artifacts
	**.war
	*.rbc
	*.sassc
	.rspec
	.redcar/
	.sass-cache
	/config/config.yml
	/config/database.yml
	/coverage.data
	/coverage/
	/db/*.javadb/
	/db/*.sqlite3
	/doc/api/
	/doc/app/
	/doc/features.html
	/doc/specs.html
	/public/cache
	/public/stylesheets/compiled
	/public/system/*
	/spec/tmp/*
	/cache
	/capybara*
	/capybara-*.html
	/gems
	/specifications
	rerun.txt
	pickle-email-*.html

	# If you find yourself ignoring temporary files generated by your text editor
	# or operating system, you probably want to add a global ignore instead:
	#   git config --global core.excludesfile ~/.gitignore_global
	#
	# Here are some files you may want to ignore globally:

	# scm revert files
	**.orig

	# Mac finder artifacts
	.DS_Store

	# Netbeans project directory
	/nbproject/

	# RubyMine project files
	.idea

	# Textmate project files
	/*.tmproj

	# vim artifacts
	**.swp

	#Espresso
	*.esproj
	.rvmrc
	
Now visit your server and login to mysql. 
	
	 mysql -u root -p
	 #Enter your password when prompted. 
	 
Create the databases that you need:

	create database DB_NAME;

Exit mysql:
	
	exit

Create a new database configuration file config/database.base.yml and edit it as so. Use this template to also edit config/database.yml for the databases you created on your server.
**NOTE: Leave database names and passwords as astericks in the database.base.yml file**
	
	# MySQL.  Versions 4.1 and 5.0 are recommended.
	#
	# Install the MYSQL driver
	#   gem install mysql2
	#
	# Ensure the MySQL gem is defined in your Gemfile
	#   gem 'mysql2'
	#
	# And be sure to use new-style password hashing:
	#   http://dev.mysql.com/doc/refman/5.0/en/old-client.html
	development:
	  adapter: mysql2
	  encoding: utf8
	  database: ***
	  pool: 5
	  username: root
	  password: ***
	  host: localhost

	# Warning: The database defined as "test" will be erased and
	# re-generated from your development database when you run "rake".
	# Do not set this db to the same as development or production.
	test:
	  adapter: mysql2
	  encoding: utf8
	  database: ***
	  pool: 5
	  username: root
	  password: ***
	  host: localhost

	production:
	  adapter: mysql2
	  encoding: utf8
	  database: ***
	  pool: 5
	  username: root
	  password: ***
	  host: localhost
	  
Initalize git repository:

	git init
	git add .
	git commit -m "Inital Commit"
	
Now go to github and create a new repository:

	git remote add origin git@github.com:github_user/repo_name
	git push origin master

Setup Deployment:
	
	cap deploy:setup
	
Edit database.yml on server to add username and password to the production database:
	
	vi apps/*PROJECT_NAME*/shared/config/database.yml

Deploy it cold:

		cap deploy:cold
		
Fix up nginx and restart:

	sudo rm /etc/nginx/sites-enabled/default
	sudo service nginx restart
	sudo update-rc.d -f unicorn_PROJECTNAME defaults
	
Push changes and deploy:

	git push origin master
	cap deploy
	
CONGRATULATIONS! You now have a running server!
	
***

#### Sources
http://www.andrewgertig.com/setting-up-a-digital-ocean-droplet-vps-on-ubuntu-with-rails-nginx-unicorn-postgres-redis-and-capistrano

https://coderwall.com/p/yz8cha




