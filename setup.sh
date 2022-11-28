#!/bin/sh

HOST=${HTTP_HOST}


fetch () {
    mkdir -p $2
    curl -sSL ${HOST}/$1.tar.zst | zstd -d -T0 | tar -xf - -C $2 --strip-components=1
}

evx () {
    echo "export $@\n" | tee -a ${HOME}/.profile
    eval "export $@"
}

setup_nushell () {
    echo --- setup nushell
    fetch nushell /usr/local/bin
    fetch nushell.conf ${HOME}/.config/nushell
    echo --- done
}

setup_nvim() {
    echo --- setup nvim
    fetch nvim /usr/local
    fetch nvim.conf ${HOME}/.config/nvim
    echo --- done
}

setup_wasm() {
    echo --- setup wasm
    fetch wasmtime /usr/local/bin
    echo --- done
}

setup_openresty() {
    echo --- setup openresty
    fetch openresty /opt/openresty
    mkdir -p /var/log/openresty
    echo --- done
}

setup_node() {
    echo --- setup node, lspy, lsyaml, lsjson
    local tg=${NODE_ROOT:-/opt/node}
    fetch node $tg
    evx "PATH=$tg/bin:\$PATH"
    echo --- done
}

setup_python() {
    echo --- setup python
    local tg=${PYTHON_ROOT:-/opt/python}
    fetch python $tg
    evx "PATH=$tg/bin:\$PATH"
    evx "LD_LIBRARY_PATH=$tg/lib:\$LD_LIBRARY_PATH"
    echo --- done
}

setup_utils() {
    echo --- setup utils
    fetch utils /usr/local/bin
    echo --- done
}

setup_ssh() {
    echo --- setup sshd
    fetch sshd /
    echo --- done
}

setup_lsphp() {
    echo --- setup lsphp
    fetch lsphp /opt/language-server/vscode-php-debug
    echo --- done
}

setup_lsnode() {
    echo --- setup lsnode
    fetch lsnode /opt/language-server/vscode-node-debug2
    echo --- done
}

setup_lslua() {
    echo --- setup lslua
    fetch lslua /opt/language-server/sumneko_lua
    echo --- done
}

setup_vs() {
    echo --- setup vscode-server
    fetch vscode-server ${HOME}
    echo --- done
}

setup_s() {
    setup_nushell
    setup_utils
    nu
}

setup_n() {
    setup_nvim
    setup_node
    nvim
}

setup_py() {
    setup_s
    setup_n
    setup_python
    nvim
}

setup_php() {
    setup_s
    setup_n
    setup_lsphp
    nvim
}

if [ -z "$@"]; then
    echo 'curl ${HTTP_HOST}/setup.sh | sh -s <...>'
    echo '#py: s n python'
    echo '#php: s n lsphp'
    echo '#s: nushell utils'
    echo '#n: nvim node'
    echo '# openresty'
    echo '# ssh'
    echo '# python lsnode lslua lsphp'
else
    for i in "$@"; do
        eval "setup_$i"
    done
fi
