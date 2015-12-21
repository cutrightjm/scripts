#!/bin/bash
# wp_install.sh version 1
# installs latest wordpress site

## sets docroot for apache and mysql root's password so it can be used by debconf
DOCUMENT_ROOT="/var/www/wordpress"
MYSQL_ROOT_PASS="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"

## uses this server email to set up apache's config file
echo "Enter in the email for the server administrator:"
read SERVER_ADMIN_EMAIL

apt-get update
apt-get upgrade

## Set up passwords so mysql-server install doesn't have password prompt
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASS"

## install the required packages to run
apt-get -y install apache2
apt-get -y install libapache2-mod-php5
apt-get -y install libapache2-mod-auth-mysql
apt-get -y install php5-mysql
apt-get -y install mysql-server

## download and extract wordpress
wget http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz

## sets up variables for wordpress installation
MYSQL_DB=wordpress$(echo "$RANDOM")
MYSQL_USER=wordpress$(echo "$RANDOM")
MYSQL_USER_PASS="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"

## creates a .my.cnf so you can run mysql from the command line without password prompt
printf "[mysql]\nuser=root\npassword=\""$MYSQL_ROOT_PASS"\"\n" > ~/.my.cnf

## adds a wordpress user with own password and creates database for wordpress
mysql --defaults-file=~/.my.cnf -e "create database $MYSQL_DB; create user "$MYSQL_USER"@localhost; set password for "$MYSQL_USER"@localhost = PASSWORD(\""$MYSQL_USER_PASS"\"); GRANT ALL PRIVILEGES ON "$MYSQL_DB".* TO "$MYSQL_USER"@localhost IDENTIFIED BY '"$MYSQL_USER_PASS"'; flush privileges;"

## removes the .my.cnf file which contains mysql's root password
rm -r ~/.my.cnf

## sets up wordpress to use the newly created user and password
cp ~/wordpress/wp-config-sample.php ~/wordpress/wp-config.php
sed -i s/database_name_here/$MYSQL_DB/ ~/wordpress/wp-config.php
sed -i s/username_here/$MYSQL_USER/ ~/wordpress/wp-config.php
sed -i s/password_here/$MYSQL_USER_PASS/ ~/wordpress/wp-config.php

## puts wordpress in the appropriate place and changes permissions
mv wordpress /var/www/
sudo chown www-data:www-data /var/www/wordpress -R

## configures apache to serve wordpress as the site root
cp /etc/apache2/sites-available/default ./default.bak
echo "setting correct server admin email"
sed -i s/webmaster@localhost/$SERVER_ADMIN_EMAIL/ /etc/apache2/sites-available/default
echo "setting document root of webserver to wordpress install..."
sed -i s@/\var\/www@${DOCUMENT_ROOT}@ /etc/apache2/sites-available/default
service apache2 reload

## removes the password used to do an unattended install of mysql-server
echo PURGE | debconf-communicate mysql-server

## browse to this URL to configure the wordpress install
echo "browse to the url /wp-admin/install.php to configure wordpress"
