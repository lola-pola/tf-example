terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
    }
  }
}

provider "azurerm" {
  features {}
  # subscription_id = "613ad620-f6ee-4055-bd0a-68a93656bee3"

}