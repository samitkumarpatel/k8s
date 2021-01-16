## aks
An Azure disk can only be mounted with Access mode type ReadWriteOnce, which makes it available to one node in AKS. If you need to share a persistent volume across multiple nodes, use Azure Files.
- [azure disk -dynamic](https://docs.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv)
- [azure disk -static](https://docs.microsoft.com/en-us/azure/aks/azure-disk-volume)