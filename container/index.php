<!doctype html>
<html lang=en>

<head>
    <meta charset=utf-8>
    <title>Hello World from NS8-LAMP</title>

    <style>
        @import 'https://fonts.googleapis.com/css?family=Montserrat|Raleway|Source+Code+Pro';

        body {
            font-family: 'Raleway', sans-serif;
        }

        h2 {
            font-family: 'Montserrat', sans-serif;
        }

        pre {
            font-family: 'Source Code Pro', monospace;
            padding: 16px;
            overflow: auto;
            font-size: 85%;
            line-height: 1.45;
            background-color: #f7f7f7;
            border-radius: 3px;
            word-wrap: normal;
        }

        .container {
            max-width: 1024px;
            width: 100%;
            margin: 0 auto;
        }

        .warning {
            background-color: #ffeeba;
            color: #856404;
            padding: 10px;
            border: 1px solid #ffeeba;
            border-radius: 5px;
            margin-top: 20px;
        }

        .warning-icon {
            font-weight: bold;
            color: #856404;
            margin-right: 5px;
        }
    </style>
</head>

<body>
    <div class="container">
        <header>
            <h2>Welcome to <a href="https://github.com/stephdl/ns8-lamp" target="_blank">ns8-Lamp</a> a.k.a
                stephdl/ns8-lamp</h2>
        </header>
        <article>
            <p>For documentation, <a href="https://github.com/stephdl/ns8-lamp" target="_blank">click here</a>.</p>
            <p>For PHP information, <a href="phpinfo.php" target="_blank">click here</a>.</p>

            <div class="warning">
                <span class="warning-icon">⚠️</span>
                <strong>Important:</strong> Please delete the <code>phpinfo.php</code> file after installing the web
                application to avoid exposing sensitive information.
            </div>
        </article>
        <section>
            <pre>
OS: <?php echo $osInfo['pretty_name']; ?><br/>
Apache: <?php echo apache_get_version(); ?><br/>
MySQL Version: <?php echo $db->getAttribute(PDO::ATTR_SERVER_VERSION); ?><br/>
PHP Version: <?php echo phpversion(); ?><br/>
phpMyAdmin Version: <?php echo getenv('PHPMYADMIN_VERSION'); ?>
            </pre>
        </section>
    </div>
</body>

</html>
