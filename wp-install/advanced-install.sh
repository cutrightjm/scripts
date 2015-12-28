#still need secure accts

function is_wordpress {
	read -n1 -p "Is Wordpress currently installed? [y/n] " is_wordpress

	case $is_wordpress in
		y|Y) printf "\n\tWordpress is currently installed\n"; isWordpressInstalled="true";;
		n|N) printf "\n\tWordpress is current not installed\n"; isWordpressInstalled="false";;
		  *) printf "\n\tInvalid option. Try again.\n" && is_wordpress;;
	esac
}

function is_apache {
	read -n1 -p "Is Apache currently installed? [y/n] " is_apache

	case $is_apache in
		y|Y) printf "\n\tApache is currently installed\n"; isApacheInstalled="true";;
		n|N) printf "\n\tApache is current not installed\n"; isApacheInstalled="false";;
		  *) printf "\n\tInvalid option. Try again.\n" && is_apache;;
	esac
}

function is_php {
		read -n1 -p "Is PHP currently installed? [y/n] " is_php

	case $is_php in
		y|Y) printf "\n\tPHP is currently installed\n"; isPHPInstalled="true";;
		n|N) printf "\n\tPHP is current not installed\n"; isPHPInstalled="false";;
		  *) printf "\n\tInvalid option. Try again.\n" && is_php;;
	esac
}

function is_sql {
	read -n1 -p "Is mysql-server currently installed? [y/n] " is_sql

	case $is_sql in
		y|Y) printf "\n\tmysql-server is currently installed\n"; isSQLInstalled="true";;
		n|N) printf "\n\tmysql-server is current not installed\n"; isSQLInstalled="false";;
		  *) printf "\n\tInvalid option. Try again.\n" && is_sql;;
	esac
}

function is_qty {
        read -n1 -p "How many instances would you like to install? [1-9] " is_qty

        case $is_qty in
                [1-9]) printf "\n"$is_qty" instances will be installed.\n"; instance_qty=$is_qty;;
                    *) printf "\n\tInvalid option. Try again.\n" && is_qty;;
        esac
}

function get_email {
	read -e -p "What is the server administrator's email address? " adminEmail
}

function sql_creds {
	if [ $isSQLInstalled == "false" ];
	then
		mysql_root_pass="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"
		## creates a .my.cnf so you can run mysql from the command line without password prompt
		printf "[mysql]\nuser=root\npassword=\""$mysql_root_pass"\"\n" > ~/.my.cnf
		echo $mysql_root_pass

	else
		read -e -s -p "What is the root password for mysql-server? " mysql_root_pass
		echo $mysql_root_pass
	fi


	## Set up passwords so mysql-server install doesn't have password prompt
	debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysql_root_pass"
	debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysql_root_pass"
}

function install_prereqs {
	echo "install prereqs...."
	#if [$isWordpressInstalled = "true"]

	if [ $isApacheInstalled == "false" ]; then
		apt-get -y install apache2 libapache2-mod-php5 libapache2-mod-auth-mysql
	fi

	if [ $isPHPInstalled == "false" ]; then
		apt-get -y install php5-mysql
	fi

	if [ $isSQLInstalled == "false" ]; then
		apt-get -y install mysql-server
	fi
}

