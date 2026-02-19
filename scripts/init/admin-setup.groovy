import jenkins.model.*
import hudson.security.*

def jenkins = Jenkins.getInstance()

// Disable setup wizard
jenkins.setInstallState(jenkins.install.InstallState.INITIAL_SETUP_COMPLETED)

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def adminUser = System.getenv('JENKINS_ADMIN_USER') ?: 'admin'
def adminPass = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'admin'
hudsonRealm.createAccount(adminUser, adminPass)
jenkins.setSecurityRealm(hudsonRealm)

// Allow logged-in users full control
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
jenkins.setAuthorizationStrategy(strategy)

jenkins.save()
println("Admin user '${adminUser}' created and setup wizard disabled.")