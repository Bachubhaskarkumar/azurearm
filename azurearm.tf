terraform {
  required_version = ">=1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}
resource "azurerm_resource_group" "bhaskar-rg" {
  name     = "bhaskar-rg"
  location = "EAST US"
}
resource "azurerm_resource_group_template_deployment" "deploy" {
  name                = "deploy"
  resource_group_name = azurerm_resource_group.bhaskar-rg.name
  template_body = file("${path.module}/deploymentTemplate.json")

   template_content = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "functions": [],
    "variables": {},
    "resources": [
        {
            "name": "vnet",
            "type": "Microsoft.Network/virtualNetworks",
            "apiVersion": "2020-11-01",
            "location": "EAST US",
            "properties": {
                "addressSpace": {
                    "addressPrefixes": [
                        "10.0.0.0/16"
                    ]
                },
                "subnets": [
                    {
                        "name": "SubnetA",
                        "properties": {
                            "addressPrefix": "10.0.0.0/24",
                            "networkSecurityGroup": {
                                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', 'nsg')]"
                              }
                        }
                    }
                ]
            }
        },
        {
            "name": "public-ip",
            "type": "Microsoft.Network/publicIPAddresses",
            "apiVersion": "2020-11-01",
            "location": "EAST US",
            "properties": {
                "publicIPAllocationMethod": "Dynamic"
                }
            },
            {
                "name": "nic",
                "type": "Microsoft.Network/networkInterfaces",
                "apiVersion": "2020-11-01",
                "location": "EAST US",            
                "properties": {
                    "ipConfigurations": [
                        {
                            "name": "ipConfig",
                            "properties": {
                                "privateIPAllocationMethod": "Dynamic",
                                "publicIPAddress": {
                                    "id": "[resourceId('Microsoft.Network/publicIPAddresses', 'public-ip')]"
                                  },
                                "subnet": {
                                    "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet', 'SubnetA')]"
                                }
                            }
                        }
                    ]
                },
                "dependsOn": [
                    "[resourceId('Microsoft.Network/publicIPAddresses', 'public-ip')]",
                    "[resourceId('Microsoft.Network/virtualNetworks', 'vnet')]"
                ]
            }
        },        
        {
            "name": "harsha1512",
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2021-04-01",
            "location": "[resourceGroup().location]",
            "sku": {
                "name": "Standard_LRS"
            },
            "kind": "StorageV2"
        },
        {
            "name": "nsg",
            "type": "Microsoft.Network/networkSecurityGroups",
            "apiVersion": "2020-11-01",
            "location": "[resourceGroup().location]",
            "properties": {
                "securityRules": [
                    {
                        "name": "Allow-RDP",
                        "properties": {
                            "description": "description",
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "3389",
                            "sourceAddressPrefix": "*",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 100,
                            "direction": "Inbound"
                        }
                    }
                ]
            }
        },
        {
            "name": "vm",
            "type": "Microsoft.Compute/virtualMachines",
            "apiVersion": "2021-03-01",
            "location": "[resourceGroup().location]",
            "dependsOn": [
                "[resourceId('Microsoft.Storage/storageAccounts', toLower('harsha1512'))]"
            ],
            "properties": {
                "hardwareProfile": {
                    "vmSize": "Standard_D2s_v3"
                },
                "osProfile": {
                    "computerName": "vm",
                    "adminUsername": "demousr",
                    "adminPassword": "[parameters('secret')]"
                },
                "storageProfile": {
                    "imageReference": {
                        "publisher": "MicrosoftWindowsServer",
                        "offer": "WindowsServer",
                        "sku": "2019-Datacenter",
                        "version": "latest"
                    },
                    "osDisk": {
                        "name": "windowsVM1OSDisk",
                        "caching": "ReadWrite",
                        "createOption": "FromImage"
                    },
                    "dataDisks": [
                        {
                            "name":"vm-data-disk",
                            "diskSizeGB":16,
                            "createOption": "Empty",
                            "lun":0
                        }
                    ]
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', 'nic')]"
                        }
                    ]
                },
                "diagnosticsProfile": {
                    "bootDiagnostics": {
                        "enabled": true,
                        "storageUri": "[reference(resourceId('Microsoft.Storage/storageAccounts/', toLower('harsha1512'))).primaryEndpoints.blob]"
                    }
                }
            }
        }
    },
    "outputs": {},
}
TEMPLATE

  # these key-value pairs are passed into the ARM Template's `parameters` block
  
  parameters_content = jsondecode({
    "secret" = {
        value = azurerm_key_vault_secret.secret.value
        }
  })

  deployment_mode = "Incremental"
}
