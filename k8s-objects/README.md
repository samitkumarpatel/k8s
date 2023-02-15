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

- **Service to Service call**:

'<service.name>.<namespace name>.svc.cluster.local or <service.name>.<namespace name>'

HTTP/HTTPS across namespace ref : http://<service-name>.<namespace-name>.svc.cluster.local

If you want to use it as a host and want to resolve it,
'''
                Use : <service name> (Use if in same namespace)
                Use : <service.name>.<namespace name> (Use if across namespace)
                Use : <service.name>.<namespace name>.svc.cluster.local (FQDN)
'''
If you are using ambassador to any other API gateway for a service located in another namespace it's always suggested to use short fqdn but it's also fine to use full however make sure it's not auto appending .svc.cluster.local :
'''
            Use : <service name>
            Use : <service.name>.<namespace name>
            Not : <service.name>.<namespace name>.svc.cluster.local
'''
For example, servicename.namespacename.svc.cluster.local,

Description

This will send a request to a particular service inside the namespace you have mentioned.

Extra :

External name service Ref

If you are using the External name as service to resolve the name internally you can use the below for ref

kind: Service
apiVersion: v1
metadata:
  name: service
spec:
  type: ExternalName
  externalName: <servicename>.<namespace>.svc.cluster.local
Here, replace the <servicename> and <namespace> with the appropriate values.

In Kubernetes, namespaces are used to create virtual environment but all are connected with each other through specific DNS convention.


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
