#!/bin/bash

# Script to install essential Jenkins plugins without initial configuration
# This runs during AMI creation, not at runtime

JENKINS_HOME="/var/lib/jenkins"
JENKINS_CLI="/opt/jenkins-cli.jar"
JENKINS_URL="http://localhost:8080"

# Wait for Jenkins to be fully ready
echo "Waiting for Jenkins to be ready..."
for i in {1..60}; do
    if curl -s "$JENKINS_URL/login" > /dev/null 2>&1; then
        echo "Jenkins is responding"
        break
    fi
    echo "Waiting... ($i/60)"
    sleep 10
done

# Skip initial setup wizard by creating install state file
mkdir -p "$JENKINS_HOME"
echo "2.0" > "$JENKINS_HOME/jenkins.install.InstallUtil.lastExecVersion"
echo "2.0" > "$JENKINS_HOME/jenkins.install.UpgradeWizard.state"

# Create plugins directory
mkdir -p "$JENKINS_HOME/plugins"

# List of essential plugins to install
PLUGINS=(
    "ant:latest"
    "build-timeout:latest"
    "credentials-binding:latest"
    "timestamper:latest"
    "ws-cleanup:latest"
    "github-branch-source:latest"
    "pipeline-github-lib:latest"
    "pipeline-stage-view:latest"
    "git:latest"
    "github:latest"
    "github-api:latest"
    "ssh-slaves:latest"
    "matrix-auth:latest"
    "pam-auth:latest"
    "ldap:latest"
    "email-ext:latest"
    "mailer:latest"
    "workflow-aggregator:latest"
    "pipeline-stage-view:latest"
    "pipeline-rest-api:latest"
    "handlebars:latest"
    "jquery-detached:latest"
    "momentjs:latest"
    "pipeline-input-step:latest"
    "ace-editor:latest"
    "workflow-scm-step:latest"
    "workflow-cps:latest"
    "workflow-job:latest"
    "workflow-multibranch:latest"
    "workflow-durable-task-step:latest"
    "workflow-cps-global-lib:latest"
    "workflow-basic-steps:latest"
    "workflow-support:latest"
    "workflow-step-api:latest"
    "workflow-api:latest"
    "scm-api:latest"
    "structs:latest"
    "junit:latest"
    "resource-disposer:latest"
    "command-launcher:latest"
    "bouncycastle-api:latest"
    "jdk-tool:latest"
    "script-security:latest"
    "matrix-project:latest"
    "windows-slaves:latest"
    "display-url-api:latest"
    "apache-httpcomponents-client-4-api:latest"
    "jsch:latest"
    "ssh-credentials:latest"
    "credentials:latest"
    "plain-credentials:latest"
    "credentials-binding:latest"
    "trilead-api:latest"
    "cloudbees-folder:latest"
    "antisamy-markup-formatter:latest"
    "build-name-setter:latest"
    "conditional-buildstep:latest"
    "config-file-provider:latest"
    "copyartifact:latest"
    "description-setter:latest"
    "envinject:latest"
    "groovy:latest"
    "jobConfigHistory:latest"
    "join:latest"
    "multiple-scms:latest"
    "parameterized-trigger:latest"
    "rebuild:latest"
    "ssh:latest"
    "subversion:latest"
    "text-finder:latest"
    "token-macro:latest"
    "urltrigger:latest"
    "xvfb:latest"
    "docker-workflow:latest"
    "docker-commons:latest"
    "blueocean:latest"
    "aws-credentials:latest"
    "ec2:latest"
    "s3:latest"
    "aws-cli:latest"
)

echo "Installing Jenkins plugins..."

# Install plugins using Jenkins CLI
for plugin in "${PLUGINS[@]}"; do
    echo "Installing plugin: $plugin"
    
    # Try to install plugin, but don't fail if it doesn't work
    if ! java -jar "$JENKINS_CLI" -s "$JENKINS_URL" install-plugin "$plugin" -deploy 2>/dev/null; then
        echo "Warning: Failed to install $plugin, continuing..."
    fi
done

echo "Plugin installation completed"

# Restart Jenkins to ensure all plugins are loaded
echo "Restarting Jenkins to load plugins..."
systemctl restart jenkins

# Wait for restart
sleep 30

echo "Jenkins plugin installation finished"