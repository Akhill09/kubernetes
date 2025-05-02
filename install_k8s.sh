#! /bin/bash

sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config


sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system


sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a


sudo tee /etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF


sudo dnf -y install epel-release vim git curl wget kubelet kubeadm kubectl --disableexcludes=kubernetes


sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF


sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin




sudo mkdir -p /etc/containerd
containerd config default > config.toml
sudo cp config.toml /etc/containerd/


sudo systemctl restart containerd
sudo systemctl enable containerd



sudo systemctl status containerd


lsmod | grep br_netfilter


sudo systemctl enable kubelet

sudo kubeadm config images pull


sudo kubeadm init \
  --pod-network-cidr=10.192.0.0/16 \
  --control-plane-endpoint=$(hostname -f)


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/canal.yaml

kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
