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
|ReplicaSet|apps/v1|
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

**Deployment**
is a k8s Object,thats comes higher in the hirerchy. It has many features like:
- rolling update
- undo changes
- pause
- resume changes as required

Defination : is similar to ReplicaSet except kind: Deployment
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name:
  labels:
    key: value
spec:
  template:
    metadata:
       name:
       labels:
         key:value
    spec:
     containers:
     - image:
       name: 
  replicas: 2
  selector:
    matchLabels:
       key: value

```

Below are the command to make use of Deployment

- `kubectl create -f deployment.yaml` - will create a new deployment
- `kubectl get deployment` - will listout all the deployment available in the current context namespace
- `kubectl get rs` - you can see a replica set with the name deployment
- `kubectl get pods` - will show all the pods running with the current context and current namespace which are also created by the deployment

Example: can be found on the deployment folder

**Update & Rollback - Deployment **
A new deployment create a new rollout. a new rollout create a new revision

Below are the command to check the status and history of a deployment

```
kubectl rollout status deployment/deploymentName :  status of the rollout
kubectl rollout history  deployment/deploymentName: will show the history with revision / changes-cause of a rollout
```
If you notice the `kubectl rollout history ..` command will show 2 column like this

```
REVISION  CHANGE-CAUSE
1         <none>
```
The reason column CHANGE-CAUSE show <none>, because we have not specified the cause during creation of the deployment. To do that follow the below command

```
kubectl create -f fileName.yaml --record
```

***Update***

k8s has several stratergy to deal with deployments  
- Rolling Update
- 
-

so when you deploy a new version a stratergy has to be applied so that k8s wil create a different replicaset and spawn up new pod with new version and in the same time it will remove the old version pod from old replicaset

you can also change the image version number from a deployment by using below command
```
kubectl set image deployment/deploymentName imageName=imageName:new.version
kubectl set image deployment myapp-deployment nginx=nginx:latest
```
But it will change on the fly and your deployment file will have the old configuration. so the good practice will be do the change on the manifest file and apply the update stratergy.

example
```

```

***Rollback***
If something went wrong during the deployment , you need to rollback your deployment . if you have folloed the k8s upgrade stratergy you could simply do that with below commands:



```
kubectl rollout undo deployment/deploymentName
To check: kubectl get replicaset
```

**Networking in k8s**
- each pod in k8s cluster get his own IP address
- All container/PODs can communicate to one another without NAT
- All nodes can communicate will all containers and vice-versa without NAT
- But while provision k8s , we no need to take this care as there are many products available to make use of i.e. cisco, vmware nsx, cilium, flanne

**service**
There are various type of service in k8s to make the traffice out or set communication with in pods
- NodePort
- ClusterIP
- LoadBalancer

***NodePort***
This is a machanism to map a port from k8s Node to a port from a pods.
- targetPort - will be the pod port
- port - are the service port
- NodePort: is the port from Node. it has to be valida range between 30000-32767 

```
apiVersion: v1
kind: Service
metadata:
  name: serviceName
spec:
  type: NodePort
  ports:
  - targetPort: portOfPod 
    port: servicePort
    nodePort: NodePortRangeBetween30000_32767
  selector:
   # labels from deployment
```


all the other example of service type are available on the service directory for your reference
