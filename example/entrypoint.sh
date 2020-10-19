#!/usr/bin/env sh

makise_pid=0
nginx_pid=0

# SIGTERM-handler
term_handler() {
    # gracefully stopping nginx
    if [ $nginx_pid -ne 0 ]; then
        echo "{\"message\": \"Stopping nginx\"}"

        kill -SIGQUIT "$nginx_pid"
        wait "$nginx_pid"
    fi

    # gracefully stopping app
    if [ $makise_pid -ne 0 ]; then
        echo "{\"message\": \"Stopping application\"}"

        # for app graceful shutdown app should implement SIGTERM listener
        kill -SIGTERM "$makise_pid"
        wait "$makise_pid"
    fi

    exit 0 # or exit 143; 128 + 15 -- SIGTERM
}

# Trap terminating signals
trap 'term_handler' SIGUSR1
trap 'term_handler' SIGTERM

# run application
php makise http:start --host=127.0.0.1 --port=1215 &
makise_pid="$!"

nginx &
nginx_pid="$!"

# wait for makise app terminating
wait ${makise_pid}
