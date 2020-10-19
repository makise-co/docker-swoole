#!/usr/bin/env sh

# optionally enable auto migrations
# but recommend way is to run migrations in one container before deploying the app
#if [[ -n "$SHOULD_MIGRATE" ]]; then
    # Run migrations
    #php artisan migrate --force;
#fi

http() {
    makise_pid=0
    nginx_pid=0

    # SIGTERM-handler
    term_handler() {
        # gracefully stopping nginx
        if [ $nginx_pid -ne 0 ]; then
            echo "Stopping nginx"
            kill -SIGQUIT "$nginx_pid"
            wait "$nginx_pid"
        fi

        # gracefully stopping app
        if [ $makise_pid -ne 0 ]; then
            echo "Stopping application"
            kill -SIGTERM "$makise_pid"
            wait "$makise_pid"
        fi

        exit 0; # or exit 143; 128 + 15 -- SIGTERM
    }

    # Trap terminating signals
    trap 'term_handler' SIGUSR1
    trap 'term_handler' SIGTERM

    # run application
    php artisan swoole:http start &
    makise_pid="$!"

    nginx -g 'daemon off;' &
    nginx_pid="$!"

    # wait for makise app terminating
    wait ${makise_pid}
}

queue() {
    # "default" is your queue connection name
    exec php artisan queue:work default --queue="$START_QUEUE" --memory="$MEMORY" --tries="$TRIES" --timeout="$TIMEOUT"
}

schedule() {
    exec /usr/sbin/crond -f -d 8 -L /dev/stdout
}

# for queue workers
if [[ -n "$START_QUEUE" ]]; then
    queue;
# for Laravel Scheduler
elif [[ -n "$START_SCHEDULE" ]]; then
    schedule;
# Everything else is fallback to HTTP server
else
    http;
fi
