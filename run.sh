#!/bin/bash
#
# Run the provisioning example.

# We have a few prerequisites
[[ ! -x "$(which terraform)" ]] && echo "Couldn't find terraform in your PATH. Please see https://www.terraform.io/downloads.html" && exit 1
[[ ! -x "$(which curl)" ]] && echo "Couldn't find curl in your PATH." && exit 1
[[ ! -x "$(which ssh)" ]] && echo "Couldn't find ssh in your PATH." && exit 1
[[ ! -x "$(which ssh-keygen)" ]] && echo "Couldn't find ssh-keygen in your PATH." && exit 1

if [[ "$1" == "" || "$2" == "" ]]; then
	echo "Usage: $0 <aws_access_key> <aws_secret_key>"
	exit 1
fi

# Generate the SSH key pair, if it doesn't exist
if [[ ! -f "id_rsa_example" ]]; then
	echo "Generating 4096-bit RSA SSH key pair. This can take a few seconds."
	ssh-keygen -t rsa -b 4096 -f id_rsa_example -N ""
fi

# Grab our external IP for the security groups
MANAGEMENT_IP=$(curl -s http://ipinfo.io/ip)
[[ ! "$MANAGEMENT_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo "Couldn't determine your external IP: $MANAGEMENT_IP" && exit 1

terraform apply -var 'aws_access_key='"$1"'' -var 'aws_secret_key='"$2"'' -var "management_ip=$MANAGEMENT_IP"

# Verify that the load balancer works as expected
echo "Provisioning complete:"
curl -s $(terraform output lb-ip)
echo ""
curl -s $(terraform output lb-ip)
