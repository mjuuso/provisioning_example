#!/bin/bash
#
# A simple provisioning script that is run on both the app and lb nodes.

# Piping curl to bash is always an interesting idea.
# We'll, however, trust this now for installing Chef.

curl -L https://www.opscode.com/chef/install.sh | sudo bash

if [[ "$1" == "app" ]]; then
	echo "Provisioning an application node"
	sudo chef-solo -c chef/solo.rb -o example_app

elif [[ "$1" == "lb" ]]; then
	echo "Provisioning a load balancer node, app nodes: $APP_NODES"
	# we need -E to pass the environment to chef-solo; namely $APP_NODES
	sudo -E chef-solo -c chef/solo.rb -o example_web
fi