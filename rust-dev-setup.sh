#!/bin/sh

basecmd=process
subcmd=install
datadir="${XDG_DATA_HOME:-$HOME/.local/share}"
configsrepo=https://raw.githubusercontent.com/andrewkboyd/configs/master
secureopts=--proto '=https' --tlsv1.3

if [ "$#" -ge 1 ]; then
	subcmd=$1
	shift
fi

# If uninstalling just do it and shortcut out, anything else means install / setup
# Only remove things that we know we installed
case $subcmd in
	uninstall)
		echo '\e[32mRemoving installed packages...\e[0m'
		sudo apt-get remove tmux fonts-powerline git curl
    rustup self uninstall
		echo '\e[32mRemoving configuration files...\e[0m'
		rm ~/.tmux.conf
		rm -r ~/.config/nvim/
		rm -r $datadir/nvim/
		exit 0
		;;
	*)
		echo '\e[32mSetting up Rust Development Environment\e[0m'
esac

# It is the user responsibility to update the system first
# a reboot may be desired after this to make sure kernel headers and libraries are reloaded
echo '\e[32mUpdating system...\e[0m'
sudo apt-get update
sudo apt-get full-upgrade

# make sure we have the packages we need
echo '\e[32mMaking sure we have the packages we need...\e[0m'
sudo apt-get install neovim curl git fonts-powerline tmux -y
if [ $? -ne 0 ]; then
  echo '\e[31mFailed to install packages!\e[0m'
  exit 1
fi

echo '\e[32mWorking from the $HOME directory for configuration\e[0m'
cd $HOME
if [ $? -ne 0 ]; then
  echo '\e[31mNo $HOME variable or directory not found?\e[0m'
  exit 1
fi

# Configure tmux
echo '\e[32mConfigure tmux\e[0m'
curl -fsSO $secureopts $configsrepo/.tmux.conf
if [ $? -ne 0 ]; then
  echo '\e[31mFailed to get .tmux.conf!\e[0m'
  exit 1
fi

echo '\e[32mConfigure neovim\e[0m'
# Install vim-plug
curl --create-dirs $secureopts -sSfLo $datadir/nvim/site/autoload/plug.vim \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
if [ $? -ne 0 ]; then
  echo '\e[31mFailed to get vim-plug!\e[0m'
  exit 1
fi

# Install configuration file
curl --create-dirs $secureopts -sSfLo ~/.config/nvim/init.vim $configsrepo/.config/nvim/init.vim
if [ $? -ne 0 ]; then
  echo '\e[31mFailed to get neovim configuration!\e[0m'
  exit 1
fi

# Update / Install plugins
vim +PlugInstall +UpdateRemotePlugins +qa
if [ $? -ne 0 ]; then
  echo '\e[31mFailed to install neovim plugins!\e[0m'
  exit 1
fi

# Install Rust
echo '\e[32mInstall & Configure rust\e[0m'
curl $secureopts -sSfo rust-install.sh https://sh.rustup.rs
chmod +x rust-install.sh
./rust-install.sh -y
rm rust-install.sh
if [ $? -ne 0 ]; then
  echo '\e[31mFailed to install rust!\e[0m'
  exit 1
fi

echo '\e[32mMaking sure to exit and restart your terminal for fonts to take effect...\e[0m'
echo '\e[32mDone!\e[0m'
