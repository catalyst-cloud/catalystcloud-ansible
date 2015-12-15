================================
Catalyst Cloud Ansible Templates
================================

This repository provides sample playbooks that demonstrate how to use Ansible to drive the Catalyst Cloud (http://catalyst.net.nz/catalyst-cloud).

Would you like to learn more?

 - The documentation for the Catalyst Cloud can be found at: http://docs.catalystcloud.io
 - The documentation for Ansible can be found at: http://docs.ansible.com/ansible/index.html

Installing Ansible
==================

The `install-ansible.sh` script helps you to easily install Ansible (latest or stable) and the dependencies required to interact with the Catalyst Cloud (OpenStack client tools, [shade](http://docs.openstack.org/infra/shade/)) in a virtual environment.

Run `install-ansible.sh -v latest` to install the latest version of Ansible. Run the source commend printed by the script to activate the virtual environment and set up Ansible environment variables.

Run `which ansible` and `ansible --version` to confirm the correct version of Ansible is being used.

Profit!
