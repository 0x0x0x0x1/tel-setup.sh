#!/usr/bin/env bash
# ~ TEL setup file ~ #
tel_version=0.1
source ~/../usr/bin/tel-helpers

# Initial setup: Update package lists, setup storage, and install essential tools
pkg update -y
termux-setup-storage
pkg install wget which -y

# Function to clone Git repositories with error handling
clone_repo() {
    local repo_url=$1
    local dest_dir=$2
    if [ -d "$dest_dir" ]; then
        rm -rf "$dest_dir"
    fi
    catch "$(git clone --depth=1 "$repo_url" "$dest_dir" 2>&1)"
}

# Function to install packages
install_packages() {
    local packages=$1
    log "Installing required packages: $packages"
    catch "$(pkg install $packages -y 2>&1)"
}

# Function to check if update is needed
check_update() {
    # Add logic to check if an update is needed
    # This could be a version comparison or a checksum verification
    return 0
}

if [ -z "$1" ]; then
    update_args="--setup"
else
    update_args="$1"
fi

UPDATE=false
if [ -f ~/.tel/.installed ]; then
    logf ".installed exists"
    error "TEL appears to already be installed. Continuing will replace all TEL files, you may also lose user configuration files. It is recommended to take a backup if you wish to continue. (command: tel-backup)"
    warn "Are you sure you want to continue? (y/N)"
    read -r user_response
    if [ "$user_response" != 'y' ] && [ "$user_response" != 'Y' ]; then
        error 'User exited the setup'
        exit 0
    fi
fi

check_connection

rm -rf ~/../etc/motd ~/../usr/etc/motd
log "Updating Termux packages..."
apt-get update -y && apt-get upgrade -y && logf "Finished updating Termux packages"

install_packages "git make curl wget nano tmux zsh termux-api sed figlet util-linux fzf fd bat links imagemagick openssh bc sl jq pup eza termimage ncurses-utils tsu man"
install_packages "python"

log "Installing python package manager"
which -a pip | grep -q '[n]ot found' && catch "$(curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py 2>&1)" && catch "$(python get-pip.py 2>&1)" && rm -f get-pip.py

log "Installing python packages"
catch "$(pip install --user blessed pywal lolcat powerline-status 2>&1)"

mkdir -p ~/.termux ~/.tel ~/.config ~/bin

log "Installing Oh My Zsh"
chsh -s zsh
clone_repo "https://github.com/ohmyzsh/ohmyzsh.git" "~/.oh-my-zsh"
[ -f ~/.zshrc ] && cp -f ~/.zshrc ~/.zshrc.bak
cp -f ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

log "Fetching updates..."
~/../usr/bin/tel-update $update_args

log "Installing shell plugins"
clone_repo "https://github.com/romkatv/powerlevel10k.git" "~/.oh-my-zsh/custom/themes/powerlevel10k"
sh ~/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install
clone_repo "https://github.com/securisec/fast-syntax-highlighting.git" "~/.oh-my-zsh/plugins/fast-syntax-highlighting"
clone_repo "https://github.com/zsh-users/zsh-autosuggestions.git" "~/.oh-my-zsh/plugins/zsh-autosuggestions"
clone_repo "https://github.com/marlonrichert/zsh-autocomplete.git" "~/.oh-my-zsh/plugins/zsh-autocomplete"
clone_repo "https://github.com/Aloxaf/fzf-tab.git" "~/.oh-my-zsh/plugins/fzf-tab"
sed -i 's/robbyrussell/powerlevel10k\/powerlevel10k/g' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(fzf-tab fancy-ctrl-z zsh-autosuggestions fast-syntax-highlighting)/g' ~/.zshrc

if [ ! -d ~/.tel/anisay ]; then
    log "Installing anisay"
    clone_repo "https://github.com/sealedjoy/anisay.git" "~/.tel/anisay"
    catch "$(cd ~/.tel/anisay && ~/.tel/anisay/install.sh 2>&1)"
fi

echo -e "\n#|||||||||||||||#\n. ~/.tel/.telrc\n#|||||||||||||||#\n" >> ~/.zshrc

if [ -f "$HOME/../usr/etc/motd_finished" ]; then
    rm -rf ~/../usr/etc/motd
fi

fix_permissions
logf "Fixing permissions"

if [ "$UPDATE" = false ]; then
    echo -ne "$tel_version" > ~/.tel/.installed
    log "Installation Complete"
else
    log "Update Complete"
fi

theme --alpha 99 > /dev/null 2>&1
logf "Complete"
log "App will restart in five seconds!"
sleep 10
sed -i 's/3.10/3.11/' ~/.tel/.tel_tmux.conf
sed -i 's/exa/eza/' ~/.aliases
tel-restart || {
    error 'Restart cannot be performed when the app is not active on screen!'
    log "Press RETURN to retry"
    read
    tel-restart
    error 'Please run the command "tel-restart" manually'
}
exit 0 and
