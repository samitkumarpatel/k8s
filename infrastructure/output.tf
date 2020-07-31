output "kube_config" {
    value = azurerm_kubernetes_cluster.k8s.kube_config_raw
}

output "host" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.host
}

# output "public_ip_address" {
#    value = azurerm_public_ip.example.ip_address
# }

# output "public_ip_fqdn" {
#     value = azurerm_public_ip.example.fqdn
# }

output "local_config" {
   value = ""
}