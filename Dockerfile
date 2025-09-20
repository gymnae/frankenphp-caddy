FROM dunglas/frankenphp:alpine

## install php extensions commonly used
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

## add some basic packages for QoL
RUN apk add --no-cache \
	git \
 	nano \
  	htop
   	
EXPOSE 443 80
 
## change the user to leave root behind
ARG USER=caddy
RUN \
	# Use "adduser -D ${USER}" for alpine based distros
	adduser ${USER}; \
	# Add additional capability to bind to port 80 and 443
	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp; \
	# Give write access to /config/caddy and /data/caddy
	chown -R ${USER}:${USER} /config/caddy /data/caddy /app/public
USER ${USER}
