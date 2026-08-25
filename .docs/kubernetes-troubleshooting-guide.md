# On-Premise Kubernetes: Component Architecture & Troubleshooting Guide

A reference for how each Kubernetes component actually runs under the hood, the tools needed to inspect it, and how to validate/troubleshoot it with examples.

---

## How Each Component Actually Runs

This is the part that trips people up — not everything is "a container," and not everything is managed the same way.

| Component | How it runs | Managed by | Where to find it |
|---|---|---|---|
| **etcd** | Static pod (container) — unless you deployed *external/stacked-external* etcd, which is rare in kubeadm setups | kubelet (via manifest file) | `/etc/kubernetes/manifests/etcd.yaml` on control-plane VM |
| **kube-apiserver** | Static pod (container) | kubelet (via manifest file) | `/etc/kubernetes/manifests/kube-apiserver.yaml` |
| **kube-scheduler** | Static pod (container) | kubelet (via manifest file) | `/etc/kubernetes/manifests/kube-scheduler.yaml` |
| **kube-controller-manager** | Static pod (container) | kubelet (via manifest file) | `/etc/kubernetes/manifests/kube-controller-manager.yaml` |
| **kubelet** | **NOT a container** — a systemd service/binary running directly on the host OS | systemd | `/usr/bin/kubelet`, unit file `kubelet.service` |
| **containerd** (container runtime) | **NOT a container** — a systemd service/binary; this is what actually creates/runs every container above, including kubelet's static pods | systemd | `/usr/bin/containerd`, unit file `containerd.service` |
| **kube-proxy** | Regular pod, deployed as a **DaemonSet** (one per node) — different from the static pods above | kube-controller-manager / scheduled normally like any workload | `kubectl get daemonset -n kube-system kube-proxy` |
| **CNI plugin (e.g. Flannel)** | Regular pod, deployed as a **DaemonSet** | Same as above | `kubectl get daemonset -n kube-system` |
| **kubectl** | **Not a running component at all** — it's just a CLI binary that sends HTTP requests to the API server | N/A | Runs wherever you invoke it |

### Why this distinction matters

- **Static pods** (etcd, API server, scheduler, controller-manager) are watched and restarted by `kubelet` directly from YAML files on disk — the API server doesn't even need to be up for kubelet to manage them. This is how the cluster "bootstraps itself." You **can't** `kubectl edit` these normally the way you'd edit a Deployment — you edit the manifest file on disk and kubelet auto-detects the change and restarts the pod.
- **kubelet and containerd are turtles-all-the-way-down's base layer** — they're plain Linux processes managed by `systemd`, not by Kubernetes itself. If either is down, nothing above them can run, and `kubectl`/`crictl` won't help — you go straight to `systemctl` and `journalctl`.
- **kube-proxy and CNI pods are ordinary DaemonSet pods** — they behave like any workload: schedulable, restartable via `kubectl delete pod`, visible in `kubectl get pods -n kube-system`.

---

## Tools You'll Need

| Tool | Purpose | Works even if API server is down? |
|---|---|---|
| `kubectl` | Primary interface — status, logs, describe, events | No |
| `journalctl` | systemd service logs (kubelet, containerd) on each VM | Yes |
| `crictl` | Inspect containers/pods at the CRI level, bypassing kubectl/API server entirely | Yes |
| `etcdctl` | Direct etcd health/data inspection | Yes (if etcd itself is reachable) |
| `systemctl` | Check if kubelet/containerd services are running/enabled | Yes |
| `curl` | Hit component health endpoints directly | Partially |
| `ss` / `netstat` | Verify ports are listening | Yes |
| `tcpdump` | Network-level debugging between nodes | Yes |
| `openssl` | Inspect/validate certificates (common failure cause) | Yes |

**Key insight:** when the API server itself is broken, `kubectl` is useless. That's when `crictl` (talks directly to containerd) and `journalctl`/`systemctl` (talk directly to the OS) become your only way in.

---

## Control Plane Components

### 1. etcd — *runs as a static pod (container)*

**What it does:** Stores all cluster state (key-value store). If etcd is down, nothing works — no scheduling, no API reads/writes.

