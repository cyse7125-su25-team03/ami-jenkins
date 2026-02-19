import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import hudson.util.Secret

def jenkins = Jenkins.getInstance()
def domain = Domain.global()
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Read env vars from /etc/default/jenkins
def envFile = new File('/etc/default/jenkins')
def envVars = [:]
envFile.eachLine { line ->
    if (line && !line.startsWith('#') && line.contains('=')) {
        def parts = line.split('=', 2)
        envVars[parts[0].trim()] = parts[1].trim()
    }
}

// ---- DockerHub Credentials ----
def dockerUser = envVars['DOCKERHUB_USERNAME']
def dockerPass = envVars['DOCKERHUB_TOKEN']

if (dockerUser && dockerPass) {
    def dockerCreds = new UsernamePasswordCredentialsImpl(
            CredentialsScope.GLOBAL,
            'dockerhub-credentials',
            'DockerHub Credentials',
            dockerUser,
            dockerPass
    )
    store.addCredentials(domain, dockerCreds)
    println("DockerHub credentials added.")
} else {
    println("WARNING: DockerHub credentials not provided via environment variables.")
}

// ---- GitHub Credentials ----
def githubUser = envVars['GITHUB_USERNAME']
def githubToken = envVars['GITHUB_TOKEN']

if (githubUser && githubToken) {
    def githubCreds = new UsernamePasswordCredentialsImpl(
            CredentialsScope.GLOBAL,
            'github-credentials',
            'GitHub Credentials',
            githubUser,
            githubToken
    )
    store.addCredentials(domain, githubCreds)
    println("GitHub credentials added.")
} else {
    println("WARNING: GitHub credentials not provided via environment variables.")
}

jenkins.save()