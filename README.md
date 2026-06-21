# dotfiles

## Install

```
git clone <repo> ~/dev/dotfiles
cd ~/dev/dotfiles
./install
```

After install, open tmux and press `prefix + I` to install plugins.

### Set fish as default shell

If fish is not your default shell:

```
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)
```

Then log out and back in.
