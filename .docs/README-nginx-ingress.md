**nginx by nginxinc**
    
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


**nginx by kubernetes**
    
- [Github](https://github.com/kubernetes/ingress-nginx/tree/main).
    
- [Installation](https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/tags/ingress-nginx-3.7.1/deploy/static/provider/baremetal/deploy.yaml)


[back](../README.md)
    
    
