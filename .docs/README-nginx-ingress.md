## nginx ingress controller by nginxinc
    
- [Github](https://github.com/nginxinc/kubernetes-ingress/tree/main).
    
- [Installtion](https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-manifests/).

- Installtion step by step.

```sh
    git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v3.7.1
    cd kubernetes-ingress/

    kubectl apply -f deployments/common/ns-and-sa.yaml
    kubectl apply -f deployments/rbac/rbac.yaml
    kubectl get pods,svc -n nginx-ingress

    kubectl apply -f examples/shared-examples/default-server-secret/default-server-secret.yaml
    kubectl apply -f deployments/common/nginx-config.yaml
    kubectl apply -f deployments/common/ingress-class.yaml
    kubectl get pods,svc -n nginx-ingress
    kubectl apply -f config/crd/bases/k8s.nginx.org_virtualservers.yaml
    kubectl apply -f config/crd/bases/k8s.nginx.org_virtualserverroutes.yaml
    kubectl apply -f config/crd/bases/k8s.nginx.org_transportservers.yaml
    kubectl apply -f config/crd/bases/k8s.nginx.org_policies.yaml
    kubectl apply -f config/crd/bases/k8s.nginx.org_globalconfigurations.yaml
    kubectl apply -f deployments/deployment/nginx-ingress.yaml
    kubectl create -f deployments/service/nodeport.yaml
    kubectl get pods --namespace=nginx-ingress
    kubectl get pods,svc --namespace=nginx-ingress
```        


## nginx ingress controller by kubernetes
    
- [Github](https://github.com/kubernetes/ingress-nginx/tree/main).

- [User Guide](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/).

- [Deploy](https://kubernetes.github.io/ingress-nginx/deploy/).

- Installation.
    - [Baremetal](Baremetal)
    ```sh
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0-beta.0/deploy/static/provider/baremetal/deploy.yaml
    ```
    - UC


**summary**


Summary Table:

| **Aspect**             | **NGINX Inc. Ingress Controller**               | **Kubernetes NGINX Ingress Controller**   |
|-------------------------|------------------------------------------------|-------------------------------------------|
| **Maintainer**          | F5 NGINX                                       | Kubernetes Community                      |
| **Licensing**           | Free (OSS) or Paid (NGINX Plus)                | Free (Apache 2.0)                         |
| **Advanced Features**   | Yes (e.g., NGINX Plus, WAF, mTLS, JWT)         | Limited                                   |
| **Performance**         | Optimized for enterprises                      | Standard performance                      |
| **Support**             | Paid enterprise support                        | Community-driven                          |
| **Configuration**       | Highly customizable (ConfigMaps, Annotations) | Basic customization with annotations      |
| **Use Case**            | Enterprise-grade workloads, advanced security  | General-purpose Kubernetes ingress        |




[back](../README.md)
    
    
