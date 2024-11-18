**kubeconfig**

```sh
kubectl config --kubeconfig=samit-kubeconfig view
#OR
kubectl config --kubeconfig=amit-kubeconfig view

#OR
export KUBECONFIG=/path/to/samit-kubeconfig

kubectl config view

```

kubeconfig file

```sh
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    certificate-authority-data: </etc/kubernetes/pki/ca.crt base64 encoded data>
    server: https://<HOST_IP>:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: <username>
  name: admin-context
users:
- name: <username>
  user:
    client-certificate-data: <path/to/user/file.crt>
    client-key-data: <path/to/user/file.key>
current-context: admin-context
```



> Note : Some data might be base64 encoded on the config file. If you want the real data to be seen, make sure you decode it like `echo 'base64 encoded content' | base64 -d`


[back](../README.md)