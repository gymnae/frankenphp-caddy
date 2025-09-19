FROM dunglas/frankenphp:alpine

RUN install-php-extensions \
 gd \
 ctype \
 curl \
 dom \
 filter \
 hash \
 iconv \
 json \
 libxml \
 mbstring \
 openssl \
 SimpleXML \
 exif \
 fileinfo \
 intl \
 apcu \
 memcached \
 PDO \
 zip \
 zlib \
 opcache

 ENV FRANKENPHP_CONFIG="worker ./public/index.php"

 ARG USER=caddy

RUN \
	# Use "adduser -D ${USER}" for alpine based distros
	useradd ${USER}; \
	# Add additional capability to bind to port 80 and 443
	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp; \
	# Give write access to /config/caddy and /data/caddy
	chown -R ${USER}:${USER} /config/caddy /data/caddy

USER ${USER}
