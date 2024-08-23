#!/bin/bash

mysqld_safe --socket=/var/run/mysqld/mysqld.sock --user=root > /dev/null 2>&1 &
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

PASS=${MYSQL_ADMIN_PASS:-$(pwgen -s 12 1)}
_word=$( [ ${MYSQL_ADMIN_PASS} ] && echo "preset" || echo "random" )
echo "=> Creating MySQL admin user with password"

mysql -uroot -e "CREATE USER 'admin'@'%' IDENTIFIED BY '$PASS'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION"
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS phpmyadmin"
# mysql -uroot -e "CREATE USER 'pma'@'localhost' IDENTIFIED BY ''"
# mysql -uroot -e " GRANT ALL PRIVILEGES ON phpmyadmin.* TO  'pma'@'localhost'"
mysql -uroot -e "CREATE USER 'version_user'@'localhost' IDENTIFIED BY 'version_password'";
mysql -uroot -e "GRANT SELECT ON mysql.version TO 'version_user'@'localhost'"

# Create a new database and for phpmyadmin
mysql < /var/www/phpMyAdmin-*/sql/create_tables.sql

CREATE_MYSQL_USER=false

if [ -n "$CREATE_MYSQL_BASIC_USER_AND_DB" ] || \
   [ -n "$MYSQL_USER_NAME" ] || \
   [ -n "$MYSQL_USER_DB" ] || \
   [ -n "$MYSQL_USER_PASS" ]; then
      CREATE_MYSQL_USER=true
fi

if [ "$CREATE_MYSQL_USER" = true ]; then
    _user=${MYSQL_USER_NAME:-user}
    _userdb=${MYSQL_USER_DB:-db}
    _userpass=${MYSQL_USER_PASS:-password}

    mysql -uroot -e "CREATE USER '${_user}'@'%' IDENTIFIED BY  '${_userpass}'"
    mysql -uroot -e "GRANT USAGE ON *.* TO  '${_user}'@'%' IDENTIFIED BY '${_userpass}'"
    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${_userdb}"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON ${_userdb}.* TO '${_user}'@'%'"
fi

if [[ -e /db/init.sql ]]; then
    echo "=> Initializing the database"

    mysql -uroot < /db/init.sql
fi

echo "=> Done!"

echo "========================================================================"
echo "You can now connect to this MySQL Server using: podman exec -ti lamp-app mysql"
echo ""
echo "MySQL user 'root' has no password but only allows local connections"
echo ""

if [ "$CREATE_MYSQL_USER" = true ]; then
    echo "We also created"
    echo "A database called '${_userdb}' and"
    echo "a user called '${_user}' with password"
    echo "'${_user}' has full access on '${_userdb}'"
fi

echo "enjoy!"
echo "========================================================================"

mysqladmin -uroot shutdown
