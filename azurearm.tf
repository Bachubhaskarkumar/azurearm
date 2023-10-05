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

  template_body = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "variables": {
    "location": "[resourceGroup().location]",
    "nicName": "[concat(${data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]}, '-nic')]",
    "osDiskName": "[concat(${data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]}, '-osdisk')]",
    "vnetName": "[concat(${data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]}, '-vnet')]",
    "subnetName": "[concat(${data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]}, '-subnet')]",
    "publicIPAddressName": "[concat(${data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]}, '-ip')]",
    "networkSecurityGroupName": "[concat(${data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]}, '-nsg')]",
    "diagnosticsStorageAccountName": "[concat('diag', uniquestring(resourceGroup().id))]"
  },
  "resources": [
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "apiVersion": "2020-11-01",
      "name": "[variables('publicIPAddressName')]",
      "location": "[variables('location')]",
      "properties": {
        "publicIPAllocationMethod": "Dynamic"
      }
    },
    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2021-02-01",
      "name": "[variables('networkSecurityGroupName')]",
      "location": "[variables('location')]",
      "properties": {
        "securityRules": []
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2021-02-01",
      "name": "[variables('vnetName')]",
      "location": "[variables('location')]",
      "properties": {
        "addressSpace": {
          "addressPrefixes": ["10.0.0.0/16"]
        }
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks/subnets",
      "apiVersion": "2021-02-01",
      "name": "[concat(variables('vnetName'), '/default')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
      ],
      "properties": {
        "addressPrefix": "10.0.0.0/24",
        "networkSecurityGroup": {
          "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('networkSecurityGroupName'))]"
        }
      }
    },
    {
      "type": "Microsoft.Network/networkInterfaces",
      "apiVersion": "2021-02-01",
      "name": "[variables('nicName')]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPAddressName'))]",
        "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('vnetName'), 'default')]"
      ],
      "properties": {
        "ipConfigurations": [
          {
            "name": "ipconfig",
            "properties": {
              "privateIPAllocationMethod": "Dynamic",
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPAddressName'))]"
              },
              "subnet": {
                "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('vnetName'), 'default')]"
              }
            }
          }
        ]
      }
    },
    {
      "type": "Microsoft.Compute/virtualMachines",
      "apiVersion": "2022-03-01",
      "name": "[data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]",
        "[resourceId('Microsoft.Compute/disks', variables('osDiskName'))]"
      ],
      "properties": {
        "hardwareProfile": {
          "vmSize": "Standard_DS2_v2"
        },
        "osProfile": {
          "computerName": "[data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]]",
          "adminUsername": "[data.azurerm_key_vault_secret.vm_credentials.value["adminUsername"]]",
          "adminPassword": "[data.azurerm_key_vault_secret.vm_credentials.value["adminPassword"]]"
        },
        "storageProfile": {
          "imageReference": {
            "publisher": "Canonical",
            "offer": "UbuntuServer",
            "sku": "18.04-LTS",
            "version": "latest"
          },
          "osDisk": {
            "name": "[variables('osDiskName')]",
            "createOption": "FromImage",
            "caching": "ReadWrite"
          }
        },
        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"
            }
          ]
        }
      }
    }
  ],
  "outputs": {}
}
TEMPLATE
}
