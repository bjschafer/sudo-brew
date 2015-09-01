#!/bin/bash

function check_root {
    if [ "$EUID" -eq "0" ]; then
	    echo "running as root."
    else
	    echo "Root authentication required. (Rerun with sudo)." 1>&2
	    exit 1
    fi
}
check_root

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"

rm -rf /opt/homebrew*

sudo -u _brew -g _brew getconf DARWIN_USER_TEMP_DIR | xargs dirname | xargs -I {} rm -rf '{}'
sysadminctl -deleteUser _brew -keepHome
bashrc='/etc/bashrc'
if [ -n "$(grep "alias brew=" ${bashrc})" ]; then
    sed -i '' -e '/^alias brew/ d' ${bashrc}
fi

if [ -n "$(grep "alias pip=" ${bashrc})" ]; then
    sed -i '' -e '/^alias pip/ d' ${bashrc}
fi

if [ -n "$(grep "alias gem=" ${bashrc})" ]; then
    sed -i '' -e '/^alias gem/ d' ${bashrc}
fi

