locals{
  vm_name = "cl${var.client_number}"
  vm_resource_prefix = "vm"
  vm_resource_name = "${local.vm_resource_prefix}${var.resource_name_specifier}${local.vm_name}"

  nic_name = local.vm_name
  nic_resource_prefix = "nic"
  nic_resource_name = "${local.nic_resource_prefix}${var.resource_name_specifier}${local.nic_name}"

  pip_name = local.vm_name
  pip_resource_prefix = "pip"
  pip_resource_name = "${local.pip_resource_prefix}${var.resource_name_specifier}${local.pip_name}"

  fileshare_ext_name = "mount_fileshare"
  fileshare_ext_resource_prefix = "ext"
  fileshare_ext_resource_name = "${local.ext_resource_prefix}${var.resource_name_specifier}${local.fileshare_ext_name}"

  bootstrapping_ext_name = "bootstrapping"
  bootstrapping_ext_resource_prefix = "ext"
  bootstrapping_ext_resource_name = "${local.ext_resource_prefix}${var.resource_name_specifier}${local.bootstrapping_ext_name}"
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
  size                = "Standard_B2s"
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
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  #patch_mode  = "AutomaticByPlatform"

}

resource "random_password" "admin_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "azurerm_key_vault_secret" "admin_password_secret" {
  name         = "${local.vm_name}AdminPassword"
  value        = random_password.admin_password.result
  key_vault_id = data.azurerm_key_vault.kv.id
}

# Mount fileshare script to mount Azure File Share to Windows VM
resource "azurerm_virtual_machine_extension" "mount_fileshare" {
  name                 = local.fileshare_ext_resource_name
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = jsonencode({
  commandToExecute = "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.mount_fileshare_script.rendered)}')) | Out-File -filepath mount_fileshare_script.ps1\"; powershell -ExecutionPolicy Unrestricted -File mount_fileshare_script.ps1 -storageAccountName '${data.template_file.mount_fileshare_script.vars.storageAccountName}' -storageAccountKey '${data.template_file.mount_fileshare_script.vars.storageAccountKey}' -fileshareName '${data.template_file.mount_fileshare_script.vars.fileshareName}' -storageAccountConnectionString '${data.template_file.mount_fileshare_script.vars.storageAccountConnectionString}'"
  })

}

data "template_file" "mount_fileshare_script" {
    template = "${file("${path.module}/../../scripts/mount_fileshare.ps1")}"
    vars = {
        storageAccountName  = var.storage_account_name
        storageAccountKey  = var.storage_account_key
        fileshareName =  var.fileshare_name
        storageAccountConnectionString = var.storage_account_connection_string
  }
}

# Bootstrapping script to install dependencies
data "template_file" "bootstrapping_script" {
    template = "${file("${path.module}/../../scripts/bootstrapping.ps1")}"
}

resource "azurerm_virtual_machine_extension" "bootstrapping" {
  name                 = local.bootstrapping_ext_resource_name
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = jsonencode({
  commandToExecute = "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.bootstrapping_script.rendered)}')) | Out-File -filepath bootstrapping.ps1\"; powershell -ExecutionPolicy Unrestricted -File bootstrapping.ps1"
  })

}