# ansible
As any 'sudo' user, execute
```bash
curl https://raw.githubusercontent.com/cpollet/ansible/master/bootstrap.sh | /bin/bash
```
You can customize the ansible repo with the `ANSIBLE_REPO` env variable.

Then you may want to execute any of the following tags:
 * dev
 * profile

using
```base
ansible-pull \
  --ask-become-pass \
  -t TAG \
  -U https://github.com/cpollet/ansible.git
```

you can customize the dotfiles repo with the `DOTFILES_REPO` env variable.