#!/bin/bash

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p

yum install -y docker
systemctl start docker.service
systemctl enable docker.service

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet kubeadm kubectl

cat >init-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: "${k8stoken}"
  ttl: "0"
# nodeRegistration:
#   kubeletExtraArgs:
#     cloud-provider: aws
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
# apiServer:
#   extraArgs:
#     cloud-provider: aws
# controllerManager:
#   extraArgs:
#     cloud-provider: aws
networking:
  podSubnet: 10.244.0.0/16
EOF

echo "Running kubeadm init"
kubeadm init --config=init-config.yaml --ignore-preflight-errors=NumCPU

mkdir -p /home/ec2-user/.kube && cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config && chown -R ec2-user. /home/ec2-user/.kube

su -c 'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml' ec2-user

