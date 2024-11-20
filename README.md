# k8s

**Kubernetes documentation**

- [https://kubernetes.io](https://kubernetes.io/docs/concepts/overview/components/)


**Kubernetes Infrastructure**
- aws
    - [1 (or more) node cluster with ec2 vm](./infrastructure/aws/ec2-vm/README.md)
    - [1 (or more) node cluster with ec2 public vm](./infrastructure/aws/ec2-public-vm/README.md)
    - [eks]()
- azure
    - [azure vm]()
    - [aks]()
- gcp
    - [gcp vm]()
    - [gke]()

**Kubernetes Installation**

Always look for Kubernetes official documents 

prerequisites
    
- Docker Runtime (not equal to docker engine). There are many like CRI-O, containerd and etc ...
- kubeadm
- kubelet
- kubectl

**cka**

- [cka](./.docs/README-cka.md)

**ckd**

- [ckd](./.docs/README-ckd.md)

**Kubernetes Administration**
- [cri & kubernetes tools insllation tips](./.docs/kubernetes-1-31-installation.v2.md).
- [cri](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
    - [containerd](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
    - [CRI-O](https://cri-o.io/)
    - Docker Engine
        - [docker engine](https://docs.docker.com/engine/install/ubuntu/).
        - [cri-dockerd](https://mirantis.github.io/cri-dockerd/usage/install/).
    - [Mirantis Container Runtime]()
- [cni](https://github.com/containernetworking/cni)

- [User & RBAC](./.docs/README-user-rbac.md).
- [kubeconfig](./.docs/README-kube-config.md).
- Debugging Inside cluster.
    - [shopd](https://github.com/jpetazzo/shpod)
    
    - alpine
    ```sh
        kubectl run alpine --image=alpine -it
        # apk update
        # apk add bind-tools curl wget
        # host service-name # to see the attached dns record
    ```


**Ingress Controller**

- [Supported Kubernetes Ingress Class](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).
    - nginx
        - [nginx.org](./.docs/README-nginx-ingress.md)
        - [Kubernetes nginx](./.docs/README-nginx-ingress.md)
    - [haproxy]()
    - [traefik]()


**Kubernetes Components Overview**

![cluster official](./.docs/cluster-components.svg)

---

Cluster Component

![cluster](./.docs/cluster.png)

---

Ingress Controller

![nginx.](./.docs/nginx-ingress.png)


