#!/bin/bash
pushd /opt/homebrew > /dev/null
source /opt/homebrew/etc/sourceenv
sudo -u _brew -g _brew brew-cask $@
popd > /dev/null

