# eks

## eks Infrastructure details

The typical resources required are:

**VPC**: With private/public subnets.
**IAM roles**: For the EKS cluster and node groups.
**EKS cluster**: The managed Kubernetes control plane.
**Node groups**: Managed or self-managed EC2 instances
**Fargate Profile**: Fargate Profile

## Documentation:


- [eks with developer.hashicorp.com](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks).
- [terraform-aws-modules](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).

## Installation

### eks cluster with Terraform Learning Modules. 

```sh
git clone https://github.com/hashicorp-education/learn-terraform-provision-eks-cluster
cd learn-terraform-provision-eks-cluster
# Follow the steps along
```
### eks cluster with eksctl

### eks cluster with awsCli

### eks cluster with `Terraform resources` -aws provider.

- Infra from scratch with aws eks paas.
- Navigate to `aws`/`eks`/`eks-nodegroup` folder from this repository.
- Make sure you have terraform and aws cli Installed.
- Command to be execute for cluster Installation and `kubectl` aceess:
    
```sh
    terraform init

    terraform validate

    terraform plan -out plan.out

    terraform apply plan.out

    terraform output -raw kubeconfig >> kubeconfig

    export KUBECONFIG=$(pwd)/kubeconfig

    kubectl get nodes -o wide

```
- To test your cluster with an deployment, follow below:

```sh
kubectl -f apply https://raw.githubusercontent.com/samitkumarpatel/k8s/refs/heads/main/api-resources/nginx.yml

# Wait for some time
kubectl get svc -o wide
``` 
- After the above command, You can see an similar line like below (along with other details):

```sh
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP
nginx-lb     LoadBalancer   172.20.26.140    a8abf1179f0a748c9933d9383937c22b-554167943.eu-north-1.elb.amazonaws.com   80:32504/TCP   103s   app=nginx
```

### eks cluster with `Terraform modules`.
- [eks with terraform-aws-modules](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
    
## Install `nginx controller` in aks

- **[nginx controller from Kubernetes contributed repository](https://kubernetes.github.io/ingress-nginx/deploy/#aws).**

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0-beta.0/deploy/static/provider/aws/deploy.yaml
    
kubectl get svc -n ingress-nginx 
```

- **[Ingress Controller from F5]()**

Under construction

- **Test Ingress endpoint**

Then deploy the Ingress Example like below for testing purpose.
    
> Ingress endpoint or publically accessable URL can be found from `kubectl get svc -n ingress-nginx`. Look for Loadbalancer service Type and copy the endpoint from `EXTERNAL-IP` column.

```sh
kubectl -f apply https://raw.githubusercontent.com/samitkumarpatel/k8s/refs/heads/main/api-resources/nginx.yml
```
    
> If you see any validation error whiel Ingress creation, This is due to the validation hook is not accessable with in cluster and this is due to Ingress Installation issue. To fix that temporary, follow below (It's not recomanded for production):

```sh
kubectl delete validatingwebhookconfiguration ingress-nginx-admission
kubectl get validatingwebhookconfiguration
kubectl apply -f nginx.yml
kubectl get ingress
kubectl describe ingress nginx-ingress-domain
```

If no error Test it like this. 

> In the below example remember to replave the `<EXTERNAL-IP>` from ingress Loadbalancer Service Type.

```sh    
    curl -H "Host:a.foo.bar" <EXTERNAL-IP>
    #Like below
    curl -H "Host:a.foo.bar" a69dc76bf3dfb48dd86f8d4d06dca3b0-c8fd7e2c584bcfaf.elb.eu-north-1.amazonaws.com

    curl -H "Host:a.foo.bar" <EXTERNAL-IP>/a

    curl -H "Host:www.nginx-example.io" <EXTERNAL-IP>

    curl -H "Host:www.nginx-example.io" <EXTERNAL-IP>/nginx
```

Or you can modify the Host part in `nginx.yml` available in `api-resources` folder in this repo from `www.nginx-example.io` to `<EXTERNAL-IP>` and access it from Browser.


## `User Creation` to access cluster.
