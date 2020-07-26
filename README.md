# k8s
Kubernetes leaning

[k8s cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)


## Workload

[What are workload in k8s ?](https://kubernetes.io/docs/concepts/workloads/)


The sample menifest file, example and Official documantation :

### Pod (example)

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

### Controller
There are many Controller to deal with in k8s. Below are the details :

- ReplicaSet
- ReplicationController
- Deployments
- StatefulSets
- DaemonSet
- Jobs
- Garbage Collection
- TTL Controller for Finished Resources
- CronJob

[click](https://kubernetes.io/docs/concepts/workloads/controllers/) here for documentation


##### <u>ReplicationController</u>
>Note: A Deployment that configures a ReplicaSet is now the recommended way to set up replication.

A ReplicationController ensures that a specified number of pod replicas are running at any one time. In other words, a ReplicationController makes sure that a pod or a homogeneous set of pods is always up and available.

[click](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/) for the documentation.

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

##### <u> Replicaset </u>

A ReplicaSet's purpose is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods.

example:

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


### Service & Networking

[click](https://kubernetes.io/docs/concepts/services-networking/) for more details

### Storage

[click](https://kubernetes.io/docs/concepts/storage/) for more details

### Configuration

### Security

### policies

### 