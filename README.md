# JenkinZero (jenkinz)

## What is JenkinZero ?

It's a zero configuration jenkins master and build agent running using "Docker in Docker".  This code is based on the work of Maxfield Stewart from Riot Games : https://github.com/maxfields2000/dockerjenkins_tutorial and was written in my free time.  Feel free to fork it, submit PRs etc.

## How do I use JenkinZero ?

It's simple to use but has some strict requirements.  

1 : You must have docker and docker-compose installed.

2 : The build steps inside the Jenkinsfile provided must be 100% containerized.

3 : Currently only runs on a linux host.  Windows (cygwin) support may happen in future.

### Usage

Step 1 :
```
Check out this repository and check out your own repository (which includes your Jenkinsfile) into this repository.

If your repository is called "my_app" then the directory structure should look like :

jenkinz/my_app

For convenience there is a repository called "demo" which contains a working CI pipeline.
```

Step 2 :

Source the ./jenkinz.sh script.

```
. ./jenkinz.sh

or

source ./jenkinz.sh
```

This will make the jenkinz commands available in your shell.  

Run : jenkinz usage

Step 3 :

Run some builds.

Run a single build (uses default Jenkinsfile in top level of the demo repository) :
```
jenkinz --repository demo 

```

Run a single build using a Jenkinsfile with a different name :
```
jenkinz --repository demo -f Jenkinsfile.build_only 

```

Run a 5 builds using a Jenkinsfile with a different name :
```
jenkinz --repository demo -f Jenkinsfile.build_only -b 5

```

Run a 5 builds (uses default Jenkinsfile in top level of the demo repository) :
```
jenkinz --repository demo -b 5 

```

Run a "quickcheck" build to ensure the master and agent start correctly and the pipeline project is created : 
```
jenkinz -r demo -f Jenkinsfile.quickcheck
```

## Cleanup

Stop jenkinz :
```
jenkinz stop
```

Remove jenkinz :
```
jenkinz clean
```

## Summary

The majority of this code was taken from other repositories and glued together with some bash.  Feel free
to submit PRs or fork if you find this useful.
