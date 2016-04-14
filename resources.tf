/* First we'll set some variables for AWS authentication, and
   to help us configure multiple instances in different
   availability zones. */

variable "aws_access_key" {
    default = ""
}

variable "aws_secret_key" {
    default = ""
}

variable "management_ip" {
    default = ""
}

variable "provisioning_example-zones" {
    default = {
        zone0 = "eu-west-1a"
        zone1 = "eu-west-1b"
        zone2 = "eu-west-1c"
    }
}

variable "provisioning_example-cidr_blocks" {
    default = {
        zone0 = "10.11.1.0/24"
        zone1 = "10.11.2.0/24"
        zone2 = "10.11.3.0/24"
    }
}


/* We'll be using AWS for provisioning of the instances,
   so we'll set "aws" as a provider. */

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "eu-west-1"
}


/* Set up a VPC with a private /16 range. */

resource "aws_vpc" "provisioning_example" {
    cidr_block = "10.11.0.0/16"

    tags {
        Name = "provisioning_example VPC"
    }
}


/* We'll set up two subnets in different availability zones for
   high availability in case an AZ fails. Our load balancer is
   still a single point of failure on eu-west-1a; we'd be better
   off using an Elastic Load Balancer. */

resource "aws_subnet" "provisioning_example" {
    vpc_id = "${aws_vpc.provisioning_example.id}"
    cidr_block = "${lookup(var.provisioning_example-cidr_blocks, concat("zone", count.index))}"
    availability_zone = "${lookup(var.provisioning_example-zones, concat("zone", count.index))}"
    count = 2
    
    /* We could have our app instances in private IP addresses, but that would mean
       we'd need a NAT for them to access the Internet (for provisioning). We'd also need
       to use a bastion host for the SSH provisioner. For simplicity, every instance is
       set to have a public IP. */

    map_public_ip_on_launch = true 
}


/* We'll need an Internet gateway, a routing table and routing
   table associations for both of our subnets. */

resource "aws_internet_gateway" "provisioning_example" {
  vpc_id = "${aws_vpc.provisioning_example.id}"
}

resource "aws_route_table" "provisioning_example" {
  vpc_id = "${aws_vpc.provisioning_example.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.provisioning_example.id}"
  }
}

resource "aws_route_table_association" "provisioning_example" {
    subnet_id = "${element(aws_subnet.provisioning_example.*.id, count.index)}"
    route_table_id = "${aws_route_table.provisioning_example.id}"
    count = 2
}


/* Security group for the load balancer. We'll open port 80/tcp
   to the world, and port 22/tcp to our management IP. We'll allow
   everything outbound. */

resource "aws_security_group" "provisioning_example-lb" {
    name = "provisioning_example lb"
    description = "Security group for the load balancer"
    vpc_id = "${aws_vpc.provisioning_example.id}"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.management_ip}/32"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


/* Security group for the app nodes. We'll allow 8484/tcp from our load
   balancer, and 22/tcp from the management IP. */

resource "aws_security_group" "provisioning_example-app" {
    name = "provisioning_example app"
    description = "Security group for the app instances"
    vpc_id = "${aws_vpc.provisioning_example.id}"
    ingress {
        from_port = 8484
        to_port = 8484
        protocol = "tcp"
        security_groups = ["${aws_security_group.provisioning_example-lb.id}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.management_ip}/32"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


/* Our root SSH key pair is created by the wrapper script. */

resource "aws_key_pair" "root" {
    key_name = "root-key"
    public_key = "${file("id_rsa_example.pub")}"
}


/* The load balancer node is a t2.micro running Ubuntu 14.04 LTS */

resource "aws_instance" "provisioning_example-lb" {
    ami = "ami-f95ef58a"
    instance_type = "t2.micro"
    tags {
        Name = "node-lb"
    }

    /* We'll place the load balancer in the first subnet, ie. eu-west-1a. */
    subnet_id = "${aws_subnet.provisioning_example.0.id}"
    
    associate_public_ip_address = true

    key_name = "${aws_key_pair.root.key_name}"
    vpc_security_group_ids = ["${aws_security_group.provisioning_example-lb.id}"]

    /* We can't use the terraform chef provisioner, as we won't
       be running a chef server for this. Instead, we'll use a
       simple provisioning script to install and run chef-solo. */

    provisioner "file" {
        source = "chef"
        destination = "/home/ubuntu"
        connection {
            user = "ubuntu"
            key_file = "id_rsa_example"
            timeout = "60s"
        }
    }

    /* We pass the private IP addresses of our app nodes to the provisioning script,
       which in turn passes them to Chef to be used in the nginx config template. */

    provisioner "remote-exec" {
        inline = [
          	"chmod +x /home/ubuntu/chef/provision.sh",
          	"APP_NODES=${join(",", aws_instance.provisioning_example-app.*.private_ip)} /home/ubuntu/chef/provision.sh lb"
        ]
        connection {
            user = "ubuntu"
            key_file = "id_rsa_example"
            timeout = "60s"
        }
    }
}


/* The app nodes are also t2.micros running Ubuntu 14.04 LTS
   for simplicity. We place the app nodes in different AZs. */

resource "aws_instance" "provisioning_example-app" {
    ami = "ami-f95ef58a"
    instance_type = "t2.micro"
    tags {
        Name = "node-app${count.index}"
    }
    count = 2
    subnet_id = "${element(aws_subnet.provisioning_example.*.id, count.index)}"
    associate_public_ip_address = true

    key_name = "${aws_key_pair.root.key_name}"
    vpc_security_group_ids = ["${aws_security_group.provisioning_example-app.id}"]

    provisioner "file" {
        source = "chef"
        destination = "/home/ubuntu"
        connection {
            user = "ubuntu"
            key_file = "id_rsa_example"
            timeout = "60s"
        }
    }

    provisioner "remote-exec" {
        inline = [
          	"chmod +x /home/ubuntu/chef/provision.sh",
          	"/home/ubuntu/chef/provision.sh app"
        ]
        connection {
            user = "ubuntu"
            key_file = "id_rsa_example"
            timeout = "60s"
        }
    }
}


/* We'll need the load balancer IP to verify it works */

output "lb-ip" {
    value = "${aws_instance.provisioning_example-lb.public_ip}"
}
