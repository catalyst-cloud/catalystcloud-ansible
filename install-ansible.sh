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
  echo "-n venv-name, --name venv-name   override the default python virtual environment name"
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
    -n|--name)
      ANSIBLE_VENV="$2"
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

check_debian_packages() {
  PACKAGES=$1
  for package in $PACKAGES; do
    dpkg-query -Wf'${db:Status-abbrev}' $package 2>/dev/null | grep -q '^i'
    if [ $? != 0 ]; then
      return 1;
    fi
  done
  return 0;
}

check_python3_exists() {
  if [ `python -c 'import sys; print(list(sys.version_info)[:1][0])'` != 2 ]; then
    which python3
    if [ $? != 0 ]; then
      echo -e "\nError: This script requires python3 in order to run.\n"
      exit 1
    fi
  fi
}

# check python3 is available or exit.
check_python3_exists

echo "Installing $VERSION version of Ansible to $ANSIBLE_VENV python virtual environment"

# Install the required packages
RUN_PACKAGE_MANAGER=true;
if [[ -f /etc/debian_version ]] || [[ -f /etc/lsb_release ]]; then
  PKG_MANAGER="apt"
  # PACKAGES="build-essential gcc git libffi-dev libssl-dev python-dev python-pip python-setuptools"
  PACKAGES="build-essential gcc git libffi-dev libssl-dev python3-dev python3-pip python3-setuptools"
  if check_debian_packages "$PACKAGES"; then
    RUN_PACKAGE_MANAGER=false;
  fi
elif [[ -f /etc/redhat-release ]] || [[ -f /etc/fedora-release ]]; then
  PKG_MANAGER="yum"
  PACKAGES="gcc git python3-devel python3-pip python3-setuptools"
elif [[ -f /etc/solus-release ]]; then
  PKG_MANAGER="eopkg"
  PACKAGES="gcc git pip3 python3-devel python3-setuptools"
else
  echo "Unknown Linux distribution."
  echo "Please ensure the packages $PACKAGES are installed before proceeding."
  echo "Press ENTER to continue."
  read
fi
if [ "$RUN_PACKAGE_MANAGER" = true ]; then
  case "$PKG_MANAGER" in
    "apt")
      sudo $PKG_MANAGER update
      sudo $PKG_MANAGER -y install $PACKAGES
      ;;
    "yum")
      sudo $PKG_MANAGER -y update
      sudo $PKG_MANAGER -y groupinstall 'Development Tools'
      sudo $PKG_MANAGER -y install $PACKAGES
      ;;
    "eopkg")
      sudo $PKG_MANAGER it -c system.devel
      sudo $PKG_MANAGER install $PACKAGES
      ;;
  esac
fi

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

# Create and activate a python3 virtual environment for Ansible.
if ! virtualenv --python=python3 "$ANSIBLE_VENV"; then
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
  if ! pip install jinja2; then
    echo "Could not install jinja2 as a dependency for Ansible."
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
if ! pip install shade python-openstackclient openstacksdk; then
  echo "Could not install the OpenStack client tools and shade"
  exit 1
fi

# Install dnspython so we can do opendns lookups
# this lets us create better default security group rules
if ! pip install dnspython; then
  echo "Could not install dnspython"
  exit 1
fi

echo
echo "Ansible installed successfully!"
echo
echo "The following versions are installed in $PWD/$ANSIBLE_VENV:"
echo
"$PWD/$ANSIBLE_VENV/bin/pip" freeze | egrep 'ansible|shade|openstackclient|openstacksdk'
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
