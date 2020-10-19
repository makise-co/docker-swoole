# docker-swoole
Alpine Docker image with nginx as proxy server and PHP with Swoole.

This image is optimized for cloud environments.

Nginx features:
* nginx as proxy server to the backend app (app should listen on port 1215)
* nginx write logs to stdout/stderr
* nginx write access logs in JSON format (it easily can be parsed by ELK)
* nginx supports X-Request-ID header and passing it to the app server. 
You can disable this behavior by overriding `/etc/nginx/conf.d/default.conf` file.

PHP features:
* Version: 7.4
* OPcache is enabled for CLI apps
* Memory limit is increased to 512M
* Composer (with parallel packages install plugin) is on board
* Extensions:
    * swoole
    * sockets
    * pq
    * zip
    * exif
    * pcntl
    * opcache
    * bcmath
    * iconv
    * intl
    * soap
    * pdo_mysql
    * pdo_pgsql
    * redis

Examples can be found [here](example).
