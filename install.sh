#!/bin/bash


echo "Do you want install Pterodactyl? (y/n)"
read answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo "Step 1 - Making Dirs"
    mkdir pterodactyl
 
    cd pterodactyl
 
    mkdir panel
 
    cd panel

    echo "Select Platform Linux/Mac-os"
    read answer
    if [[ "$answer" == "linux" || "$answer" == "Linux" ]]; then
      apt install docker-compose
    elif [[ "$answer" == "mac-os" || "$answer" == "Mac-os" ]]; then
      echo "Go to https://docs.docker.com/desktop/setup/install/mac-install/ and install Docker"
    else:
      echo "Incorrect platform"
      exit 1

    echo """
    version: '3.8'
 
x-common:
 
  database:
 
    &db-environment
 
    # Do not remove the "&db-password" from the end of the line below, it is important
 
    # for Panel functionality.
 
    MYSQL_PASSWORD: &db-password "CHANGE_ME"
 
    MYSQL_ROOT_PASSWORD: "CHANGE_ME_TOO"
 
  panel:
 
    &panel-environment
 
    # This URL should be the URL that your reverse proxy routes to the panel server
 
    APP_URL: "https://pterodactyl.example.com"
 
    # A list of valid timezones can be found here: http://php.net/manual/en/timezones.php
 
    APP_TIMEZONE: "UTC"
 
    APP_SERVICE_AUTHOR: "noreply@example.com"
 
    TRUSTED_PROXIES: "*" # Set this to your proxy IP
 
    # Uncomment the line below and set to a non-empty value if you want to use Let's Encrypt
 
    # to generate an SSL certificate for the Panel.
 
    # LE_EMAIL: ""
 
  mail:
 
    &mail-environment
 
    MAIL_FROM: "noreply@example.com"
 
    MAIL_DRIVER: "smtp"
 
    MAIL_HOST: "mail"
 
    MAIL_PORT: "1025"
 
    MAIL_USERNAME: ""
 
    MAIL_PASSWORD: ""
 
    MAIL_ENCRYPTION: "true"
 
 
 
#
 
# ------------------------------------------------------------------------------------------
 
# DANGER ZONE BELOW
 
#
 
# The remainder of this file likely does not need to be changed. Please only make modifications
 
# below if you understand what you are doing.
 
#
 
services:
 
  database:
 
    image: mariadb:10.5
 
    restart: always
 
    command: --default-authentication-plugin=mysql_native_password
 
    volumes:
 
      - "/srv/pterodactyl/database:/var/lib/mysql"
 
    environment:
 
      <<: *db-environment
 
      MYSQL_DATABASE: "panel"
 
      MYSQL_USER: "pterodactyl"
 
  cache:
 
    image: redis:alpine
 
    restart: always
 
  panel:
 
    image: ghcr.io/pterodactyl/panel:latest
 
    restart: always
 
    ports:
 
      - "80:80"
 
      - "443:443"
 
    links:
 
      - database
 
      - cache
 
    volumes:
 
      - "/srv/pterodactyl/var/:/app/var/"
 
      - "/srv/pterodactyl/nginx/:/etc/nginx/http.d/"
 
      - "/srv/pterodactyl/certs/:/etc/letsencrypt/"
 
      - "/srv/pterodactyl/logs/:/app/storage/logs"
 
    environment:
 
      <<: [*panel-environment, *mail-environment]
 
      DB_PASSWORD: *db-password
 
      APP_ENV: "production"
 
      APP_ENVIRONMENT_ONLY: "false"
 
      CACHE_DRIVER: "redis"
 
      SESSION_DRIVER: "redis"
 
      QUEUE_DRIVER: "redis"
 
      REDIS_HOST: "cache"
 
      DB_HOST: "database"
 
      DB_PORT: "3306"
 
networks:
 
  default:
 
    ipam:
 
      config:
 
        - subnet: 172.20.0.0/16
    
    
    """

    echo "Paste this in docker-compose.yml, press Control + o, Enter, Control + x, Enter  (press Enter to continue)"
      
    nano docker-compose.yml

    docker-compose up -d

    echo "Press Enter to exit..."
    read answer
    echo "Goodbye!"
else
    echo "Canceled!"
    exit 1
fi



