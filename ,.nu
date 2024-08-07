### {{{ base.nu
$env.comma_scope = {|_|{ created: '2024-08-07{3}16:30:27' }}
$env.comma = {|_|{}}
### }}}

### {{{ 01_env.nu
for e in [nuon toml yaml json] {
    if ($".env.($e)" |  path exists) {
        open $".env.($e)" | load-env
    }
}
### }}}


'setup'
| comma fun {|a,s,_|
    python3 app/setup.py app/setup.yaml setup http://layer.s $a.0
} {
    cmp: {|a,s,_|
        let c = [nvim nu conf co]
        let b = $a.0
        if ($b | is-empty) {
            $c
        } else {
            let o = $b
            | split row ','
            | filter { $in | is-not-empty }
            $c
            | filter { $in in $o | not $in }
            | each {|x| [...$o, $x] | str join ',' }
        }
    }
    wth: { glob: '*' }
}
