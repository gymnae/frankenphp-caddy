FROM dunglas/frankenphp:builder AS builder

# Copy xcaddy in the builder image
COPY --from=caddy:builder /usr/bin/xcaddy /usr/bin/xcaddy

# CGO must be enabled to build FrankenPHP
RUN CGO_ENABLED=1 \
    XCADDY_SETCAP=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s' -tags=nobadger,nomysql,nopgx" \
    CGO_CFLAGS=$(php-config --includes) \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
        --output /usr/local/bin/frankenphp \
        --with github.com/dunglas/frankenphp=./ \
        --with github.com/dunglas/frankenphp/caddy=./caddy/ \
        --with github.com/dunglas/caddy-cbrotli \
        ## Mercure and Vulcain are included in the official build, but feel free to remove them
        #--with github.com/dunglas/mercure/caddy \
        #--with github.com/dunglas/vulcain/caddy
        # Add extra Caddy modules here
		--with github.com/greenpau/caddy-security \  
		--with github.com/WeidiDeng/caddy-cloudflare-ip \
		--with github.com/caddyserver/replace-response \
		--with github.com/fvbommel/caddy-combine-ip-ranges

FROM dunglas/frankenphp AS runner

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
