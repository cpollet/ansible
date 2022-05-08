#!/bin/bash

[ -z "$ANSIBLE_REPO" ] && ANSIBLE_REPO=https://github.com/cpollet/ansible.git

sudo apt-get --yes install software-properties-common
sudo apt-add-repository --yes ppa:ansible/ansible
sudo apt-get update
sudo apt-get --yes install ansible git

ansible-pull \
  --ask-become-pass \
  -t base \
  -U $ANSIBLE_REPO
