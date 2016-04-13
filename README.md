# Provision a simple environment in AWS using Terraform and Chef
This is an example of how to provision a simple environment in AWS using Terraform and Chef.

Once run, you will end up with:
- a round-robin load balancer node running nginx
- two application nodes running a simple Golang application located in src/

The lightweight wrapper script ```run.sh``` will create a SSH key pair and makes sure you have all the prerequisites needed to run the example. The simple Golang application is included pre-built in the Chef cookbook example_app.

To run:
```
./run.sh <aws_access_key> <aws_secret_key>
```

The repository includes a sample Jenkinsfile that can be used to build a Continuous Delivery pipeline for the application.