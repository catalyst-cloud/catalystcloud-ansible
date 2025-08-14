Catalyst Cloud Ansible Templates
================================

This repository provides sample playbooks that demonstrate how to use Ansible
with Catalyst Cloud (https://catalystcloud.nz).

Would you like to learn more?

 - The documentation for Catalyst Cloud can be found at:
   http://docs.catalystcloud.nz
 - The documentation for Ansible can be found at:
   http://docs.ansible.com/ansible/index.html

Installing Ansible
==================

The `install-ansible.sh` script helps you to easily install Ansible (latest or
stable) and the dependencies required to interact with Catalyst Cloud
(OpenStack client tools, [shade](http://docs.openstack.org/infra/shade/)) in a
virtual environment.

Run `install-ansible.sh -v latest` to install the latest version of Ansible.
Run the source command printed by the script to activate the virtual
environment and set up Ansible environment variables.

Run `which ansible` and `ansible --version` to confirm the correct version of
Ansible is being used.

.. Note::

  This installer no longer supports Python 2.x, as it has been deprecated and is nearing
  end of life.

Sample Playbooks
================

The `cookbooks` directory provides code examples that demonstrate how to
perform common operation with Ansible, such as loops, dict lookups, etc.

All other directories are named after specific services provided by
Catalyst Cloud and illustrate how to use them via Ansible.

