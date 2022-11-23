#!/bin/sh

HOST=${HTTP_HOST}


fetch () {
    mkdir -p $2
    curl -sSL ${HOST}/$1.tar.zst | zstd -d -T0 | tar -xf - -C $2 --strip-components=1
}

setup_nushell () {
    echo --- setup nushell
    fetch nushell /usr/local
    fetch nushell.conf ${HOME}/.config/nushell
}

setup_nvim() {
    echo --- setup nvim
    fetch nvim /usr/local
    fetch nvim.conf ${HOME}/.config/nvim
}

setup_openresty() {
    echo --- setup openresty
    fetch openresty /opt/openresty
}

setup_node() {
    echo --- setup node
    fetch node /usr/local
}

for i in "$@"; do
    eval "setup_$i"
done
