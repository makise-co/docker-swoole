FROM php:7.4-cli-alpine
LABEL maintainer="Dmitry K. coder1994@gmail.com"

# Build threads count
ENV NPROC=4

# iconv fix for Alpine
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Dependencies versions
ENV SWOOLE_VERSION 4.5.5
ENV LIBPQ_VERSION 12_2

# Installing PHP extensions
RUN apk update \
    && apk add --no-cache unzip nghttp2-libs \
    && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache --virtual .php-deps \
        icu-dev \
        libzip-dev \
        libxml2-dev \
        openssl-dev \
        oniguruma-dev \
        nghttp2-dev \
        bison \
# add work-around for iconv (https://github.com/docker-library/php/issues/240#issuecomment-305038173)
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv \
# Install sockets extension before swoole
    && docker-php-source extract \
    && docker-php-ext-configure sockets \
    && cd /usr/src/php/ext/sockets; make -j${NPROC}; make install; cd - \
    && docker-php-ext-enable --ini-name=10-sockets.ini sockets \
    && docker-php-source delete \
    && php --ri sockets \
# Swoole
    && curl https://codeload.github.com/swoole/swoole-src/zip/v$SWOOLE_VERSION > swoole.zip \
    && unzip -qq swoole.zip && mv swoole-src-$SWOOLE_VERSION swoole \
    && cd swoole; phpize; ./configure --enable-sockets --enable-openssl --enable-http2; make -j${NPROC}; make install; cd - \
    # Clean-up
    && rm swoole.zip; rm -rf swoole; docker-php-source delete \
    # Enable swoole extension with lower priority than pdo_pgsql
    && docker-php-ext-enable --ini-name 15-swoole.ini swoole \
    && php --ri swoole \
# libpq
    && curl https://codeload.github.com/postgres/postgres/zip/REL_$LIBPQ_VERSION > postgres.zip \
    && unzip -qq postgres.zip && mv postgres-REL_$LIBPQ_VERSION postgres \
    && cd postgres; ./configure --with-openssl --without-readline --without-zlib; cd - \
    && cd postgres/src/interfaces/libpq; make; make install; cd - \
    && cd postgres/src/bin/pg_config; make install; cd -; /usr/local/pgsql/bin/pg_config \
    && cd postgres/src/backend; make generated-headers; cd - \
    && cd postgres/src/include; make install; cd - \
    # Clean-up
    && rm postgres.zip && rm -rf postgres \
# pq extenstion
    && pecl install raphf && docker-php-ext-enable --ini-name 10-raphf.ini raphf \
    && pecl install --onlyreqdeps --nobuild pq && \
        cd "$(pecl config-get temp_dir)/pq" && \
        phpize && \
        ./configure --with-pq=/usr/local/pgsql && \
        make -j${NPROC} && make install && \
        # Enable pq with lower priority than raphf
        docker-php-ext-enable --ini-name 11-pq.ini pq && \
        cd - \
# Another php extensions
    && docker-php-ext-install -j${NPROC} \
        zip \
        exif \
        pcntl \
        opcache \
        bcmath \
        iconv \
        intl \
        soap \
        pdo_mysql \
        pdo_pgsql \
    && pecl install redis \
    && docker-php-ext-enable redis \
# Remove unnecessary dependencies
    && apk del --no-network .phpize-deps \
    && apk del --no-network .php-deps

# Additional dependencies for PHP extensions
RUN apk add --no-cache icu-libs libzip libstdc++

# Check PHP modules working
RUN php --ri mbstring && php --ri zip && php --ri pcntl \
    && php --ri bcmath && php --ri sockets && php --ri iconv && php --ri intl \
    && php --ri soap \
    && php --ri swoole && php --ri pdo_pgsql && php --ri pdo_mysql && php --ri pq \
    && php --ri redis

# install nginx
RUN apk add --no-cache nginx

# Installing composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install composer parallel packages installer plugin
RUN composer global require hirak/prestissimo

# set-up php config
COPY php/php.ini /usr/local/etc/php/

# set-up nginx config
COPY nginx/default.conf /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# forward nginx request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

# test nginx works
RUN nginx -t

# Changing Workdir
WORKDIR /var/www/app
