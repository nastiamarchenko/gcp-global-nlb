# Kubernetes Engine Multi Cluster TCP-proxy Load Balancing
based on tutorial https://cloud.google.com/community/tutorials/modular-load-balancing-with-terraform

```
It's supposed that Terraform has been installed and GCP Project exists 
Enabled APIs: Kubernetes Engine API 
```

## Clone the code 

```
git clone https://github.com/nastiamarchenko/gcp-morse-socket
```

## Set up the environment

1. Set your project ID:

```
gcloud config set project [PROJECT_ID]
```

2. Configure the environment for Terraform:

```
[[ $CLOUD_SHELL ]] || gcloud auth application-default login
export PROJECT_ID=$(gcloud config get-value project)
```

## Create container image and push it to Google Container Registry

```
cd ./gcp-morse-socket/k8s-app
docker build -t gcr.io/${PROJECT_ID}/morse-socket .
docker push gcr.io/${PROJECT_ID}/morse-socket
```

## Run Terraform

```
cd ../
terraform init
terraform plan -var="project_id=$PROJECT_ID" --out="myplan"
terraform apply "myplan"
```

## Testing

1. Wait for the load balancer to be provisioned:
2. Open the address of the load balancer:

```
telnet $(terraform output load-bailancer-ip) 110
```

## Cleanup

1. Delete resources created by terraform:

```
terraform destroy
```
