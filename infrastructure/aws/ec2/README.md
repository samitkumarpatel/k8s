
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

**User creation**
or [follow](https://kubernetes.io/docs/tasks/administer-cluster/certificates/#openssl) documents.

```sh
openssl genrsa -out samit.key 2048
openssl req -new -key samit.key -out samit.csr -subj "/CN=samit" -subj "/CN=51.20.250.97"
sudo openssl x509 -req -in samit.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out samit.crt -days 30

# all access
kubectl create clusterrolebinding samit-admin-binding --clusterrole=cluster-admin --user=samit

# OR
# minimal access
kubectl create rolebinding samit-binding --clusterrole=view --user=samit --namespace=default   
```

**Kubeconfig file creation**
```sh

kubectl config set-credentials samit --client-certificate=samit.crt --client-key=samit.key
kubectl config set-context samit --cluster=kubernetes --namespace=default --user=samit



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

**Sample config**

```sh
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.31.22.155:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
users:
- name: kubernetes-admin
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
current-context: kubernetes-admin@kubernetes
```

**Access the cluster**

```sh
kubectl --insecure-skip-tls-verify get nodes
kubectl --insecure-skip-tls-verify get pods
```