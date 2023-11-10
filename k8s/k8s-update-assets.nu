def comp [context: string, offset: int] {
    let size = $context | str substring 0..$offset | split row ' ' | length
    if $size < 3 {
        ['update' 'pull' 'push' 'sync']
    } else if $size < 4 {
        ['asset' 'image']
    }
}

def gen_to [version rc] {
    if ($rc.to? | is-empty) {
        $rc.from | split row '/' | last
    } else {
        $rc.to
    } | str replace --all '{}' $version
}

def target_files [manifest version] {
    $manifest | transpose k v | each {|it|
        let h = $version | get $it.k
        gen_to $h $it.v
    }
}

export def main [...args:string@comp] {
    let utils = {
        slice2: {|x| $x | str substring 1.. }
        tag_name:  {|x| $x | jq -r '.tag_name' }
        trim: {|x| $x | str trim }
    }
    
    let dufs = "file.s/k8s_assets"
    let target = $"($env.HOME)/pub/Platform/k8s"
    let manifest = open assets/manifest.yaml
    let index = open assets/version.json
    let version = $index.version
    let images = $index.images

    match $"($args.0?) ($args.1?)" {
        'update asset' => {
            let ori = $version
            let new = $manifest | transpose k v | reduce -f {} {|it, acc|
                if not ($it.v.url? | is-empty) {
                    print $"fetch ($it.k)'s version"
                    mut r = (curl -sSL $it.v.url)
                    for f in $it.v.get {
                        $r = (do ($utils | get $f) $r)
                    }
                    $acc | upsert $it.k $r
                } else {
                    $acc
                }
            }

            open assets/version.json | upsert version ($ori | merge $new) | save -f assets/version.json
        }
        'update image' => {
            mut k8s_image = kubeadm config images list $"--kubernetes-version=($version.k8s)" | lines
            for i in 6..8 {
                $k8s_image ++= [ $"registry.k8s.io/pause:3.($i)" ]
            }
            $k8s_image ++= [ $"registry.k8s.io/etcd:3.5.9-0" ]
            let istio_ver = $version.istio
            $k8s_image ++= [ $"docker.io/istio/proxyv2:($istio_ver)" ]
            $k8s_image ++= [ $"docker.io/istio/pilot:($istio_ver)" ]
            open assets/version.json | upsert images $k8s_image | save -f assets/version.json
        }
        'pull asset' => {
            $manifest | transpose k v | reduce -f {} {|it, acc|
                if not ($it.v.from? | is-empty) {
                    let h = $version | get $it.k
                    let from = $it.v.from | str replace --all '{}' $h
                    let to = gen_to $h $it.v
                    print $'wget ($target)/($to)'
                    wget -c $from -O $"($target)/($to)"
                }
            }
        }
        'pull image' => {
            let offset = if ($args.2? | is-empty) { 0 } else { $args.2 | into int }
            for i in ($images | range $offset..) {
                let f = ($i | str replace -a --regex "[/:]" "_")
                print $"pull ($i)"
                nerdctl pull $i
                #skopeo copy $'docker://($i)' $'docker-daemon:($i)'
                #skopeo copy $'docker://($i)' $'oci-archive:($env.HOME)/Downloads/images/($f)'
                #skopeo copy $'docker://($i)' $'docker://registry.s/($f)'
                #nerdctl save $(cat assets-k8s-images) | zstd -19 -T0 > ~/pub/Platform/k8s/kube-system_${K8S_VERSION}.tar.zst
            }
        }
        'push asset' => {
            target_files $manifest $version | each {|to|
                print $"curl -T ($target)/($to) http://($dufs)/($to)"
                curl -sSL -T $"($target)/($to)" $"http://($dufs)/($to)"
            }
        }
        'sync asset' => {
            mkdir $target
            for to in (target_files $manifest $version) {
                wget -c $"http://($dufs)/($to)" -O $"($target)/($to)"
            }
        }
        'export asset' => {
            $manifest | to yaml | save -f assets/manifest.yaml
        }
    }

}