**Validate:**
```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```
Expect: `127.0.0.1:2379 is healthy: successfully committed proposal`

**Troubleshoot example:**
- Symptom: `kubectl get pods` hangs or times out.
- Check if the etcd static pod is running (via containerd directly, not kubectl):
  ```bash
  sudo crictl ps -a | grep etcd
  sudo crictl logs <etcd-container-id>
  ```
- Common cause: disk full or slow disk (etcd is very I/O sensitive) — check with `df -h` and look for `"took too long"` warnings in logs.
- Another common cause: clock skew between control-plane nodes in HA setups — check `chronyc tracking`.
- If the manifest itself is broken, check: `/etc/kubernetes/manifests/etcd.yaml` for typos — kubelet will crashloop it endlessly without a clear kubectl-visible error.

---

### 2. kube-apiserver — *runs as a static pod (container)*

**What it does:** Front door for all cluster operations; everything (kubectl, kubelet, scheduler, controller-manager) talks through it.

**Validate:**
```bash
curl -k https://localhost:6443/healthz
```
Expect: `ok`

Or, if the API server is up, verify deeper subsystem health:
```bash
kubectl get --raw='/readyz?verbose'
```

**Troubleshoot example:**
- Symptom: `kubectl` returns `The connection to the server <ip>:6443 was refused`.
- Since kubectl won't work here, go straight to the container layer:
  ```bash
  sudo crictl ps -a | grep kube-apiserver
  sudo crictl logs <container-id>
  ```
