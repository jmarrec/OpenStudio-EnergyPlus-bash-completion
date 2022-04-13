#!/bin/bash

#if brew ls --versions bash-completion > /dev/null; then
  ## The package is installed
#else
  ## The package is not installed
  #brew install bash-completion
#fi

## ln -s /path/to/original/ /path/to/link
# Mac (Untested): sudo ln -sf $(pwd)/openstudio.sh $(brew --prefix)/etc/bash_completion.d/openstudio
# Ubuntu: sudo ln -sf $(pwd)/openstudio.sh /etc/bash_completion.d/openstudio

## brew install bash_completion
## In bash_profile:

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Darwin;;
    CYGWIN*|MINGW*|MSYS*)    machine=Windows;;
    *)          machine="UNKNOWN:${unameOut}"
  esac

if [[ $machine == Darwin ]]
then
  echo "Run: sudo ln -sf $(pwd)/openstudio.sh $(brew --prefix)/etc/bash_completion.d/openstudio.sh"

  echo "# Recommended formulae for bash-completion
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
    echo "BashCompletion loaded."
  fi
  "
else
  echo "sudo ln -sf $(pwd)/openstudio.sh /etc/bash_completion.d/openstudio"
  echo "Make sure you have bash_completion installed: sudo apt install bash-completion"
fi
