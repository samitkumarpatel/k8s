# On-Premise Kubernetes Cluster Setup

A step-by-step guide for bootstrapping a Kubernetes cluster on your own VMs using `kubeadm`, `containerd`, and Flannel.

---

## 1. Provision VMs

- 1 (or 3/5 for HA) control-plane VM(s) + N worker VMs
- Minimum recommended specs: 2 vCPU / 2GB RAM per node (control plane benefits from more)
- Ensure each VM has:
  - A unique hostname
  - A unique MAC address
  - A unique `/sys/class/dmi/id/product_uuid` (important if VMs were cloned from a template — `kubeadm` checks this and will fail on duplicates)
- All VMs must be able to reach each other over the network (same subnet or routed)

---

## 2. Base OS Preparation (run on **all** VMs)

### Disable swap
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### Load required kernel modules
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

### Set required sysctl params
```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### Sync system time
```bash
sudo apt install -y chrony   # or ntp
sudo systemctl enable --now chrony
```
Cluster certificates and etcd are sensitive to clock skew, so this matters more than it looks.

### Open required firewall ports

| Node type      | Ports                              | Purpose                          |
|----------------|-------------------------------------|-----------------------------------|
| Control plane  | 6443                                 | Kubernetes API server            |
| Control plane  | 2379-2380                            | etcd client/peer communication   |
| Control plane  | 10250, 10259, 10257                  | kubelet API, scheduler, controller-manager |
| Workers        | 10250                                | kubelet API                      |
| Workers        | 30000-32767                          | NodePort service range           |

---

## 3. Install Container Runtime — containerd (all VMs)

```bash
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

Edit `/etc/containerd/config.toml` and set the cgroup driver to `systemd` (required to match modern kubelet defaults):

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
```

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## 4. Install Kubernetes Tooling (all VMs)

Install `kubeadm`, `kubelet`, and `kubectl` from the official Kubernetes package repo (`pkgs.k8s.io`):

```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

> Replace `v1.31` with the Kubernetes minor version you intend to run.

Enable kubelet (it will crashloop until `kubeadm` configures it — that's expected and normal):
```bash
sudo systemctl enable kubelet
```

`kubectl` is optional on worker nodes but useful on the control plane or your own workstation.

---

## 5. Initialize the Control Plane

Run **only on the control-plane VM**:

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```
(CIDR shown is for Flannel — adjust if using a different CNI.)

Configure `kubectl` access for your user:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Save the `kubeadm join ...` command printed at the end of the output** — you'll need it for the workers.

If you lose it or need a new one later:
```bash
kubeadm token create --print-join-command
```

---

## 6. Install a CNI (Flannel)

Nodes will stay in `NotReady` state until a CNI is installed.

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

---

## 7. Join Worker Nodes

On each worker VM, run the join command saved from step 5:

```bash
sudo kubeadm join <control-plane-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

From the control plane, verify:
```bash
kubectl get nodes
```
All nodes should eventually show `Ready`.

---

## 8. Optional Next Steps

- **Untaint the control plane** if you want it schedulable (common for single-node/lab setups):
  ```bash
  kubectl taint nodes --all node-role.kubernetes.io/control-plane-
  ```
- **Metrics Server** (enables `kubectl top`):
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  ```
- **Ingress controller** (e.g. ingress-nginx) for HTTP routing into the cluster
- **Storage provisioner** (e.g. local-path-provisioner, or a CSI driver for your storage backend) if you need PersistentVolumes

---

## Quick Reference Checklist

- [ ] VMs provisioned with unique hostnames/UUIDs
- [ ] Swap disabled on all nodes
- [ ] Kernel modules & sysctl params set on all nodes
- [ ] Time sync configured
- [ ] Firewall ports opened
- [ ] containerd installed & configured (systemd cgroup driver)
- [ ] kubelet, kubeadm, kubectl installed on all nodes
- [ ] `kubeadm init` run on control plane
- [ ] kubectl configured
- [ ] CNI installed
- [ ] Workers joined
- [ ] All nodes show `Ready`
