#!/bin/sh

HOST=${HTTP_HOST}


fetch () {
    mkdir -p $2
    curl -sSL ${HOST}/$1 | xz -d -T0 | tar -xf - -C $2 --strip-components=1
}

setup_nushell () {
    fetch nushell.tar.xz /usr/local
    fetch nushell.conf.tar.xz /usr/local
}

setup_nvim() {
    fetch nvim.tar.xz /usr/local
    fetch nvim.conf.tar.xz ${HOME}/.config/nvim
}


setup_nvim
