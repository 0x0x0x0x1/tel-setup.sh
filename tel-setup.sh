#!/usr/bin/env bash
# ~ TEL setup file ~ #
tel_version=0.1
source ~/../usr/bin/tel-helpers 
# cp self to tmpdir
#run update here
#~/../usr/bin/tel-update > /dev/null
# run diff agaisnt old tel-setup



if [ -z "$1" ]; then
	update_args="--setup"
else
	update_args="$1"
fi

# SHOULD CHECK HERE IF UPDATE IS NEEDED if so update then re run setup
UPDATE=false

if [ -f ~/.tel/.installed ]; then #set update var if finished installation was detected
	logf ".installed exists"
	error "TEL appears to already be installed. Continuing will replace all TEL files, you may also lose user configuration files. It is recommended to take a backup if you wish to continue. (command: tel-backup)"
	warn "Are you sure you want to continue? (y/N)"
	read -r user_reponse
	if [ "$user_reponse" != 'y' ] && [ "$user_reponse" != 'Y' ]; then
		error 'User exited the setup'
		exit 0
	fi
fi

check_connection

rm -rf ~/../etc/motd # avoids user prompt to maintain motd
rm -rf ~/../usr/etc/motd
log "Updating Termux packages..."
logf "apt-get upgrade"
apt-get update -y && apt-get upgrade -y && logf "finished updating Termux packages" #print to screen as hotfix

log "Installing required packages"
log "This may take a while..."
logf "pkg install"
catch "$(pkg install git make curl wget nano tmux zsh termux-api sed figlet util-linux fzf fd bat links imagemagick openssh bc sl jq pup eza termimage ncurses-utils tsu man -y 2>&1)"
# maybe add: neofetch cronie moreutils, rmed tree cowsay
log "Installing python"
logf "python install"
catch "$(pkg install python -y 2>&1)" 

log "Installing python package manager"
logf "pip install"
which -a pip | grep -q '[n]ot found' && catch "$(curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py 2>&1)" && catch "$(python get-pip.py 2>&1)" && rm -f get-pip.py #skip reinstalling if pip exists

log "Installing python packages"
logf "pip pkgs install"
catch "$(pip install --user blessed pywal lolcat powerline-status 2>&1)" #removed psutil
logf "Finished packages download and installation"

#create required directories
mkdir -p ~/.termux
mkdir -p ~/.tel
mkdir -p ~/.config
mkdir -p ~/bin

# # # # ZSH setup # # #
log "Installing OMZ"
logf "ohmyzsh"
chsh -s zsh #set zsh default shell
rm -rf ~/../etc/motd 
rm -rf ~/.oh-my-zsh #incase setup is reran (must clone to empty dirs)
rm -rf ~/.tel/shell #incase setup is reran (must clone to empty dirs)
catch "$(git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh 2>&1)"
if [ -f ~/.zshrc ] ; then
	cp -f ~/.zshrc ~/.zshrc.bak #backup previous 
fi

cp -f ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# Get updates!
log "Fetching updates..."
logf "running tel-update"
~/../usr/bin/tel-update $update_args

log "Installing shell plugins"
logf "cloning plugins"
catch "$(git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k 2>&1)"
#run p10k installer now
catch "$(sh ~/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install 2>&1)"
catch "$(git clone --depth=1 https://github.com/securisec/fast-syntax-highlighting.git ~/.oh-my-zsh/plugins/fast-syntax-highlighting 2>&1)"
#catch "$(git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/plugins/zsh-completions 2>&1)"
catch "$(git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions 2>&1)"
catch "$(git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete ~/.oh-my-zsh/plugins/zsh-autocomplete 2>&1)"
catch "$(git clone --depth=1 https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/plugins/fzf-tab 2>&1)"
#catch "$(git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search ~/.tel/shell/plugins/zsh-history-substring-search 2>&1)"
#sed -i 's/robbyrussell/avit/g' ~/.zshrc
sed -i 's/robbyrussell/powerlevel10k\/powerlevel10k/g' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(fzf-tab fancy-ctrl-z zsh-autosuggestions fast-syntax-highlighting)/g' ~/.zshrc 
#removed magic-enter common-aliases 

## Anisay ##
if [ ! -d ~/.tel/anisay ]; then
log "Installing anisay"
catch "$(git clone --depth=1 https://github.com/sealedjoy/anisay ~/.tel/anisay 2>&1)"
catch "$(cd ~/.tel/anisay && ~/.tel/anisay/install.sh 2>&1)"
fi
#
# # # insert TEL loading file into .zshrc # # # 
echo -e "	\n#|||||||||||||||#\n. ~/.tel/.telrc\n#|||||||||||||||#\n	" >> ~/.zshrc

if [ -f "$HOME/../usr/etc/motd_finished" ]; then
	#mv ~/../usr/etc/motd_finished ~/../usr/etc/motd #set final motd
	(rm -rf ~/../usr/etc/motd)
fi

fix_permissions
logf "fixing permissions"

if [ "$UPDATE" = false ]; then
	echo -ne "$tel_version" > ~/.tel/.installed #mark setup finished
        log "Installation Complete"
else
        log "Update Complete"
fi
theme --alpha 99 > /dev/null 2>&1
logf "complete"
log "app will restart in five seconds!"
sleep 10
# fix in tmux and aliases 
sed -i 's/3.10/3.11/' ~/.tel/.tel_tmux.conf
sed -i 's/exa/eza/' ~/.aliases
tel-restart
error 'Restart cannot be performed when app is not active on screen!'
log "press RETURN to retry"
read 
tel-restart
error 'Please run the command "tel-restart" manually'
exit 0
