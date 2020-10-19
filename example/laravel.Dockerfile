FROM phpmakise/php-swoole:lastest
LABEL maintainer="yourmail@yourhost.com"

# Determine is it dev build
ARG DEV=1

# copy composer files
COPY composer.json composer.lock ./

# Install dependencies
RUN if [ $DEV -eq 1 ]; then \
    composer install --no-autoloader; \
    else \
    composer install --no-dev --no-autoloader; \
    fi

# copy app files
COPY app ./app/
COPY bootstrap ./bootstrap/
COPY config ./config/
COPY database ./database/
COPY public ./public/
COPY routes ./routes/
COPY storage ./storage/
# Optionally you can disable tests directory copying
COPY tests ./tests/
COPY artisan phpunit.xml ./

# Create cache dir for laravel views
RUN mkdir -p ./storage/framework/views

# dump autoload
RUN if [ $DEV -eq 1 ]; then \
    composer dump-autoload -o; \
    else \
    composer dump-autoload -a; \
    fi

# Create .env file to bypass Laravel errors
RUN touch -a .env

# Create link to stroage path
RUN php artisan storage:link

# Optionally you can disable copying of static swagger docs
COPY swagger /var/www/html/swagger

# Copy entry point
COPY laravel-entrypoint.sh /entrypoint.sh

# Optionally put Laravel Scheduler invocation to the crontab
RUN echo '* * * * * cd /var/www/app && php artisan schedule:run' > /etc/crontabs/root

STOPSIGNAL SIGTERM

CMD ["/entrypoint.sh"]
