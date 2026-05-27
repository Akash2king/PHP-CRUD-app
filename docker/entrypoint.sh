#!/bin/bash
set -e

export PORT="${PORT:-8080}"
export WEB_BIND="${WEB_BIND:-0.0.0.0}"

resolve_embedded_db() {
    case "${USE_EMBEDDED_DB:-auto}" in
        true|1|yes)
            echo "true"
            ;;
        false|0|no)
            echo "false"
            ;;
        auto|*)
            if [ "${DB_HOST}" = "127.0.0.1" ] || [ "${DB_HOST}" = "localhost" ]; then
                echo "true"
            else
                echo "false"
            fi
            ;;
    esac
}

mysql_ssl_args() {
    if [ "${DB_SSL}" = "true" ] || [ "${DB_SSL}" = "1" ]; then
        echo "--ssl-mode=REQUIRED"
    fi
}

mysql_ready() {
    mysqladmin ping --silent 2>/dev/null
}

wait_for_mysql() {
    local host="$1"
    local port="$2"
    echo "Waiting for MySQL at ${host}:${port}..."
    for _ in $(seq 1 90); do
        if php -r "
            \$opts = [];
            if (in_array(getenv('DB_SSL'), ['1', 'true', 'yes'], true)) {
                \$opts[PDO::MYSQL_ATTR_SSL_CA] = getenv('DB_SSL_CA') ?: '/etc/ssl/certs/ca-certificates.crt';
            }
            try {
                new PDO(
                    'mysql:host=${host};port=${port}',
                    getenv('DB_USER') ?: 'root',
                    getenv('DB_PASSWORD') ?: '',
                    \$opts
                );
                exit(0);
            } catch (Exception \$e) {
                exit(1);
            }
        " 2>/dev/null; then
            echo "MySQL is ready."
            return 0
        fi
        sleep 2
    done
    echo "MySQL did not become ready in time."
    exit 1
}

import_schema_if_needed() {
  local has_tables
  has_tables=$(mysql $(mysql_ssl_args) -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" \
    -N -e "SHOW TABLES LIKE 'notes';" 2>/dev/null || true)

  if [ -n "${has_tables}" ]; then
    echo "Database schema already present."
    return 0
  fi

  echo "Importing schema into ${DB_NAME}..."
  mysql $(mysql_ssl_args) -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" < /docker-init/crud.sql
  echo "Schema imported."
}

init_embedded_database() {
    if [ -f /var/lib/mysql/.docker-initialized ]; then
        return 0
    fi

    echo "Initializing embedded database..."

    if [ ! -d /var/lib/mysql/mysql ]; then
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal
    fi

    mysqld --user=mysql --datadir=/var/lib/mysql &
    mysqld_pid=$!

    for _ in $(seq 1 60); do
        if mysql_ready; then
            break
        fi
        sleep 1
    done

    if ! mysql_ready; then
        echo "MariaDB failed to start during initialization."
        exit 1
    fi

    mysql -uroot <<-EOSQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
        CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
        FLUSH PRIVILEGES;
EOSQL

    mysql -uroot -p"${DB_ROOT_PASSWORD}" "${DB_NAME}" < /docker-init/crud.sql
    touch /var/lib/mysql/.docker-initialized

    mysqladmin -uroot -p"${DB_ROOT_PASSWORD}" shutdown
    wait "${mysqld_pid}" 2>/dev/null || true

    echo "Embedded database initialized."
}

configure_nginx() {
    envsubst '${PORT} ${WEB_BIND}' < /etc/nginx/templates/default.conf.template \
        > /etc/nginx/conf.d/default.conf
    echo "Nginx listening on ${WEB_BIND}:${PORT}"
}

USE_EMBEDDED_DB="$(resolve_embedded_db)"
configure_nginx

if [ "${USE_EMBEDDED_DB}" = "true" ]; then
    init_embedded_database
    SUPERVISOR_CONFIG="/etc/supervisor/conf.d/supervisord.embedded.conf"
else
    wait_for_mysql "${DB_HOST}" "${DB_PORT}"
    import_schema_if_needed
    SUPERVISOR_CONFIG="/etc/supervisor/conf.d/supervisord.app.conf"
fi

echo "Starting app (embedded_db=${USE_EMBEDDED_DB})..."
exec /usr/bin/supervisord -n -c "${SUPERVISOR_CONFIG}"
