import javaposse.jobdsl.plugin.*
import hudson.model.*
import jenkins.model.*
import javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration
import jenkins.model.GlobalConfiguration

def jenkins = Jenkins.getInstance()

// Check if seed job already exists
if (jenkins.getItem('seed-job') != null) {
    println("Seed job already exists, skipping creation.")
    return
}

GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).useScriptSecurity = false
GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class).save()

println("Creating seed job...")

def jobName = 'seed-job'
def configXml = """<?xml version='1.1' encoding='UTF-8'?>
<project>
  <description>Seed job that generates all other jobs from DSL scripts</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <scm class="hudson.scm.NullSCM"/>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <javaposse.jobdsl.plugin.ExecuteDslScripts>
      <targets>*.groovy</targets>
      <usingScriptText>false</usingScriptText>
      <sandbox>false</sandbox>
      <ignoreExisting>false</ignoreExisting>
      <ignoreMissingFiles>false</ignoreMissingFiles>
      <failOnMissingPlugin>false</failOnMissingPlugin>
      <failOnSeedCollision>false</failOnSeedCollision>
      <unstableOnDeprecation>false</unstableOnDeprecation>
      <removedJobAction>DELETE</removedJobAction>
      <removedViewAction>DELETE</removedViewAction>
      <removedConfigFilesAction>DELETE</removedConfigFilesAction>
      <lookupStrategy>JENKINS_ROOT</lookupStrategy>
    </javaposse.jobdsl.plugin.ExecuteDslScripts>
  </builders>
</project>"""

def xmlStream = new ByteArrayInputStream(configXml.getBytes('UTF-8'))
jenkins.createProjectFromXML(jobName, xmlStream)

println("Seed job created. Scheduling build...")
jenkins.getItem(jobName).scheduleBuild2(30)