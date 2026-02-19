import jenkins.model.*
import hudson.security.*

def jenkins = Jenkins.getInstance()

// Disable setup wizard
jenkins.setInstallState(jenkins.install.InstallState.INITIAL_SETUP_COMPLETED)

// Read env vars from /etc/default/jenkins
def envFile = new File('/etc/default/jenkins')
def envVars = [:]
envFile.eachLine { line ->
    if (line && !line.startsWith('#') && line.contains('=')) {
        def parts = line.split('=', 2)
        envVars[parts[0].trim()] = parts[1].trim()
    }
}

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def adminUser = envVars['JENKINS_ADMIN_USER'] ?: 'admin'
def adminPass = envVars['JENKINS_ADMIN_PASSWORD'] ?: 'admin'
hudsonRealm.createAccount(adminUser, adminPass)
jenkins.setSecurityRealm(hudsonRealm)

// Allow logged-in users full control
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
jenkins.setAuthorizationStrategy(strategy)

jenkins.save()
println("Admin user '${adminUser}' created and setup wizard disabled.")