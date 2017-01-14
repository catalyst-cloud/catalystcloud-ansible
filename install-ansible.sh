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

# Set Ansible python virtual environment name
ANSIBLE_VENV="ansible-venv"

# check if we already have ansible installed when installing the stable version
# abort or delete depending on the version we have installed
if [[ "$VERSION" == "stable" ]]; then
  ANSIBLE_VENV_BIN="$PWD/$ANSIBLE_VENV/bin/ansible"
  if [[ -f $ANSIBLE_VENV_BIN ]]; then
    # this may or may not be the latest stable version of ansible
    STABLE_VERSION="2.1.1.0"
    CURRENT_VERSION=$( $ANSIBLE_VENV_BIN --version | awk '/^ansible/{ print $2 }' )
    if [ "${CURRENT_VERSION//.}" -lt "${STABLE_VERSION//.}" ]; then
      echo "Deleting your install of Ansible $CURRENT_VERSION as a newer stable version is available"
      rm -r "$PWD/$ANSIBLE_VENV"
    else
      echo "Aborting as Ansible $CURRENT_VERSION is already installed at $ANSIBLE_VENV_BIN"
      exit 1
    fi
  fi
fi

echo "Installing $VERSION version of Ansible"

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

RUN_PACKAGE_MANAGER=true;
# Ensure python-dev is installed.
if [[ -f /etc/debian_version ]] || [[ -f /etc/lsb_release ]]; then
  PKG_MANAGER="apt"
  PACKAGES="python-dev python-setuptools python-pip gcc git libssl-dev libffi-dev"
  if check_debian_packages "$PACKAGES"; then
    RUN_PACKAGE_MANAGER=false;
  fi
elif [[ -f /etc/redhat-release ]] || [[ -f /etc/fedora-release ]]; then
  PKG_MANAGER="yum"
  PACKAGES="python-devel python-setuptools python-pip gcc git"
fi

if [ "$RUN_PACKAGE_MANAGER" = true ]; then
    sudo $PKG_MANAGER update
    sudo $PKG_MANAGER -y install $PACKAGES
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

# Create and activate a python2 virtual environment for Ansible.
if ! virtualenv --python=python2 "$ANSIBLE_VENV"; then
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

# Installing theese modules fixes Python urllib3 SNIMissingWarning and InsecurePlatformWarning
# when running the opestack clients
# https://urllib3.readthedocs.org/en/latest/security.html#insecureplatformwarning.
# https://urllib3.readthedocs.org/en/latest/security.html#snimissingwarning.
# This only runs on ubuntu 14.04, enable this for other distros as required
if lsb_release -r -s | grep -q '14.04'; then
  if ! pip install pyopenssl ndg-httpsclient pyasn1; then
    echo "Could not install extra python packages on 14.04."
    exit 1
  fi
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
if ! pip install shade; then
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
echo "To activate run the following command:"
echo
if [[ "$VERSION" == "stable" ]]; then
  echo "source $PWD/$ANSIBLE_VENV/bin/activate"
else
  echo "source $PWD/$ANSIBLE_VENV/bin/activate && source $PWD/$ANSIBLE_VENV/ansible/hacking/env-setup"
fi
echo
exit 0
