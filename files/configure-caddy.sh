#!/bin/bash

# Script to configure Caddy with dynamic domain at startup
# This script reads the domain from various sources and updates Caddy configuration

LOG_FILE="/var/log/jenkins-startup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting Jenkins and Caddy configuration..."

# Function to get domain from various sources
get_domain() {
    local domain=""
    
    # Method 1: Check user data for JENKINS_DOMAIN
    if [ -z "$domain" ]; then
        domain=$(curl -s http://169.254.169.254/latest/user-data | grep -oP 'JENKINS_DOMAIN=\K[^[:space:]]+' | head -1)
        if [ ! -z "$domain" ]; then
            log "Domain found in user data: $domain"
        fi
    fi
    
    # Method 2: Check EC2 tags
    if [ -z "$domain" ]; then
        # Get instance ID
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
        # Get region
        REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
        
        # Try to get domain from tags (requires IAM permissions)
        domain=$(aws ec2 describe-tags --region "$REGION" --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=JenkinsDomain" --query 'Tags[0].Value' --output text 2>/dev/null)
        if [ "$domain" != "None" ] && [ ! -z "$domain" ]; then
            log "Domain found in EC2 tags: $domain"
        else
            domain=""
        fi
    fi
    
    # Method 3: Check environment variable
    if [ -z "$domain" ] && [ ! -z "$JENKINS_DOMAIN" ]; then
        domain="$JENKINS_DOMAIN"
        log "Domain found in environment variable: $domain"
    fi
    
    # Method 4: Use public IP as fallback (for testing)
    if [ -z "$domain" ]; then
        PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
        if [ ! -z "$PUBLIC_IP" ]; then
            domain="$PUBLIC_IP"
            log "Using public IP as domain: $domain"
        fi
    fi
    
    echo "$domain"
}

# Wait for network to be ready
sleep 10

# Get the domain
DOMAIN=$(get_domain)

if [ -z "$DOMAIN" ]; then
    log "ERROR: No domain found. Caddy will use localhost."
    DOMAIN="localhost"
fi

log "Configuring Caddy for domain: $DOMAIN"

# Set environment variable for Caddy
export JENKINS_DOMAIN="$DOMAIN"
echo "JENKINS_DOMAIN=$DOMAIN" >> /etc/environment

# Update systemd environment for Caddy
mkdir -p /etc/systemd/system/caddy.service.d
cat > /etc/systemd/system/caddy.service.d/environment.conf << EOF
[Service]
Environment="JENKINS_DOMAIN=$DOMAIN"
EOF

# Wait for Jenkins to be ready
log "Waiting for Jenkins to start..."
for i in {1..30}; do
    if curl -s http://localhost:8080 > /dev/null; then
        log "Jenkins is ready"
        break
    fi
    log "Waiting for Jenkins... attempt $i/30"
    sleep 10
done

# Start Caddy
log "Starting Caddy..."
systemctl daemon-reload
systemctl restart caddy

# Check if Caddy started successfully
if systemctl is-active --quiet caddy; then
    log "Caddy started successfully"
    
    # If we have a real domain (not IP), wait a bit for Let's Encrypt
    if [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "Using IP address - SSL certificate will be self-signed"
    else
        log "Using domain name - waiting for Let's Encrypt certificate..."
        sleep 30
    fi
    
    log "Jenkins should be accessible at: https://$DOMAIN"
else
    log "ERROR: Failed to start Caddy"
    systemctl status caddy >> "$LOG_FILE"
fi

log "Configuration complete"