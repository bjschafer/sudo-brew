#!/bin/sh

pushd $(pwd) > /dev/null
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export WORKING_DIR="$DIR"

# Get DDNSD uid
export uid=$(dscl . read /Users/_brew UniqueID | awk '{ print $NF }')
export brew_dir="/opt/homebrew"
export bin_dir="$brew_dir/bin"
export etc_dir="$brew_dir/etc"
export launchd_dir="$brew_dir/Library/LaunchDaemons"
export libexec_dir="$brew_dir/libexec"
export log_dir="$brew_dir/Library/Logs"

function secho {
    echo "[$(date "+%Y-%m-%d %H.%M.%S %Z")] $(basename $0): $1"
}
export -f secho

function check_root {
    if [ "$EUID" -eq "0" ]; then
        secho "Running as root."
    else
        secho "Root authentication required. (Rerun with sudo)." 1>&2
        exit 1
    fi
}
export -f check_root

function create_brew_group {
    if [ -z "$(dscl . list /Groups | grep _brew)" ]; then
        unique_id="499"
        while [ -n "$(dscl . -list /Groups PrimaryGroupID | grep $unique_id)" ]; do
            let unique_id-=1
        done
        dseditgroup -o create _brew -r "HomeBrew" -P '*'
        dscl . create /Groups/_brew PrimaryGroupID $unique_id
        dscl . append /Groups/_brew RecordName brew 
        dscl . append /Groups/_brew RecordName _Brew
        dscl . append /Groups/_brew RecordName Brew
    fi
}
export -f create_brew_group

function create_brew_user {
    if [ -z "$(dscl . list /Users | grep _brew)" ]; then
        unique_id="499"
        while [ -n "$(dscl . list /Users UniqueID | grep $unique_id)" ]; do
            let unique_id-=1
        done
        dscl . create /Users/_brew
        dscl . create /Users/_brew UniqueID $unique_id
        dscl . create /Users/_brew RecordName _brew
        dscl . append /Users/_brew RecordName brew
        dscl . append /Users/_brew RecordName _Brew
        dscl . append /Users/_brew RecordName Brew
        dscl . create /Users/_brew NFSHomeDirectory "$brew_dir"
        dscl . create /Users/_brew UserShell '/bin/bash'
        dscl . create /Users/_brew RealName "HomeBrew"
        dscl . create /Users/_brew PrimaryGroupID "$(dscl . read /Groups/_brew PrimaryGroupID | awk '{ print $NF }')"
    fi
    export uid=$unique_id
}
export -f create_brew_user

function create_directories {

    if [ ! -d "$libexec_dir" ]; then
        mkdir -p "$libexec_dir"
    fi
    if [ ! -d "$launchd_dir" ]; then
        mkdir -p "$launchd_dir"
    fi
    if [ ! -d "$etc_dir" ]; then
        mkdir -p "$etc_dir"
    fi
    if [ ! -d "$bin_dir" ]; then
        mkdir -p "$bin_dir"
    fi
 
    chown root:wheel /opt
    chown _brew:_brew "$brew_dir"
    
    chmod 755 /opt
    chmod 755 "$brew_dir"
    
    chmod +a "group:everyone deny delete" "$brew_dir"

}
export -f create_directories

function delete_existing {
    sudo -u _brew -g _brew getconf DARWIN_USER_TEMP_DIR | xargs dirname | xargs -I {} rm -rf '{}'
    if [ -n "$(dscl . list /Users RecordName | grep _ddnsd)" ]; then
        sysadminctl -deleteUser _brew -keepHome
    fi
    if [ -n "$(dscl . list /Groups RecordName | grep _brew)" ]; then
        dscl . delete /Groups/_brew
    fi
    if [ -h "/Library/LaunchDaemons/com.pmartin.homebrew.plist" ]; then
        launchctl unbootstrap system /Library/LaunchDaemons/com.pmartin.homebrew.plist
        if [ $? -eq 116 ]; then
            launchctl unload /Library/LaunchDaemons/com.pmartin.homebrew.plist
        fi
        launchctl remove system/com.pmartin.homebrew
        unlink "/Library/LaunchDaemons/com.pmartin.homebrew.plist"
        rm "$launchd_dir/com.pmartin.homebrew.plist"
    fi
    if [ -h "/Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist" ]; then
        launchctl unbootstrap system /Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist
        if [ $? -eq 116 ]; then
            launchctl unload /Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist
        fi
        launchctl remove system/com.pmartin.homebrew.permissions
        unlink "/Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist"
        rm "$launchd_dir/com.pmartin.homebrew.permissions.plist"
    fi        
    # REMOVE DAEMON
        
    if [ -d "$brew_dir" ]; then
        rm -rfv "$brew_dir"
    fi
       
    # Remove Logging Config
    if [ -f "/etc/newsyslog.d/brew.conf" ]; then
        rm -fv "/etc/newsyslog.d/brew.conf"
    fi
        
}

function install_scripts {
    cd "$WORKING_DIR"
    secho "Installing launch daemon scripts."
    cp -fv ./libexec/brew_update.sh "$libexec_dir/"
    cp -fv ./libexec/brew_permissions.sh "$libexec_dir/"
    cp -fv ./bin/brew.sh "$bin_dir"
    cp -fv ./bin/brew-cask.sh "$bin_dir"
    cp -fv ./bin/pip.sh "$bin_dir"
    cp -fv ./etc/sourceenv "$etc_dir"
    chown -Rfv _brew:_brew "$brew_dir"
    chmod -Rfv 755 "$brew_dir"
}

