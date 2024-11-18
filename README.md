# k8s

**kubernetes.io**
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
- 1.31
    - [ubuntu](./.docs/kubernetes-1-31-installation.md)

**cka**

- [cka](./.docs/README-cka.md)

**ckd**

- [ckd](./.docs/README-ckd.md)

**Kubernetes Administration**

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


**Kubernetes Components Overview**

![cluster official](./.docs/cluster-components.svg)

> This Image has been taken from from Kubernetes official documents.
---

Cluster Component

![cluster](./.docs/cluster.png)

---

Ingress Controller

![nginx.](./.docs/nginx-ingress.png)