- Common cause: bad flag/typo in `/etc/kubernetes/manifests/kube-apiserver.yaml` — kubelet keeps restarting it since it's just a YAML file kubelet watches on disk.
- Common cause: etcd unreachable — API server logs will show `etcdserver: request timed out` — fix etcd first (it's a hard dependency).
- Check port is actually listening:
  ```bash
  sudo ss -tlnp | grep 6443
  ```

---

### 3. kube-scheduler — *runs as a static pod (container)*

**What it does:** Decides which node a new pod runs on. If it's down, pods stay `Pending` forever.

**Validate:**
```bash
kubectl get pods -n kube-system -l component=kube-scheduler
```
Should show `Running`. Check leader election (relevant in HA/multi-control-plane setups):
```bash
kubectl get lease -n kube-system kube-scheduler
```

**Troubleshoot example:**
- Symptom: New pod stuck in `Pending`, and `kubectl describe pod <pod>` shows no scheduling-related **Events** at all (not even a "no nodes available" message).
- That silence itself is the signal — the scheduler isn't running or can't reach the API server. Check:
  ```bash
  sudo crictl ps -a | grep kube-scheduler
  sudo crictl logs <container-id>
  ```
- Common cause: same as API server — bad static pod manifest at `/etc/kubernetes/manifests/kube-scheduler.yaml`, or an auth/cert path issue preventing it from reaching the API server.

---

### 4. kube-controller-manager — *runs as a static pod (container)*

**What it does:** Runs the reconciliation loops (Deployments, ReplicaSets, Node lifecycle, etc.) that keep actual cluster state matching desired state.

**Validate:**
```bash
kubectl get pods -n kube-system -l component=kube-controller-manager
```

**Troubleshoot example:**
- Symptom: You delete a Deployment's pod and it never gets recreated.
- Check logs the same way:
  ```bash
  sudo crictl ps -a | grep controller-manager
  sudo crictl logs <container-id>
  ```
- Common cause: it lost leader election or can't reach the API server — look for `"leaderelection lost"` in logs.

---

## Node Components

### 5. kubelet — *NOT a container; a systemd-managed binary on the host*

**What it does:** Runs on every node (including control-plane VMs); talks to containerd to actually start/stop containers, and reports node/pod status back to the API server. This is the process that *creates* all the static pod containers above — it can't be a container itself (chicken-and-egg problem).

**Validate:**
```bash
systemctl status kubelet
```
Should be `active (running)`.

**Troubleshoot example:**
- Symptom: `kubectl get nodes` shows a node as `NotReady`.
- Check kubelet logs directly on that VM (not via kubectl):
  ```bash
  sudo journalctl -u kubelet -f --no-pager
  ```
- Common causes you'll see in logs:
  - `"Failed to update node status"` → kubelet can't reach the API server (network/firewall/cert issue)
  - `"cgroup driver mismatch"` → containerd configured for `cgroupfs` but kubelet expects `systemd` (or vice versa) — a very common setup mistake
  - `"PLEG is not healthy"` → container runtime (containerd) is unresponsive:
    ```bash
    sudo systemctl status containerd
    sudo crictl info
    ```
- Also check for resource-pressure taints:
  ```bash
  kubectl describe node <node-name> | grep -A5 Conditions
  ```

---

### 6. kube-proxy — *runs as a regular pod, deployed via DaemonSet*

**What it does:** Runs on every node; maintains iptables/IPVS rules so Services route traffic to the correct pod IPs. Unlike the control-plane components, this is a normal Kubernetes workload — it's scheduled, restartable, and visible like any pod.

**Validate:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
```
Should show one `Running` pod per node.

**Troubleshoot example:**
- Symptom: A pod can reach another pod directly by IP, but `curl <service-name>` (ClusterIP) fails or times out.
- Check kube-proxy logs on the affected node (works fine via kubectl since this is a normal pod):
  ```bash
  kubectl logs -n kube-system <kube-proxy-pod-name>
  ```
- Verify iptables rules actually exist for the service:
  ```bash
  sudo iptables -t nat -L -n | grep <service-cluster-ip>
  ```
  If nothing shows up, kube-proxy isn't syncing rules — check if the pod is crashlooping.
- Common cause: another firewall manager on the node (e.g. `firewalld`) periodically flushing iptables rules that kube-proxy set — disable or reconfigure the conflicting firewall tool.

---

### 7. containerd (bonus — the layer underneath everything) — *NOT a container; a systemd-managed binary*

**What it does:** The actual container runtime. kubelet talks to it via the CRI (Container Runtime Interface) to create every container mentioned above — static pods, kube-proxy, application pods, all of it.

**Validate:**
```bash
systemctl status containerd
sudo crictl info
```

**Troubleshoot example:**
- Symptom: kubelet logs show `"PLEG is not healthy"` or pods stuck in `ContainerCreating`.
- Check containerd's own logs:
  ```bash
  sudo journalctl -u containerd -f --no-pager
  ```
- Common cause: disk pressure (image storage full), corrupted containerd state after an unclean shutdown, or a cgroup driver mismatch with kubelet (see kubelet section above).

---

## Quick Escalation Flow (in order)

1. `kubectl get nodes` and `kubectl get pods -A` — anything obviously `NotReady` or crashlooping?
2. `kubectl describe <resource>` — read the **Events** section first, always.
3. **If kubectl itself doesn't work** → the API server (a container) or the network to it is down. SSH into the control-plane VM and use `crictl` directly — it bypasses the API server entirely.
4. **If a specific control-plane static pod is broken** → check its manifest file in `/etc/kubernetes/manifests/` for typos/bad flags, then `crictl logs` on its container.
5. **If a node is `NotReady`** → SSH to that VM; since kubelet/containerd aren't containers, use `journalctl -u kubelet` and `systemctl status containerd` — kubectl-based inspection won't help here.
6. **If networking/Services are broken** → check the kube-proxy pod (a normal pod) via `kubectl logs`, then verify iptables rules on that specific node.
7. **If it's cluster-wide and confusing** → check etcd health first via `etcdctl`, since every other component is a dependent of it.

---

## Summary Cheat Sheet

| Symptom | First place to look |
|---|---|
| `kubectl` commands hang/refuse connection | `crictl ps -a` on control-plane VM for kube-apiserver, then etcd |
| Pod stuck `Pending` forever, no events | kube-scheduler container logs |
| Deleted pod never recreated | kube-controller-manager container logs |
| Node shows `NotReady` | `journalctl -u kubelet` on that VM |
| Pods stuck `ContainerCreating` | `journalctl -u containerd` on that VM |
| Service ClusterIP unreachable, pod IP works | kube-proxy pod logs + `iptables -t nat -L` on that node |
| Everything cluster-wide is flaky/slow | `etcdctl endpoint health` + disk I/O check |
