terraform {
  # 1.11 is the floor for the module's write-only private key handling.
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.23.0, < 5.0.0"
    }
  }

  backend "azurerm" {}
}
