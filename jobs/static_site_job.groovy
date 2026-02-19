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

// PR status check job - validates conventional commits on PRs
multibranchPipelineJob('static-site-pr-check') {
    displayName('Static Site - PR Status Check')
    description('Validate conventional commits on pull requests')

    branchSources {
        branchSource {
            source {
                github {
                    id('static-site-pr-check')
                    repoOwner('__GITHUB_ORG__')
                    repository('__GITHUB_REPO__')
                    credentialsId('github-credentials')
                    configuredByUrl(true)
                    repositoryUrl('https://github.com/__GITHUB_ORG__/__GITHUB_REPO__.git')
                    traits {
                        gitHubBranchDiscovery {
                            strategyId(1)
                        }
                        gitHubPullRequestDiscovery {
                            strategyId(1)  // Merge PR head with target branch
                        }
                        headWildcardFilter {
                            includes('PR-*')
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
            scriptPath('Jenkinsfile.pr')
        }
    }
}