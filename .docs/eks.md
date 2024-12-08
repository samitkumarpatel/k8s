# eks

## Infrastructure Plan

The typical resources required are:

**VPC**: With private/public subnets.
**IAM roles**: For the EKS cluster and node groups.
**EKS cluster**: The managed Kubernetes control plane.
**Node groups**: Managed or self-managed EC2 instances

## Documentation:


- [eks with developer.hashicorp.com](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks).


- Other way to install

```sh
git clone https://github.com/hashicorp-education/learn-terraform-provision-eks-cluster
cd learn-terraform-provision-eks-cluster
# Follow the steps along
```
- eksctl

- Install via Terraform by using aws provider.

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
    
    - Install `nginx controller`. [Followed from this Guide](https://kubernetes.github.io/ingress-nginx/deploy/#aws).

    ```sh
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0-beta.0/deploy/static/provider/aws/deploy.yaml

    ```
    - `User Creation` to access cluster.