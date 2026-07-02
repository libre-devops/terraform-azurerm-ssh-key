<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure SSH Key

Azure SSH public keys with ephemeral generation: private keys go straight to Key Vault write-only and
never touch Terraform state.

[![CI](https://github.com/libre-devops/terraform-azurerm-ssh-key/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-ssh-key/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-ssh-key?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-ssh-key/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-ssh-key)](./LICENSE)

---

## Overview

SSH keys keyed by the Azure resource name, in two modes per entry:

- **Bring your own** (`public_key` set, ssh-rsa or ssh-ed25519): only the `azurerm_ssh_public_key`
  resource is created; no private key exists anywhere. The most state-hygienic mode.
- **Generate** (the default): the key pair comes from the tls provider's **ephemeral**
  `tls_private_key`, so it exists only during the run and is **never stored in plan or state**. Both
  halves are written into your Key Vault through the provider's write-only `value_wo` argument, and
  the public half is read back (public material, safe to persist) to create the Azure resource.
  `algorithm` picks **RSA** (default, `rsa_bits` >= 2048, default 4096) or **ED25519** (the provider
  doc's rsa-only claim is stale; ed25519 acceptance was verified against ARM directly).

Rotation is one knob: an ephemeral resource regenerates every run, but the vault is only written when
`value_wo_version` changes, so bumping it rotates the whole pair (both halves come from the same
ephemeral instance, so they always match) and the Azure resource follows. The module exports no
private key material, and none exists in state to export.

Vault secret conveniences: names default to the key name with underscores dashed (vault names forbid
underscores), `secret_format` picks PEM (default), OpenSSH, or PKCS#8, and content type, expiry, and
not-before pass through. Outputs cover ids, zipmap, OpenSSH public key text (what a VM's
`admin_ssh_key` consumes), fingerprints, and the vaulted secret ids. The resource group is passed by
id and parsed.

## Usage

```hcl
module "ssh_key" {
  source  = "libre-devops/ssh-key/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  key_vault_id = module.keyvault.ids["kv-ldo-uks-prd-001"]

  ssh_keys = {
    # Generated: RSA 4096, private key vaulted write-only.
    "ssh-ldo-uks-prd-001" = {}

    # Bring your own: no private key anywhere.
    "ssh-ldo-uks-prd-002" = {
      public_key = file("~/.ssh/id_rsa.pub")
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - a bring-your-own public key (no vault needed).
- [`examples/complete`](./examples/complete) - the full surface: a generated key with the secure
  defaults, a generated key exercising every storage option (format, name, content type, expiry,
  rotation version, per-key tags), and a bring-your-own key, with the vault the private keys land in.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in a table
here so the reason is auditable.

There are currently **no exceptions**: the module and its examples scan clean. The module exists to
keep private keys OUT of reach (vaulted write-only, never output), so there is nothing to waive.

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here recording the reason. Both the file and
the table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.23.0, < 5.0.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.1.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.23.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.private_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.public_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_ssh_public_key.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ssh_public_key) | resource |
| [azurerm_key_vault_secret.public_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | The Key Vault generated key material lives in: both halves are written as write-only secrets, and the public half is read back to feed the Azure resource. Required when any key is generated (bring-your-own keys need no vault). | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the SSH public key resources. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource id of the resource group to create the SSH public key resources in. The name is parsed from it (pass the rg module's ids output). | `string` | n/a | yes |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | The SSH keys to manage, keyed by the Azure SSH public key resource name. Two modes per entry:<br/><br/>- Bring your own: set public\_key (ssh-rsa at 2048-bit or larger, or ssh-ed25519) and only the Azure<br/>  public key resource is created; no private key exists anywhere.<br/>- Generate (when public\_key is null, the default): the key pair is generated EPHEMERALLY (never in<br/>  plan or state) and both halves are written into key\_vault\_id through the provider's write-only<br/>  value\_wo argument; the public half is read back (public material, safe to persist) to create the<br/>  Azure public key resource. algorithm picks RSA (default; size via rsa\_bits, default 4096, minimum<br/>  2048 per Azure) or ED25519. Rotation is one knob: bump value\_wo\_version and a freshly generated<br/>  pair replaces both secrets and the Azure resource's key. The module deliberately exports NO private<br/>  key material.<br/><br/>Generated-key attributes: algorithm and rsa\_bits; secret\_name (defaults to the key name with underscores dashed,<br/>since vault secret names forbid underscores); public\_secret\_name (defaults to the private name with a<br/>-pub suffix); secret\_format for the private half (pem, openssh, or pkcs8; default pem);<br/>secret\_content\_type; secret\_expiration\_date / secret\_not\_before\_date; value\_wo\_version (bump to<br/>rotate the pair). tags merge over the module tags on the Azure resource and the secrets. | <pre>map(object({<br/>    public_key = optional(string)<br/>    algorithm  = optional(string, "RSA")<br/>    rsa_bits   = optional(number, 4096)<br/><br/>    secret_name            = optional(string)<br/>    public_secret_name     = optional(string)<br/>    secret_format          = optional(string, "pem")<br/>    secret_content_type    = optional(string, "application/x-pem-file")<br/>    secret_expiration_date = optional(string)<br/>    secret_not_before_date = optional(string)<br/>    value_wo_version       = optional(number, 1)<br/><br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every SSH public key resource (merged with any per-key tags). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ids"></a> [ids](#output\_ids) | Map of key name to Azure SSH public key resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of key name to { name, id }, for easy composition with other modules. |
| <a name="output_names"></a> [names](#output\_names) | Map of key name to name (convenience passthrough). |
| <a name="output_private_key_secret_ids"></a> [private\_key\_secret\_ids](#output\_private\_key\_secret\_ids) | Map of key name to the vaulted private key secret's versioned id (generated keys only). |
| <a name="output_private_key_secret_versionless_ids"></a> [private\_key\_secret\_versionless\_ids](#output\_private\_key\_secret\_versionless\_ids) | Map of key name to the vaulted private key secret's versionless id (always resolves to the latest version). |
| <a name="output_public_key_secret_ids"></a> [public\_key\_secret\_ids](#output\_public\_key\_secret\_ids) | Map of key name to the vaulted public key secret's versioned id (the state-free bridge secret). |
| <a name="output_public_keys_openssh"></a> [public\_keys\_openssh](#output\_public\_keys\_openssh) | Map of key name to the OpenSSH public key text (what a VM's admin\_ssh\_key consumes). |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The resource group the SSH public keys live in, parsed from resource\_group\_id. |
| <a name="output_ssh_public_keys"></a> [ssh\_public\_keys](#output\_ssh\_public\_keys) | The Azure SSH public key resources, keyed by name. Full resource objects (public material only). |
<!-- END_TF_DOCS -->
