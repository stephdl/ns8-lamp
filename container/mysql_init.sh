#!/bin/bash

set -e 
# Redirect any output to the journal (stderr)
exec 1>&2

mysqld_safe --socket=/var/run/mysqld/mysqld.sock --user=root > /dev/null 2>&1 &
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

if [[ -f "/initdb.d/lamp.sql" ]]; then
    echo "=> Found lamp.sql, restoring database"
    mysql -uroot < /initdb.d/lamp.sql
    if [[ $? -eq 0 ]]; then
        echo "=> lamp.sql successfully imported."
        rm -rf /initdb.d/lamp.sql
        mysqladmin -uroot shutdown
    else
        echo "=> lamp.sql import failed."
        exit 1
    fi
else
    echo "=> No lamp.sql found we do the mysql init"

    PASS=${MYSQL_ADMIN_PASS:-$(pwgen -s 12 1)}
    _word=$( [ ${MYSQL_ADMIN_PASS} ] && echo "preset" || echo "random" )
    echo "=> Creating MySQL admin user with password"
    mysql -uroot -e "CREATE USER 'admin'@'%' IDENTIFIED BY '$PASS'"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION"
    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS phpmyadmin"

    echo "create version_user for mysql version"
    mysql -uroot -e "CREATE USER 'version_user'@'localhost' IDENTIFIED BY 'version_password'";
    mysql -uroot -e "GRANT USAGE ON *.* TO 'version_user'@'localhost';"

    echo "Create a new database and for phpmyadmin"
    mysql -uroot < /var/www/phpMyAdmin-*/sql/create_tables.sql

    CREATE_MYSQL_USER="False"

    if [ "$CREATE_MYSQL_USER" == "True" ]; then
        _user=${MYSQL_USER_NAME:?}
        _userdb=${MYSQL_USER_DB:?}
        _userpass=${MYSQL_USER_PASS:?}
        echo "create a new user  ${_user} with  database ${_userdb}"
        mysql -uroot -e "CREATE USER '${_user}'@'%' IDENTIFIED BY  '${_userpass}'"
        mysql -uroot -e "GRANT USAGE ON *.* TO  '${_user}'@'%' IDENTIFIED BY '${_userpass}'"
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${_userdb}"
        mysql -uroot -e "GRANT ALL PRIVILEGES ON ${_userdb}.* TO '${_user}'@'%'"
    fi

    echo "=> Done!"

    echo "========================================================================"
    echo "You can now connect to this MySQL Server using: podman exec -ti lamp-app mysql"
    echo ""
    echo "MySQL user 'root' has no password but only allows local connections"
    echo ""

    if [ "$CREATE_MYSQL_USER" == "True" ]; then
        echo "We also created"
        echo "A database called '${_userdb}' and"
        echo "a user called '${_user}' with password"
        echo "'${_user}' has full access on '${_userdb}'"
    fi

    echo "enjoy!"
    echo "========================================================================"

    mysqladmin -uroot shutdown

fi
