#!/usr/bin/env bash

function directory {
  #creates a directory "documents" and changes directory into it
  mkdir documents
  cd documents

  #makes the current user the owner of this config directory
  sudo chown -R $(whoami) ~/.config 
}

#clones the repository where the appto be deployed is
function cloneRepo {
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< CLONING REPO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  git clone https://github.com/primuse/SendIt-React.git
  cd SendIt-React
}

function app {
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< INSTALLING APP DEPENDENCIES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  npm install

  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ENVIRONMENT IS READY; STARTING APP >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  pm2 start npm -- start
  pm2 startup
  sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu
  pm2 save

  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< APPLICATION STARTED >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  cd ~
}

#gets latest ubuntu updates 
function updateUbuntu {
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< RUN UBUNTU UPDATE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo apt-get update
}

function installNodeJs {
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< INSTALLING NODEJS AND NPM >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
  sudo apt-get install -y nodejs
}

function installNginx {
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< INSTALLING NGINX >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo apt-get -y install nginx
}

#installs pm2 to run app in the background
function installPm2 {
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< INSTALLING PM2>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo npm i pm2@latest -g
}

function nginxConfig {
  #verifies the nginx version that was installed
  nginx -v

  # remove default nginx config
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< REMOVING DEFAULT NGINX CONFIG FILES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default

  #change ownership of the sites-available directory to the current user
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< CHANGING FILE PERMISSIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo chown -R $(whoami) /etc/nginx/sites-available

  # creates custom nginx config with a proxy pass
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< CREATING CUSTOM NGINX CONFIG FILE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo cat > /etc/nginx/sites-available/sendit <<EOF
server {
  listen 80;
  server_name localhost sendit-ah.gq www.sendit-ah.gq;
  location / {
    proxy_pass http://127.0.0.1:3000;
  }
}
EOF
  cat /etc/nginx/sites-available/sendit

  # enable sendit config instead
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ENABLING CUSTOM FILE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo ln -s /etc/nginx/sites-available/sendit /etc/nginx/sites-enabled/sendit

  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< RESTARTING NGINX SERVICE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo service nginx restart
  systemctl status nginx.service

  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< SERVICE RESTARTED >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
}

# installs packages for the setup and configuration of SSL certificates
function certbot {
  echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< INSTALLING CERTBOT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  sudo apt-get install software-properties-common
  sudo add-apt-repository ppa:certbot/certbot
  sudo apt-get update
  sudo apt-get install -y python-certbot-nginx
}


function main {
  updateUbuntu
  installNodeJs
  installNginx
  installPm2
  directory
  cloneRepo
  app
  nginxConfig
  certbot
}
main