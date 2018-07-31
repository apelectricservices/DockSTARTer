#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

setup_docker_remote() {
    local PROMPT
    PROMPT=${1:-}
    local QUESTION
    QUESTION="Would you like to allow remote access to Docker? WARNING: This can be a security risk!"
    info "${QUESTION}"
    local YN
    while true; do
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            YN=N
        elif [[ ${PROMPT} == "menu" ]]; then
            local ANSWER
            set +e
            ANSWER=$(whiptail --fb --yesno "${QUESTION}" 0 0 3>&1 1>&2 2>&3; echo $?)
            set -e
            reset || true
            [[ ${ANSWER} == 0 ]] && YN=Y || YN=N
        else
            read -rp "[Yn]" YN
        fi
        case ${YN} in
            [Yy]* )
                info "Enabling remote access to Docker."
cat > /etc/systemd/system/docker.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd

EOL
cat > /etc/docker/daemon.json <<EOL
{
  "hosts": [
    "unix:///var/run/docker.sock",
    "tcp://0.0.0.0:2375"
  ]
}

EOL
                info "Remote access to Docker has been configured. A reboot is required to finalize the changes."
                break
                ;;
            [Nn]* )
                info "Remote access to Docker will not be enabled."
                return
                ;;
            * )
                error "Please answer yes or no."
                ;;
        esac
    done
}
