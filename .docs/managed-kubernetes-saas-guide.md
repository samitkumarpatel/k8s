# Managed Kubernetes (EKS / AKS / GKE): Component Architecture & Troubleshooting Guide

A companion to the on-premise guide — covering what you can and can't see/touch in managed Kubernetes, and how to troubleshoot each component when the cloud provider owns the control plane.

---

## The Big Mental Shift

On-prem, **you** are the systemd/crictl layer for the control plane. In managed Kubernetes, the provider hides that layer completely — no SSH access to control-plane nodes, no `crictl`, no static pod manifests to edit. Your troubleshooting toolkit shrinks for the control plane and shifts almost entirely to **cloud provider APIs/consoles + logs**, while node-level troubleshooting (kubelet, kube-proxy) stays similar to on-prem *if* you're on EKS/AKS Standard or GKE Standard (where nodes are still VMs you can access).

---

## How Each Component Runs — Comparison Table

| Component | On-Prem (kubeadm) | AWS EKS | Azure AKS | GCP GKE |
|---|---|---|---|---|
| **etcd** | Static pod, on your control-plane VM | Fully managed, invisible — runs in AWS-owned infra, no access at all | Fully managed, invisible | Fully managed, invisible |
| **kube-apiserver** | Static pod, on your control-plane VM | Fully managed, invisible — you only see the public/private endpoint | Fully managed, invisible | Fully managed, invisible |
| **kube-scheduler** | Static pod | Fully managed, invisible | Fully managed, invisible | Fully managed, invisible |
| **kube-controller-manager** | Static pod | Fully managed, invisible | Fully managed, invisible | Fully managed, invisible |
| **kubelet** | systemd binary on every VM | Runs on **your** worker nodes (EC2) — accessible via SSH if self-managed node group; hidden if using **Fargate** | Runs on **your** worker nodes (VMSS) — accessible via SSH/AKS node access | Runs on **your** worker nodes (GCE VMs) — accessible via SSH; hidden entirely in **Autopilot** |
| **containerd** | systemd binary on every VM | Same as kubelet — visible on managed/self-managed node EC2s, hidden on Fargate | Same as kubelet — visible on AKS nodes | Same as kubelet — visible on Standard nodes, hidden on Autopilot |
| **kube-proxy** | DaemonSet pod | DaemonSet pod, visible via `kubectl` | DaemonSet pod, visible via `kubectl` | DaemonSet pod, visible via `kubectl` (Standard); may not exist as a visible pod on Autopilot |
| **CNI** | Flannel (DaemonSet, your choice) | Amazon VPC CNI (DaemonSet, pre-installed) | Azure CNI or kubenet (DaemonSet, pre-installed) | GKE VPC-native CNI (built-in, less visible) |
| **kubectl** | CLI only | CLI only | CLI only | CLI only |

**Key takeaway:** control-plane components (etcd, API server, scheduler, controller-manager) go from "static pods you can `crictl logs`" to "black boxes you can only observe through provider-emitted logs and metrics." Node-level components (kubelet, containerd, kube-proxy) stay largely the same **unless** you use a serverless node option (Fargate / GKE Autopilot), in which case those disappear from view too.

---

## Tools You'll Need (Managed vs On-Prem)

| Tool | On-Prem role | Managed Cloud role |
|---|---|---|
| `kubectl` | Primary interface | Still primary interface — now your *only* window into most things |
| `journalctl` / `crictl` | Direct control-plane inspection | Only usable if you SSH into a **worker** node (not available for control plane at all) |
| `etcdctl` | Direct etcd inspection | **Not usable** — etcd is inaccessible in all three |
| Cloud provider CLI (`aws`, `az`, `gcloud`) | N/A | Central tool for cluster-level status, node group health, and pulling control-plane logs |
| Cloud provider console/logs (CloudWatch, Azure Monitor, Cloud Logging) | N/A | Where control-plane component logs actually live |
| `kubectl get events` / `describe` | Useful | Even more critical — often your only signal when something upstream is failing |

---

## Control Plane Components (Fully Managed — same pattern across all three)

Since you can't `crictl logs` a control plane that isn't yours, troubleshooting shifts to **provider-exposed logs** and **symptom-based inference through kubectl**.

### 1. etcd

**Validate:** No direct access. Infer health via API server responsiveness:
```bash
kubectl get --raw='/healthz'
kubectl get --raw='/readyz?verbose'
```

