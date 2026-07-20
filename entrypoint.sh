#!/bin/bash
set -e

cd /home/frappe/frappe-bench

# Start Redis server in the background
redis-server --daemonize yes --port ${REDIS_PORT:-6379}
echo "Redis server started"

# Configure sites directory
echo "{}" > sites/common_site_config.json

# Build common_site_config.json from environment variables
bench set-config -g db_host "${DB_HOST:-db}"
bench set-config -g db_port "${DB_PORT:-3306}"
bench set-config -g db_user "${DB_USER:-root}"
bench set-config -g db_password "${DB_PASSWORD:-}"
bench set-config -g redis_cache "redis://${REDIS_HOST:-localhost}:${REDIS_PORT:-6379}/0"
bench set-config -g redis_queue "redis://${REDIS_HOST:-localhost}:${REDIS_PORT:-6379}/1"
bench set-config -g redis_socketio "redis://${REDIS_HOST:-localhost}:${REDIS_PORT:-6379}/2"
bench set-config -g socketio_port 9000

# Set root_login to the DB user (Railway uses 'railway' user, not 'root')
bench set-config -g root_login "${DB_USER:-root}"
bench set-config -g root_password "${DB_ROOT_PASSWORD:-${DB_PASSWORD}}"

# Set developer mode if needed
if [ "${DEVELOPER_MODE}" = "1" ]; then
    bench set-config -g developer_mode 1
fi

SITE_NAME="${SITE_NAME:-lms.localhost}"

# Check if the site already exists
if [ ! -d "sites/${SITE_NAME}" ]; then
    echo "Creating new site: ${SITE_NAME}"

    bench new-site "${SITE_NAME}" \
        --mariadb-root-password="${DB_ROOT_PASSWORD:-${DB_PASSWORD}}" \
        --admin-password="${ADMIN_PASSWORD:-admin}" \
        --no-mariadb-socket \
        --db-name="${DB_NAME:-_lms}" \
        --install-app lms

    echo "Site created successfully!"
else
    echo "Site ${SITE_NAME} already exists, running migrations..."
    bench --site "${SITE_NAME}" migrate
fi

# Set default site
bench use "${SITE_NAME}"

# Enable scheduler
bench --site "${SITE_NAME}" enable-scheduler || true

echo "Starting Frappe bench..."
# Start gunicorn on the Railway-assigned port
PORT="${PORT:-8000}"
exec bench serve --port "${PORT}"
