#!/usr/bin/env bash

# REQ: Installs utilities with homebrew. <skr 2022-06 s:inprogress>

set +B -Cefuxo pipefail

local=/usr/local src=$local/src bin=$local/bin

brewfile='
  brew "azure-cli"
  brew "bash"
  brew "gh"
  brew "gnu-tar"
  brew "yq"
  
  cask "multipass"
'

releases=(
  'cloud-init'
)

main() {
  brew bundle --file=- <<<$brewfile
  
  make_dirs
  install_cloud-init
}

make_dirs() {
  sudo mkdir -p $src $bin
}

install_cloud-init() {
  r_path+='."rdf:RDF"'
  r_path+='."lp:ProductSeries"'
  r_path+='."lp:release"'
  r_path+=[0]

  r_path+='."lp:ProductRelease"'
  r_path+='."lp:specifiedAt"'
  r_path+='."@rdf:resource"'

  v_path+='."rdf:RDF"'
  v_path+='."lp:ProductRelease"'
  v_path+='."lp:version"'

  scheme=https
  host=launchpad.net
  name=trunk

  for release in "${releases[@]}"
  do
    resource=$(
      url=$scheme://$host/$release/$name/+rdf
      curl -LSfs $url | xq -r "$r_path" 
    )
    version=$(
      url=$scheme://$host$resource
      curl -LSfs $url | xq -r "$v_path"
    )

    url=$scheme://$host/$release/$name/$version/+download/$release-$version.tar.gz
    curl -LSfs $url | sudo tar xz -C $src
  done
}

main
