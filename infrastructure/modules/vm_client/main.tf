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

  bootstrapping_ext_name            = "bootstrapping"
  bootstrapping_ext_resource_prefix = "ext"
  bootstrapping_ext_resource_name   = "${local.bootstrapping_ext_resource_prefix}${var.resource_name_specifier}${local.bootstrapping_ext_name}"
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name_us
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = var.resource_group_name_us
}

data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name_eu
}

resource "azurerm_network_interface" "nic" {
  name                = local.nic_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name_us

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
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
  key_vault_id = data.azurerm_key_vault.kv.id
}

# This creates the Custom Script Extension to copy the script to the VM
resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "customScript"
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
    commandToExecute = "powershell.exe -ExecutionPolicy Unrestricted -File ${var.create_service_script_name} -storageAccountName \"${var.storage_account_name}\" -storageAccountKey \"${var.storage_account_key}\" -storagePrivateDomain \"${var.storage_private_domain}\" -fileshareName \"${var.fileshare_name}\" -storageAccountConnectionString \"${var.storage_account_connection_string}\" -DownloadedFile \"${var.bootstrapping_script_name}\" -DestinationFolder \"C:\\scripts\" -ServiceName \"RunSetupScriptService\" -ServiceDescription \"Run  create_service.ps1 at startup. Filehash: ${var.script_file_md5}\" -Username \"adminuser\" -Password \"${azurerm_key_vault_secret.admin_password_secret.value}\""
  })

  depends_on = [
    null_resource.file_change
  ]

}

resource "null_resource" "file_change" {

  triggers = {
    script_file_md5 = var.script_file_md5
  }

}

 # Bootstrapping script to install dependencies
#  data "template_file" "create_service" {
#      template = "${file("${path.module}/../../scripts/create-service.ps1")}"
#  }

 
# Mount fileshare script to mount Azure File Share to Windows VM
# resource "azurerm_virtual_machine_extension" "mount_fileshare" {
#   name                 = local.fileshare_ext_resource_name
#   virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.10"

#   protected_settings = jsonencode({
#     commandToExecute = "powershell -ExecutionPolicy Unrestricted -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.bootstrapping.rendered)}')) | Out-File -filepath create-service.ps1\"; powershell -ExecutionPolicy Unrestricted -File create-service.ps1 -storageAccountName '${data.template_file.bootstrapping.vars.storageAccountName}' -storageAccountKey '${data.template_file.bootstrapping.vars.storageAccountKey}' -fileshareName '${data.template_file.bootstrapping.vars.fileshareName}' -storageAccountConnectionString '${data.template_file.bootstrapping.vars.storageAccountConnectionString}' -storagePrivateDomain '${data.template_file.bootstrapping.vars.storagePrivateDomain}'"
#   })

# }

#  resource "azurerm_virtual_machine_extension" "bootstrapping" {
#    name                 = local.bootstrapping_ext_resource_name
#    virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
#    publisher            = "Microsoft.Compute"
#    type                 = "CustomScriptExtension"
#    type_handler_version = "1.9"
#    protected_settings = jsonencode({
#    commandToExecute = "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.bootstrapping_script.rendered)}')) | Out-File -filepath create-service.ps1\"; powershell -ExecutionPolicy Unrestricted -File create-service.ps1"
#    })

#  }