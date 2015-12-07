#!/bin/bash
# This script installs the latest version of Ansible and the OpenStack
# client libraries in an isolated python virtual environment.

# Ensure python-dev is installed.
if [[ -f /etc/debian_version ]] || [[ -f /etc/lsb_release ]]; then
  PKG_MANAGER="apt"
  PACKAGES="python-dev gcc git"
elif [[ -f /etc/redhat-release ]] || [[ -f /etc/fedora-release ]]; then
  PKG_MANAGER="yum"
  PACKAGES="python-devel gcc git"
fi
sudo $PKG_MANAGER update
sudo $PKG_MANAGER install $PACKAGES

# Ensure Python virtualenv and pip are installed.
if ! which pip; then
  echo "Could not find python pip on \$PATH"
  echo "Installing pip via easy_install (sudo password may be required)"
  sudo easy_install pip
  if ! which pip; then
    echo "Could not install pip using easy_install."
    echo "This script requires python pip installed."
    exit 1
  fi
fi
if ! which virtualenv; then
  echo "Could not find virtualenv on \$PATH"
  echo "Installing virtualenv via easy_install (sudo password may be required)"
  sudo easy_install virtualenv
  if ! which virtualenv; then
    echo "Could not install virtualenv using easy_install."
    echo "This script requires python virtualenv installed."
    exit 1
  fi
fi

# Create and activate virtual environment for Ansible.
if ! virtualenv ansible; then
  echo "Failed to create virtual environment for ansible on current location."
  exit 1
fi
source ansible/bin/activate

# Install the dependencies version of Ansible.
if ! pip install paramiko PyYAML Jinja2 httplib2 six pycrypto markupsafe; then
  echo "Could not install the dependenceis for Ansible."
  exit 1
fi

# Install the selected version of Ansible.
if [[ "$1" == "latest" ]]; then
  cd ansible
  if [[ -d "ansible" ]]; then
    rm -rf ansible
  fi
  if ! git clone git://github.com/ansible/ansible.git --recursive; then
    echo "Could not install the latest version of Ansible."
    exit 1
  fi
else
  if ! pip install ansible; then
    echo "Could not install the stable version of Ansible."
    exit 1
  fi
fi

# Install the shade library and the OpenStack client libraries.
if ! pip install shade; then
  echo "Could not install the OpenStack client tools and shade"
  exit 1
fi

echo ""
echo "Ansible installed successfully!"
echo "Please remember to activate its virtual environment before using it, by"
echo "running the following command:"
echo "source $PWD/ansible/bin/activate && source $PWD/ansible/ansible/hacking/env-setup" 
exit 0

