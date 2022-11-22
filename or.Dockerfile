FROM alpine

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        coreutils \
        curl \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        make \
        perl-dev \
        readline-dev \
        zlib-dev \
  ; apk add --no-cache \
        gd \
        geoip \
        libgcc \
        libxslt \
        zlib \
  \
  ; build_dir=/root/build \
  ; mkdir -p $build_dir \
  \
  ; cd $build_dir \
  ; OPENRESTY_VER=$(curl -sSL https://api.github.com/repos/openresty/openresty/tags -H 'Accept: application/vnd.github.v3+json' | jq -r '.[0].name' | cut -c 2-) \
  ; curl -sSL https://openresty.org/download/openresty-${OPENRESTY_VER}.tar.gz | tar -zxf - \
  ; cd openresty-${OPENRESTY_VER} \
  ; ./configure --prefix=/opt/openresty \
        --with-luajit \
        --with-threads \
        --with-file-aio \
        --with-http_v2_module \
        --with-http_ssl_module \
        --with-http_auth_request_module \
        --with-http_addition_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_iconv_module \
        --with-http_slice_module \
        --with-http_sub_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_realip_module \
        --with-stream_ssl_preread_module \
  ; make \
  ; make install \
  \
  ; ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
  ; ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log
  \
  ; cd ../../ && rm -rf $build_dir \
  ; apk del .build-deps \
  #; mkdir -p /var/run/openresty \
  ; opm install ledgetech/lua-resty-http \
  ; ln -fs /opt/openresty/nginx/conf /etc/openresty \
  ; echo 'shopt -s cdable_vars' >> /root/.bashrc

COPY config /etc/openresty
WORKDIR /srv

VOLUME [ "/srv" ]
EXPOSE 80 443

CMD ["/opt/openresty/bin/openresty", "-g", "daemon off;"]

STOPSIGNAL SIGQUIT
