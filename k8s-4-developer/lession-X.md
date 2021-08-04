# Docker Security

Container are not isolated from host. 
Container and host share their kernel.
Container are isolated by namespace. it can only see his own process, not host process or not from any other name space processes.

```sh
docker run --name ubuntu ubuntu sleep 3600
docker exec -it ubuntu bash
ps aux
```

root user in Linux has many Capabilities, like :

CHOWN ,DAC, KILL, SETFCAP, SETPCAP, SETGID, SETUID, NET_BIND, NET_RAW, MAC_ADMIN, BROADCAST, NET_ADMIN, SYS_ADMIN, SYS_CHROOT, AUDIT_WRITE, etc..

if you want to add the above capabilities during the docker run, make use of below like command:
```sh 
docker run --cap-add MAC_ADMIN ubuntu # add cap 
docker run --cap-drop MAC_ADMIN ubuntu # drop cap
docker run --priviliged ubuntu # Give ALl Cap
```

# Kubernetes Security

you can configure in bith pod level as well as container level

```yaml
apiVersion:
kind:
metadata:
  name:
spec:
  securityContext:
    runAsUser: 1000
    capabilities:
       add: [MAC_ADMIN]
  containers:
    - name:
      image:
      securityContext:
        runAsUser: 1000
        capabilities:
           add: [MAC_ADMIN]
```

# Service Account

2 types of user accoiunt in k8s
1. User - used by User like admin, developer and other
2. Service - account use by application to intract with k8s
```sh
kubectl create serviceaccount <name>
k get serviceaccount
k describe serviceaccount <name>
``` 
It create a token as well, to see this token run

```sh
k describe secret <token_name> 
```
This token can be used as a bearer token for k8s api

```sh
curl https://k8s:6443/api -insecure --header "Authorization: Bearer <token>"
```

The service account tokens are made automatically available for the pod using service account as a mount volume. To make use of that , you can simply attach that as a env Variable and make use of it.
k describe pod <podname> will show you attach volume details, If you navigate to that path you can find 3 files i.e. ca.cert , namespace and token.

For each namespace has his own `default` service account with name default. This serviceaccount is much more restricted, so that its always recomanded to use you own service account.


# Resources Requirements
k8s scheduler decide which pod goes to which nodes.

### CPU
1 CPU =
   1 AWS vCPU
   1 GCP Core
   1 Azure Core
   1 Hyperthread

### MEM
1G (gigabyte) = 1,000,000,000 bytes
1M (Megabyte) = 1,000,000 bytes
1K (Kilobyte) = 1,000 bytes

1Gi (Gibibyte) = 1,073,741,824 bytes
1Mi (Mebibyte) = 1,048,576 bytes
1Ki (Kibibyte) = 1024 bytes

This can be used in your pod defination like 

```yaml
 ....
  containers:
    resources:
      limit:
        cpu:
        memory:
      request:
        cpu:
        memory:
```

If you want all the pod running on the cluster to assing some default memory and cpu, you need to create a LimitRange k8s object.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
   name:
spec:
  limits:
  - defaul:
      memory: 512Mi
    defaultRequest:
      memory: 256Mi
    type: Container
```

[This](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/) has more information around this.


# Taints & Tolerations
Taints & Tolerations are used to set restriction on node - so that pod can be restricted to run or accept the pod with certiain toleration .

When we set k8s cluster, by default in master node a taints is set by default.

Taints has to be apply on Nodes
Tolerations has to apply to pods

```sh
k taint nodes <name> key=val:taint-effect
k taint nodes node1 app=blue:NoSchedule
``` 
taint-effect are 
- NoSchedule
- PreferNoSchedule
- NoExecute


if the node has a taint like this
```sh
k taint nodes node1 app=blue:NoSchedule
```
than the manidest has to be look like this for toleration

pod-defination.yaml
```yaml
apiVersion:
kind:
metadata:
  name:
spec:
  containers:
  - name:
    image:
  tolerations:
  - key: "app"
    operator: "Equal"
    value: "blue"
    effect: "NoSchedule"
```

