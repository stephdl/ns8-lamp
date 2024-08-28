#!/bin/bash
#
# Prepare our container for initial boot.

set -e 
# Redirect any output to the journal (stderr)
exec 1>&2

# writing ssmtp.conf
# Check if SMTP is enabled

echo "Editing ssmtp.conf"
if [[ "$SMTP_ENABLED" != "1" ]]; then
    echo "SMTP relay settings from cluster-admin is not enabled. Exiting."
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
    echo "The .htaccess file has been created"
else
    echo "The .htaccess file already exists"
fi

echo "Editing Mysql config"
if [ -e /var/run/mysqld/mysqld.sock ];then
    echo "Removing MySQL socket"
    rm /var/run/mysqld/mysqld.sock
fi


if [[ ! -d /var/lib/mysql/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in /var/lib/mysql"
    echo "=> Installing or restoring MySQL ..."

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
