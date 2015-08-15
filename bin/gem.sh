#!/bin/bash
pushd /opt/homebrew > /dev/null
source /opt/homebrew/etc/sourceenv
version=$(basename $(dirname $(dirname $(ls -l $(which ruby) | awk '{ print $NF }'))))
if [[ "gem $@" == *'gem install'*  ]]; then
    sudo -u _brew -g _brew gem $@ --install-dir /usr/local/lib/ruby/gems/$version
else
    sudo -u _brew -g _brew gem $@
fi
popd > /dev/null

