provider "azurerm" {
  features {}
}

data "azurerm_key_vault_secret" "vm_credentials" {
  name         = "vm-credentials"  # Name of the secret in Azure Key Vault
  key_vault_id = "/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.KeyVault/vaults/<key_vault_name>"
}

resource "azurerm_template_deployment" "example" {
  name                = "example-deployment"
  resource_group_name = azurerm_resource_group.example.name
  deployment_mode     = "Incremental"
  template_content = <<TEMPLATE
    # Your ARM template content here
  TEMPLATE

  parameters = {
    adminUsername = data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]
    adminPassword = data.azurerm_key_vault_secret.vm_credentials.value["adminPassword"]
  }
}
