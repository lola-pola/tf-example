
# varaible "log_analytics_workspace_location"
resource "azurerm_resource_group" "rg" {
  name     = var.customer_name
  location = var.resource_group_location
}

resource "azurerm_resource_group" "rg-ep" {
  name     = "${var.node_resource_group}-${var.customer_name}-ep"
  location = var.resource_group_location
}




# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  depends_on = [azurerm_resource_group.rg]
  name                = "${var.customer_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  address_space       = [var.address_space]
}


resource "azurerm_subnet" "subnet_address_core" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "core"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_core_prefix]

}

resource "azurerm_subnet" "subnet_address_ep" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "ep"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_ep_prefix]

}

resource "azurerm_subnet" "subnet_address_nat" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "nat"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_nat_prefix]

}

resource "azurerm_subnet" "subnet_address_public" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "public"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_public_prefix]

}

resource "azurerm_subnet" "subnet_address_site" {
  depends_on = [azurerm_virtual_network.vnet]
  name                 = "site"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_site_prefix]

}

##security groups
resource "azurerm_application_security_group" "sec_address_site" {
  depends_on = [azurerm_resource_group.rg-ep]
  name                = "site"
  resource_group_name = "${var.node_resource_group}-${var.customer_name}-ep"
  location            = var.resource_group_location
}
resource "azurerm_application_security_group" "sec_address_public" {
  depends_on = [azurerm_resource_group.rg-ep]
  name                = "public"
  resource_group_name = "${var.node_resource_group}-${var.customer_name}-ep"
  location            = var.resource_group_location
}

# Create NSG rules
resource "azurerm_network_security_group" "nsg-1" {
  depends_on = [azurerm_resource_group.rg-ep]
  name                = "nsg-1"
  location = "${var.node_resource_group}-${var.customer_name}-ep"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_network_security_group" "nsg-2" {
  depends_on = [azurerm_resource_group.rg-ep]
  name                = "nsg-2"
  location = "${var.node_resource_group}-${var.customer_name}-ep"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsg-test-role-1" {
  depends_on = [azurerm_resource_group.rg-ep]
  name                        = "nsg-test-role-1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  # source_address_prefix       = "*"
  # destination_address_prefix  = "*"
  source_application_security_group_ids = [azurerm_application_security_group.sec_address_site.id]
  destination_application_security_group_ids = [azurerm_application_security_group.sec_address_public.id]
  resource_group_name = "${var.node_resource_group}-${var.customer_name}-ep"
  network_security_group_name = azurerm_network_security_group.nsg-1.name
}


resource "azurerm_network_security_rule" "nsg-test-role-2" {
  depends_on = [azurerm_resource_group.rg-ep]
  name                        = "nsg-test-role-2"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  # source_address_prefix       = "*"
  # destination_address_prefix  = "*"
  source_application_security_group_ids = [azurerm_application_security_group.sec_address_site.id]
  destination_application_security_group_ids = [azurerm_application_security_group.sec_address_public.id]
  resource_group_name = "${var.node_resource_group}-${var.customer_name}-ep"
  network_security_group_name = azurerm_network_security_group.nsg-2.name
}




resource "azurerm_kubernetes_cluster" "aks" {
  depends_on = [azurerm_virtual_network.vnet]
  name                = var.customer_name
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
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}analyzer", 0, min(12, length("${var.customer_name}analyzer")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_analyzer
  max_count             = var.max_count_analyzer
  vm_size               = var.vm_size_analyzer
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map_user
  node_labels = {"NodeType" = "analyzer"}
}

resource "azurerm_kubernetes_cluster_node_pool" "clickhouse" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}clickhouse", 0, min(12, length("${var.customer_name}clickhouse")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_clickhouse
  max_count             = var.max_count_clickhouse
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_clickhouse
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "clickhouse"}
  
}

resource "azurerm_kubernetes_cluster_node_pool" "cs" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}cs", 0, min(12, length("${var.customer_name}cs")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_cs
  max_count             = var.max_count_cs
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_cs
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "analyzer"}
}

resource "azurerm_kubernetes_cluster_node_pool" "ec" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}ec", 0, min(12, length("${var.customer_name}ec")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_ec
  max_count             = var.max_count_ec
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_ec
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "ec"}
}

resource "azurerm_kubernetes_cluster_node_pool" "kafka" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}kafka", 0, min(12, length("${var.customer_name}kafka")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_kafka
  max_count             = var.max_count_kafka
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_kafka
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "kafka"}
}

resource "azurerm_kubernetes_cluster_node_pool" "management" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}management", 0, min(12, length("${var.customer_name}management")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_management
  max_count             = var.max_count_management
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_management
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "kafka"}
}


resource "azurerm_kubernetes_cluster_node_pool" "pg" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}pg", 0, min(12, length("${var.customer_name}pg")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_pg
  max_count             = var.max_count_pg
  vnet_subnet_id       = azurerm_subnet.subnet_address_core.id
  vm_size               = var.vm_size_pg
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "pg"}
}

resource "azurerm_kubernetes_cluster_node_pool" "site" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name = substr("${var.customer_name}site", 0, min(12, length("${var.customer_name}site")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  min_count             = var.min_count_site
  max_count             = var.max_count_site
  vnet_subnet_id = azurerm_subnet.subnet_address_site.id
  vm_size               = var.vm_size_site
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "site"}

}



output "client_certificate" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  value = azurerm_kubernetes_cluster.aks.kube_config_raw

  sensitive = true
}


resource "azurerm_kubernetes_cluster" "aks-ep" {
  depends_on = [azurerm_virtual_network.vnet]
  name                = "${var.customer_name}-ep"
  dns_prefix          = var.customer_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = var.kubernetes_version
  automatic_channel_upgrade = var.automatic_channel_upgrade 
  http_application_routing_enabled = var.http_application_routing_enabled 
  sku_tier = var.sku_tier
  node_resource_group = "${var.node_resource_group}-${var.customer_name}-ep"
  
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



resource "azurerm_kubernetes_cluster_node_pool" "aks-ep-nodes" {
  depends_on = [azurerm_kubernetes_cluster.aks-ep]
  name = substr("${var.customer_name}gateway", 0, min(12, length("${var.customer_name}gateway")))
  mode                  = "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-ep.id
  min_count             = var.min_count_site
  max_count             = var.max_count_site
  vnet_subnet_id = azurerm_subnet.subnet_address_ep.id
  vm_size               = var.vm_size_ep
  enable_auto_scaling   = var.enable_auto_scaling
  tags                  = var.tags_map
  node_labels = {"NodeType" = "gateway"}
}



output "client_certificate_aks_ep" {
  depends_on = [azurerm_kubernetes_cluster.aks-ep]
  value     = azurerm_kubernetes_cluster.aks-ep.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config_aks_ep" {
  depends_on = [azurerm_kubernetes_cluster.aks-ep]
  value = azurerm_kubernetes_cluster.aks-ep.kube_config_raw

  sensitive = true
}