# k8s-devsecops-training

## Setup
Once you clone this repo, you will need to install dependencies by executing
```bash
chmod +x setup.sh
./setup.sh
```

## Creating Resources
All AWS resources are provisioned using Terraform module, to create the resource run
```bash
terraform init
terraform apply
```
## Configure Kubernetes Cluster
You will need to update kubeconfig file before you are able to interact with your kubernetes cluster
```bash
aws eks update-kubeconfig --name k8s-devsecops-training
```
Once you have access to the cluster, make sure to restart exernal-dns pod for it to be able to use IAM Role for Service Account
```bash
kubectl delete pod -n external-dns -l app.kubernetes.io/name=external-dns
```

## Deploying ZAP
ZAP proxy will be deployed as a pod on your kubernetes cluster, we will use helm to deploy ZAP
```bash
cd helm/
helm upgrade -i zapproxy -n zap --create-namespace zap/
```

## Clean Up
Delete all Kubernetes resources first by executing
```bash
kubectl delete namespace <your-app-namespace>
kubectl delete namespace sonarqube
kubectl delete namespace zap
kubectl delete namespace ingress-nginx
```

Delete images from ECR repos
- scratch-k8s-devsecops-training
- prod-k8s-devsecops-training

Clean up file inside S3 bucket ```k8s-devsecops-training-<account_id>-<region>-artifacts```

Delete AWS resources via Terraform
```bash
terraform destroy
```