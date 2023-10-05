data "azurerm_client_config" "current" {}
provider "azurerm" {
version = "~> 3.75.0"
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "mybhaskar"
  location = "East US"
}

# Create an Azure Key Vault to store secrets
resource "azurerm_key_vault" "example" {
  name                       = "mybhaskar"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  enabled_for_template_deployment = true
  enabled_for_deployment       = true
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "Recover",
      "Purge"
    ]
  }
}

# Store Azure Service Principal credentials in Key Vault
resource "azurerm_key_vault_secret" "sp_credentials" {
  name         = "azure-credentials"
  value        = "azurecredential"  # Store this secret in Jenkins or use another secure method
  key_vault_id = azurerm_key_vault.example.id
}

# Define your virtual machine configuration using ARM templates
resource "azurerm_template_deployment" "example" {
  name                = "bhaskar-deployment"
  resource_group_name = azurerm_resource_group.example.name
  #template_content    = file("arm-template.json")  # Path to your ARM template file
  deployment_mode     = "Incremental"
  parameters = {
    adminUsername = "adminuser"
    adminPassword = "P@ssw0rd123!"  # Store this secret in Jenkins or use another secure method
    subnetId = "/subscriptions/****/resourceGroups/mybhaskar/providers/Microsoft.Network/virtualNetworks/myNIC/subnets/mySubnet"
  }
   template_body       = <<DEPLOY
  #template_body       = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUsername": {
      "type": "string",
      "metadata": {
        "description": "Administrator username for the VM."
      }
    },
    "adminPassword": {
      "type": "securestring",
      "metadata": {
        "description": "Administrator password for the VM."
      }
    }
    "subnetId": {
      "type": "string"
     }
  },
  "resources": [
    {
      "type": "Microsoft.Compute/virtualMachines",
      "apiVersion": "2021-03-01",
      "name": "myVM",
      "location": "[resourceGroup().location]",
      "dependsOn": [],
      "properties": {
        "hardwareProfile": {
          "vmSize": "Standard_DS2_v2"
        },
        "storageProfile": {
          "osDisk": {
            "createOption": "FromImage",
            "managedDisk": {
              "storageAccountType": "Standard_LRS"
            }
          },
          "imageReference": {
            "publisher": "Canonical",
            "offer": "UbuntuServer",
            "sku": "18.04-LTS",
            "version": "latest"
          }
        },
        "osProfile": {
          "computerName": "myVM",
          "adminUsername": "[parameters('adminUsername')]",
          "adminPassword": "[parameters('adminPassword')]"
        },
        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces', 'myNIC')]"
            }
          ]
        }
      }
    },
    {
      "type": "Microsoft.Network/networkInterfaces",
      "apiVersion": "2021-02-01",
      "name": "myNIC",
      "location": "[resourceGroup().location]",
      "dependsOn": [],
      "properties": {
        "ipConfigurations": [
          {
            "name": "myIPConfig",
            "properties": {
              "subnet": {
                "id": "[variables('subnetId')]"
              }
            }
          }
        ]
      }
    }
  ],
  "outputs": {
    "adminUsername": {
      "type": "string",
      "value": "[parameters('adminUsername')]"
    }
  }
}
DEPLOY
#TEMPLATE
}
# Output the public IP address of the VM
output "public_ip" {
  value = azurerm_template_deployment.example.outputs["adminUsername"]
}
