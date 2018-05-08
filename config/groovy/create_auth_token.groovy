
import jenkins.model.*
import jenkins.security.*
import hudson.model.*; //User class

// This token will be used to query the Jenkins API. 

println "Get auth token"

User u = User.get("jenkinz")  
ApiTokenProperty t = u.getProperty(ApiTokenProperty.class)  
def token = t.getApiTokenInsecure()

println "Write to file : /var/jenkins_home/.auth_token"
def auth_token = new File('/var/jenkins_home/.auth_token')
auth_token.write "$token"
println "$token"
