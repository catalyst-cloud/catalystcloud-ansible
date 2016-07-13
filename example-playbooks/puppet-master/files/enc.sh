#! /usr/bin/env bash
# Return back 'yaml' including scraped role property as profile

. /etc/openstack.rc

ROLE=`openstack server show $1 -f json | jq .properties | ruby -e "puts /role='([^.]+)'/.match(STDIN.read)[1]"`
echo "classes: ['roles::$ROLE']"
