resource "azurerm_windows_virtual_machine" "vm" {
  count = var.image_type == "Windows" ? 1 : 0

  name           = upper(format("%s-%s", local.vm_label, local.name))
  computer_name  = format("%s-%s", local.vm_label, local.name)
  admin_username = "AzAptivAdmin-tf"
  admin_password = null_resource.encrypted_admin_password.triggers["pw"]

  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.rg[0].name
  location            = var.location
  size                = lookup(local.vm_sizes_map, var.vm_size)


  zone = random_shuffle.az.result[0]

  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  license_type             = "Windows_Server"
  enable_automatic_updates = true

  source_image_reference {
    publisher = module.os.calculated_value_os_publisher
    offer     = module.os.calculated_value_os_offer
    sku       = module.os.calculated_value_os_sku
    version   = "latest"
  }


  os_disk {
    name                 = format("%s-%s-osdisk", local.vm_label, local.name)
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 128
  }

  tags = var.tags

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.vm-sa.primary_blob_endpoint
  }
}




resource "azurerm_linux_virtual_machine" "vm" {
  count = var.image_type != "Windows" ? 1 : 0

  name           = upper(format("%s-%s", local.vm_label, local.name))
  computer_name  = format("%s-%s", local.vm_label, local.name)
  admin_username = "AzAptivAdmin-tf"
  admin_password = null_resource.encrypted_admin_password.triggers["pw"]

  disable_password_authentication = false

  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.rg[0].name
  location            = var.location
  size                = lookup(local.vm_sizes_map, var.vm_size, "Small")


  zone = random_shuffle.az.result[0]

  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]


  os_disk {
    name                 = format("%s-%s-osdisk", local.vm_label, local.name)
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 128
  }

  #source_image_id = var.vm_os_id != "" ? var.vm_os_id : null

  source_image_reference {
    publisher = module.os.calculated_value_os_publisher
    offer     = module.os.calculated_value_os_offer
    sku       = module.os.calculated_value_os_sku
    version   = "latest"
  }

  tags = var.tags

  boot_diagnostics {
    storage_account_uri = join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint)
  }
}
