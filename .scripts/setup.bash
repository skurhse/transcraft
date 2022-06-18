#!/usr/bin/env bash

# REQ: Installs utilities with homebrew. <skr 2022-06 s:inprogress>

set +B -Cefuxo pipefail

local='/usr/local' src="$local/src" bin="$local/bin"

brewfile='
  brew "azure-cli"
  brew "bash"
  brew "gh"
  brew "gnu-tar"
  brew "yq"
  
  cask "multipass"
'

main() {
  run_brew_bundle
  
  make_local_dirs
  install_cloud-init
}

run_brew_bundle() {
  brew bundle --file=- <<<$brewfile
}

make_local_dirs() {
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

  scheme='https'
  host='launchpad.net'
  name='cloud-init'
  release='trunk'

  resource=$(
    url="$scheme://$host/$name/$release/+rdf"
    curl -LSfs "$url" | xq -r "$r_path" 
  )

  version=$(
    url="$scheme://$host$resource"
    curl -LSfs "$url" | xq -r "$v_path"
  )

  url="$scheme://$host/$name/$release/$version/+download/$name-$version.tar.gz"
  curl -LSfs "$url" | sudo tar xz -C "$src"

  cd "$src/$name-$version"
  for command in 'build' 'develop'
  do
    sudo python3 setup.py "$command"
  done

  # CAVEAT: Hardcoded. <skr>
  source_file='../Cellar/python@3.9/3.9.13_1/Frameworks/Python.framework/Versions/3.9/bin/cloud-init'
  target_file='/opt/homebrew/bin/cloud-init'

  ! ln -s  "$source_file" "$target_file"
}

main
