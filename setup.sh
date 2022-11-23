#!/bin/sh

HOST=${HTTP_HOST}


fetch () {
    mkdir -p $2
    curl -sSL ${HOST}/$1 | zstd -d -T0 | tar -xf - -C $2 --strip-components=1
}

setup_nushell () {
    fetch nushell.tar.zst /usr/local
    fetch nushell.conf.tar.zst /usr/local
}

setup_nvim() {
    fetch nvim.tar.zst /usr/local
    fetch nvim.conf.tar.zst ${HOME}/.config/nvim
}


setup_nvim
