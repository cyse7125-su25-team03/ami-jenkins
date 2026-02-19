multibranchPipelineJob('static-site') {
    displayName('Static Site - Build & Publish')
    description('Build and publish multi-platform container image for static-site to DockerHub')

    branchSources {
        github {
            id('static-site')
            repoOwner('cyse7125-su24-teamNN')  // Replace with your org name
            repository('static-site')
            scanCredentialsId('github-credentials')
            buildForkPRMerge(true)
            buildOriginBranch(true)
            buildOriginPRMerge(true)
        }
    }

    orphanedItemStrategy {
        discardOldItems {
            numToKeep(10)
        }
    }

    triggers {
        periodic(1)  // Scan every 1 minute for webhook-triggered changes
    }

    factory {
        workflowBranchProjectFactory {
            scriptPath('Jenkinsfile')
        }
    }
}