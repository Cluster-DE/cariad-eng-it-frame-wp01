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

  bootstrapping_md5 = filemd5("${path.module}/../../scripts/bootstrapping.ps1")
  create_service_md5 = filemd5("${path.module}/../../scripts/create_service.ps1")

  bootstrapping_md5_prefix = substr(local.bootstrapping_md5, 0, 2)
  create_service_md5_prefix = substr(local.create_service_md5, 0, 2)
  extension_resource_name   = "customScript_${local.bootstrapping_md5_prefix}${local.create_service_md5_prefix}"
}

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
  size                = "Standard_D2_v4" #optimized for storage
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

resource "random_password" "admin_password" {
  length  = 14
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
  name                 = "extension_resource_name"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
      "fileUris": [
        "https://${var.storage_account_name}.blob.core.windows.net/${var.scripts_container_name}/${var.bootstrapping_script_name}",
        "https://${var.storage_account_name}.blob.core.windows.net/${var.scripts_container_name}/${var.create_service_script_name}"
      ]
    }
  SETTINGS


  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -ExecutionPolicy Unrestricted -File ${var.create_service_script_name} -storageAccountName \"${var.storage_account_name}\" -storageAccountKey \"${var.storage_account_key}\" -storagePrivateDomain \"${var.storage_private_domain}\" -fileshareName \"${var.fileshare_name}\" -storageAccountConnectionString \"${var.storage_account_connection_string}\" -DownloadedFile \"${var.bootstrapping_script_name}\" -DestinationFolder \"C:\\scripts\" -Username \"adminuser\" && powershell.exe Write-Host \"${local.create_service_md5} ${local.bootstrapping_md5}\""
  })
}