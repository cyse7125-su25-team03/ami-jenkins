multibranchPipelineJob('static-site') {
    displayName('Static Site - Build & Publish')
    description('Build and publish multi-platform container image for static-site to DockerHub')

    branchSources {
        branchSource {
            source {
                github {
                    id('static-site')
                    repoOwner('__GITHUB_ORG__')
                    repository('__GITHUB_REPO__')
                    credentialsId('github-credentials')
                    configuredByUrl(true)
                    repositoryUrl('https://github.com/__GITHUB_ORG__/__GITHUB_REPO__.git')
                    buildForkPRMerge(false)
                    buildOriginBranch(true)
                    buildOriginPRMerge(true)
                    buildOriginBranchWithPR(false)
                    traits {
                        gitHubBranchDiscovery {
                            strategyId(1) // Exclude branches that are also PRs
                        }
                        headWildcardFilter {
                            includes('main')
                            excludes('')
                        }
                    }
                }
            }
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