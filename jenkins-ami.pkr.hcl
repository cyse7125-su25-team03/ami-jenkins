packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0, < 2.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_profile" {
  type    = string
  default = "root"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_name" {
  type    = string
  default = "jenkins-caddy-ubuntu-24-04"
}

variable "ami_source" {
  type    = string
  default = "ami-04b4f1a9cf54c11d0"
}

variable "volume_size" {
  type    = number
  default = 8
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0235c64467cb3be7d"
}

source "amazon-ebs" "ubuntu" {
  ami_name        = "${var.ami_name}-{{timestamp}}"
  ami_description = "Jenkins with Caddy AMI built on Ubuntu 24.04 LTS"
  instance_type   = var.instance_type
  region          = var.region
  source_ami      = var.ami_source

  ssh_username = var.ssh_username
  subnet_id    = var.subnet_id

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = var.volume_size
    volume_type           = "gp2"
  }

  tags = {
    Name        = "Jenkins with Caddy AMI"
    Environment = "production"
    Service     = "jenkins"
    OS          = "Ubuntu 24.04 LTS"
  }
}

build {
  name = "jenkins-ami-build"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "file" {
    source      = "./caddy/Caddyfile"
    destination = "/tmp/Caddyfile"
  }

  provisioner "file" {
    source      = "./scripts/plugins.txt"
    destination = "/tmp/plugins.txt"
  }

  provisioner "file" {
    source      = "./scripts/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh"
    ]
  }
}