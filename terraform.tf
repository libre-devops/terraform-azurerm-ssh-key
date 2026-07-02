terraform {
  # 1.11 is the floor for the write-only (value_wo) private key handling.
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 4.23.0 is where azurerm_key_vault_secret gained value_wo / value_wo_version.
      version = ">= 4.23.0, < 5.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}
