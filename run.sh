#!/bin/bash

declare __tz="Etc/UTC"
declare __userid="$(id -u):$(id -g)"
declare __username="$(id -u -n)"
declare -i __uid="${__userid%%:*}" __gid="${__userid##*:}";
declare -i __subuid_size=$(( $(podman info --format "{{ range .Host.IDMappings.UIDMap }} + {{ .Size }}{{ end }}" ) - 1 ))
declare -i __subgid_size=$(( $(podman info --format "{{ range .Host.IDMappings.GIDMap }} + {{ .Size }}{{ end }}" ) - 1 ))

[[ ${__subuid_size} -gt 0 && ${__subgid_size} -gt 0 ]] || exit 1

[[ -e "/tmp/.${__username}--xauth-podman" ]] || {
	touch "/tmp/.${__username}--xauth-podman" && xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "/tmp/.${__username}--xauth-podman" nmerge - &> /dev/null; } || \
	exit 1

podman run	--uidmap ${__uid}:0:1 --uidmap 0:1:${__uid} --uidmap $(( __uid + 1 )):$(( __uid + 1 )):$(( __subuid_size - __uid )) \
		--gidmap ${__gid}:0:1 --gidmap 0:1:${__gid} --gidmap $(( __gid + 1 )):$(( __gid + 1 )):$(( __subgid_size - __gid )) \
		--user "${__userid}" --security-opt label=disable \
		-v "/dev/dri":"/dev/dri" -v "/tmp/.X11-unix/":"/tmp/.X11-unix/" -v "/tmp/.${__username}--xauth-podman":"/tmp/.xauth-podman":'rw' -v "/run/user/${__uid}/":"/run/user/${__uid}/" \
		-e DISPLAY="unix:${DISPLAY##:}" -e PULSE_SERVER="/run/user/${__uid}/pulse/native" -e XAUTHORITY="/tmp/.xauth-podman" -e XDG_RUNTIME_DIR="/run/user/${__uid}" --ipc host \
		--rm --name bitmessage-gui --network slirp4netns:allow_host_loopback=true -e TZ="${__tz}" \
		-v "${HOME}/.config/PyBitmessage":"/PyBitmessage--data":rw -p 127.0.0.1:8444:8444 -p 127.0.0.1:8442:8442 -d local/bitmessage-gui
