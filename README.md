# aks Infrastructure

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

# k8s
(most of the description, defination, images are taken from [k8s official docs](https://kubernetes.io/docs/home/) )

Kubernetes is a portable, extensible, open-source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation. It has a large, rapidly growing ecosystem. Kubernetes services, support, and tools are widely available

overview , why k8s is popular and useful.

![alt text](./.tmp/k8s-overview.png "k8s_deployment")


##### Important links

[k8s official documentation](https://kubernetes.io/docs/home/)

[k8s cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

[k8s workload](https://kubernetes.io/docs/concepts/workloads/)

[pull image from privare registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

##### k8s componeant

![alt text](./.tmp/k8s-componeant.png "k8s_componeant")

For more details, explore [k8s componeant](https://kubernetes.io/docs/concepts/overview/components/)

**Control Plane Components (master)**

The control plane's components make global decisions about the cluster (for example, scheduling), as well as detecting and responding to cluster events (for example, starting up a new pod when a deployment's replicas field is unsatisfied).

- **kube-apiserver** : The API server is a component of the Kubernetes control plane that exposes the Kubernetes API. The API server is the front end for the Kubernetes control plane
- **etcd** : Consistent and highly-available key value store used as Kubernetes' backing store for all cluster data.
- **kube-scheduler** : Control plane component that watches for newly created Pods with no assigned node, and selects a node for them to run on.
- **kube-controller-manager** : Control Plane component that runs controller processes.
- **cloud-controller-manager** : A Kubernetes control plane component that embeds cloud-specific control logic. The cloud controller manager lets you link your cluster into your cloud provider's API, and separates out the components that interact with that cloud platform from components that just interact with your cluster.

**Node Components**

Node components run on every node, maintaining running pods and providing the Kubernetes runtime environment.

- **kubelet** : An agent that runs on each node in the cluster. It makes sure that containers are running in a Pod.
- **kube-proxy** : kube-proxy is a network proxy that runs on each node in your cluster, implementing part of the Kubernetes Service concept. 
- **Container runtime** : The container runtime is the software that is responsible for running containers.

**Addons** 

Addons use Kubernetes resources (DaemonSet, Deployment, etc) to implement cluster features. Because these are providing cluster-level features, namespaced resources for addons belong within the kube-system namespace.

- DNS
- Web UI (Dashboard)
- Container Resource Monitoring
- Cluster-level Logging

___ 

Syntex, example and Official documantation Reference :

#### Pod

```yml
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  label:
    type: FE
spec:
  containers:
    - name: nginx
      image: nginx
      ....
```

```sh
kubectl create -f pod/pod-defination.yml
kubectl describe pods/podname
kubectl apply -f ....
```

#### Controller

There are many Controller to deal with in k8s. Below are the details :

- ReplicationController
- ReplicaSet
- Deployments
- StatefulSets
- DaemonSet
- Jobs
- Garbage Collection
- TTL Controller for Finished Resources
- CronJob

[click](https://kubernetes.io/docs/concepts/workloads/controllers/) here for documentation


**ReplicationController**

>Note: A Deployment that configures a ReplicaSet is now the recommended way to set up replication.

A ReplicationController ensures that a specified number of pod replicas are running at any one time. In other words, a ReplicationController makes sure that a pod or a homogeneous set of pods is always up and available.

[official documantation](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/)

Example : 

```yml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    app: nginx
  template:
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

```sh
kubectl create -f controllers/replication-controller/rc-defination01.yml 
kubectl apply -f controllers/replication-controller/rc-defination01.yml
kubectl describe replicationcontrollers/nginx

pods=$(kubectl get pods --selector=app=nginx --output=jsonpath={.items..metadata.name})
echo $pods

kubectl delete replicationcontrollers/nginx
kubectl delete -f controllers/replication-controller/rc-defination01.yml
```

**Replicaset**

A ReplicaSet's purpose is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods.

When to use a ReplicaSet ?

A ReplicaSet ensures that a specified number of pod replicas are running at any given time. However, a Deployment is a higher-level concept that manages ReplicaSets and provides declarative updates to Pods along with a lot of other useful features. Therefore, we recommend using Deployments instead of directly using ReplicaSets, unless you require custom update orchestration or don't require updates at all.

[official documentation](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) for more.

Example:

```yml

apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # modify replicas according to your case
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: gcr.io/google_samples/gb-frontend:v3

```

```sh 
kubectl get rs
kubectl create -f controllers/replicaset/rs-defination.yml
kubectl describe rs/frontend
kubectl apply -f controllers/replicaset/rs-defination.yml
kubectl delete rs/frontend
kubectl delete -f controllers/replicaset/rs-defination.yml
```

**Deployments**

A Deployment provides declarative updates for Pods and ReplicaSets.

You describe a desired state in a Deployment, and the Deployment Controller changes the actual state to the desired state at a controlled rate. You can define Deployments to create new ReplicaSets, or to remove existing Deployments and adopt all their resources with new Deployments.

> Note: Do not manage ReplicaSets owned by a Deployment. Consider opening an issue in the main Kubernetes repository if your use case is not covered below.

[official documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

```yml 

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80

```
Useful command

```sh
kubectl get deployments
kubectl create -f controllers/deployment/nginx-deployment.yml
kubectl apply -f controllers/deployment/nginx-deployment.yml --dry-run=true -o=yaml
kubectl describe deployments.apps nginx-deployment
kubectl describe deployments
kubectl delete deployments.apps nginx-deployment
```


### Service , Load Balancing & Networking

Concepts and resources behind networking in Kubernetes.

Kubernetes networking addresses four concerns:

- Containers within a Pod use networking to communicate via loopback.
- Cluster networking provides communication between different Pods.
- The Service resource lets you expose an application running in Pods to be reachable from outside your cluster.
- You can also use Services to publish services only for consumption inside your cluster.

[official documentation](https://kubernetes.io/docs/concepts/services-networking/) for more details

**Service**
[official documentation](https://kubernetes.io/docs/concepts/services-networking/service/)

An abstract way to expose an application running on a set of Pods as a network service.

With Kubernetes you don't need to modify your application to use an unfamiliar service discovery mechanism. Kubernetes gives Pods their own IP addresses and a single DNS name for a set of Pods, and can load-balance across them.

A Service in Kubernetes is a REST object, similar to a Pod. Like all of the REST objects, you can POST a Service definition to the API server to create a new instance. The name of a Service object must be a valid DNS label name.


> Note: A Service can map any incoming port to a targetPort. By default and for convenience, the targetPort is set to the same value as the port field.

Publishing Services (ServiceTypes)

For some parts of your application (for example, frontends) you may want to expose a Service onto an external IP address, that's outside of your cluster.

Kubernetes ServiceTypes allow you to specify what kind of Service you want. The default is ClusterIP.

Type values and their behaviors are:

- **ClusterIP**: Exposes the Service on a cluster-internal IP. Choosing this value makes the Service only reachable from within the cluster. This is the default ServiceType.

- **NodePort**: Exposes the Service on each Node's IP at a static port (the NodePort). A ClusterIP Service, to which the NodePort Service routes, is automatically created. You'll be able to contact the NodePort Service, from outside the cluster, by requesting <NodeIP>:<NodePort>.

If you set the type field to NodePort, the Kubernetes control plane allocates a port from a range specified by --service-node-port-range flag **(default: 30000-32767)**. Each node proxies that port (the same port number on every Node) into your Service. Your Service reports the allocated port in its .spec.ports[*].nodePort field.

If you want to specify particular IP(s) to proxy the port, you can set the --nodeport-addresses flag in kube-proxy to particular IP block(s); this is supported since Kubernetes v1.10. This flag takes a comma-delimited list of IP blocks (e.g. 10.0.0.0/8, 192.0.2.0/25) to specify IP address ranges that kube-proxy should consider as local to this node.

```yml 
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort
  selector:
    app: MyApp
  ports:
      # By default and for convenience, the `targetPort` is set to the same value as the `port` field.
    - port: 80
      targetPort: 80
      # Optional field
      # By default and for convenience, the Kubernetes control plane will allocate a port from a range (default: 30000-32767)
      nodePort: 30007
```

```sh
```

- **LoadBalancer**: Exposes the Service externally using a cloud provider's load balancer. NodePort and ClusterIP Services, to which the external load balancer routes, are automatically created.

- **ExternalName**: Maps the Service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record

with its value. No proxying of any kind is set up.

Note: You need either kube-dns version 1.7 or CoreDNS version 0.0.8 or higher to use the ExternalName type.

You can also use Ingress to expose your Service. Ingress is not a Service type, but it acts as the entry point for your cluster. It lets you consolidate your routing rules into a single resource as it can expose multiple services under the same IP address





**Service Topology**


**EndpointSlices**

**DNS for Services and Pods**

**Connecting Applications with Services**


**Ingress**

**Ingress Controllers**

Network Policies

Adding entries to Pod /etc/hosts with HostAliases

IPv4/IPv6 dual-stack



### Storage

[official documentation](https://kubernetes.io/docs/concepts/storage/) for more details

### Configuration


### Security

### policies

