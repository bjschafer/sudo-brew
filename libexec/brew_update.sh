#!/bin/bash

while ! ping -c1 github.com &>/dev/null; do :; done

echo "[$(date "+%Y-%m-%d %H.%M.%S %Z")] brew.sh: Performing homebrew update."
brew update -v
brew upgrade -v --all
echo ""

exit 0
