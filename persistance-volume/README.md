## aks
An Azure disk can only be mounted with Access mode type ReadWriteOnce, which makes it available to one node in AKS. If you need to share a persistent volume across multiple nodes, use Azure Files.
**azure disc**
- [azure disk -dynamic](https://docs.microsoft.com/en-us/azure/aks/azure-disks-dynamic-pv)
- [azure disk -static](https://docs.microsoft.com/en-us/azure/aks/azure-disk-volume)

**azure file**
- [azure file - dynamic](https://docs.microsoft.com/en-us/azure/aks/azure-files-dynamic-pv)
- [azure file - static ](https://docs.microsoft.com/en-us/azure/aks/azure-files-volume)