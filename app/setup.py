import yaml
from pathlib import Path
import re
import sys, os

# export LAYER_SETUP_ARGS='./setup.py ./setup.yaml setup http://localhost:8080 nvim,nu,config,only'
# python3 ./setup.py ./setup.yaml setup http://localhost:8080 python,nvim
mock = os.environ.get('LAYER_SETUP_ARGS')
input = mock and mock.split(' ') or sys.argv

action = input[2]
file = Path(input[1])
host = input[3]
arg = re.split(r'[\s,/|]', ' '.join(input[4:]))
data = yaml.safe_load(file.read_text())

manifest = data['manifest']

component_tag = {}
for t in data['component_tag']:
    for i in t:
        component_tag[i] = t[0]

alias_map = {}
alias_index = {}
alias_dep = {}
for ax, a in enumerate(manifest):
    alias_map[a['name']] = a['name']
    alias_index[a['name']] = ax
    if a.get('belong'):
        if not alias_dep.get(a['belong']):
            alias_dep[a['belong']] = []
        alias_dep[a['belong']].append(a['name'])
    if not a.get('alias'):
        continue
    for i in a['alias']:
        alias_map[i] = a['name']

target = set()
components = set()
tags = set()
requires = set()
config_only = set()

for a in arg:
    if a in component_tag:
        tags.add(component_tag[a])
    if a in alias_map:
        target.add(alias_map[a])

def deref(name):
    return manifest[alias_index[alias_map[name]]]

def coll_deps(ent):
    if not ent.get('requires'):
        return
    for r in ent['requires']:
        requires.add(r)
        coll_deps(deref(r))

for i in target:
    coll_deps(deref(i))
    if i in alias_dep:
        for x in alias_dep[i]:
            m = deref(x)
            if set(m['tag']).intersection(tags):
                components.add(x)
                if 'config_only' in tags and 'config' in m['tag']:
                    config_only.add(x)
                coll_deps(m)


def gen_setup(entity):
    name = entity['name']
    tg = entity.get('target')
    src = entity.get('source')
    print(f'echo "setup {name}" ')
    if tg:
        if 'config' in entity.get('tag', []):
            print(f'rm -rf {tg}')
            print(f'mkdir -p {tg}')
            print(f'curl -SL --progress-bar {host}/{src}.tar.zst | zstd -d -T0 | tar -xf - -C {tg} --strip-components=1')
        else:
            print(f'$SUDO mkdir -p {tg}')
            print(f'curl -SL --progress-bar {host}/{src}.tar.zst | zstd -d -T0 | $SUDO tar -xf - -C {tg} --strip-components=1')
        if entity.get('link'):
            print(f'$SUDO ln -fs {tg}/{entity["link"]} /usr/local/bin/')
        if entity.get('env'):
            for k, v in entity['env'].items():
                print(f'echo "export {k}={v}" >> ${{HOME}}/.profile')

def lst(taget, tags):
    print(f'# setup {", ".join(taget)} with {", ".join(tags)}')
    print(f'# components: {", ".join(components)}')

def setup_zstd():
    print(f'''
if [ ! -x /usr/local/bin/zstd ]; then
    echo 'setup zstd'
    $SUDO curl -sSLo /usr/local/bin/zstd {host}/zstd
    $SUDO chmod +x /usr/local/bin/zstd
fi''')

def setup(taget, tags):
    print('#!/usr/bin/env bash')
    print("SUDO=''")
    print("if [ `id -u` != 0 ]; then SUDO='sudo'; fi")
    print('echo')
    setup_zstd()
    print('echo')
    print(f'echo ... {", ".join(taget)} with {", ".join(tags)}')
    print('echo')
    print('set -eu')
    print('CONFIG_ROOT=${XDG_CONFIG_HOME:-$HOME/.config}')
    lst = []
    if 'config_only' in tags:
        for i in config_only:
            if not i in lst:
                lst.append(i)
    else:
        for i in requires:
            if not i in lst:
                lst.append(i)
        for i in target:
            if not i in lst:
                lst.append(i)
        for i in components:
            if not i in lst:
                lst.append(i)
    for i in lst:
        gen_setup(deref(i))
    print(f'# manifests: {", ".join(lst)}')

def collect(manifest):
    pass

MIRROR = '''
china_mirrors() {
    local b_u="cp /etc/apt/sources.list /etc/apt/sources.list.\$(date +%y%m%d%H%M%S)"
    local b_a="cp /etc/apk/repositories /etc/apk/repositories.\$(date +%y%m%d%H%M%S)"
    local s_u="sed -i 's/\(archive\|security\).ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list"
    local s_d="sed -i 's/\(.*\)\(security\|deb\).debian.org\(.*\)main/\\1mirrors.ustc.edu.cn\\3main contrib non-free/g' /etc/apt/sources.list"
    local s_a="sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories"
    local s="" #$([ 0 < $UID ] && echo sudo)
    local cmd
    local os
    if [ -n "$1" ]; then
        cmd="echo"
        os="$1"
    else
        cmd="$s"
        os=$(grep ^ID= /etc/os-release | sed 's/ID=\(.*\)/\\1/')
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

china_mirrors
'''

if action == 'list':
    lst(target, tags)
elif action == 'setup':
    setup(target, tags)
elif action == 'mirror':
    print(MIRROR)
elif action == 'collect':
    collect(manifest)
