# Sample Jenkinsfile
# Requires the Pipeline and CloudBees Docker Pipeline plugins.
# They should be enabled by default in Jenkins 2.0.

node {
    stage 'Checkout'
    # We'll pull the code with the default settings for this job

    checkout scm


    stage 'Build'
    # We'll build the application inside a container with a
    # ready-made golang environment

    docker.image("golang:1.6").inside {
        sh 'GOOS=linux GOARCH=amd64 go build src/app.go'
    }


    stage 'Deploy'
    # Our deployment steps go here:
    # - ship the compiled application to the environment
    # - sudo restart app
    # sh './deployment.sh'
}
