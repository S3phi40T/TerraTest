locals {

  data_disks         = [for disk in var.data_disks : merge(disk, { label = local.vm_label, instance = index(var.data_disks, disk) }) if var.data_disks != []]
  windows_data_disks = var.image_type == "Windows" ? local.data_disks : []
  linux_data_disks   = var.image_type == "Linux" ? local.data_disks : []

  name = format("%s%s", var.pid, var.instance_number)

  contributor_users_list = flatten([
    for user in var.contributor_users : {
      user_id = user
    }
  ])

  vm_sizes_map = {
    Extra-Small = "Standard_DS1_v2"
    Small       = "Standard_D2s_v5"
    Medium      = "Standard_D4s_v5"
    Large       = "Standard_D8s_v5"
    Extra-Large = "Standard_D16s_v5"
  }

  region_abbreviated_map = {
    westeurope    = "EUW"
    eastus        = "NAE"
    westus        = "NAW"
    southeastasia = "AP"
  }

  environment_abbreviated_map = {
    Production     = "P"
    Non-Production = "NP"
  }

  environment_abbreviated    = lookup(local.environment_abbreviated_map, var.environment)
  region_abbreviated         = lookup(local.region_abbreviated_map, var.location)
  subscription_id             = lookup(var.subscriptions, "Int${local.sub_environment_abbreviated}-001-${local.region_abbreviated}")
  sub_environment_abbreviated = lookup(local.sub_environment_abbreviated_map, var.environment)
  rg_environment_abbreviated = lookup(local.rg_environment_abbreviated_map, var.environment)

  rg_environment_abbreviated_map = {
    Production     = "Prd"
    Non-Production = "NonPrd"
  }

  sub_environment_abbreviated_map = {
    Production     = "Prod"
    Non-Production = "NonProd"
  }

  vm_label = format("%s%s%s", "AZ", local.region_abbreviated, local.environment_abbreviated)

  script_data_disk = var.data_disks == [] ? false : true

  /*vm_extensions = [for i in range(var.nb_instances) : [
    for ext in var.vm_extensions : merge(ext, {
      instance = i
  }) if var.vm_extensions != []]]
*/

}


resource "random_shuffle" "az" {
  input        = ["1", "2", "3"]
  result_count = 1

}

module "os" {
  source       = "./os"
  vm_os_simple = var.vm_os_simple
}


resource "random_password" "admin_pw" {
  length = 16
}

resource "null_resource" "encrypted_admin_password" {
  triggers = {
    orig = random_password.admin_pw.result
    pw   = bcrypt(random_password.admin_pw.result)
  }

  lifecycle {
    ignore_changes = [triggers["pw"]]
  }
}

data "azurerm_key_vault" "keyvault" {
  provider            = azurerm.prod-corp
  name                = "kvsecretsautomation"
  resource_group_name = "RG-Prd-TFC"
}

data "azurerm_key_vault_secret" "domainusername" { 
  name         = "domainusername"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "domainpassword" { 
  name         = "domainpassword"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "domainname" { 
  name         = "domainname"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "domainou" { 
  name         = "domainou"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "ansibledomainusername" {
  name         = "ansibledomainusername"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_resource_group" "rg" {
  count = var.resource_group_name == "" ? 0 : 1
  name  = var.resource_group_name
}

data "azurerm_subnet" "subnet" {
  name                 = var.environment == "Production" ? "SN-Prod-${local.region_abbreviated}-CLOUDMOD" : "SN-NonProd-${local.region_abbreviated}-CLOUDMOD"
  virtual_network_name = var.environment == "Production" ? "VN01-Prd-IntApp-${local.region_abbreviated}" : "VN01-NonPrd-IntApp-${local.region_abbreviated}"
  resource_group_name  = var.environment == "Production" ? "RG-Prod-VNET-01" : "RG-NonProd-VNET-01"
}
