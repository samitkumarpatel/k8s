# k8s

**Official Documentation**
- [https://kubernetes.io](https://kubernetes.io/docs/concepts/overview/components/)

**Installation**
- ubuntu
    - [command to install both master and worker node](./kubernetes-1-31-installation.md)

**Kubernetes Infrastructure on**
- aws
    - [3 (or more) node cluster with ec2](./infrastructure/aws/ec2/README.md)
- azure

- gcp

**cka**

- [cka](./README-cka.md)

**ckd**

- [ckd](./README-ckd.md)

**Debugging Tools**

- [shopd](https://github.com/jpetazzo/shpod)
- alpine
```sh
kubectl run alpine --image=alpine -it
# apk update
# apk add bind-tools curl wget
# host service-name # to see the attached dns record
```

**Ingress Controller**
- [Supported Ingress Class](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).
- nginx
    - [nginx ingress controller](https://github.com/nginxinc/kubernetes-ingress/tree/main).
    - [nginx Installtion Steps](https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-manifests/)


**Kubernetes Components Overview**

![cluster official](./.docs/cluster-components.svg)

> This Image has been taken from from Kubernetes official documents.
---

Cluster Component

![cluster](./.docs/cluster.png)

---

Ingress Controller

![nginx.](./.docs/nginx-ingress.png)


