<!--
  Header for the minimal example README. Edit this file, then run `just docs`
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

# Minimal example

The smallest valid call: a bring-your-own public key, creating only the Azure SSH public key resource;
no private key exists anywhere, so no vault is needed. The environment comes from the Terraform
workspace (`terraform.workspace`), not a variable. Run it with `just e2e minimal`, which applies the
stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# Minimal call: bring your own public key. Only the Azure SSH public key resource is created; no
# private key exists anywhere (no vault needed). The key below is a throwaway example public key.
module "ssh_key" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  ssh_keys = {
    "ssh-${var.short}-${var.loc}-${terraform.workspace}-001" = {
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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_ssh_key"></a> [ssh\_key](#module\_ssh\_key) | ../../ | n/a |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

No resources.

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
| <a name="output_public_keys_openssh"></a> [public\_keys\_openssh](#output\_public\_keys\_openssh) | Map of key name to the OpenSSH public key text. |
<!-- END_TF_DOCS -->
