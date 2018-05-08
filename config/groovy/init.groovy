// Configuration run when jenkins starts up
 
import hudson.model.*;
import jenkins.model.*;
import hudson.security.AuthorizationStrategy;


Thread.start {
      println "--> Enable non-logged in user to trigger build"
      Jenkins.getInstance().setAuthorizationStrategy(AuthorizationStrategy.UNSECURED);
      println "--> Setting agent port for jnlp"
      def env = System.getenv()
      int port = env['JENKINS_SLAVE_AGENT_PORT'].toInteger()
      Jenkins.instance.setSlaveAgentPort(port)
      println "--> Setting agent port for jnlp... done"
      println "--> Disable StrictVerification for jnlp agents"
      jenkins.slaves.DefaultJnlpSlaveReceiver.disableStrictVerification=true
      println "--> Set master executor to 0"
      println "--> This allows builds to start as soon as Jenkins starts."
      Jenkins.instance.setNumExecutors(0)
      println "--> Set JENKINS URL to default value. Can be Changed in Jenkins Configuration page"
      jlc = JenkinsLocationConfiguration.get()
      jlc.setUrl("http://jenkins:8080/")
      println(jlc.getUrl())
      jlc.save()
}

