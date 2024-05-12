ARG WP_IMG_BASE_VERSION=6.1.1
ARG PHP_VERSION=8.1
ARG UNIT_VERSION=1.30.0



################################################
# Tag official WordPress image resources       #
################################################
FROM wordpress:${WP_IMG_BASE_VERSION}-php${PHP_VERSION}-fpm-alpine AS wordpress



################################################
# Build rootfs                                 #
################################################
FROM scratch AS rootfs

# Install attr utility
COPY --from=nlss/attr ["/usr/local/bin/attr", "/usr/local/bin/"]

# Add crond service
COPY --from=ghcr.io/n0rthernl1ghts/base-alpine:3.17 ["/etc/services.d/cron/", "/etc/services.d/cron/"]

# WordPress specific php configuration
COPY --from=wordpress ["/usr/local/etc/php/conf.d/opcache-recommended.ini", "/usr/local/etc/php/conf.d/error-logging.ini", "/usr/local/etc/php/conf.d/"]

# Overlay
COPY ["./rootfs/", "/"]



################################################
# Final stage                                  #
################################################
ARG PHP_VERSION
ARG UNIT_VERSION
FROM --platform=${TARGETPLATFORM} ghcr.io/n0rthernl1ghts/unit-php:${UNIT_VERSION}-PHP${PHP_VERSION}

RUN set -eux \
    && apk add --update --no-cache bash tzdata imagemagick ghostscript \
    && apk add --no-cache --virtual .wp-build-deps \
       		${PHPIZE_DEPS:?} \
       		freetype-dev \
       		icu-dev \
       		imagemagick-dev \
       		libjpeg-turbo-dev \
       		libpng-dev \
       		libwebp-dev \
       		libzip-dev \
    && docker-php-ext-configure gd \
       		--with-freetype \
       		--with-jpeg \
       		--with-webp \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install -j "$(nproc)" \
       		bcmath \
       		exif \
       		gd \
       		intl \
       		mysqli \
            opcache \
       		zip \
    && pecl install apcu imagick-3.6.0 \
    && docker-php-ext-enable apcu imagick \
    && extDir="$(php -i | grep "^extension_dir" | awk -F'=>' '{print $2}' | xargs)" \
    && runDeps="$( \
       		scanelf --needed --nobanner --format '%n#p' --recursive "${extDir}" \
       			| tr ',' '\n' \
       			| sort -u \
       			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-network --virtual .wordpress-phpexts-rundeps ${runDeps} \
    && apk del --no-network .wp-build-deps \
    && php --version || exit 1 \
    && mkdir -p /var/www/html/wp-content/languages \
    && mkdir -p /var/www/html/wp-content/themes \
    && mkdir -p /var/www/html/wp-content/plugins \
    && mkdir -p /var/www/html/wp-content/uploads \
    && chown -R www-data:www-data /var/www/html/wp-content \
    && rm -rf /usr/src/php /var/cache/apk/* /tmp/*

COPY --from=rootfs ["/", "/"]

RUN echo "* * * * * /usr/local/bin/wp cron event run --due-now" >> /etc/crontabs/www-data

ENV S6_KEEP_ENV=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV CRON_ENABLED=true

ARG WP_IMG_BASE_VERSION
ENV WP_IMG_BASE_VERSION=${WP_IMG_BASE_VERSION}

LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>" \
      org.opencontainers.image.source="https://github.com/N0rthernL1ghts/wordpress-unit-base" \
      org.opencontainers.image.description="NGINX Unit Powered WordPress Base ${WP_IMG_BASE_VERSION} for n0rthernl1ghts/wordpress - Build ${TARGETPLATFORM}" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${WP_IMG_BASE_VERSION}"
ENTRYPOINT ["/init"]
EXPOSE 80/TCP
