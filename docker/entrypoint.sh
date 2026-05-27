#!/bin/bash
set -e

for env_file in /run/config/.env /var/www/html/.env; do
  [ -f "${env_file}" ] || continue
  while IFS= read -r line || [ -n "${line}" ]; do
    case "${line}" in ''|\#*) continue ;; *=*)
      k="${line%%=*}"; v="${line#*=}"
      [ -z "${!k+x}" ] && export "${k}=${v}"
    esac
  done < "${env_file}"
done

mysql_ssl() { [ "${DB_SSL}" = "true" ] || [ "${DB_SSL}" = "1" ] && echo "--ssl"; }

wait_for_mysql() {
  echo "Waiting for ${DB_HOST}..."
  for _ in $(seq 1 90); do
    php -r "
      \$o = [];
      if (in_array(getenv('DB_SSL'), ['1','true','yes'], true))
        \$o[PDO::MYSQL_ATTR_SSL_CA] = '/etc/ssl/certs/ca-certificates.crt';
      try { new PDO('mysql:host='.getenv('DB_HOST').';port='.getenv('DB_PORT'), getenv('DB_USER'), getenv('DB_PASSWORD'), \$o); exit(0); }
      catch (Exception \$e) { exit(1); }
    " && echo "MySQL ready." && return 0
    sleep 2
  done
  echo "MySQL timeout." && exit 1
}

import_schema() {
  count=$(mysql $(mysql_ssl) -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" \
    -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}' AND table_name IN ('notes','user');" 2>/dev/null || echo 0)
  [ "${count}" = "2" ] && echo "Schema exists." && return 0
  echo "Importing schema..."
  mysql $(mysql_ssl) -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" < /docker-init/crud.sql
}

envsubst '${PORT} ${WEB_BIND}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf
wait_for_mysql
import_schema
exec supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
