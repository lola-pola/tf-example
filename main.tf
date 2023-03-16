
# varaible "log_analytics_workspace_location"
resource "azurerm_resource_group" "rg" {
  name     = var.customer_name
  location = var.resource_group_location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.customer_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  address_space       = [var.address_space]
}


resource "azurerm_subnet" "subnet_address_core" {
  name                 = "core"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_core_prefix]

}

resource "azurerm_subnet" "subnet_address_ep" {
  name                 = "ep"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_ep_prefix]

}

resource "azurerm_subnet" "subnet_address_nat" {
  name                 = "nat"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_nat_prefix]

}

resource "azurerm_subnet" "subnet_address_public" {
  name                 = "public"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_public_prefix]

}

resource "azurerm_subnet" "subnet_address_site" {
  name                 = "site"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_site_prefix]

}

## this is AKS 
# resource "azurerm_container_registry" "acr" {
#   name                = "${var.customer_name}acr"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = var.resource_group_location
#   sku                 = "Premium"
#   admin_enabled       = false
#    retention_policy {
#     days    = 10
#     enabled = true
#   }
# }

# # add the role to the identity the kubernetes cluster was assigned
# resource "azurerm_role_assignment" "kubweb_to_acr" {
#   scope                = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
# }

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.customer_name
  dns_prefix          = var.customer_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = var.kubernetes_version
  automatic_channel_upgrade = var.automatic_channel_upgrade 
  http_application_routing_enabled = var.http_application_routing_enabled 
  sku_tier = var.sku_tier
  node_resource_group = "${var.node_resource_group}-${var.customer_name}"
  workload_identity_enabled = true

  
  # api_server_access_profile{
  #   enable_private_cluster = var.enable_private_cluster
  #   private_dns_zone_name = var.private_dns_zone_name
  #   private_dns_zone_resource_group_name = var.private_dns_zone_resource_group_name
  # }
  
  storage_profile {
    blob_driver_enabled = true
    disk_driver_enabled = true
    file_driver_enabled = true
    snapshot_controller_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_plugin_mode = "Overlay"
    ebpf_data_plane = "cilium"
    pod_cidr = "192.168.0.0/16"
    
  }
    

  default_node_pool {
    name                = "${var.customer_name}sys"
    min_count           = var.system_min_count
    vnet_subnet_id = azurerm_subnet.subnet_address_core.id
    max_count           = var.system_max_count
    vm_size             = var.vm_size
    enable_auto_scaling = var.enable_auto_scaling
    tags                = var.tags_map
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags_map
}






resource "azurerm_kubernetes_cluster_node_pool" "analyzer" {
  name = substr("${var.customer_name}analyzer", 0, min(12, length("${var.customer_name}analyzer")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_analyzer
  max_count             = var.max_count_analyzer
  vm_size               = var.vm_size_analyzer
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map_user
}

resource "azurerm_kubernetes_cluster_node_pool" "clickhouse" {
  name = substr("${var.customer_name}clickhouse", 0, min(12, length("${var.customer_name}clickhouse")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_clickhouse
  max_count             = var.max_count_clickhouse
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_clickhouse
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  
}

resource "azurerm_kubernetes_cluster_node_pool" "cs" {
  name = substr("${var.customer_name}cs", 0, min(12, length("${var.customer_name}cs")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_cs
  max_count             = var.max_count_cs
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_cs
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
}

resource "azurerm_kubernetes_cluster_node_pool" "ec" {
  name = substr("${var.customer_name}ec", 0, min(12, length("${var.customer_name}ec")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_ec
  max_count             = var.max_count_ec
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_ec
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
}

resource "azurerm_kubernetes_cluster_node_pool" "kafka" {
  name = substr("${var.customer_name}kafka", 0, min(12, length("${var.customer_name}kafka")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_kafka
  max_count             = var.max_count_kafka
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_kafka
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
}

resource "azurerm_kubernetes_cluster_node_pool" "management" {
  name = substr("${var.customer_name}management", 0, min(12, length("${var.customer_name}management")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_management
  max_count             = var.max_count_management
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_management
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
}


resource "azurerm_kubernetes_cluster_node_pool" "pg" {
  name = substr("${var.customer_name}pg", 0, min(12, length("${var.customer_name}pg")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_pg
  max_count             = var.max_count_pg
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_pg
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
}

resource "azurerm_kubernetes_cluster_node_pool" "site" {
  name = substr("${var.customer_name}site", 0, min(12, length("${var.customer_name}site")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_site
  max_count             = var.max_count_site
  vnet_subnet_id = azurerm_subnet.subnet_address_site.id
  vm_size               = var.vm_size_site
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
}



output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw

  sensitive = true
}


resource "azurerm_kubernetes_cluster" "aks-ep" {
  name                = "${var.customer_name}-ep"
  dns_prefix          = var.customer_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = var.kubernetes_version
  automatic_channel_upgrade = var.automatic_channel_upgrade 
  http_application_routing_enabled = var.http_application_routing_enabled 
  sku_tier = var.sku_tier
  node_resource_group = "${var.node_resource_group}-${var.customer_name}"
  
  # api_server_access_profile{
  #   enable_private_cluster = var.enable_private_cluster
  #   private_dns_zone_name = var.private_dns_zone_name
  #   private_dns_zone_resource_group_name = var.private_dns_zone_resource_group_name
  # }
  
  storage_profile {
    blob_driver_enabled = true
    disk_driver_enabled = true
    file_driver_enabled = true
    snapshot_controller_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_plugin_mode = "Overlay"
    ebpf_data_plane = "cilium"
    pod_cidr = "192.168.0.0/16"
    
  }
    

  default_node_pool {
    name                = "${var.customer_name}sys"
    min_count           = var.system_min_count
    vnet_subnet_id = azurerm_subnet.subnet_address_ep.id
    max_count           = var.system_max_count
    vm_size             = var.vm_size
    enable_auto_scaling = var.enable_auto_scaling
    tags                = var.tags_map
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags_map
}



resource "azurerm_kubernetes_cluster_node_pool" "aks-ep" {
  name = substr("${var.customer_name}ep", 0, min(12, length("${var.customer_name}ep")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-ep.id
  min_count             = var.min_count_site
  max_count             = var.max_count_site
  vnet_subnet_id = azurerm_subnet.subnet_address_ep.id
  vm_size               = var.vm_size_ep
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
}



output "client_certificate_aksep" {
  value     = azurerm_kubernetes_cluster.aks-ep.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config_aks_ep" {
  value = azurerm_kubernetes_cluster.aks-ep.kube_config_raw

  sensitive = true
}