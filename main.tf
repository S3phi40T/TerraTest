resource "azurerm_resource_group" "rg" {
  count    = var.resource_group_name == "" ? 1 : 0
  name     = upper(format("RG-%s-%s", local.rg_environment_abbreviated, var.pid))
  location = var.location

  tags = var.tags
}

resource "azurerm_storage_account" "vm-sa" {
  name                     = replace(lower(format("azstg%s%s%sdiag", local.region_abbreviated, local.environment_abbreviated, local.name)), "/[^a-z^0-9]/", "")
  resource_group_name      = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.rg[0].name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags

  public_network_access_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["Logging", "Metrics", "AzureServices"]
  }
}

resource "azurerm_managed_disk" "linux_data_disk" {
  for_each = { for disk in flatten(local.linux_data_disks) : format("%s-0%d", disk.name, disk.instance + 1) => disk }

  zone = azurerm_linux_virtual_machine.vm[0].zone

  name = upper(format("%s-datadisk-0%d", azurerm_linux_virtual_machine.vm[0].name, each.value.instance + 1))

  location            = azurerm_linux_virtual_machine.vm[0].location
  resource_group_name = azurerm_linux_virtual_machine.vm[0].resource_group_name

  storage_account_type = each.value.disk_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb

  tags = var.tags
}


resource "azurerm_managed_disk" "windows_data_disk" {
  for_each = { for disk in flatten(local.windows_data_disks) : format("%s-0%d", disk.name, disk.instance + 1) => disk }

  zone = azurerm_windows_virtual_machine.vm[0].zone

  name = upper(format("%s-datadisk-0%d", azurerm_windows_virtual_machine.vm[0].name, each.value.instance + 1))

  location            = azurerm_windows_virtual_machine.vm[0].location
  resource_group_name = azurerm_windows_virtual_machine.vm[0].resource_group_name

  storage_account_type = each.value.disk_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb

  tags = var.tags
}


resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment" {
  for_each = { for disk in flatten(local.data_disks) : format("%s-0%d", disk.name, disk.instance + 1) => disk }

  managed_disk_id    = var.image_type == "Windows" ? azurerm_managed_disk.windows_data_disk[each.key].id : azurerm_managed_disk.linux_data_disk[each.key].id
  virtual_machine_id = var.image_type == "Windows" ? azurerm_windows_virtual_machine.vm[0].id : azurerm_linux_virtual_machine.vm[0].id
  lun                = lookup(each.value, "lun", 10)
  caching            = lookup(each.value, "caching", "None")
  create_option      = lookup(each.value, "attach_create_option", "Attach")
}

resource "azurerm_network_interface" "vm" {
  name                 = upper(format("%s-nic", format("%s-%s", local.vm_label, local.name)))
  resource_group_name  = var.resource_group_name != "" ? var.resource_group_name : azurerm_resource_group.rg[0].name
  location             = var.location
  enable_ip_forwarding = false

  ip_configuration {
    name                          = format("%s-%s-ip", local.vm_label, local.name)
    subnet_id                     = var.subnet_id == "" ? data.azurerm_subnet.subnet.id : var.subnet_id
    private_ip_address_allocation = length(var.private_ip_address) > 0 ? "Static" : "Dynamic"
    private_ip_address            = length(var.private_ip_address) > 0 ? var.private_ip_address : null
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "rbac" {
  for_each             = { for user in local.contributor_users_list : user.user_id => user }
  scope                = var.resource_group_name == "" ? azurerm_resource_group.rg[0].id : data.azurerm_resource_group.rg[0].id
  role_definition_name = "Contributor"
  principal_id         = each.value.user_id
}
