#!/bin/bash

while ! ping -c1 github.com &>/dev/null; do :; done

while [ "$(launchctl blame system/com.pmartin.homebrew)" != '(not running)' ]; do
    echo "[$(date "+%Y-%m-%d %H.%M.%S %Z")] brew.sh: Waiting to fix homebrew permissions."
    sleep 15
done

echo "[$(date "+%Y-%m-%d %H.%M.%S %Z")] brew.sh: Fixing homebrew permissions."
cd `brew --prefix`
git checkout master
git ls-files -z | pbcopy
chown -R _brew:_brew Cellar
pbpaste | xargs -0 chown -R _brew:_brew
chown -R _brew:_brew Library/Homebrew Library/Aliases Library/Formula Library/Contributions 
test -d Library/LinkedKegs && chown -R _brew:_brew Library/LinkedKegs
chown -R _brew:_brew bin Library share/man/man1 2> /dev/null
chown -R _brew:_brew .git
if [ ! -d "/opt/homebrew/Library/Caches/Homebrew" ]; then
    mkdir -p "/opt/homebrew/Library/Caches/Homebrew"
fi
chmod 755 "/opt/homebrew/Library/Caches/Homebrew"
if [ ! -d "/opt/homebrew/Library/Logs/Homebrew" ]; then
    mkdir -p "/opt/homebrew/Library/Logs/Homebrew"
fi
chmod 755 "/opt/homebrew/Library/Logs/Homebrew"
if [ ! -d "/Library/Caches/Homebrew" ]; then
    mkdir -p "/Library/Caches/Homebrew"
fi
if [ -d "/opt/homebrew-cask" ]; then
    chown -R _brew:_brew "/opt/homebrew-cask"
fi
chown -R _brew:_brew "/Library/Caches/Homebrew"
chown -R _brew:_brew "/opt/homebrew/bin"
chown -R _brew:_brew "/opt/homebrew/etc"
chown -R _brew:_brew "/opt/homebrew/libexec"
chown -R _brew:_brew "/opt/homebrew/Library/Caches"
chown -R _brew:_brew "/opt/homebrew/Library/Logs"
chown -R _brew:_brew "/opt/homebrew/Library/Preferences"
chown -R root:wheel "/opt/homebrew/Library/LaunchDaemons"
chown -R _brew:_brew "/usr/local"
exit 0

