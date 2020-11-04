#!/usr/bin/env sh

set +x

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 
unzip awscliv2.zip

sudo ./aws/install && sudo apt install amazon-ecr-credential-helper -y
aws version

mkdir ${HOME}/.aws
echo "$AWS_CONFIG" | base64 --decode > ${HOME}/.aws/config
echo "$AWS_CREDENTIALS" | base64 --decode > ${HOME}/.aws/credentials


curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client


mkdir ${HOME}/.kube
echo "$KUBE_CONFIG" | base64 --decode > ${HOME}/.kube/config

kubectl version