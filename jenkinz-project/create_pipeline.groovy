// When Jenkins has started successfully and we have replaced the PROJECT_NAME with the 
// project we wish to build then this groovy is used to create the pipeline project.
 
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

// Hardcoded in /tmp/jenkinsfile for convenience. This file is mounted into the jenkins container.

def script = new File("/jenkinz/workspace/PROJECT_NAME/JENKINSFILE").text
WorkflowJob job = Jenkins.instance.createProject(WorkflowJob.class, "PROJECT_NAME")
job.setDefinition(new CpsFlowDefinition(script, true))

// At this point the pipeline project should be visible in jenkins.
