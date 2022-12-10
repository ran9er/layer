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
    fetch nushell.conf ${XDG_CONFIG_HOME:-$HOME/.config}/nushell
    echo --- done
}

setup_nushell_reconf() {
    echo -- upgrade nushell conf
    rm -rf ${XDG_CONFIG_HOME:-$HOME/.config}/nushell
    fetch nushell.conf ${XDG_CONFIG_HOME:-$HOME/.config}/nushell
    echo --- done
}

setup_nvim() {
    echo --- setup nvim
    fetch nvim /usr/local
    fetch nvim.conf ${XDG_CONFIG_HOME:-$HOME/.config}/nvim
    echo --- done
}

setup_nvim_reconf() {
    echo -- upgrade nvim conf
    rm -rf ${XDG_CONFIG_HOME:-$HOME/.config}/nvim
    fetch nvim.conf ${XDG_CONFIG_HOME:-$HOME/.config}/nvim
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
    fetch lsphp /opt/language-server/phpactor
    fetch phpdb /opt/language-server/vscode-php-debug
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
    evx "PATH=/opt/language-server/sumneko_lua/bin:\$PATH"
    echo --- done
}

setup_vs() {
    echo --- setup vscode-server
    mkdir -p ${HOME}/.vscode-server
    fetch vscode-server ${HOME}/.vscode-server
    echo --- done
}

setup_s() {
    setup_nushell
    setup_utils
}

setup_n() {
    setup_nvim
    setup_node
}

setup_py() {
    setup_n
    setup_python
}

setup_php() {
    setup_n
    setup_lsphp
}

china_mirrors() {
    local b_u="cp /etc/apt/sources.list /etc/apt/sources.list.\$(date +%y%m%d%H%M%S)"
    local b_a="cp /etc/apk/repositories /etc/apk/repositories.\$(date +%y%m%d%H%M%S)"
    local s_u="sed -i 's/\(archive\|security\).ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list"
    local s_d="sed -i 's/\(.*\)\(security\|deb\).debian.org\(.*\)main/\1mirrors.ustc.edu.cn\3main contrib non-free/g' /etc/apt/sources.list"
    local s_a="sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories"
    local s="" #$([ 0 < $UID ] && echo sudo)
    local cmd
    local os
    if [ -n "$1" ]; then
        cmd="echo"
        os="$1"
    else
        cmd="$s"
        os=$(grep ^ID= /etc/os-release | sed 's/ID=\(.*\)/\1/')
    fi
    case $os in
        ubuntu )
            eval "$cmd $b_u"
            eval "$cmd $s_u"
            ;;
        debian )
            eval "$cmd $b_u"
            eval "$cmd $s_d"
            ;;
        alpine )
            eval "$cmd $b_a"
            eval "$cmd $s_a"
            ;;
        * )
    esac
}

if [ -z "$@" ]; then
    echo 'curl ${HTTP_HOST}/setup.sh | sh -s <...>'
    echo '#py:  n python'
    echo '#php: n lsphp'
    echo '#s: nushell utils'
    echo '#n: nvim node'
    echo '# openresty ssh nvim nushell vs'
    echo '# wasm python node'
    echo '# lsnode lslua lsphp'
    echo '# nvim_reconf nushell_reconf'
    echo '# china mirror'
elif [ "$@" = "china" ]; then
    echo 'china mirrors for debian|ubuntu|alpine'
    china_mirrors
else
    for i in "$@"; do
        eval "setup_$i"
    done
fi
