
[Official Documentation](https://kubernetes.io/docs/tasks/administer-cluster/certificates/#openssl) or follow below steps.

**A Admin User**

This user will be having full access to the cluster.

```sh
# Generate certificate for the user
openssl req -new -newkey rsa:2048 -nodes -keyout samit.key -out samit.csr -subj "/CN=samit"

sudo openssl x509 -req -in samit.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out samit.crt -days 30

# RBAC for the user
kubectl create clusterrolebinding samit-admin-binding --clusterrole=cluster-admin --user=samit

# Create kubeconfig file for the user
kubectl config set-cluster ec2-k8s --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --server=https://<control_plain_public_ip>:6443 --kubeconfig=samit-kubeconfig

kubectl config set-credentials samit --client-certificate=samit.crt --client-key=samit.key --embed-certs=true --kubeconfig=samit-kubeconfig

kubectl config set-context ec2-k8s-samit-context --cluster=ec2-k8s --user=samit --kubeconfig=samit-kubeconfig

kubectl config use-context ec2-k8s-samit-context --kubeconfig=samit-kubeconfig
 
```

Copy `samit-kubeconfig` file and share to a admin.

Test It!

```sh
# Test If the generated config is working or not
kubectl --kubeconfig=samit-kubeconfig get pods
kubectl --kubeconfig=samit-kubeconfig get nodes

#OR
export KUBECONFIG=$(pwd)/samit-kubeconfig
kubectl get pods
kubectl getnodes

```


**A Normal/ReadOnly User**

This user will have minimum access to the cluster.

```sh

openssl req -new -newkey rsa:2048 -nodes -keyout amit.key -out amit.csr -subj "/CN=amit"

sudo openssl x509 -req -in amit.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out amit.crt -days 30

kubectl create rolebinding amit-binding --clusterrole=view --user=amit --namespace=default

# Create kubeconfig file for the user
kubectl config set-cluster ec2-k8s --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --server=https://<control_plain_public_ip>:6443 --kubeconfig=amit-kubeconfig

kubectl config set-credentials amit --client-certificate=amit.crt --client-key=amit.key --embed-certs=true --kubeconfig=amit-kubeconfig

kubectl config set-context ec2-k8s-amit-context --cluster=ec2-k8s --user=amit --kubeconfig=amit-kubeconfig

kubectl config use-context ec2-k8s-amit-context --kubeconfig=amit-kubeconfig

```

Copy `amit-kubeconfig` file and share to a admin.

Test It!

```sh
# Test
kubectl --kubeconfig=amit-kubeconfig get pods #This will work and can be seen pods running on default namespace
kubectl --kubeconfig=amit-kubeconfig get nodes # Forbidden
```


You can create custom roles and role bindings using Kubernetes manifests as well. The manifest looks like below

```yml
# Developer role with watch access
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["watch"]

# Binding the developer role to a user
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: default
subjects:
- kind: User
  name: developer-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io

# Deployment role with full access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployer
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]

# Binding the deployer role to a user
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: deployer-binding
subjects:
- kind: User
  name: deployer-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: deployer
  apiGroup: rbac.authorization.k8s.io

```

[back](../README.md)