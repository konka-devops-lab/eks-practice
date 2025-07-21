#!/bin/bash
sudo dnf update -y
sudo dnf install git tmux tree -y
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.3/2025-04-17/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
curl -sS https://webinstall.dev/k9s | bash
aws eks update-kubeconfig --name dev-eks --region us-east-1
echo "alias k=kubectl" >> /home/ec2-user/.bashrc
source /home/ec2-user/.bashrc
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh