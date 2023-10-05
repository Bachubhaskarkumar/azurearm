output "vm_credentials_value" {
  value = data.azurerm_key_vault_secret.vm_credentials.value
}
