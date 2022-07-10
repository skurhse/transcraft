#!/usr/bin/env bash

# REQ: Creates a cloud-init user-data MIME multi-part archive. <skr 2022-06>

# TODO: Drive data. <>

set +o braceexpand
set -o errexit
set +o noclobber
set -o nounset
set -o noglob
set -o pipefail

if [[ $LVL == 'DEBUG' ]]
then
	set -o xtrace
fi

realpath="$(realpath "$0")"
dirname="$(dirname "$realpath")"
cd "$dirname/.."

source 'lib/options.bash'
source 'lib/models/user_data.bash'

function main {
	parse_options "$@"

	make_user_data

	create_mime_file
}

main "$@"
