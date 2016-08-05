#!/bin/bash

# This script installs the latest version of Ansible and the OpenStack
# client libraries in an isolated python virtual environment.

################################################################################
# Functions
################################################################################

help() {
  echo "usage: $0 [-v version]"
  echo ""
  echo "optional arguments:"
  echo "-v version, --version version    valid versions: latest, stable"
  echo "-h, --help                       prints help information"
}


################################################################################
# Main()
################################################################################

# Set Ansible python virtual environment name
ANSIBLE_VENV="ansible-venv"

# Parse command line arguments
VERSION="stable"
while [ $# -ge 1 ]; do
  case $1 in
    --)
      # no more arguments
      shift
      break
      ;;
    -v|--version)
      VERSION="$2"
      shift
      ;;
    -h|--help)
      help
      exit 0
      ;;
    *)
      echo "Unknown argument $1"
      exit 1
      ;;
  esac
  shift
done

echo "Installing $VERSION version of Ansible"

# Ensure python-dev is installed.
if [[ -f /etc/debian_version ]] || [[ -f /etc/lsb_release ]]; then
  PKG_MANAGER="apt"
  PACKAGES="python-dev python-setuptools python-pip gcc git libssl-dev libffi-dev"
elif [[ -f /etc/redhat-release ]] || [[ -f /etc/fedora-release ]]; then
  PKG_MANAGER="yum"
  PACKAGES="python-devel python-setuptools python-pip gcc git"
fi
sudo $PKG_MANAGER update
sudo $PKG_MANAGER -y install "$PACKAGES"

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
if ! virtualenv "$ANSIBLE_VENV"; then
  echo "Failed to create virtual environment for Ansible at current location."
  exit 1
fi
source "$ANSIBLE_VENV/bin/activate"

# Update pip to latest version.
if ! pip install -U pip; then
  echo "Could not update pip."
  exit 1
fi

# Updating setuptools fixes this warning (see https://github.com/ansible/ansible/pull/16723)
# [WARNING]: Optional dependency 'cryptography' raised an exception, falling back to 'Crypto'
# Update setuptools to latest version.
if ! pip install -U setuptools; then
  echo "Could not update setuptools."
  exit 1
fi

# Install the selected version of Ansible.
if [[ "$VERSION" == "latest" ]]; then
  if [[ -d "$ANSIBLE_VENV/ansible" ]]; then
    rm -rf "$ANSIBLE_VENV/ansible"
  fi
  if ! git clone git://github.com/ansible/ansible.git --recursive "$ANSIBLE_VENV/ansible"; then
    echo "Could not install the latest version of Ansible."
    exit 1
  fi
elif [[ "$VERSION" == "stable" ]]; then
  if ! pip install ansible; then
    echo "Could not install the stable version of Ansible."
    exit 1
  fi
else
  echo "Unknown version: $VERSION."
  echo "Valid versions are stable and latest."
  exit 1
fi

# Install the shade library and the OpenStack client libraries.
if ! pip install shade; then
  echo "Could not install the OpenStack client tools and shade"
  exit 1
fi

echo
echo "Ansible installed successfully!"
echo
echo "To activate run the following command:"
echo
if [[ "$VERSION" == "stable" ]]; then
  echo "source $PWD/$ANSIBLE_VENV/bin/activate"
else
  echo "source $PWD/$ANSIBLE_VENV/bin/activate && source $PWD/$ANSIBLE_VENV/ansible/hacking/env-setup"
fi
echo
exit 0
