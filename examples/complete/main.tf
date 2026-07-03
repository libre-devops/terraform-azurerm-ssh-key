locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  kv_name  = "kv-${var.short}-${var.loc}-${terraform.workspace}-002"
}

data "azurerm_client_config" "current" {}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-ssh-key" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# The vault the generated private keys are written into. Access policies grant the caller secret
# access so the writes work immediately; the runner IP is allow-listed for the data-plane writes.
# purge_protection is off only so the example is disposable.
module "keyvault" {
  source  = "libre-devops/keyvault/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  key_vaults = {
    (local.kv_name) = {
      rbac_authorization_enabled = false
      purge_protection_enabled   = false

      # The keyvault module firewalls vaults by default (deny with AzureServices bypass). This
      # DISPOSABLE example vault opts out so the CI runner can reach the data plane without
      # per-run IP allow-listing. For a real, firewalled vault either keep the default and
      # allow-list your egress IP as below, or let the terraform-azure action do the dance for
      # you (add-current-ip-to-key-vault-before-tf-run + firewall-key-vault-name inputs).
      #
      # network_acls = {
      #   default_action = "Deny"
      #   bypass         = "AzureServices"
      #   ip_rules       = ["<your egress ip>/32"]
      # }
      network_acls = null
      access_policies = [
        {
          object_id          = data.azurerm_client_config.current.object_id
          secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Purge"]
        }
      ]
    }
  }
}

# Complete call: the full surface. A generated key with the secure defaults (RSA 4096, private key
# written to the vault through value_wo), a generated key exercising every storage option, and a
# bring-your-own public key alongside them.
module "ssh_key" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  key_vault_id = module.keyvault.ids[local.kv_name]

  ssh_keys = {
    # Secure defaults: generated RSA 4096, private key vaulted write-only as ssh-<...>-generated.
    "ssh-${var.short}-${var.loc}-${terraform.workspace}-generated" = {}

    # Every storage option: smaller key, custom secret name/format/content type, an expiry, a bumped
    # write-only version, and per-key tags.
    "ssh_${var.short}_${var.loc}_${terraform.workspace}_tuned" = {
      rsa_bits               = 2048
      secret_name            = "ssh-${var.short}-${var.loc}-${terraform.workspace}-tuned"
      secret_format          = "openssh"
      secret_content_type    = "text/plain"
      secret_expiration_date = "2027-01-01T00:00:00Z"
      value_wo_version       = 2
      tags                   = { Component = "compute" }
    }

    # Generated ED25519 (Azure accepts ssh-ed25519 alongside ssh-rsa).
    "ssh-${var.short}-${var.loc}-${terraform.workspace}-ed25519" = {
      algorithm = "ED25519"
    }

    # Bring your own: only the Azure resource, no private key anywhere (throwaway example key).
    "ssh-${var.short}-${var.loc}-${terraform.workspace}-byo" = {
      public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtbmPhzCR+ZpI/Y4H1IvPEI+tvGT4R5ReLtj5QZVcRXJiRdIbYsb6sjaYu8JcR6vzSHAlJcx0zmcSP4SR7HqtuXbODv+OvVpBCoil9LWbCfOgOQ6XZ3oSFYe8lFllbFLiM7I+ok+s7Cygnu58fil7pDdBFrS7DZRjvT87RrOX0dp2LDNNN7LYFy5nwHvkBv9z36q9RFGcP4e0XDNtU0+LGnolz4oDWkJt/0POaHIxnJJX7ge0r0bReZq/t1XRr/RrhPYk6gkWsSkfbwwxGPA2UdxFRDVn2aMx6Hz8gQfcHRS2kEvKRMIgQfBOmB6OInLCLaUZRWm5YdEBZXwtdREor example"
    }
  }

}
