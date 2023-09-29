#! /bin/bash

echo "Installing terraform"
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

echo "Installing helm"
cp config/get_helm.sh .
chmod 700 get_helm.sh
./get_helm.sh --version v3.12.3
rm get_helm.sh

echo "Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "alias k=kubectl" >> /home/ec2-user/.bashrc

echo "Installing kubectx"
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kctx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kns

source /home/ec2-user/.bashrc

echo "Creating EC2 Spot service role"
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com