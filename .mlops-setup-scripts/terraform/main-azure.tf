// Copied from https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=terraform#code-try-3
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tfstate" {
  // Azure resource names can be at most 24 characters
  name     = substr("yangmlopsproject", 0, 24)
  location = "East US"
}

resource "azurerm_storage_account" "tfstate" {
  // Azure resource names can be at most 24 characters
  name                     = substr("yangmlopsproject", 0, 24)
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "cicd-setup-tfstate" {
  name                  = "cicd-setup-tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
}

output "ARM_ACCESS_KEY" {
  value     = azurerm_storage_account.tfstate.primary_access_key
  sensitive = true
}
