import yaml
from pathlib import Path
import sys

# input = sys.argv
input = ['setup', 'http://localhost', 'nu', 'vim', 'conf', 'python',  'php', 'lslua', 'ls']

action = input[0]
source = input[1]
arg = input[2:]
file = Path('.') / 'setup.yaml'
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

for a in arg:
    if a in component_tag:
        tags.add(component_tag[a])
    if a in alias_map:
        target.add(alias_map[a])

for i in target:
    if i in alias_dep:
        for x in alias_dep[i]:
            m = manifest[alias_index[alias_map[x]]]
            if set(m['tag']).intersection(tags):
                components.add(x)


def gen_setup(entity):
    print(f'## {entity["name"]}')

def lst(taget, tags):
    print(f'# setup {", ".join(taget)} with {", ".join(tags)}')
    print(f'# components: {", ".join(components)}')

def setup(taget, tags):
    print(f'# setup {", ".join(taget)} with {", ".join(tags)}')
    lst = []
    for i in requires:
        if not i in lst:
            lst.append(i)
    for i in components:
        if not i in lst:
            lst.append(i)
    for i in target:
        if not i in lst:
            lst.append(i)
    for i in lst:
        gen_setup(manifest[alias_index[i]])
    print(f'# manifests: {", ".join(lst)}')

if action == 'list':
    lst(target, tags)
elif action == 'setup':
    setup(target, tags)
