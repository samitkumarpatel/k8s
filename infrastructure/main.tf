provider "azurerm" {
  version = "=2.0.0"
  features {}
}

terraform {
  required_version = ">= 0.12.0"
}

resource "azurerm_resource_group" "k8s" {
    name     = var.resource_group_name
    location = var.location
}


resource "azurerm_container_registry" "acr" {
  name                     = var.acr_name
  resource_group_name      = azurerm_resource_group.k8s.name
  location                 = azurerm_resource_group.k8s.location
  sku                      = "Standard"
  admin_enabled            = true
  
  tags = {
    Environment = "Development"
  }
}

data "azurerm_client_config" "current" { }

resource "azurerm_kubernetes_cluster" "k8s" {
    name                = var.cluster_name
    location            = azurerm_resource_group.k8s.location
    resource_group_name = azurerm_resource_group.k8s.name
    dns_prefix          = var.dns_prefix
    node_resource_group = "${var.cluster_name}_nodepool01"
    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = file(var.ssh_public_key)
        }
    }

    service_principal {
        client_id     = data.azurerm_client_config.current.client_id
        client_secret = var.ARM_CLIENT_SECRET
    }

    default_node_pool {
        name            = var.node_pool_name
        node_count      = var.agent_count
        vm_size         = "Standard_DS1_v2"
        enable_node_public_ip = false
    }

    tags = {
        Environment = "Development"
    }
}

# resource "azurerm_kubernetes_cluster_node_pool" "example" {
#     name                  = "aks001-internal"
#     kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
#     vm_size               = "Standard_DS1_v2"
#     node_count            = var.agent_count

#     tags = {
#         Environment = "Production"
#     }
# }

# resource "azurerm_public_ip" "example" {
#  name                = var.pip_name
#  resource_group_name = azurerm_resource_group.k8s.name
#  location            = azurerm_resource_group.k8s.location
#  allocation_method   = "Static"
#  domain_name_label   = "k8s001dns"
#  tags = {
#    Environment = "Development"
#  }
# }
