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
  echo "Failed to create virtual environment for Ansible at current location."
  exit 1
fi
source ansible/bin/activate

# Install the dependencies for Ansible.
if ! pip install paramiko PyYAML Jinja2 httplib2 six pycrypto markupsafe; then
  echo "Could not install the dependencies for Ansible."
  exit 1
fi

# Install the selected version of Ansible.
if [[ "$VERSION" == "latest" ]]; then
  if [[ -d "ansible/ansible" ]]; then
    rm -rf ansible/ansible
  fi
  if ! git clone git://github.com/ansible/ansible.git --recursive ansible/ansible; then
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
echo "Please remember to activate its virtual environment before using it, by"
echo "running the following command:"
if [[ "$VERSION" == "stable" ]]; then
  echo "source $PWD/ansible/bin/activate"
else
  echo "source $PWD/ansible/bin/activate && source $PWD/ansible/ansible/hacking/env-setup"
fi
echo
exit 0
