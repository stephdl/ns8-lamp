# ns8-lamp


NS8-LAMP is a containerized environment that encapsulates the LAMP stack, which includes Linux (Ubuntu), Apache (web server), MariaDB (database), and PHP (scripting language). This container allows for easy deployment and management of web applications, providing consistency, portability, and isolation across different environments.

## Usage

Use the /app directory as the storage location for your web application. You can access it by running the following command:


    runagent -m lamp1 podman exec -ti lamp-app bash

Once inside the container, navigate to the /app directory:

`cd /app`

From here, you can download your web application files using one of the following methods:

- git:

    `git clone http://github.com/url/of/project`

- wget:
  
    `wget http://your-url`
  
- rsync:

    `rsync user@hostname:/path .`
  
- sftp:
  
    `sftp user@hostname`
  
- ftp:
  
    `ftp hostname`
  
- ftp-ssl:
  
    `ftp-ssl hostname`

Once your application files are in the /app directory, you can associate them with the Fully Qualified Domain Name (FQDN) set in the user interface.

You can also access phpMyAdmin by navigating to:

    https://FQDN/phpmyadmin

The username is admin, and the password is the one you set in the user interface.

## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/lamp:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "lamp1", "image_name": "lamp", "image_url": "ghcr.io/nethserver/lamp:latest"}

## Configure

Let's assume that the mattermost instance is named `lamp1`.

Launch `configure-module`, by setting the following parameters:
- `host`: a fully qualified domain name for the application
- `http2https`: enable or disable HTTP to HTTPS redirection (true/false)
- `lets_encrypt`: enable or disable Let's Encrypt certificate (true/false)
- `create_mysql_user`: create database and mysqluser (true/false)
- `mysql_admin_pass`: password of the mysql admin user of all databases
- `mysql_user_db`: database of the mysql user
- `mysql_user_name`: name of the mysql user
-  `mysql_user_pass`: password of the mysql user
-  `php_upload_max_filesize`: maximum file size and maximum post size in MB


Example:

```
api-cli run configure-module --agent module/lamp1 --data - <<EOF
{
    "create_mysql_user": true,
    "host": "lamp1.rocky9-pve.org",
    "http2https": false,
    "lets_encrypt": false,
    "mysql_admin_pass": "Nethesis,1234",
    "mysql_user_db": "foo",
    "mysql_user_name": "foo",
    "mysql_user_pass": "Nethesis,1234",
    "php_upload_max_filesize": "100"
}
EOF
```

The above command will:
- start and configure the lamp instance
- configure a virtual host for trafik to access the instance

## Get the configuration
You can retrieve the configuration with

```
api-cli run get-configuration --agent module/lamp1
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve lamp1

## Smarthost setting discovery

Some configuration settings, like the smarthost setup, are not part of the
`configure-module` action input: they are discovered by looking at some
Redis keys.  To ensure the module is always up-to-date with the
centralized [smarthost
setup](https://nethserver.github.io/ns8-core/core/smarthost/) every time
lamp starts, the command `bin/discover-smarthost` runs and refreshes
the `state/smarthost.env` file with fresh values from Redis.

Furthermore if smarthost setup is changed when lamp is already
running, the event handler `events/smarthost-changed/10reload_services`
restarts the main module service.

See also the `systemd/user/lamp.service` file.

This setting discovery is just an example to understand how the module is
expected to work: it can be rewritten or discarded completely.


We use ssmtp to handle sending emails from our server. The php.ini configuration is set to use the ssmtp -t command, allowing PHP to send emails seamlessly via ssmtp.
For other programming languages, ensure that they are configured to use the ssmtp command similarly, typically by setting their mail sending command or path to `ssmtp -t`,
just like in PHP. This way, all emails sent by different applications or scripts will be routed through ssmtp.

php settings example: `sendmail_path = /usr/sbin/ssmtp -t`

you can try by the command line to send an email with a php script

```
<?php
$to = 'recipient@example.com';
$subject = 'Test Email';
$message = 'This is a test email sent from PHP using ssmtp.';
$headers = 'From: your-email@example.com' . "\r\n" .
           'Reply-To: your-email@example.com' . "\r\n" .
           'X-Mailer: PHP/' . phpversion();

if(mail($to, $subject, $message, $headers)) {
    echo 'Email sent successfully!';
} else {
    echo 'Failed to send email.';
}
?>
```

execute it by : `php /path/2/script`

## Debug

some CLI are needed to debug

- The module runs under an agent that initiate a lot of environment variables (in /home/lamp1/.config/state), it could be nice to verify them
on the root terminal

    `runagent -m lamp1 env`

- you can become runagent for testing scripts and initiate all environment variables
  
    `runagent -m lamp1`

 the path become : 
```
    echo $PATH
    /home/lamp1/.config/bin:/usr/local/agent/pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/
```

- if you want to debug a container or see environment inside
 `runagent -m lamp1`
 ```
podman ps
CONTAINER ID  IMAGE                                      COMMAND               CREATED        STATUS        PORTS                    NAMES
d292c6ff28e9  localhost/podman-pause:4.6.1-1702418000                          9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  80b8de25945f-infra
d8df02bf6f4a  docker.io/library/mariadb:10.11.5          --character-set-s...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  mariadb-app
9e58e5bd676f  docker.io/library/nginx:stable-alpine3.17  nginx -g daemon o...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  lamp-app
```

you can see what environment variable is inside the container
```
podman exec  lamp-app env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
TERM=xterm
PKG_RELEASE=1
MARIADB_DB_HOST=127.0.0.1
MARIADB_DB_NAME=lamp
MARIADB_IMAGE=docker.io/mariadb:10.11.5
MARIADB_DB_TYPE=mysql
container=podman
NGINX_VERSION=1.24.0
NJS_VERSION=0.7.12
MARIADB_DB_USER=lamp
MARIADB_DB_PASSWORD=lamp
MARIADB_DB_PORT=3306
HOME=/root
```

you can run a shell inside the container

```
podman exec -ti   lamp-app sh
/ # 
```
## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/lamp:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org]((https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
