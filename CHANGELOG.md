## v0.9

Tests completed against multiple official Jenkins images from the jenkinsci repository in Docker Hub.  Build log now includes the jenkins version and plugin versions used during the build.

## v0.8

Run your builds against a specific version of the official Jenkins on Docker Hub (Only supports Alpine based images)

Get a list of available Alpine based images in Docker Hub :

```
jenkinz list-tags

Example Output : 

jenkinsci/jenkins:2.121-alpine
jenkinsci/jenkins:2.107.3-alpine
jenkinsci/jenkins:2.120-alpine
jenkinsci/jenkins:2.119-alpine
jenkinsci/jenkins:2.118-alpine

Run a build against a specific version :

jenkinz --image jenkins/jenkins:2.60.3-alpine --repository demo
```


## v0.7

(This was just plain old shoddy. Skip v0.7 and goto v0.8)
Jenkinz defaults to using a Jenkins Master based on 2.107.2. To use the previous version 2.107.1 just specify the -v option.

For Example :
```
jenkinz -v 2.107.1 -r demo 
```

## v0.6

Experimental "Chaos" support.  Default chaos.cb config in the top level looks like : 
```
master_restart:?
network_flap:?:10
```

This can be enabled by passing in the --chaos argument. 

For Example :
```
jenkinz -r demo-nginx -b 5 --chaos
```

This default chaos.cb file will cause the jenkins master to restart at some point during the build. There will also be a 10 second network flap at some point during the build. This is a rough POC.

## v0.5

Support for parallel stages. For each agent label found in the Jenkinsfile provided a agent is started. This will allow stages to run in parallel.  An example can be found here : demo/Jenkinsfile.parallel.tests.

Usage : jenkinz -r demo -f Jenkinsfile.parallel.tests

## v0.4

Support for Jenkins Master restart during build added. The Master can be restarted multiple times during a build and the build should still complete successfully. This is part of the upcoming ChaosButler function which will also simulate network flaps during a build.

Example Output :
```
(18/51) Installing gmp (6.1.2-r1)
(19/51) Installing isl (0.18-r0)
(20/51) Installing libgomp (6.4.0-r5)
(21/51) Installing libatomic (6.4.0-r5)
(22/51) Installing libgcc (6.4.0-r5)
(23/51) Installing mpfr3 (3.1.5-r1)
(24/51) Installing mpc1 (1.0.3-r1)
(25/51) Installing libstdc++ (6.4.0-r5)
(26/51) Installing gcc (6.4.0-r5)
Resuming build at Fri Apr 27 22:43:28 GMT 2018 after Jenkins restart
Waiting to resume part of demo #1: Waiting for next available executor
Cannot contact jenkinz-slave: java.io.IOException: remote file operation failed: /jenkinz/workspace/demo at hudson.remoting.Channel@16e82dce:JNLP4-connect connection from 172.21.0.2/172.21.0.2:42380: hudson.remoting.ChannelClosedException: Channel "unknown": Remote call on JNLP4-connect connection from 172.21.0.2/172.21.0.2:42380 failed. The channel is closing down or has closed down
Waiting to resume part of demo #1: Waiting for next available executor
Waiting to resume part of demo #1: jenkinz-slave is offline
Ready to run at Fri Apr 27 22:44:09 GMT 2018
(27/51) Installing libssh2 (1.8.0-r2)
(28/51) Installing libcurl (7.59.0-r0)
(29/51) Installing expat (2.2.5-r0)
(30/51) Installing pcre2 (10.30-r0)
(31/51) Installing git (2.15.0-r1)
```
