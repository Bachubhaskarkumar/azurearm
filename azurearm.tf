data "azurerm_client_config" "current" {}
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "myResourceGroup"
  location = "East US"
}

# Create an Azure Key Vault to store secrets
resource "azurerm_key_vault" "example" {
  name                       = "mykeyvault"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  enabled_for_template_deployment = true
  enabled_for_deployment       = true
  enabled_for_visual_studio    = true
}

# Store Azure Service Principal credentials in Key Vault
resource "azurerm_key_vault_secret" "sp_credentials" {
  name         = "sp-credentials"
  value        = "azurecredentials"  # Store this secret in Jenkins or use another secure method
  key_vault_id = azurerm_key_vault.example.id
}

# Define your virtual machine configuration using ARM templates
resource "azurerm_template_deployment" "example" {
  name                = "example-deployment"
  resource_group_name = azurerm_resource_group.example.name
  template_content    = file("arm-template.json")  # Path to your ARM template file
  parameter {
    name  = "adminUsername"
    value = "adminuser"
  }
  parameter {
    name  = "adminPassword"
    value = "P@ssw0rd123!"  # Store this secret in Jenkins or use another secure method
  }
}

# Output the public IP address of the VM
output "public_ip" {
  value = azurerm_template_deployment.example.outputs["adminUsername"]
}
