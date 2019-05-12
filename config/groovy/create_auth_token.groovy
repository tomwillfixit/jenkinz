import hudson.model.*
import jenkins.model.*
import jenkins.security.*
import jenkins.security.apitoken.*

// you can change the "admin" name
// the false is to explicitely ask to not create a user who does not exist yet
def user = User.get("jenkinz", true)
def prop = user.getProperty(ApiTokenProperty.class)
// the name is up to you
def result = prop.tokenStore.generateNewToken("token-created-by-script")
user.save()

// return result.plainValue

println "Write to file : /var/jenkins_home/.auth_token"
def auth_token = new File('/var/jenkins_home/.auth_token')
auth_token.write "$result.plainValue"
println "$result.plainValue"
