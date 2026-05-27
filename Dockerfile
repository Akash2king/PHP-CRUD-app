FROM php:8.2-fpm-bookworm AS build
RUN docker-php-ext-install pdo pdo_mysql

FROM php:8.2-fpm-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends nginx supervisor default-mysql-client gettext-base \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
WORKDIR /var/www/html
COPY . /var/www/html
COPY crud.sql /docker-init/crud.sql
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /usr/local/bin/entrypoint.sh && rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf
ENV PORT=8080 WEB_BIND=0.0.0.0 DB_PORT=3306 DB_NAME=crud DB_SSL=true
ENV DB_HOST="" DB_USER="" DB_PASSWORD=""
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
