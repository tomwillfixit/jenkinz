// CI Pipeline for Memcached Container Image

pipeline {
    agent { label 'centos' }
    environment {
        MAIL_TO = 'test@changeme.com'
    }
    stages {
        stage('Build Memcached Container Image') {
            steps {
		retry(3) {
                script {
                        sh 'make build'
                    }
		}
            }
        }
	stage('Test Connectivity') {
            steps {
                script {
                        sh 'make test'
                    }
            }
        }
	
    }
    post {
        always {
            sh 'make clean'
            deleteDir() /* clean up our workspace */
        }
        failure {
            slackSend channel: '#ci-build',
            color: 'danger',
            message: "WARNING : CI Pipeline for Memcached Container Image failed : ${env.BUILD_URL}"
            
            mail (to: "${MAIL_TO}",
            subject: "WARNING : CI Pipeline for Memcached Container Image failed",
            body: "Details at : ${env.BUILD_URL}.")
        } 
    }
}