function install_vhost {
        read -e -p "What is the domain of this blog (example.com)? " domain

        read -n1 -p "Is this blog (a) at that domain, (b) a subdomain, or (c) a subpage? (m) for more info " whatType
        case $whatType in
                a|A) printf "\n\tWordpress will be hosted at "$domain"\n"; whatType="domain";;
                b|B) printf "\n\tWordpress will be hosted at subdomain."$domain"\n"; whatType="subdomain";;
                c|C) printf "\n\tWordpress will be hosted at "$domain"/subpage\n"; whatType="subpage";;
                m|M) printf "\n\tIf you host the blog at that domain, the URL will be "$domain" \n\tIf you host it at a subdomain, it will be at subdomain."$domain" \n\tIf you choose a subpage, the URL will be "$domain"/subpage\n"; install_vhost ;;
                  *) printf "\n\tInvalid choice - please choose a, b, c, or m."; install_vhost;;
        esac


        ## You can technically leave out that whatType for "domain", since it is already specified in the read statement,
        ## but leaving it in makes the code easier to follow
        if [ $whatType == "domain" ]; then
                completeDomain=$domain
        fi

        if [ $whatType == "subdomain" ]; then
                read -e -p "What would you like the subdomain to be called? " subdomain
                completeDomain=$subdomain.$domain
                printf "\tThe complete URL is "$completeDomain"\n"
        fi

        if [ $whatType == "subpage" ]; then
                read -e -p "What would you like the subpage to be called? " subpage
                completeDomain=$domain/$subpage
                printf "\tThe complete URL is "$completeDomain"\n"
        fi

        #the name of the vhosts file is $wordpressURL
        #the actual address of the site is $completeDomain
        wordpressURL=$completeDomain
        if [ $whatType == "subpage" ]; then
                wordpressURL=$domain"-"$subpage
        fi


        ## this makes the vhosts file for the appropriate type of website
        ## this is for @ domain
        if [ $whatType == "domain" ]; then
                printf "<VirtualHost "$compleDomain":80>\n\tServerAdmin "$adminEmail"" > /etc/apache2/sites-available/$wordpressURL
                printf "\n\tServerName "$completeDomain"" >> /etc/apache2/sites-available/$wordpressURL
                printf "\n\tDocumentRoot /var/www/"$wordpressURL"\n</VirtualHost>" >> /etc/apache2/sites-available/$wordpressURL
        fi

        ## this is for subdomains
        if [ $whatType == "subdomain" ]; then
                printf "<VirtualHost "$completeDomain":80>\n\tServerAdmin "$adminEmail"" > /etc/apache2/sites-available/$wordpressURL
                printf "\n\tServerName "$completeDomain"" >> /etc/apache2/sites-available/$wordpressURL
                printf "\n\tDocumentRoot /var/www/"$wordpressURL"\n</VirtualHost>" >> /etc/apache2/sites-available/$wordpressURL
        fi

        ## this is for subpages
        if [ $whatType == "subpage" ]; then
                printf "<VirtualHost "$domain":80>\n\tServerAdmin "$adminEmail"" > /etc/apache2/sites-available/$wordpressURL
                printf "\n\tServerName "$domain"" >> /etc/apache2/sites-available/$wordpressURL
		printf "\n\tAlias /"$subpage" /var/www/"$wordpressURL"" >> /etc/apache2/sites-available/$wordpressURL
#                printf "\n\tDocumentRoot /var/www/"$wordpressURL"\n</VirtualHost>" >> /etc/apache2/sites-available/$wordpressURL
		printf "\n</VirtualHost" >> /etc/apache2/sites-available/$wordpressURL
        fi

        ## pipes all text from this to /dev/null since install_cleanup handles reloading apache
        a2ensite $wordpressURL 2> /dev/null
}


function install_instances {
	for ((i=1 ; i<=$instance_qty ; i++ )); do
		echo "installing instance " $i

		## sets up variables for wordpress installation
		MYSQL_DB=wordpress$(echo "$RANDOM")
		MYSQL_USER=wordpress$(echo "$RANDOM")
		MYSQL_USER_PASS="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"


		## adds a wordpress user with own password and creates database for wordpress
		mysql --defaults-file=~/.my.cnf -e "create database $MYSQL_DB; create user "$MYSQL_USER"@localhost; set password for "$MYSQL_USER"@localhost = PASSWORD(\""$MYSQL_USER_PASS"\"); GRANT ALL PRIVILEGES ON "$MYSQL_DB".* TO "$MYSQL_USER"@localhost IDENTIFIED BY '"$MYSQL_USER_PASS"'; flush privileges;"

		#get_domain

                ##creates the vhost file for this particular instance
                install_vhost


		cp -r ~/wordpress/ ~/$wordpressURL


		## sets up wordpress to use the newly created user and password
		cp ~/$wordpressURL/wp-config-sample.php ~/$wordpressURL/wp-config.php
		sed -i s/database_name_here/$MYSQL_DB/ ~/$wordpressURL/wp-config.php
		sed -i s/username_here/$MYSQL_USER/ ~/$wordpressURL/wp-config.php
		sed -i s/password_here/$MYSQL_USER_PASS/ ~/$wordpressURL/wp-config.php


		## puts wordpress in the appropriate place and changes permissions
		mv $wordpressURL /var/www/
		chown www-data:www-data /var/www/$wordpressURL -R

	done
}

function install_cleanup {
	rm ~/.my.cnf
	service apache2 reload
}

## download and extract wordpress
#wget http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
get_email
is_wordpress
is_apache
is_php
is_sql
sql_creds
is_qty
install_prereqs
install_instances
install_cleanup
