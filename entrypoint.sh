#!/usr/bin/env bash

# To use a Tor proxy in a fully Bitmessage-compatible way, set
# sockshostname = <name-of-the-container>
# socksport = 9050
# in keys.dat and set the real in-container-address using the
# environment variables SOCKS_HOST and SOCKS_PORT,
# eg 10.0.2.2 and 9050, respectively

if [[ $(echo "$1" | cut -c1) == "-" ]]; then
  set -- pybitmessage "${@}"; fi

if [[ "${1}" == "pybitmessage" ]]; then
  CONFIG_SOCKS_PROXY_TYPE=$(awk -F ' = ' '/^socksproxytype =/ { print $2 }' "/home/user/.config/PyBitmessage/keys.dat")
  if [[ "${CONFIG_SOCKS_PROXY_TYPE}" == "SOCKS5" && -n "${SOCKS_HOST}" && -n "${SOCKS_PORT}" ]]; then
    CONFIG_SOCKS_HOST=$(awk -F ' = ' '/^sockshostname =/ { print $2 }' "/home/user/.config/PyBitmessage/keys.dat")
    CONFIG_SOCKS_PORT=$(awk -F ' = ' '/^socksport =/ { print $2 }' "/home/user/.config/PyBitmessage/keys.dat")
    TAP0_IP_ADDRESS=$(ip -4 -o address show tap0 | grep -Po '(?<=\sinet\s)[0-9.]+'); C=0
    if [[ "${CONFIG_SOCKS_HOST}" == "${TAP0_IP_ADDRESS}" ]]; then
      C=1
    else
      MY_HOSTNAMES=( $(awk -v a="${TAP0_IP_ADDRESS}" '($1 == a) { print }' /etc/hosts | cut -f2) )
      for my_hostname in "${MY_HOSTNAMES[@]}"; do [[ "${CONFIG_SOCKS_HOST}" != "${my_hostname}" ]] || { C=1; break; }; done
    fi
    [[ -e /tmp/socat-socks_proxy.lock && -e /tmp/socat-socks_proxy.pid ]] && kill -0 "$(cat /tmp/socat-socks_proxy.pid)" > /dev/null 2>&1
    SOCAT_RUNNING=$((1 - ${?}))
    if [[ ${C} -ne 0 && ${SOCAT_RUNNING} -eq 0 ]]; then
      rm -f /tmp/socat-socks_proxy.lock /tmp/socat-socks_proxy.pid
      /usr/bin/socat -L /tmp/socat-socks_proxy.lock TCP4-LISTEN:"${CONFIG_SOCKS_PORT}",bind="${TAP0_IP_ADDRESS}",reuseaddr,fork TCP4:"${SOCKS_HOST}:${SOCKS_PORT}" &
      echo $! > /tmp/socat-socks_proxy.pid
    fi
  fi
fi

exec "${@}"
