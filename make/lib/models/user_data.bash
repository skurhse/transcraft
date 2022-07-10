function make_user_data {
  declare -Ag user_data=(
    [path]="../${options[mime_file]}"
  )
}

function create_mime_file {
 	cloud-init devel make-mime \
	  -a cloud-init/cloud-config/config.yaml:cloud-config \
	  -a cloud-init/x-shellscript/per-instance/install_quilt.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-instance/install_prometheus.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-instance/configure_iptables.bash:x-shellscript-per-instance \
	  -a cloud-init/x-shellscript/per-instance/configure_sshd.bash:x-shellscript-per-instance \
	> "${user_data[path]}"
}
