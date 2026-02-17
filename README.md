# Jenkins AMI with Caddy Reverse Proxy

This Packer configuration creates an AWS AMI with Jenkins and Caddy pre-installed. The AMI includes essential Jenkins plugins and is configured to automatically obtain SSL certificates from Let's Encrypt when launched

## Features

- **Ubuntu 24.04 LTS** base image
- **Jenkins LTS** with essential plugins pre-installed
- **Caddy** as reverse proxy with automatic HTTPS
- **Docker** and **AWS CLI** pre-installed
- **Automatic SSL certificate** management via Let's Encrypt
- **Dynamic domain configuration** at startup

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Packer** installed (version 1.7+)

## Building the AMI

1. **Clone or create the files** in the directory structure shown above

2. **Build the AMI**:
   ```bash
   packer build -var-file="variables.pkrvars.hcl" jenkins-ami.pkr.hcl
   
   ```


## Launching Jenkins Instances

### Method 1: Using User Data (Recommended)

When launching an EC2 instance from the AMI, provide the domain in user data:

```bash
#!/bin/bash
JENKINS_DOMAIN=jenkins.yourdomain.com
```

### Method 2: Using EC2 Tags

Add a tag to your EC2 instance:
- **Key**: `JenkinsDomain`
- **Value**: `jenkins.yourdomain.com`

### Method 3: Using Environment Variables

Set the environment variable before starting services:
```bash
export JENKINS_DOMAIN=jenkins.yourdomain.com
```

## DNS Configuration

**Before launching the instance**, ensure:

1. **Domain points to instance**: Create an A record pointing your domain to the EC2 instance's public IP
2. **Security groups allow**:
   - Port 80 (HTTP) - for Let's Encrypt validation
   - Port 443 (HTTPS) - for Jenkins access
   - Port 22 (SSH) - for administration


## First-Time Setup

1. **Launch instance** with domain configuration
2. **Wait 2-3 minutes** for services to start and SSL certificate to be obtained
3. **Access Jenkins** at `https://your-domain.com`
4. **Complete Jenkins setup wizard**:
   - Get initial admin password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
   - Install suggested plugins (or skip, since essential plugins are pre-installed)
   - Create admin user
   - Configure Jenkins URL (should auto-detect)

## Troubleshooting

### Check Service Status
```bash
# Jenkins
sudo systemctl status jenkins

# Caddy
sudo systemctl status caddy

# Startup configuration
sudo systemctl status jenkins-startup
```

### View Logs
```bash
# Startup configuration logs
sudo tail -f /var/log/jenkins-startup.log

# Caddy logs
sudo journalctl -u caddy -f

# Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

### Manual Configuration
If automatic configuration fails:
```bash
# Set domain manually
export JENKINS_DOMAIN=your-domain.com
sudo /usr/local/bin/configure-caddy.sh
```

### SSL Certificate Issues
```bash
# Check Caddy configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy configuration
sudo systemctl reload caddy

# Check certificate status
sudo caddy list-certificates
```

## Customization

### Adding More Plugins
Edit `files/install-plugins.sh` and add plugins to the `PLUGINS` array before building the AMI.

### Modifying Caddy Configuration
Edit `files/Caddyfile` to customize reverse proxy settings, add additional routes, or modify security headers.

### Custom Startup Tasks
Add additional configuration to `files/configure-caddy.sh` for any custom startup requirements.

## Pre-installed Software

- **Jenkins LTS** with essential plugins
- **Java 17** (OpenJDK)
- **Docker** (jenkins user added to docker group)
- **AWS CLI v2**
- **Git**
- **Caddy** web server
- **Common development tools** (curl, wget, unzip)

## Security Considerations

1. **Change default credentials** immediately after first login
2. **Configure Jenkins security** (authentication, authorization)
3. **Regularly update** Jenkins and plugins
4. **Use IAM roles** instead of hardcoded AWS credentials
5. **Restrict security group access** to necessary IPs only
6. **Enable Jenkins CSRF protection**
7. **Configure backup strategy** for Jenkins data


## Support

For issues related to:
- **Packer configuration**: Check Packer documentation
- **Jenkins setup**: Refer to Jenkins documentation
- **Caddy configuration**: See Caddy documentation
- **AWS permissions**: Review AWS IAM documentation

## License

This configuration is provided as-is for educational and production use.
