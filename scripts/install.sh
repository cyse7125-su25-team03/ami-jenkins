#!/bin/bash
set -eux

# Update and upgrade
sudo apt update && sudo apt upgrade -y

# install dependencies
sudo apt install -y \
  openjdk-17-jdk \
  software-properties-common 

# Install Jenkins
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update && sudo apt-get install -y jenkins

# Install Caddy (automatic HTTPS)
sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt-get update && sudo apt-get install -y caddy

# Install plugins
sudo mkdir -p /var/lib/jenkins/plugins
sudo mv /tmp/plugins.txt /var/lib/jenkins/plugins.txt
wget -q https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.13.2/jenkins-plugin-manager-2.13.2.jar -O /opt/jenkins-plugin-manager.jar

sudo java -jar /opt/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --plugin-file /var/lib/jenkins/plugins.txt

sudo systemctl start jenkins
sleep 5
sudo systemctl stop jenkins
sudo chown -R jenkins:jenkins /var/lib/jenkins/plugins

# Replace default Caddyfile with reverse proxy for Jenkins
sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile

# Disable timeout
sudo mkdir -p /etc/systemd/system/jenkins.service.d
echo -e "[Service]\nTimeoutStartSec=900s" | sudo tee /etc/systemd/system/jenkins.service.d/override.conf

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl enable caddy
sudo systemctl restart jenkins
sudo systemctl restart caddy
