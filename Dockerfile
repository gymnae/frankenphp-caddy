# syntax=docker/dockerfile:1

# Pin the PHP minor version explicitly. The untagged `dunglas/frankenphp` /
# `:builder` images follow the newest PHP release (8.6 since FrankenPHP 1.14),
# which Nextcloud does not support yet and which several PECL extensions
# (e.g. APCu) do not build against.
ARG FRANKENPHP_VERSION=1
ARG PHP_VERSION=8.5
ARG DEBIAN_VARIANT=trixie

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-builder-php${PHP_VERSION}-${DEBIAN_VARIANT} AS builder

# Copy xcaddy in the builder image
COPY --from=caddy:builder /usr/bin/xcaddy /usr/bin/xcaddy

# CGO must be enabled to build FrankenPHP
RUN CGO_ENABLED=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s' -trimpath -tags=nobadger,nomysql,nopgx" \
    CGO_CFLAGS=$(php-config --includes) \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
        --output /usr/local/bin/frankenphp \
        --with github.com/dunglas/frankenphp=./ \
        --with github.com/dunglas/frankenphp/caddy=./caddy/ \
        --with github.com/dunglas/caddy-cbrotli \
        --with github.com/greenpau/caddy-security \
        --with github.com/WeidiDeng/caddy-cloudflare-ip \
        --with github.com/caddyserver/replace-response \
        --with github.com/fvbommel/caddy-combine-ip-ranges \
    && /usr/local/bin/frankenphp version

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-${DEBIAN_VARIANT} AS runner

# Replace the official binary with the one containing the extra Caddy modules
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

# PHP extensions required/recommended by Nextcloud that are not already part
# of the base image (ctype, curl, dom, fileinfo, filter, hash, iconv, json,
# libxml, mbstring, openssl, pdo, posix, session, simplexml, xml*, zlib and
# opcache are built in).
RUN install-php-extensions \
        apcu \
        bcmath \
        bz2 \
        exif \
        gd \
        gmp \
        imagick \
        intl \
        memcached \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        redis \
        sysvsem \
        zip

# Production php.ini plus Nextcloud-oriented tuning
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY php/zz-nextcloud.ini $PHP_INI_DIR/conf.d/zz-nextcloud.ini

# 443/udp is needed for HTTP/3
EXPOSE 80 443 443/udp

# Run unprivileged. www-data (uid/gid 33) matches the official Nextcloud
# images, so existing php-fpm data/config volumes keep working unchanged.
ARG USER=www-data
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp \
    && chown -R ${USER}:${USER} /config/caddy /data/caddy /app
USER ${USER}
