FROM php:8.2-fpm-bookworm

# PORT: listen port (8080 matches Azure Container Apps ingress defaults)
# WEB_BIND: 0.0.0.0 allows public IP / ACA ingress access
# USE_EMBEDDED_DB: auto | true | false (auto=false when DB_HOST is external)
ENV PORT=8080 \
    WEB_BIND=0.0.0.0 \
    USE_EMBEDDED_DB=auto \
    DB_HOST=127.0.0.1 \
    DB_PORT=3306 \
    DB_NAME=crud \
    DB_USER=cruduser \
    DB_PASSWORD=crudpass \
    DB_ROOT_PASSWORD=rootpass \
    DB_SSL=false

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx \
        mariadb-server \
        supervisor \
        gettext-base \
    && docker-php-ext-install pdo pdo_mysql \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY . /var/www/html
COPY crud.sql /docker-init/crud.sql
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/supervisord.embedded.conf /etc/supervisor/conf.d/supervisord.embedded.conf
COPY docker/supervisord.app.conf /etc/supervisor/conf.d/supervisord.app.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf \
    && chown -R www-data:www-data /var/www/html \
    && mkdir -p /var/run/mysqld \
    && chown mysql:mysql /var/run/mysqld /var/lib/mysql

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
