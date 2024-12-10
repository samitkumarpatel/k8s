# eks

## Infrastructure Plan

The typical resources required are:

**VPC**: With private/public subnets.
**IAM roles**: For the EKS cluster and node groups.
**EKS cluster**: The managed Kubernetes control plane.
**Node groups**: Managed or self-managed EC2 instances

## Documentation:


### [eks with developer.hashicorp.com](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks).


### Other way to install

```sh
git clone https://github.com/hashicorp-education/learn-terraform-provision-eks-cluster
cd learn-terraform-provision-eks-cluster
# Follow the steps along
```
### eksctl

### Install via Terraform by using aws provider.

- Infra from scratch with aws eks paas.
- Navigate to `aws`/`eks`/`v1` folder.
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
    # NAME         TYPE           CLUSTER-IP       EXTERNAL-IP
    # nginx-lb     LoadBalancer   172.20.26.140    a8abf1179f0a748c9933d9383937c22b-554167943.eu-north-1.elb.amazonaws.com   80:32504/TCP   103s   app=nginx
```
    
    
    
    
### Install `nginx controller` in aks

- [nginx controller](https://kubernetes.github.io/ingress-nginx/deploy/#aws).

    ```sh
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0-beta.0/deploy/static/provider/aws/deploy.yaml
    
    kubectl get svc -n ingress-nginx 
    ```

    > Copy the ExternalIp from nginx LoadBalancer and replace with below example

    
    Then deploy the Ingress

    ```sh
    kubectl -f apply https://raw.githubusercontent.com/samitkumarpatel/k8s/refs/heads/main/api-resources/nginx.yml
    ```
    You might see some error during above command. This is due to the validation hook is not accessable. To fix that temp
    follow below:

    ```sh
        kubectl delete validatingwebhookconfiguration ingress-nginx-admission
        kubectl get validatingwebhookconfiguration
        k apply -f nginx.yml
        k get ingress
        k describe ingress nginx-ingress-domain
        
        curl -H "Host:a.foo.bar" <Ingress LoadBalancer Host>
        #Like below
        curl -H "Host:a.foo.bar" a69dc76bf3dfb48dd86f8d4d06dca3b0-c8fd7e2c584bcfaf.elb.eu-north-1.amazonaws.com
        
        curl -H "Host:a.foo.bar" a69dc76bf3dfb48dd86f8d4d06dca3b0-c8fd7e2c584bcfaf.elb.eu-north-1.amazonaws.com/a

        curl -H "Host:www.nginx-example.io" a69dc76bf3dfb48dd86f8d4d06dca3b0-c8fd7e2c584bcfaf.elb.eu-north-1.amazonaws.com
        curl -H "Host:www.nginx-example.io" a69dc76bf3dfb48dd86f8d4d06dca3b0-c8fd7e2c584bcfaf.elb.eu-north-1.amazonaws.com/nginx
    ```
    Or you can modify the Host `nginx.yml` this file from `www.nginx-example.io` to `<Ingress LoadBalancer Host>` and access it from Browser.


### `User Creation` to access cluster.
