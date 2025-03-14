#!/bin/bash -e

echo "Do you want to install Pterodactyl? (y/n)"
read -r answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo "Step 1 - Making Dirs"
    mkdir -p pterodactyl/panel
    cd pterodactyl/panel || exit

    echo "Select Platform Linux/Mac-os"
    read -r answer

    if [[ "$answer" == "linux" || "$answer" == "Linux" ]]; then
        apt install -y docker-compose
    elif [[ "$answer" == "mac-os" || "$answer" == "Mac-os" ]]; then
        echo "Go to https://docs.docker.com/desktop/setup/install/mac-install/ and install Docker"
    else
        echo "Incorrect platform"
        exit 1
    fi

    cat <<EOF > docker-compose.yml
version: '3.8'

x-common:
  database:
    &db-environment
    MYSQL_PASSWORD: &db-password "CHANGE_ME"
    MYSQL_ROOT_PASSWORD: "CHANGE_ME_TOO"

  panel:
    &panel-environment
    APP_URL: "https://pterodactyl.example.com"
    APP_TIMEZONE: "UTC"
    APP_SERVICE_AUTHOR: "noreply@example.com"
    TRUSTED_PROXIES: "*"

  mail:
    &mail-environment
    MAIL_FROM: "noreply@example.com"
    MAIL_DRIVER: "smtp"
    MAIL_HOST: "mail"
    MAIL_PORT: "1025"
    MAIL_USERNAME: ""
    MAIL_PASSWORD: ""
    MAIL_ENCRYPTION: "true"

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
EOF

    echo "Docker Compose file created. Open it in nano and save (Ctrl + O, Enter, Ctrl + X, Enter). Press Enter to continue."
    read -r

    nano docker-compose.yml

    docker-compose up -d

    echo "Press Enter to exit..."
    read -r
    echo "Goodbye!"
else
    echo "Canceled!"
    exit 1
fi
