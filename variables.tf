variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created."
  type        = string
  default     = ""
}


variable "location" {
  description = "(Optional) The location in which the resources will be created."
  type        = string
  default     = ""
}

variable "environment" {
  type    = string
  default = "Non-Production"
}


variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "is_web" {
  type    = bool
  default = false
}

variable "vm_os_simple" {
  description = "Specify WindowsServer, RHEL to get the latest image version of the specified os."
  type        = string
  default     = ""
}

variable "is_windows_image" {
  description = "Boolean flag to notify when the custom image is windows based."
  type        = bool
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}

variable "private_ip_address" {
  description = "Static private ip address to associate with primary NICs.."
  type        = string
  default     = ""
}

variable "image_type" {
  default = "Windows"
}


variable "data_disks" {
  description = "(Optional) List of extra data disks attached to each virtual machine."
  type        = any
  default     = []
}

variable "admin_users" {
  default = null
}

variable "instance_number" {

}

variable "pid" {

}

variable "contributor_users" {
  description = "A list of Principal IDs. The Principal ID is also known as the Object ID"
  default     = []
}

variable "subnet_id" {
  default = ""
}

variable "appreg_id" {

}

variable "appreg_secret" {

}

variable "aztenant" {

}

variable "prod_appreg_id" {

}

variable "prod_appreg_secret" {

}

variable "corp_subscription_id" {

}

variable "subscriptions" {

}
