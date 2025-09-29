# Kubernetes Components

## Control Plane Components

### API Server (kube-apiserver)
- Front-end interface for the Kubernetes control plane
- Exposes the Kubernetes REST API
- Validates and processes all API requests
- Only component that directly communicates with etcd
- Handles authentication, authorization, and admission control

### etcd
- Distributed, consistent key-value store
- Stores all cluster configuration and state data
- Acts as the "source of truth" for the cluster
- Highly available and fault-tolerant
- Backs up cluster state and configuration

### Scheduler (kube-scheduler)
- Watches for newly created pods without assigned nodes
- Selects optimal nodes for pod placement
- Considers resource requirements, constraints, and policies
- Evaluates factors like CPU/memory availability, affinity rules, and data locality
- Makes scheduling decisions based on multiple criteria

### Controller Manager (kube-controller-manager)
- Runs various controller processes that maintain desired cluster state
- **Node Controller**: Monitors node health and handles node failures
- **Replication Controller**: Ensures correct number of pod replicas are running
- **Endpoint Controller**: Manages service-to-pod connections
- **Service Account & Token Controllers**: Handle authentication for namespaces
- **Namespace Controller**: Manages namespace lifecycle

### Cloud Controller Manager (cloud-controller-manager)
- Integrates Kubernetes with cloud provider APIs
- Manages cloud-specific resources (load balancers, storage, networking)
- Handles cloud provider-specific functionality
- Allows cluster to interact with underlying cloud services

## Node Components

### Kubelet
- Primary node agent running on each worker node
- Ensures containers are running in pods as specified
- Communicates with API server to report node status
- Manages pod lifecycle (start, stop, restart containers)
- Monitors pod health and resource usage
- Pulls container images and manages container runtime

### Kube-proxy
- Network proxy running on each node
- Maintains network rules for pod-to-pod communication
- Implements Kubernetes Service concepts (ClusterIP, NodePort, LoadBalancer)
- Handles load balancing and service discovery
- Manages iptables rules or IPVS for traffic routing

### Container Runtime
- Software responsible for running containers
- Common runtimes: Docker, containerd, CRI-O
- Manages container lifecycle (create, start, stop, delete)
- Handles container isolation and resource limits
- Pulls and manages container images

## Additional Components

### Add-ons
- **DNS**: CoreDNS for service discovery
- **Dashboard**: Web UI for cluster management
- **Ingress Controller**: Manages external access to services
- **CNI Plugins**: Container network interface plugins
- **Storage Plugins**: Persistent volume management