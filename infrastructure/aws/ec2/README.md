
## k8s infra in ec2

> Make sure, You have terraform, ansible installed.

**File structure** 

```sh
├── inventory.yml
├── main.tf
├── playbook.yml
└── README.md
```

**Infrastructure creation with terraform**

```sh
terraform init

terraform validate

terraform plan

terraform apply -auto-approve

```

> Terraform will create a Dynamic inventory file. Make sure you have below ansible galaxy module install.

```sh
ansible-galaxy collection install cloud.terraform
```

**To view the dynamic inventory.**

```sh
ansible-inventory -i inventory.yml --list --vars
```

**Fetch the ssh key to be use for ansibel ssh plugins.**

```sh
terraform output -raw ssh_key >> id_rsa.pem

chmod 400 id_rsa.pem
```

**Test , If all vm can be ping.**

```sh
ansible -i inventory.yml all -m ping
```

**ansibel**
```sh
ansible-playbook -i inventory.yml playbook.yml --syntax-check
```

**user creation**

```sh
openssl genrsa -out samit.key 2048
openssl req -new -key samit.key -out samit.csr -subj "/CN=samit"
sudo openssl x509 -req -in samit.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out samit.crt -days 30

# all access
kubectl create clusterrolebinding samit-admin-binding --clusterrole=cluster-admin --user=samit

# OR
# minimal access
kubectl create rolebinding samit-binding --clusterrole=view --user=samit --namespace=default


kubectl config set-credentials samit --client-certificate=samit.crt --client-key=samit.key
kubectl config set-context samit --cluster=kubernetes --namespace=default --user=samit
   
```

**kubeconfig file creation**
```sh
# Step 1: Set the cluster details
kubectl config set-cluster kubernetes --server=https://<server-address>:6443 \
  --certificate-authority=samit.crt \
  --embed-certs=true

# Step 2: Set the user credentials
kubectl config set-credentials samit \
  --client-certificate=samit.crt \
  --client-key=samit.key \
  --embed-certs=true

# Step 3: Set the context
kubectl config set-context samit \
  --cluster=kubernetes \
  --namespace=default \
  --user=samit

# Step 4: Set the context as the current context
kubectl config use-context samit

```

**Access the cluster**

```sh
kubectl --insecure-skip-tls-verify get nodes
kubectl --insecure-skip-tls-verify get pods
```