**Troubleshoot example:**
- Symptom: cluster-wide slowness, `kubectl` requests timing out intermittently.
- You cannot inspect etcd directly on any of the three. Instead:
  - **EKS:** Check the EKS **Control Plane Logging** for `api` and `audit` logs in CloudWatch — look for latency warnings.
    ```bash
    aws eks update-cluster-config --name my-cluster \
      --logging '{"clusterLogging":[{"types":["api","audit"],"enabled":true}]}'
    ```
  - **AKS:** Enable **Diagnostic Settings** → send `kube-apiserver` logs to Log Analytics, query for etcd-related timeout errors.
  - **GKE:** Check **Cloud Logging** filtered to `resource.type="k8s_control_plane_component"` and `logName` containing `etcd`.
- If a real etcd-level issue is found (rare — this is the provider's job), open a support case; there's nothing more you can do at your layer.

---

### 2. kube-apiserver

**Validate:**
```bash
kubectl get --raw='/healthz'
kubectl cluster-info
```

**Troubleshoot example:**
- Symptom: `kubectl` returns connection timeouts or `Unauthorized`.
- **First check the basics that are actually your responsibility:**
  - Network path: is your endpoint public or private? For private endpoints, are you on a peered VPC/VNet or via VPN/bastion?
    ```bash
    # EKS
    aws eks describe-cluster --name my-cluster --query "cluster.resourcesVpcConfig"
    # AKS
    az aks show --name myAKSCluster --resource-group myResourceGroup --query "apiServerAccessProfile"
    # GKE
    gcloud container clusters describe my-cluster --format="value(privateClusterConfig)"
    ```
  - Credentials/kubeconfig expired or IAM/RBAC mapping broken:
    ```bash
    aws eks update-kubeconfig --name my-cluster       # EKS
    az aks get-credentials --name myAKSCluster --resource-group myResourceGroup --overwrite-existing   # AKS
    gcloud container clusters get-credentials my-cluster    # GKE
    ```
- If networking and auth check out and it's still failing, check provider status pages (AWS Health Dashboard / Azure Status / GCP Status Dashboard) — this is the point where it's genuinely out of your hands.

---

### 3. kube-scheduler / kube-controller-manager

**Validate:** No direct access — infer via pod behavior.
```bash
kubectl get pods -A --field-selector=status.phase=Pending
kubectl describe pod <pending-pod>
```

**Troubleshoot example:**
- Symptom: Pod stuck `Pending`, and unlike on-prem, you *do* usually still get scheduling-related Events here (`0/3 nodes are available: insufficient cpu`), because this part of the API is provider-managed but still functions normally in >99% of cases.
- If Events show a **real scheduling constraint** (resources, taints, affinity) — that's on you to fix, same as on-prem.
- If Events show **nothing at all** for an extended period (rare) — that indicates an actual scheduler-level outage:
  - **EKS:** Check CloudWatch Container Insights or open an AWS Support case.
  - **AKS:** Check Azure Monitor for `kube-scheduler` diagnostic logs (must be enabled first).
  - **GKE:** Check Cloud Logging for `k8s_control_plane_component` scheduler entries.
- In practice, 95% of "scheduler problems" in managed Kubernetes are actually node capacity or autoscaler problems (see Node section below), not the scheduler itself.

---

## Node Components (You still manage these — unless serverless)

### 4. kubelet

**Applies to:** EKS (EC2 node groups, self-managed or managed), AKS (all node pools), GKE Standard. **Does not apply to:** EKS Fargate, GKE Autopilot (fully abstracted).

**Validate:**
```bash
kubectl get nodes
kubectl describe node <node-name>
```
If you have SSH access to the node:
```bash
systemctl status kubelet
```

**Troubleshoot example:**
- Symptom: A node shows `NotReady`.
- Same first move as on-prem — read node Conditions:
  ```bash
  kubectl describe node <node-name> | grep -A10 Conditions
  ```
- If SSH access is available:
  ```bash
  # EKS - SSH via bastion or SSM Session Manager
  aws ssm start-session --target <instance-id>
  sudo journalctl -u kubelet -f

  # AKS - via kubectl debug node (no direct SSH needed)
  kubectl debug node/<node-name> -it --image=mcr.microsoft.com/dotnet/runtime-deps

  # GKE - via gcloud SSH
  gcloud compute ssh <node-name> --zone us-central1-a
  sudo journalctl -u kubelet -f
  ```
- Common cause specific to managed node pools: **node autoscaler drain/replace cycle** looks like a `NotReady` blip — check if it's actually a scale-down event:
  ```bash
  kubectl get events --field-selector reason=NodeNotReady
  ```
- Common cause: node AMI/image out of date and incompatible with control-plane version after an upgrade — check node pool Kubernetes version matches control plane:
  ```bash
  # EKS
  aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name standard-workers
  # AKS
  az aks nodepool show --cluster-name myAKSCluster --resource-group myResourceGroup --name nodepool1
  # GKE
  gcloud container node-pools describe default-pool --cluster my-cluster
  ```

---

### 5. kube-proxy

**Validate:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
```

**Troubleshoot example:**
- Symptom: Service ClusterIP unreachable, direct pod IP works.
- Same as on-prem — check the pod's own logs since it's a normal DaemonSet pod in all three:
  ```bash
  kubectl logs -n kube-system <kube-proxy-pod-name>
  ```
- Verify iptables/IPVS rules on the node (requires node access):
  ```bash
  sudo iptables -t nat -L -n | grep <service-cluster-ip>
  ```
- **GKE-specific note:** if using GKE Dataplane V2 (eBPF-based, Cilium under the hood), there is **no kube-proxy pod at all** — troubleshoot via:
  ```bash
  kubectl get pods -n kube-system -l k8s-app=cilium
  kubectl exec -n kube-system <cilium-pod> -- cilium status
  ```

---

### 6. containerd

**Applies to:** Same node-based caveat as kubelet — not accessible on Fargate/Autopilot.

**Validate (with node access):**
```bash
sudo systemctl status containerd
sudo crictl info
```

**Troubleshoot example:**
- Symptom: Pods stuck `ContainerCreating` on managed node pools.
- Check via node access (same commands as on-prem, see above for SSH method per provider).
- Common cause specific to cloud: **image pull failures due to IAM/identity misconfiguration** rather than local disk issues:
  ```bash
  kubectl describe pod <pod-name> | grep -A5 Events
  ```
  Look for `ImagePullBackOff` tied to registry auth (ECR/ACR/Artifact Registry permissions), not just registry unreachable.

---

## Serverless Node Options — Special Case (EKS Fargate / GKE Autopilot)

When you opt into serverless compute, kubelet/containerd/kube-proxy become fully invisible too — same trust model as the control plane.

| What you lose access to | What you troubleshoot instead |
|---|---|
| Node SSH, kubelet logs, containerd logs | `kubectl describe pod` Events only |
| Direct iptables inspection | Provider-level networking docs / VPC flow logs |
| Node-level metrics via node-exporter | Provider's built-in metrics (CloudWatch Container Insights, GKE Autopilot metrics) |

**Troubleshoot example (EKS Fargate):**
- Symptom: Pod stuck `Pending` indefinitely on a Fargate profile.
- Check Fargate profile selector matches the pod's namespace/labels:
  ```bash
  aws eks describe-fargate-profile --cluster-name my-cluster --fargate-profile-name my-profile
  ```
- Check Events for Fargate-specific scheduling errors:
  ```bash
  kubectl describe pod <pod-name>
  ```
  Common Fargate-only error: unsupported pod spec (e.g. hostPort, DaemonSets aren't supported on Fargate at all).

---

## Quick Escalation Flow (Managed Kubernetes)

1. `kubectl get nodes` and `kubectl get pods -A` — same starting point as on-prem.
2. `kubectl describe <resource>` — Events are even more important here since it's often your *only* signal.
3. **If it looks like a control-plane issue** (API server slow/unreachable, etcd-like symptoms) → check provider logs (CloudWatch / Azure Monitor / Cloud Logging), then provider status page. You cannot go deeper than this.
4. **If a node is `NotReady`** → if node access exists (not Fargate/Autopilot), SSH in and check `journalctl -u kubelet` / `systemctl status containerd`, same as on-prem. If serverless, check `kubectl describe node` and provider console only.
5. **If networking/Services are broken** → check kube-proxy (or Cilium on GKE Dataplane V2) pod logs, then node-level iptables if accessible.
6. **If nothing on your side explains it** → check the cloud provider's public status dashboard before assuming it's your misconfiguration:
   - AWS: https://health.aws.amazon.com/health/status
   - Azure: https://azure.status.microsoft/
   - GCP: https://status.cloud.google.com/

---

## Summary Cheat Sheet

| Symptom | On-Prem first move | Managed Cloud first move |
|---|---|---|
| `kubectl` hangs/refuses connection | `crictl ps -a` for kube-apiserver | Check network path (public/private endpoint) + refresh kubeconfig |
| Pod `Pending`, no events | kube-scheduler container logs | `kubectl describe pod` (usually shows resource/capacity reason); check node autoscaler |
| Deleted pod never recreated | kube-controller-manager logs | Same symptom check via `kubectl describe`; rarely a provider-side issue |
| Node `NotReady` | `journalctl -u kubelet` on VM | SSH/session into node if available, else `kubectl describe node` only |
| Pods stuck `ContainerCreating` | `journalctl -u containerd` | Check image pull auth (IAM/ACR/Artifact Registry) before assuming runtime issue |
| Service ClusterIP unreachable | kube-proxy logs + iptables | Same, but check for Cilium/eBPF dataplane on GKE first |
| Everything cluster-wide is flaky | `etcdctl endpoint health` | Provider control-plane logs + provider status dashboard |
