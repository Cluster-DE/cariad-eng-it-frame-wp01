locals {
  vm_name            = "cl${var.client_number}"
  vm_resource_prefix = "vm"
  vm_resource_name   = "${local.vm_resource_prefix}${var.resource_name_specifier}${local.vm_name}"

  nic_name            = local.vm_name
  nic_resource_prefix = "nic"
  nic_resource_name   = "${local.nic_resource_prefix}${var.resource_name_specifier}${local.nic_name}"

  pip_name            = local.vm_name
  pip_resource_prefix = "pip"
  pip_resource_name   = "${local.pip_resource_prefix}${var.resource_name_specifier}${local.pip_name}"

  fileshare_ext_name            = "mount_fileshare"
  fileshare_ext_resource_prefix = "ext"
  fileshare_ext_resource_name   = "${local.fileshare_ext_resource_prefix}${var.resource_name_specifier}${local.fileshare_ext_name}"

  extension_resource_name   = "customScript"
}

# Network interface for the VM
resource "azurerm_network_interface" "nic" {
  name                = local.nic_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name_us

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = local.pip_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name_us
  allocation_method   = "Static"
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = local.vm_resource_name
  resource_group_name = var.resource_group_name_us
  location            = var.location
  size                = "Standard_D2_v4" # 2 vCPUs, 8 GiB memory
  admin_username      = "adminuser"
  admin_password      = azurerm_key_vault_secret.admin_password_secret.value
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-avd"
    version   = "latest"
  }
}

# Generates a random password used for the VMs. 
# It should not contain special characters, as it makes it harder to pass them as arguments to scripts.
resource "random_password" "admin_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "azurerm_key_vault_secret" "admin_password_secret" {
  name         = "${local.vm_name}AdminPassword"
  value        = random_password.admin_password.result
  key_vault_id = var.key_vault_id
}

# This creates the Custom Script Extension to copy the script to the VM
resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = local.extension_resource_name
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  # Downloads blobs under C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.18\Downloads folder. 
  # The version number may vary and needs to be adapted. There is no proper way to get the exact version of type_handler_version. 
  settings = <<SETTINGS
    {
      "fileUris": [
        "https://${var.scripts_storage_account_name}.blob.core.windows.net/${var.scripts_container_name}/${var.bootstrapping_script_name}",
        "https://${var.scripts_storage_account_name}.blob.core.windows.net/${var.scripts_container_name}/${var.create_service_script_name}"
      ]
    }
  SETTINGS

  # This script will be executed on the VM. Is securely transmitted using protected settings.
  # This opens a Administrative PowerShell session as a system account, downloads the bootstrapping script and the service creation script, and executes them.
  protected_settings = jsonencode({
  commandToExecute = "powershell.exe -ExecutionPolicy Unrestricted -File ${var.create_service_script_name} -storageAccountName \"${var.storage_account_name}\" -storageAccountKey \"${var.storage_account_key}\" -fileshareName \"${var.fileshare_name}\" -storageAccountConnectionString \"${var.storage_account_connection_string}\" -DownloadedFile \"${var.bootstrapping_script_name}\" -DestinationFolder \"C:\\scripts\" -Username \"adminuser\" -Password \"${azurerm_key_vault_secret.admin_password_secret.value}\"&& powershell.exe Write-Host \"${var.create_service_md5}${var.bootstrapping_md5}\""
  })
}