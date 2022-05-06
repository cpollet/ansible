#!/bin/bash

# cat bootstrap.sh | /bin/bash

sudo apt-get --yes install software-properties-common
sudo apt-add-repository --yes ppa:ansible/ansible
sudo apt-get update
sudo apt-get --yes install ansible git

ansible-pull \
  --ask-become-pass \
  -t base,dev \
  -U https://github.com/cpollet/ansible.git
