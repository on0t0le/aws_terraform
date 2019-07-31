#!/bin/bash
### Need for kubernetes make happy
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p

### Install Docker
yum install -y docker jq
systemctl start docker.service
systemctl enable docker.service

### Add kubernetes repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

### Insatll kubernetes utilities
yum install -y kubelet kubeadm kubectl

publicip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
publicdns=$(curl http://169.254.169.254/latest/meta-data/public-hostname)

### Create cluster-init config-file
cat >init-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: "${k8stoken}"
  ttl: "0"
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: aws
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
apiServer:
  extraArgs:
    cloud-provider: aws
  certSANs:
  - "$publicip"
  - "$publicdns"
controllerManager:
  extraArgs:
    cloud-provider: aws
networking:
  podSubnet: 10.244.0.0/16
EOF

### Initialize kubernetes cluster
echo "Running kubeadm init"
kubeadm init --config=init-config.yaml --ignore-preflight-errors=NumCPU

### Copy config to user`s home
mkdir -p /home/ec2-user/.kube && cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config && chown -R ec2-user. /home/ec2-user/.kube

### Add flannel-network
su -c 'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml' ec2-user
