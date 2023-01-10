# OpenStudio-EnergyPlus-bash-completion.git

Bash completions for the OpenStudio and EnergyPlus CLIs.

## Installation

### Mac:

```shell
brew install bash-completion
# Symlink or copy it (Untested)
sudo ln -sf $(pwd)/openstudio.sh $(brew --prefix)/etc/bash_completion.d/openstudio
```

Make sure your `~/.bash_profile` loads it too

```shell
# Recommended formulae for bash-completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi
```

### Ubuntu

```shell
sudo apt install bash-completion
# Symlink or copy it here:
sudo ln -sf $(pwd)/openstudio.sh /etc/bash_completion.d/openstudio
```
