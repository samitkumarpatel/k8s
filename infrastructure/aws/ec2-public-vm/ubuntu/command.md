
swapoff -a
sed -i '/swap/d' /etc/fstab
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker run hello-world

wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb
sudo apt-get install ./cri-dockerd_0.3.15.3-0.debian-bookworm_amd64.deb

cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

cat >>/etc/modules-load.d/cri-dockerd.conf<<EOF
   overlay
   br_netfilter
EOF
sysctl --system
ufw disable
sudo apt-get remove containernetworking-plugins -y && sudo apt-get remove conmon -y
mkdir -p /etc/apt/keyrings/
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
apt-get update
apt-get install kubelet kubeadm kubectl -y
kubeadm --version
kubeadm version
kubelet --version
kubectl version --client
systemctl enable --now kubelet


kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///run/cri-dockerd.sock



##################################
https://github.com/cri-o/packaging/blob/main/README.md#usage
##################################

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

