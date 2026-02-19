multibranchPipelineJob('static-site') {
    displayName('Static Site - Build & Publish')
    description('Build and publish multi-platform container image for static-site to DockerHub')

    branchSources {
        github {
            id('static-site')
            repoOwner('cyse7125-su24-teamNN')  // Replace with your org name
            repository('static-site')
            scanCredentialsId('github-credentials')
            buildForkPRMerge(false)
            buildOriginBranch(true)
            buildOriginPRMerge(false)
            buildOriginBranchWithPR(false)
        }
    }

    // Only build the main branch
    configure {
        def traits = it / sources / data / 'jenkins.branch.BranchSource' / source / traits
        traits << 'jenkins.scm.impl.trait.WildcardSCMHeadFilterTrait' {
            includes('main')
            excludes('')
        }
    }

    orphanedItemStrategy {
        discardOldItems {
            numToKeep(10)
        }
    }

    factory {
        workflowBranchProjectFactory {
            scriptPath('Jenkinsfile')
        }
    }
}