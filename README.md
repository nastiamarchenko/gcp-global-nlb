# Kubernetes Engine Multi Cluster Load Balancing
based on tutorial https://cloud.google.com/community/tutorials/modular-load-balancing-with-terraform

```
It's supposed that Terraform has been installed and GCP Project exists 
Enabled APIs: Kubernetes Engine API 
```

## Clone the code 

```
git clone https://github.com/nastiamarchenko/morseapp
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
cd ./morseapp/k8s-app
docker build -t gcr.io/${PROJECT_ID}/morse-app .
docker push gcr.io/${PROJECT_ID}/morse-app
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

```
chmod +x ./test.sh
./test.sh
```

2. Open the address of the load balancer:

```
echo http://$(terraform output load-balancer-ip)
```

## Cleanup

1. Delete resources created by terraform:

```
terraform destroy
```