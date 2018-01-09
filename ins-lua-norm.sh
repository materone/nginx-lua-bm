#!/bin/sh

NGINX_VERSION="1.13.8"

GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 
NDK_SRC=/usr/src/ngx_devel_kit-0.3.0
LUA_SRC=/usr/src/lua-nginx-module-0.10.12rc1
REDIS_SRC=/usr/src/redis2-nginx-module-0.14
MEMC_SRC=/usr/src/memc-nginx-module-0.18
MISC_SRC=/usr/src/set-misc-nginx-module-0.31
# https://github.com/openresty/set-misc-nginx-module/archive/v0.31.tar.gz
# https://github.com/openresty/redis2-nginx-module/archive/v0.14.tar.gz
# https://github.com/openresty/memc-nginx-module/archive/v0.18.tar.gz
export LUAJIT_LIB=/usr/lib
export LUAJIT_INC=/usr/include/luajit-2.1
CONFIG="\
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-http_xslt_module=dynamic \
	--with-http_image_filter_module=dynamic \
	--with-http_geoip_module=dynamic \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--with-stream_realip_module \
	--with-stream_geoip_module=dynamic \
	--with-http_slice_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-compat \
	--with-file-aio \
	--with-http_v2_module \
	--add-dynamic-module=$LUA_SRC \
	--add-dynamic-module=$NDK_SRC \
	--add-dynamic-module=$REDIS_SRC \
	--add-dynamic-module=$MEMC_SRC \
	--add-dynamic-module=$MISC_SRC \
	--with-ld-opt="-Wl,-rpath,/usr/lib" \
	" 
addgroup -S nginx 
adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx 
apk update
apk add \
	gcc \
	libc-dev \
	make \
	openssl-dev \
	pcre-dev \
	zlib-dev \
	linux-headers \
	curl \
	gnupg \
	libxslt-dev \
	gd-dev \
	geoip-dev \
	lua \
	luajit \
	luajit-dev \
	lua-dev

test -f "nginx.tar.gz"||curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz 
test -f "nginx.tar.gz.asc"||curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc 
#add by tony for lua module
test -f "ndk.tar.gz"||curl -fSL https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz -o ndk.tar.gz
test -f "lua.tar.gz"||curl -fSL https://github.com/openresty/lua-nginx-module/archive/v0.10.12rc1.tar.gz -o lua.tar.gz
test -f "redis.tar.gz"||curl -fSL  https://github.com/openresty/redis2-nginx-module/archive/v0.14.tar.gz -o redis.tar.gz
test -f "memc.tar.gz"||curl -fSL  https://github.com/openresty/memc-nginx-module/archive/v0.18.tar.gz -o memc.tar.gz
test -f "misc.tar.gz"||curl -fSL  https://github.com/openresty/set-misc-nginx-module/archive/v0.31.tar.gz -o misc.tar.gz
mkdir -p /usr/src 
tar -zxC /usr/src -f ndk.tar.gz 
tar -zxC /usr/src -f lua.tar.gz 
tar -zxC /usr/src -f redis.tar.gz 
tar -zxC /usr/src -f memc.tar.gz 
tar -zxC /usr/src -f misc.tar.gz 
#end add
#remove gpg verify by tony
#export GNUPGHOME="$(mktemp -d)" 
#found=''; 
#for server in \
#	ha.pool.sks-keyservers.net \
#	hkp://keyserver.ubuntu.com:80 \
#	hkp://p80.pool.sks-keyservers.net:80 \
#	pgp.mit.edu \
#; do \
#	echo "Fetching GPG key $GPG_KEYS from $server"; \
#	gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
#done; 
#test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; 
#gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz 
#rm -r "$GNUPGHOME" nginx.tar.gz.asc
#enf remove gpg by tony 
tar -zxC /usr/src -f nginx.tar.gz 
#rm nginx.tar.gz 
cd /usr/src/nginx-$NGINX_VERSION 
./configure $CONFIG --with-debug 
make -j$(getconf _NPROCESSORS_ONLN) 
mv objs/nginx objs/nginx-debug 
mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so 
mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so 
mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so 
mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so 
mv objs/ndk_http_module.so objs/ndk_http_module-debug.so
mv objs/ngx_http_lua_module.so objs/ngx_http_lua_module-debug.so 
mv objs/ngx_http_memc_module.so objs/ngx_http_memc_module-debug.so
mv objs/ngx_http_redis2_module.so objs/ngx_http_redis2_module-debug.so
mv objs/ngx_http_set_misc_module.so objs/ngx_http_set_misc_module-debug.so
./configure $CONFIG 
make -j$(getconf _NPROCESSORS_ONLN) 
make install 
rm -rf /etc/nginx/html/ 
mkdir /etc/nginx/conf.d/ 
mkdir -p /usr/share/nginx/html/ 
install -m644 html/index.html /usr/share/nginx/html/ 
install -m644 html/50x.html /usr/share/nginx/html/ 
install -m755 objs/nginx-debug /usr/sbin/nginx-debug 
install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so 
install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so 
install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so 
install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so 
#add lua
install -m755 objs/ndk_http_module-debug.so /usr/lib/nginx/modules/ndk_http_module-debug.so
install -m755 objs/ngx_http_lua_module-debug.so /usr/lib/nginx/modules/ngx_http_lua_module-debug.so
install -m755 objs/ngx_http_memc_module-debug.so /usr/lib/nginx/modules/ngx_http_memc_module-debug.so
install -m755 objs/ngx_http_redis2_module-debug.so /usr/lib/nginx/modules/ngx_http_redis2_module-debug.so
install -m755 objs/ngx_http_set_misc_module-debug.so /usr/lib/nginx/modules/ngx_http_set_misc_module-debug.so
ln -s /usr/lib/nginx/modules /etc/nginx/modules 
strip /usr/sbin/nginx* 
strip /usr/lib/nginx/modules/*.so 
#ln -sf /dev/stdout /var/log/nginx/access.log 
#ln -sf /dev/stderr /var/log/nginx/error.log
