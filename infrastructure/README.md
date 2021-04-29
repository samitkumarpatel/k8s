### aks Infrastructure

make sure you have teraform installed, make the infrastructure creation possible.
(You can try az cli option as well , if you are not familier with Terraform)

```sh
export ARM_SUBSCRIPTION_ID="XXXXXXX"
export ARM_CLIENT_ID="XXXXXXX"
export ARM_CLIENT_SECRET="XXXXXXX"
export ARM_TENANT_ID="XXXXXXX"
export TF_VAR_ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET

git clone https://github.com/samitkumarpatel/k8s.git
cd k8s/infrastructure

terraform init
# before you begin , change the resource group name, cluster name and other necessary naming you want in terraform.tfvars file
terraform plan
terraform apply --auto-approve

# If the Infrastructure creation is done, execute below steps , so that kubectl will point to aks cluster from your local development env, you just created. 
# Note - This will only scoped to the current active console, If you want to make kubectl always point to aks cluster , add export KUBECONFIG=./azurek8s to .bashrc or .bash_profile or .zsh (what ever shell you are using)

export KUBECONFIG=./azurek8s
echo "$(terraform output kube_config)" > ./azurek8s

# To Test kubectl is aligned to aks cluster
kubectl get nodes

# Create generic acr (azure container registry) Secrets in aks cluster , so that it can be used in deployment manifest and with this secrets aks cluster will be able to pull the image from acr (azure container registry)

kubectl create secret docker-registry aks-registry-secret --docker-server=<acr_name>.azurecr.io --docker-username=$ACR_USERNAME --docker-password=$ACR_PASSWORD --docker-email=$ACR_EMAIL_OR_COULD_BE_ANY

```
