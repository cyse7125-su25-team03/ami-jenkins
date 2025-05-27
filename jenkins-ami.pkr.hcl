packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
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

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_name}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.region
  source_ami    = var.ami_source

  ssh_username = "ubuntu"

  tags = {
    Name        = "Jenkins with Caddy AMI"
    Environment = "production"
    Service     = "jenkins"
    OS          = "Ubuntu 24.04 LTS"
  }
}

build {
  name = "jenkins-caddy-ami"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  # Update system packages
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y"
    ]
  }

  # Install Java 17 (required for Jenkins)
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y openjdk-17-jdk",
      "java -version"
    ]
  }

  # Install Jenkins
  provisioner "shell" {
    inline = [
      "curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
      "echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y jenkins"
    ]
  }

  # Install additional tools that Jenkins commonly uses
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y git curl wget unzip",
      "sudo apt-get install -y docker.io",
      "sudo usermod -aG docker jenkins",
      "sudo usermod -aG docker ubuntu"
    ]
  }

  # Install AWS CLI
  provisioner "shell" {
    inline = [
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "rm -rf aws awscliv2.zip"
    ]
  }

  # Install Caddy
  provisioner "shell" {
    inline = [
      "sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https",
      "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg",
      "curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list",
      "sudo apt update",
      "sudo apt install -y caddy"
    ]
  }

  # Configure Caddy
  provisioner "file" {
    source      = "files/Caddyfile"
    destination = "/tmp/Caddyfile"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile",
      "sudo chown root:root /etc/caddy/Caddyfile",
      "sudo chmod 644 /etc/caddy/Caddyfile"
    ]
  }

  # Create startup script for dynamic domain configuration
  provisioner "file" {
    source      = "files/configure-caddy.sh"
    destination = "/tmp/configure-caddy.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/configure-caddy.sh /usr/local/bin/configure-caddy.sh",
      "sudo chmod +x /usr/local/bin/configure-caddy.sh"
    ]
  }

  # Create systemd service for startup configuration
  provisioner "file" {
    source      = "files/jenkins-startup.service"
    destination = "/tmp/jenkins-startup.service"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/jenkins-startup.service /etc/systemd/system/jenkins-startup.service",
      "sudo systemctl enable jenkins-startup.service"
    ]
  }

  # Install common Jenkins plugins
  provisioner "shell" {
    inline = [
      "sudo systemctl start jenkins",
      "sleep 30", # Wait for Jenkins to start
      "sudo wget -O /opt/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar",
      "sleep 60" # Wait a bit more for full initialization
    ]
  }

  # Download plugin installation script
  provisioner "file" {
    source      = "files/install-plugins.sh"
    destination = "/tmp/install-plugins.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/install-plugins.sh",
      "sudo /tmp/install-plugins.sh",
      "sudo systemctl stop jenkins"
    ]
  }

  # Enable services but don't start them (they'll start on boot)
  provisioner "shell" {
    inline = [
      "sudo systemctl enable jenkins",
      "sudo systemctl enable caddy",
      "sudo systemctl enable docker"
    ]
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "sudo apt-get autoremove -y",
      "sudo apt-get autoclean",
      "sudo rm -rf /tmp/* /var/tmp/*",
      "sudo find /var/log -type f -name '*.log' -exec truncate -s 0 {} +"
    ]
  }
}