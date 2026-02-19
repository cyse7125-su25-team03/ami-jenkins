#!/bin/bash
set -eux

# Update and upgrade
sudo apt update && sudo apt upgrade -y

# install dependencies
sudo apt install -y \
  openjdk-21-jdk \
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

# Install Docker (needed for Jenkins to build container images)
sudo apt-get install -y ca-certificates gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Add jenkins user to docker group so it can run docker commands
sudo usermod -aG docker jenkins

# Install plugins
sudo mkdir -p /var/lib/jenkins/plugins
sudo mv /tmp/plugins.txt /var/lib/jenkins/plugins.txt
wget -q https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.13.2/jenkins-plugin-manager-2.13.2.jar -O /opt/jenkins-plugin-manager.jar

sudo java -jar /opt/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --plugin-file /var/lib/jenkins/plugins.txt
  
sudo chown -R jenkins:jenkins /var/lib/jenkins/plugins

# Replace default Caddyfile with reverse proxy for Jenkins
sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile

# Setup Jenkins init scripts directory
sudo mkdir -p /var/lib/jenkins/init.groovy.d
sudo mv /tmp/admin-setup.groovy /var/lib/jenkins/init.groovy.d/admin-setup.groovy
sudo mv /tmp/credentials-setup.groovy /var/lib/jenkins/init.groovy.d/credentials-setup.groovy
sudo mv /tmp/seed-job.groovy /var/lib/jenkins/init.groovy.d/seed-job.groovy
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/

# Setup seed job workspace with DSL scripts
sudo mkdir -p /var/lib/jenkins/workspace/seed-job
sudo mv /tmp/static-site-job.groovy /var/lib/jenkins/workspace/seed-job/static-site-job.groovy
sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/seed-job

# Disable timeout
sudo mkdir -p /etc/systemd/system/jenkins.service.d
cat <<EOF | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
[Service]
TimeoutStartSec=900s
Environment="JAVA_OPTS=-Djenkins.install.runSetupWizard=false"
EOF

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl enable caddy
sudo systemctl enable docker