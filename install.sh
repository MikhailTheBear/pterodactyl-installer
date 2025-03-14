#!/bin/bash

# Приветствие
echo "Добро пожаловать в установщик Pterodactyl!"
echo "Вы хотите установить панель Pterodactyl? (yes/no)"
read install_pterodactyl
if [[ "$install_pterodactyl" != "yes" ]]; then
    echo "Установка отменена."
    exit 1
fi

echo "Введите ваш домен (например, panel.example.com):"
read domain

# Обновляем систему и устанавливаем зависимости
apt update && apt upgrade -y
apt install -y curl sudo zip unzip tar git redis-server nginx mysql-server mariadb-server software-properties-common

# Устанавливаем PHP 8.1
add-apt-repository -y ppa:ondrej/php
apt update
apt install -y php8.1 php8.1-cli php8.1-curl php8.1-mbstring php8.1-xml php8.1-bcmath php8.1-gd php8.1-mysql php8.1-zip composer

# Загружаем и настраиваем панель
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage bootstrap/cache
cp .env.example .env

# Настраиваем панель
composer install --no-dev --optimize-autoloader
php artisan key:generate

# Настройка базы данных
mysql -u root -e "CREATE DATABASE pterodactyl; CREATE USER 'pterodactyl'@'localhost' IDENTIFIED BY 'password'; GRANT ALL PRIVILEGES ON pterodactyl.* TO 'pterodactyl'@'localhost'; FLUSH PRIVILEGES;"

# Заполняем базу данных
php artisan migrate --seed --force

# Настройка веб-сервера
cat > /etc/nginx/sites-available/pterodactyl << EOF
server {
    listen 80;
    server_name $domain;
    root /var/www/pterodactyl/public;
    index index.php index.html;
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.(php|phar)$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
systemctl restart nginx

# Настраиваем крон и очередь задач
(crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
php artisan queue:restart

# Запускаем сервис
chown -R www-data:www-data /var/www/pterodactyl
systemctl restart nginx

echo "Установка Pterodactyl завершена!"
