
variable "customer_name" {
  type    = string
  default = "gltest"
}

variable "address_space" {
  type    = string
  default = "11.0.0.0/22"
}

variable "subnet_address_core_prefix" {
  type    = string
  default = "11.0.0.0/24"
}

variable "subnet_address_ep_prefix" {
  type    = string
  default = "11.0.1.0/25"
}

variable "subnet_address_nat_prefix" {
  type    = string
  default = "11.0.1.128/25"
}

variable "subnet_address_public_prefix" {
  type    = string
  default = "11.0.2.0/27"
}

variable "subnet_address_site_prefix" {
  type    = string
  default = "11.0.2.32/27"
}




variable "resource_group_location" {
  default     = "West Europe"
  type = string
  description = "Location of the resource group."
}

variable "kubernetes_version" {
  default = "1.25.4"
  type = string
  # default     = "1.24.6"
  description = "what version of kubernetes to use"
}

variable "automatic_channel_upgrade" {
  default = "stable"
  type = string
  description = "how aks will be upgraded "
}

variable "monitor_metrics" {
  default = true
  description = "is monitoring enabled"
}

variable "system_min_count" {
  default = 1
}

variable "system_max_count" {
  default = 5
}

variable "vm_size" {
  default = "Standard_D2_v2"
}


# tags map
variable "tags_map" {
  type = map(string)
  default = {
    env          = "Production",
    upgrade      = "test",
    version      = "1.25.4",
    last_version = "1.19.07"
    ManagedBy    = "Terraform"
  }
}

variable "min_count_user" {
  default = 1
}

variable "max_count_user" {
  default = 1
}

variable "vm_size_user" {
  default = "Standard_D2_v2"
  type = string
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "enable_auto_scaling" {
  default = true
}

variable "sku_tier" {
  default = "Standard"
}
# tags map
variable "tags_map_user" {
  type = map(string)
  default = {
    env          = "Production",
    nodes = "node example",
    upgrade      = "test",
    version      = "1.25.4",
    last_version = "1.19.07"
    ManagedBy    = "Terraform"
  }
}



