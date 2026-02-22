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
  default = "root-mk"
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
  default = "subnet-xxxxxxxxxxxxxxxxxx"
}

variable "jenkins_admin_user" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "jenkins_admin_password" {
  type      = string
  sensitive = true
}

variable "dockerhub_username" {
  type      = string
  sensitive = true
}

variable "dockerhub_token" {
  type      = string
  sensitive = true
}

variable "github_username" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "github_org" {
  type    = string
  default = "cyse7125-su25-team03"
}

variable "github_repo" {
  type    = string
  default = "static-site"
}

variable "github_webapp_repo" {
  type    = string
  default = "webapp-cve-processor"
}

source "amazon-ebs" "ubuntu" {
  profile         = var.aws_profile
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

  provisioner "file" {
    source      = "./scripts/init/admin-setup.groovy"
    destination = "/tmp/admin-setup.groovy"
  }

  provisioner "file" {
    source      = "./scripts/init/credentials-setup.groovy"
    destination = "/tmp/credentials-setup.groovy"
  }

  provisioner "file" {
    source      = "./scripts/init/seed-job.groovy"
    destination = "/tmp/seed-job.groovy"
  }

  provisioner "file" {
    source      = "./jobs/static_site_job.groovy"
    destination = "/tmp/static_site_job.groovy"
  }

  provisioner "file" {
    source      = "./jobs/cve_processor_job.groovy"
    destination = "/tmp/cve_processor_job.groovy"
  }

  # Write credentials to Jenkins environment file
  provisioner "shell" {
    inline = [
      "echo 'JENKINS_ADMIN_USER=${var.jenkins_admin_user}' | sudo tee -a /etc/default/jenkins",
      "echo 'JENKINS_ADMIN_PASSWORD=${var.jenkins_admin_password}' | sudo tee -a /etc/default/jenkins",
      "echo 'DOCKERHUB_USERNAME=${var.dockerhub_username}' | sudo tee -a /etc/default/jenkins",
      "echo 'DOCKERHUB_TOKEN=${var.dockerhub_token}' | sudo tee -a /etc/default/jenkins",
      "echo 'GITHUB_USERNAME=${var.github_username}' | sudo tee -a /etc/default/jenkins",
      "echo 'GITHUB_TOKEN=${var.github_token}' | sudo tee -a /etc/default/jenkins",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh",
      "sudo sed -i 's|__GITHUB_ORG__|${var.github_org}|g' /var/lib/jenkins/workspace/seed-job/static_site_job.groovy",
      "sudo sed -i 's|__GITHUB_REPO__|${var.github_repo}|g' /var/lib/jenkins/workspace/seed-job/static_site_job.groovy",
      "sudo sed -i 's|__GITHUB_ORG__|${var.github_org}|g' /var/lib/jenkins/workspace/seed-job/cve_processor_job.groovy",
      "sudo sed -i 's|__GITHUB_WEBAPP_REPO__|${var.github_webapp_repo}|g' /var/lib/jenkins/workspace/seed-job/cve_processor_job.groovy"
    ]
  }
}