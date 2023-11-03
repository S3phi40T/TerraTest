
resource "azurerm_virtual_machine_extension" "extension" {
  count = var.image_type == "Windows" && (var.data_disks != [] || var.is_web) ? 1 : 0

  name                 = "CustomScriptExtension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
        {
            "fileUris": [
                "https://stgautomationscript.blob.core.windows.net/powershell/config_script.ps1"
                ],
            "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File config_script.ps1 -is_web ${var.is_web} -data_disk ${local.script_data_disk} -username ${data.azurerm_key_vault_secret.ansibledomainusername.value} -pword ${data.azurerm_key_vault_secret.domainpassword.value} -users \"${var.admin_users}\""
        }
  SETTINGS
  depends_on           = [azurerm_virtual_machine_data_disk_attachment.disk_attachment, azurerm_virtual_machine_extension.vmdomainjoin]
  tags                 = var.tags
}

resource "azurerm_virtual_machine_extension" "extension_linux" {
  count = var.image_type == "Linux" ? 1 : 0

  name                 = "CustomScriptExtension"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[0].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  settings             = <<SETTINGS
        {
            "fileUris": [
                "https://stgautomationscript.blob.core.windows.net/ansible/join_domain_and_tools_redhat9.yml",
                "https://stgautomationscript.blob.core.windows.net/ansible/ADsudoers.j2",
                "https://stgautomationscript.blob.core.windows.net/ansible/krb5.j2",
                "https://stgautomationscript.blob.core.windows.net/ansible/sssd.j2"
                ],
            "commandToExecute": "sudo dnf install -y ansible-core ; ansible-galaxy collection install community.general ; ansible-galaxy collection install ansible.posix; ansible-playbook join_domain_and_tools_redhat9.yml --extra-vars \"adminusers=${var.admin_users} username=${data.azurerm_key_vault_secret.ansibledomainusername.value} password=\"${data.azurerm_key_vault_secret.domainpassword.value}\" adhostname=${azurerm_linux_virtual_machine.vm[0].name} domain_user=${data.azurerm_key_vault_secret.ansibledomainusername.value} domain_user_password=${data.azurerm_key_vault_secret.domainpassword.value}\""
        }
  SETTINGS
  depends_on           = [azurerm_virtual_machine_data_disk_attachment.disk_attachment]
  tags                 = var.tags
}

resource "azurerm_virtual_machine_extension" "vmdomainjoin" {
  count                = var.image_type == "Windows" ? 1 : 0
  name                 = "joindomain"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[0].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  tags                 = var.tags

  # NOTE: the `OUPath` field is intentionally blank, to put it in the Computers OU
  settings = <<SETTINGS
    {
        "Name": "${data.azurerm_key_vault_secret.domainname.value}",
        "OUPath": "${data.azurerm_key_vault_secret.domainou.value}",
        "User": "${data.azurerm_key_vault_secret.domainusername.value}",
        "Restart": "true",
        "Options": "3"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${data.azurerm_key_vault_secret.domainpassword.value}"
    }
  PROTECTED_SETTINGS

  depends_on = [azurerm_windows_virtual_machine.vm]
}
