APP_PORT=${PORT:-5000}
ADDR_BIND=${ADDR:-0.0.0.0}
WORKER=${WORKER_COUNT:-4}

gunicorn -w $WORKER -b $ADDR_BIND:$APP_PORT --access-logfile=- 'index:app'