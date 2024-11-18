Your AWS infrastructure diagram for a 3-node Kubernetes cluster on Ubuntu EC2 instances sounds like a solid setup. Here’s a brief overview of the necessary components and the ports you need to open for both control-plane and worker nodes:

Infrastructure Overview:

Control-Plane Node (Master Node):
    Instance Type: t2.medium (or higher for production)
    Components: kube-apiserver, kube-controller-manager, kube-scheduler, etcd

Worker Nodes:
    Instance Type: t2.micro (or higher for production)
    Components: kubelet, kube-proxy, container runtime (e.g., Docker, containerd)

Networking Requirements:
    Control-Plane Node:
        Ingress Ports:
            6443: Kubernetes API server
            2379-2380: etcd server client API
            10250: kubelet API
            10251: kube-scheduler
            10252: kube-controller-manager
        Egress Ports:
            0-65535: Allow all outbound traffic for communication with worker nodes and external services
    Worker Nodes:
        Ingress Ports:
            10250: kubelet API
            30000-32767: NodePort Services
    Egress Ports:
            0-65535: Allow all outbound traffic for communication with control-plane and external services

Additional Considerations:
External kubectl Access: Ensure that the security group associated with your control-plane node allows inbound traffic on port 6443 from your external IP address or range.
Kubernetes Services: Ensure that your VPC and subnets are properly configured to allow internal communication between nodes and services.

Diagram Example:

    VPC: Encompassing all nodes
    Subnets: Separate subnets for control-plane and worker nodes (optional but recommended for isolation)
    Security Groups: Clearly showing the ingress and egress rules for each node type
    Instances: Labeled with their roles (Control-Plane, Worker Node 1, Worker Node 2)
    This setup ensures that your external kubectl can communicate with the control-plane API server, and all types of Kubernetes services (ClusterIP, NodePort, LoadBalancer) will function correctly.


To set up an Application Load Balancer (ALB) for your Kubernetes cluster, you typically attach it to the worker nodes rather than the control-plane node. Here’s how it works:

Load Balancer Configuration:

Attach to Worker Nodes:

The ALB will distribute incoming traffic to the worker nodes where your application pods are running.
This setup ensures that the load balancer forwards traffic to the appropriate NodePort services on the worker nodes.

NodePort Services:
When you create a NodePort service in Kubernetes, it opens a specific port on all worker nodes.
The ALB can then route traffic to these NodePort services, which in turn forward the traffic to the appropriate pods.

Networking Requirements:
    Control-Plane Node:
        Ingress Ports:
            6443: Kubernetes API server
            2379-2380: etcd server client API
            10250: kubelet API
            10251: kube-scheduler
            10252: kube-controller-manager
        Egress Ports:
            0-65535: Allow all outbound traffic for communication with worker nodes and external services
    Worker Nodes:
        Ingress Ports:
            10250: kubelet API
            30000-32767: NodePort Services
    Egress Ports:
         all outbound traffic for communication with control-plane and external services

Diagram Example:

VPC: Encompassing all nodes
Public Subnet: For the control-plane node
Private Subnet: For the worker nodes
Security Groups: Clearly showing the ingress and egress rules for each node type
Instances: Labeled with their roles (Control-Plane, Worker Node 1, Worker Node 2)
Application Load Balancer: Attached to the worker nodes, routing traffic to NodePort services
Additional Considerations:
External Access: Ensure that the ALB security group allows inbound traffic on the ports used by your NodePort services.
Health Checks: Configure health checks on the ALB to monitor the health of your application pods.
This setup ensures that your ALB can effectively distribute traffic to your application running on the worker nodes, while keeping the control-plane node secure and focused on managing the cluster.