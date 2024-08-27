#!/bin/bash
#
# Prepare our container for initial boot.

# Where does our MySQL data live?
VOLUME_HOME="/var/lib/mysql"
#pip install asynchat
#######################################
# Use sed to replace apache php.ini values for a given PHP version.
# Globals:
#   PHP_UPLOAD_MAX_FILESIZE
#   PHP_POST_MAX_SIZE
#   PHP_TIMEZONE
# Arguments:
#   $1 - PHP version i.e. 8.3 etc.
# Returns:
#   None
#######################################
function replace_apache_php_ini_values () {
    echo "Updating for PHP $1"

    sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
        -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php/$1/apache2/php.ini \
        -e "s/^memory_limit.*/memory_limit = ${PHP_MEMORY_LIMIT}/" /etc/php/$1/apache2/php.ini \
        -e "s/^max_execution_time.*/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/" /etc/php/$1/apache2/php.ini

    sed -i "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/$1/apache2/php.ini
    #sed -i "s/;user_ini.filename = \".user.ini\"/user_ini.filename = \".user.ini\"/g" /etc/php/$1/apache2/php.ini
    sed -i "s|;sendmail_path =|sendmail_path = /usr/sbin/ssmtp -t|" /etc/php/$1/apache2/php.ini

}
if [ -e /etc/php/$PHP_VERSION/apache2/php.ini ]; then replace_apache_php_ini_values $PHP_VERSION; fi

#######################################
# Use sed to replace cli php.ini values for a given PHP version.
# Globals:
#   PHP_TIMEZONE
# Arguments:
#   $1 - PHP version i.e. 8.3 etc.
# Returns:
#   None
#######################################
function replace_cli_php_ini_values () {
    echo "Replacing CLI php.ini values"
    sed -i  "s/;date.timezone =/date.timezone = UTC/g" /etc/php/$1/cli/php.ini
}
if [ -e /etc/php/$PHP_VERSION/cli/php.ini ]; then replace_cli_php_ini_values $PHP_VERSION; fi


# writing ssmtp.conf
# Check if SMTP is enabled

SSMTP_CONF="/etc/ssmtp/ssmtp.conf"
if [[ "$SMTP_ENABLED" != "1" ]]; then
    echo "SMTP is not enabled. Exiting."
else
    # Create or overwrite the ssmtp.conf file
    {
        echo "mailhub=${SMTP_HOST}:${SMTP_PORT}"
        echo "AuthUser=${SMTP_USERNAME}"
        echo "AuthPass=${SMTP_PASSWORD}"

        # Configure encryption based on the SMTP_ENCRYPTION setting
        if [[ "$SMTP_ENCRYPTION" == "starttls" ]]; then
            echo "UseSTARTTLS=YES"
        elif [[ "$SMTP_ENCRYPTION" == "tls" ]]; then
            echo "UseTLS=YES"
        fi

        # Optional TLS certificate verification
        if [[ "$SMTP_TLSVERIFY" == "1" ]]; then
            echo "TLS_CA_File=/etc/ssl/certs/ca-certificates.crt"
            echo "TLS_CA_Dir=/etc/ssl/certs"
        fi

        # echo "hostname=$(hostname)"
        echo "FromLineOverride=YES"
    } > /etc/ssmtp/ssmtp.conf

    echo "ssmtp.conf has been configured."
fi

echo "Editing APACHE_RUN_GROUP environment variable"
sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=staff/" /etc/apache2/envvars

if [ -n "$APACHE_ROOT" ];then
    echo "Linking /var/www/html to the Apache root"
    rm -f /var/www/html && ln -s "/app/${APACHE_ROOT}" /var/www/html
fi
# log apache to stderr
ln -sf /dev/stderr /var/log/apache2/access.log
ln -sf /dev/stderr /var/log/apache2/error.log

# create a .htacess file if not exists
if [ ! -f /app/.htaccess ]; then
    echo "Creating .htaccess file"
    {
        echo "# write your custom settings, uncomment or add your directives"
        echo "# php_value max_execution_time 600"
        echo "# php_value max_input_time 600"
        echo "# php_value memory_limit 512M" 
    } > /app/.htaccess
    # set the permissions
    chmod 644 /app/.htaccess
    chown www-data:staff /app/.htaccess
    echo "The .htaccess file has been created"
else
    echo "The .htaccess file already exists"
fi

echo "Editing phpmyadmin config"
sed -i "s/cfg\['blowfish_secret'\] = ''/cfg['blowfish_secret'] = '`openssl rand -hex 16`'/" /var/www/phpmyadmin/config.inc.php

echo "Setting up MySQL directories"
mkdir -p /var/run/mysqld
mkdir -p /var/log/mysql

# Setup user and permissions for MySQL and Apache
chmod -R 770 /var/lib/mysql
chmod -R 770 /var/run/mysqld
chmod -R 770 /var/log/mysql
touch /var/log/mysql/error.log


echo "Allowing Apache/PHP to write to the app"
# Tweaks to give Apache/PHP write permissions to the app
chown -R www-data:staff /var/www
chown -R www-data:staff /app


echo "Allowing Apache/PHP to write to MySQL"
chown -R www-data:staff /var/lib/mysql
chown -R www-data:staff /var/run/mysqld
# chown -R www-data:staff /var/log/mysql

# Listen only on IPv4 addresses
sed -i 's/^Listen .*/Listen 0.0.0.0:80/' /etc/apache2/ports.conf

if [ -e /var/run/mysqld/mysqld.sock ];then
    echo "Removing MySQL socket"
    rm /var/run/mysqld/mysqld.sock
fi

echo "Editing MySQL config"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i "s/user.*/user = www-data/" /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i "s|#log_error = /var/log/mysql/error.log|log_error = /var/log/mysql/error.log|" /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i "s/skip_log_error/#skip_log_error/" /etc/mysql/mariadb.conf.d/50-mysqld_safe.cnf
sed -i "s/syslog/#syslog/" /etc/mysql/mariadb.conf.d/50-mysqld_safe.cnf

# log mysql to stderr
ln -sf /dev/stderr /var/log/mysql/error.log

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."

    # Try the 'preferred' solution
    mariadb-install-db --user=root --auth-root-authentication-method=socket --skip-test-db 
    if [ $? -ne 0 ]; then
        # Fall back to the 'depreciated' solution
        mysql_install_db > /dev/null 2>&1
    fi

    echo "=> Done!"
    /mysql_init.sh
else
    echo "=> Using an existing volume of MySQL"
fi
echo "Starting supervisord"
exec supervisord -c /etc/supervisor/supervisord.conf -n
