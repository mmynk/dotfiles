#!/bin/bash

set -e

function safe_install() {
    if command -v $1 &> /dev/null
    then
        echo "$1 already exists"
    else
        /bin/bash -c "$2"
    fi

    echo
    echo
}

echo '================='

# install Homebrew [brew.sh]
echo 'Installing Homebrew'
safe_install brew "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo '-----------------'

# check if brew is installing latest version from [https://iterm2.com/downloads.html]
echo 'Installing iterm2'
safe_install iterm2 "brew install --cask iterm2"
echo '-----------------'

# install zsh
echo 'Installing zsh'
safe_install zsh "brew install zsh"
echo '-----------------'

# make zsh default
echo 'Making zsh default shell'
chsh -s /bin/zsh
echo '-----------------'

# install oh-my-zsh
# echo 'Installing oh-my-zsh'
# /bin/bash -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# echo '-----------------'

# copy zshrc
echo 'Overriding zshrc'
mv ~/.zshrc ~/.zshrc-bak
cp .zshrc ~/
echo '-----------------'

# install sublime text
echo 'Installing sublime text'
safe_install subl "brew cask install sublime-text"
echo '-----------------'

# link subl to sublime text
echo 'Linking sublime text'
ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
echo '-----------------'

echo 'Installing pyenv'
safe_install pyenv "brew install pyenv"
echo '-----------------'

echo 'Installing python3'
pyenv install 3
echo '-----------------'

echo
echo 'Done!'
echo '================='
