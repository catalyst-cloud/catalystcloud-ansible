#!/bin/bash
# This script installs the latest version of Ansible and the OpenStack
# client libraries in an isolated python virtual environment.

# Ensure Python virtualenv and pip are installed
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

# Create and activate virtual environment for Ansible
if ! virtualenv ansible; then
  echo "Failed to create virtual environment for ansible on current location."
  exit 1
fi
source ansible/bin/activate

# Install the latest version of Ansible
if ! pip install ansible Jinja2 httplib2 six; then
  echo "Could not install the latest version of Ansible."
  exit 1
fi

# Install the shade library and the OpenStack client libraries
if ! pip install shade; then
  echo "Could not install the OpenStack client tools and shade"
  exit 1
fi

echo "Ansible installed successfully!"
echo "Please remember to activate its virtual environment before using it:"
echo "source $PWD/ansible/bin/activate"

exit 0

