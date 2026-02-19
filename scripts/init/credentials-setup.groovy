import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import hudson.util.Secret

def jenkins = Jenkins.getInstance()
def domain = Domain.global()
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// ---- DockerHub Credentials ----
def dockerUser = System.getenv('DOCKERHUB_USERNAME')
def dockerPass = System.getenv('DOCKERHUB_TOKEN')

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
def githubUser = System.getenv('GITHUB_USERNAME')
def githubToken = System.getenv('GITHUB_TOKEN')

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