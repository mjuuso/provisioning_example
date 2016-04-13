node {
    stage 'Checkout'
    checkout scm

    stage 'Build'
    docker.image("golang:1.6").inside {
        sh 'GOOS=linux GOARCH=amd64 go build src/app.go'
    }

    stage 'Deploy'
    sh './deployment.sh'
}
