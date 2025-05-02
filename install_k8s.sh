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



# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
EOF

sudo dnf -y install epel-release vim git curl wget kubelet kubeadm kubectl --disableexcludes=kubernetes


sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF


sudo dnf install -y yum-utils device-mapper-persistent-data lvm2
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
#sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo dnf -y install docker-ce-cli containerd.io 




sudo mkdir -p /etc/containerd
containerd config default > config.toml
sudo cp config.toml /etc/containerd/


sudo systemctl restart containerd
sudo systemctl enable containerd



sudo systemctl status containerd


lsmod | grep br_netfilter


sudo systemctl enable kubelet

sudo kubeadm config images pull


sudo kubeadm init --pod-network-cidr=10.192.0.0/16  --control-plane-endpoint=$(hostname -f)


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/canal.yaml

kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
