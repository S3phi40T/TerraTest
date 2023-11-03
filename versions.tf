terraform {
  required_version = ">= 1.2.0" #has to be 1.2.0 as ServiceNow does not support higher 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.72.0"
    }
  }
}


provider "azurerm" {

  features {}
  skip_provider_registration = "true"
  # Connection to Azure
  subscription_id = local.subscription_id
  client_id       = var.environment == "Production" ? var.prod_appreg_id : var.appreg_id
  client_secret   = var.environment == "Production" ? var.prod_appreg_secret : var.appreg_secret
  tenant_id       = var.aztenant
}

provider "azurerm" {
  alias = "prod-corp"
  features {}
  skip_provider_registration = "true"
  # Connection to Azure
  subscription_id = var.corp_subscription_id
  client_id       = var.prod_appreg_id
  client_secret   = var.prod_appreg_secret
  tenant_id       = var.aztenant
}
