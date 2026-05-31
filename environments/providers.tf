###############################################################
# Provider Configuration — Root Module
###############################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.73.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.9.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.governance_subscription_id
}
