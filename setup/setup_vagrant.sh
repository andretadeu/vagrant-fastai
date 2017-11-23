#!/bin/bash

set -efu -o pipefail

source $(pwd)/setup/colors.sh

# Install vagrant-aws plugin. It allows to provision and connect to AWS EC2 Instances
install_vagrant_plugins() {
  vagrant plugin install vagrant-aws
  if [ $? -ne 0 ]
  then
    printf "${Red}Vagrant not installed! Please install Vagrant to proceed with the setup\n"
    exit 4
  fi
}
