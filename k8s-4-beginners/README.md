### Help

Most helpful command to get api reference is :

```
kubectl explain --help
kubectl explain pod
kubectl explain pod.metadata
kubectl explain pod.spec
kubectl explain deployment
kubectl explain service
```

**YAML in k8s**
The mandatory elelment in k8s YAML file are 
```
apiVersion:
kind:
metadata:
   name:
   labels:
      key1: value1
      key2: value2
      ... : ...
spec:
  containers:
  - name:
    image:
```


The Kind and Version table 

|kind|version|
|----|-------|
|POD|v1|
|Service|v1|
|ReplicaSet|app/v1|
|Deployment|apps/v1|

**pod**

Useful command to create a Pod quickly
```
kubectl run redis --image=redis123
```
make use of --dry-run to get the required api request element or redirect the generated output YAML on a file

```
kubectl run redis --image=redis123 --dry-run=client -o yaml > pod.yaml
```

**controller**
controller are brain behind k8s 
Here we can only discuss Replication Controller

Replication Controller to scale
Replication Controller are Old, Replica Set is a new

-Replication Controller
YAML Schema / example

```
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-rc
  labels:
    app: nginx
    type: fe
    ...
spec:
 template:
   metadata:
     name: nginx-pod
     labels:
       app: nginx
       type: fe
       ...
   spec:
     containers:
     - name: nginx
       image: nginx
 replicas: 3
```

**replicaset**
Raplicaset is a alternative and advanced from ReplicationController
In other word we can say ReplicaSet is a process , which monitor pods

YAML schema / example
```
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name:
  labels:
spec:
 template:
   metadata:
     name: nginx-pod
     labels:
       app: nginx
       type: fe
       ...
   spec:
     containers:
     - name: nginx
       image: nginx
 replicas: 3
 selector:
   matchLabals:
    type:
    app:
```
selector is a new property compare to Replication Controller. This is a mandatory filed This is because after created of pod also you can attached with currently created ReplicaSet

to scale the ReplicaSet, there are number of ways
1. Update the menifest file and execute this command : `kubectl replace -f fileName.yaml`
2. `kubectl scale --replicas=6 -f fineName.yaml`
or
kubectl scale --replicas=6 replicaset nameOfTheReplicaSet


**service**
