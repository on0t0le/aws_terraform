#!/bin/bash
### Need for kubernetes make happy
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p

### Install Docker
yum install -y docker
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
yum install -y kubelet kubeadm

### Add cloud-provider to kubelet service
echo 'KUBELET_EXTRA_ARGS=--cloud-provider=aws' > /etc/sysconfig/kubelet

### Join node to master node
for i in {1..50}; do kubeadm join --token=${k8stoken} --discovery-token-unsafe-skip-ca-verification ${masterIP}:6443 && break || sleep 15; done
