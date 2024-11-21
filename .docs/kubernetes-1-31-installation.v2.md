# `CRI-O` with kubeadm, kubelet & kubectl

##################################

https://github.com/cri-o/packaging/blob/main/README.md#usage

##################################

```sh
KUBERNETES_VERSION=v1.31
CRIO_VERSION=v1.31

apt-get update
apt-get install -y software-properties-common curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |     gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |     tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |     gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |     tee /etc/apt/sources.list.d/cri-o.list

apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl
systemctl start crio.service
swapoff -a
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1
sysctl --system
```


# `containerd` with kubeadm, kubelet & kubectl

##########################################

https://github.com/containerd/containerd/blob/main/docs/getting-started.md

###########################################

```sh
#containerd
wget https://github.com/containerd/containerd/releases/download/v2.0.0/containerd-2.0.0-linux-amd64.tar.gz

tar Cxzvf /usr/local containerd-2.0.0-linux-amd64.tar.gz 

mkdir -p /usr/local/lib/systemd/system

touch /usr/local/lib/systemd/system/containerd.service

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /usr/local/lib/systemd/system/containerd.service

systemctl daemon-reload
systemctl enable --now containerd

#runc
wget https://github.com/opencontainers/runc/releases/download/v1.2.2/runc.amd64

install -m 755 runc.amd64 /usr/local/sbin/runc

#cni
wget https://github.com/containernetworking/plugins/releases/download/v1.6.0/cni-plugins-linux-amd64-v1.6.0.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.0.tgz


apt-get update
apt-get install -y software-properties-common curl
KUBERNETES_VERSION=v1.31

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |     gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |     tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl

swapoff -a
ufw disable

sysctl -w net.ipv4.ip_forward=1
modprobe br_netfilter
sysctl --system


#For master node only
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16

#Make sure you Copy the join token and keep it somewhere - to be run on all worker node

#container network addon
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml


#Ingress controller Installtion
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0-beta.0/deploy/static/provider/baremetal/deploy.yaml

```