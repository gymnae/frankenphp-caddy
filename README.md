# frankenphp-caddy

Experimental FrankenPHP (Caddy + embedded PHP) base image, aimed at replacing a
Caddy + php-fpm stack for Nextcloud.

Image: `gymnae/frankenphp` — tags `latest`, `php8.5`, `php8.5-YYYYMMDD`
(linux/amd64, linux/arm64), rebuilt weekly.

## Contents

- FrankenPHP (Debian trixie, **PHP 8.5** — pinned on purpose: Nextcloud refuses PHP ≥ 8.6)
- Extra Caddy modules: `caddy-cbrotli`, `caddy-security`, `caddy-cloudflare-ip`,
  `replace-response`, `caddy-combine-ip-ranges`
- PHP extensions for Nextcloud: apcu, bcmath, bz2, exif, gd, gmp, imagick, intl,
  memcached, pcntl, pdo_mysql, pdo_pgsql, redis, sysvsem, zip (+ built-ins, OPcache)
- `php.ini-production` + [`php/zz-nextcloud.ini`](php/zz-nextcloud.ini) (memory, uploads, OPcache, APCu)
- Runs as `www-data` (uid 33), same as the official Nextcloud images, so existing
  volumes keep their ownership. Ports 80, 443, 443/udp (HTTP/3).

## Nextcloud notes

- Use FrankenPHP's classic mode (`php_server`), not worker mode; Nextcloud is not worker-safe.
- Mount the Nextcloud code at `/app/public` (or point `root` in your Caddyfile at it) and
  provide your own `/etc/frankenphp/Caddyfile`.
- Run `occ` and cron with the same image: `docker exec -u www-data <container> php occ ...`.

## Changing the PHP version

Set `PHP_VERSION` in `.github/workflows/docker-image.yaml` (and the default `ARG` in
the `Dockerfile`). Check Nextcloud's supported PHP range first.