function install_daemon {
    cd "$WORKING_DIR"
    secho "Installing launch daemon property lists."
    
    cp -fv "launchd.plist/com.pmartin.homebrew.plist" "$launchd_dir"
    chown -v root:wheel "$launchd_dir/com.pmartin.homebrew.plist"
    chmod -v 644 "$launchd_dir/com.pmartin.homebrew.plist"    
    ln -sv "$launchd_dir/com.pmartin.homebrew.plist" "/Library/LaunchDaemons/com.pmartin.homebrew.plist"
    chown -hv root:wheel "/Library/LaunchDaemons/com.pmartin.homebrew.plist"
    chmod -hv 644 "/Library/LaunchDaemons/com.pmartin.homebrew.plist"

    cp -fv "launchd.plist/com.pmartin.homebrew.permissions.plist" "$launchd_dir"
    chown -v root:wheel "$launchd_dir/com.pmartin.homebrew.permissions.plist"
    chmod -v 644 "$launchd_dir/com.pmartin.homebrew.permissions.plist"
    ln -sv "$launchd_dir/com.pmartin.homebrew.permissions.plist" "/Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist"
    chown -hv root:wheel "/Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist"
    chmod -hv 644 "/Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist"
    
}

function configure_logging {
    cd "$WORKING_DIR"
    secho "Setting up logging"

    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
    fi

    chmod -vR 644 "$log_dir"
    chmod -v 755 "$log_dir"
    chmod -v +a "group:everyone deny delete" "$log_dir"
    chown -v _brew:_brew "$log_dir"
    chown -v _brew:_brew "$log_dir/brew_"*

    cp -fv "brew.conf" "/etc/newsyslog.d/"
    chmod -v 644 "/etc/newsyslog.d/brew.conf"
    
    newsyslog -NCC
    newsyslog -vvv
}

function start_daemon {
    export uid=$(dscl . read /Users/_brew UniqueID | awk '{ print $NF }')

    launchctl bootstrap system \
    /Library/LaunchDaemons/com.pmartin.homebrew.plist \
    /Library/LaunchDaemons/com.pmartin.homebrew.permissions.plist \
    
    launchctl enable system/com.pmartin.homebrew
    launchctl enable system/com.pmartin.homebrew.permissions
}

function configure_homebrew {
    if [ ! -d /usr/local/Cellar ]; then
        sudo -u $SUDO_USER ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi  
    /usr/bin/which -s git || abort "brew install git first!"
    test -d /usr/local/.git || abort "brew update first!"
 
    cd `brew --prefix`
    git checkout master
    git ls-files -z | pbcopy
    chown -R _brew:_brew Cellar
    pbpaste | xargs -0 chown -R _brew:_brew
    chown -R _brew:_brew Library/Homebrew Library/Aliases Library/Formula Library/Contributions 
    test -d Library/LinkedKegs && chown -R _brew:_brew Library/LinkedKegs
    chown -R _brew:_brew bin Library share/man/man1 2> /dev/null
    chown -R _brew:_brew .git
    if [ ! -d "$brew_dir/Library/Caches/Homebrew" ]; then
        mkdir -p "$brew_dir/Library/Caches/Homebrew"
    fi
    chown -R _brew:_brew "$brew_dir/Library/Caches/Homebrew"
    if [ ! -d "$brew_dir/Library/Logs/Homebrew" ]; then
        mkdir -p "$brew_dir/Library/Logs/Homebrew"
    fi
    chmod 755 "$brew_dir/Library/Logs/Homebrew"
    chown -R _brew:_brew "$brew_dir/Library/Logs/Homebrew"
    if [ ! -d "/Library/Caches/Homebrew" ]; then
        mkdir -p "/Library/Caches/Homebrew"
    fi
    chown -R _brew:_brew "/Library/Caches/Homebrew"
    if [ -d "/opt/homebrew-cask" ]; then
        chown -R _brew:_brew "/opt/homebrew-cask"
    fi
}

function create_aliases {
    alias brew='/opt/homebrew/bin/brew.sh'

    bashrc='/etc/bashrc'
    if [ -z "$(grep "alias brew=" ${bashrc})" ]; then
        echo "alias brew='/opt/homebrew/bin/brew.sh'" >> ${bashrc}
    fi

    if [ -z "$(grep "alias brew-cask=" ${bashrc})" ]; then
        echo "alias brew-cask='/opt/homebrew/bin/brew-cask.sh'" >> ${bashrc}
    fi

    if [ -z "$(grep "alias pip=" ${bashrc})" ]; then
        echo "alias pip='/opt/homebrew/bin/pip.sh'" >> ${bashrc}
    fi

    if [ -z "$(grep "alias gem=" ${bashrc})" ]; then
        echo "alias gem='/opt/homebrew/bin/gem.sh'" >> ${bashrc}
    fi
}

check_root
delete_existing
create_brew_group
create_brew_user
create_directories
install_scripts
install_daemon
configure_logging
configure_homebrew
start_daemon
create_aliases

popd > /dev/null
