<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

The full surface of the module: a generated key with the secure defaults (RSA 4096, private key
written to the vault through value_wo), a generated key exercising every storage option (size, secret
name, OpenSSH format, content type, expiry, a bumped rotation version, per-key tags), a generated
ED25519 key, and a bring-your-own public key alongside them. The vault the private keys land in is a disposable, un-firewalled example vault using access policies so the data-plane writes work immediately (real vaults keep the module's firewall default; the terraform-azure action can allow-list your runner IP). Run it with `just e2e complete`, which applies
the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
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
      #
      # NOTE: an explicit "network_acls = null" would NOT opt out: optional() replaces an explicit
      # null with the secure default. Allow is the expressible opt-out.
      network_acls = { default_action = "Allow" }
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.23.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.23.0, < 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_keyvault"></a> [keyvault](#module\_keyvault) | libre-devops/keyvault/azurerm | ~> 4.0 |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_ssh_key"></a> [ssh\_key](#module\_ssh\_key) | ../../ | n/a |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployed_branch"></a> [deployed\_branch](#input\_deployed\_branch) | Git branch the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_branch. | `string` | `""` | no |
| <a name="input_deployed_repo"></a> [deployed\_repo](#input\_deployed\_repo) | Repository URL the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_repo. | `string` | `""` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ids"></a> [ids](#output\_ids) | Map of key name to Azure SSH public key resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of key name to { name, id }. |
| <a name="output_private_key_secret_ids"></a> [private\_key\_secret\_ids](#output\_private\_key\_secret\_ids) | Map of key name to the vaulted private key secret id (no value; write-only). |
| <a name="output_private_key_secret_versionless_ids"></a> [private\_key\_secret\_versionless\_ids](#output\_private\_key\_secret\_versionless\_ids) | Map of key name to the vaulted private key secret's versionless id. |
| <a name="output_public_key_secret_ids"></a> [public\_key\_secret\_ids](#output\_public\_key\_secret\_ids) | Map of key name to the vaulted public key secret id (the state-free bridge). |
| <a name="output_public_keys_openssh"></a> [public\_keys\_openssh](#output\_public\_keys\_openssh) | Map of key name to the OpenSSH public key text. |
<!-- END_TF_DOCS -->
