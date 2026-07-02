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

Azure SSH public keys with generated private keys written to Key Vault write-only, and no key material
in outputs.

[![CI](https://github.com/libre-devops/terraform-azurerm-ssh-key/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-ssh-key/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-ssh-key?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-ssh-key/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-ssh-key)](./LICENSE)

---

## Overview

SSH keys keyed by the Azure resource name, in two modes per entry:

- **Bring your own** (`public_key` set): only the `azurerm_ssh_public_key` resource is created; no
  private key exists anywhere. The most state-hygienic mode.
- **Generate** (the default): the module generates an RSA key pair (Azure's SSH public key resource
  only accepts ssh-rsa at 2048-bit or larger, so the algorithm is fixed and only `rsa_bits` varies,
  defaulting to 4096), creates the Azure resource, and **by default writes the private key into your
  Key Vault** through the provider's write-only `value_wo` argument, so the secret resource never
  stores or displays it. Rotation of the stored secret is explicit via `value_wo_version`.

Honesty about state: deriving a public key from a managed key pair requires the `tls_private_key`
resource, which keeps the key material in Terraform state. The vault write and the absence of any
private key output keep every OTHER surface clean, and a check flags generated keys that opt out of
vault storage. (The tls provider's ephemeral `tls_private_key` cannot help here: ephemeral values
cannot feed persisted arguments like the Azure resource's `public_key`.) For zero key material in
state, bring your own public key.

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
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.23.0, < 5.0.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.private_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_ssh_public_key.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ssh_public_key) | resource |
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | The Key Vault generated private keys are written into (as write-only secrets, never stored in the secret resource's state). Required unless every generated key opts out with store\_private\_key\_in\_key\_vault = false. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the SSH public key resources. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource id of the resource group to create the SSH public key resources in. The name is parsed from it (pass the rg module's ids output). | `string` | n/a | yes |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | The SSH keys to manage, keyed by the Azure SSH public key resource name. Two modes per entry:<br/><br/>- Bring your own: set public\_key (ssh-rsa, at least 2048-bit, per the Azure resource's contract) and<br/>  only the Azure public key resource is created; no private key exists anywhere.<br/>- Generate (when public\_key is null, the default): the module generates an RSA key pair (Azure only<br/>  accepts ssh-rsa public keys, so the algorithm is fixed; size via rsa\_bits, default 4096), creates<br/>  the Azure public key resource, and BY DEFAULT writes the private key into key\_vault\_id through the<br/>  provider's write-only value\_wo argument, so the secret resource never stores it. NOTE the honest<br/>  caveat: the tls\_private\_key resource itself keeps the key material in Terraform state (that is what<br/>  makes deriving the public key possible); protect the state, or bring your own public key for a<br/>  state-free result. The module deliberately exports NO private key material.<br/><br/>Generated-key attributes: rsa\_bits; store\_private\_key\_in\_key\_vault (default true; opting out leaves<br/>the private key ONLY in state, which a check flags); secret\_name (defaults to the key name with<br/>underscores dashed, since vault secret names forbid underscores); secret\_format (pem, openssh, or<br/>pkcs8; default pem); secret\_content\_type; secret\_expiration\_date / secret\_not\_before\_date;<br/>value\_wo\_version (bump alongside key replacement to rotate the stored secret). tags merge over the<br/>module tags on the Azure resource and the secret. | <pre>map(object({<br/>    public_key = optional(string)<br/>    rsa_bits   = optional(number, 4096)<br/><br/>    store_private_key_in_key_vault = optional(bool, true)<br/>    secret_name                    = optional(string)<br/>    secret_format                  = optional(string, "pem")<br/>    secret_content_type            = optional(string, "application/x-pem-file")<br/>    secret_expiration_date         = optional(string)<br/>    secret_not_before_date         = optional(string)<br/>    value_wo_version               = optional(number, 1)<br/><br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every SSH public key resource (merged with any per-key tags). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ids"></a> [ids](#output\_ids) | Map of key name to Azure SSH public key resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of key name to { name, id }, for easy composition with other modules. |
| <a name="output_names"></a> [names](#output\_names) | Map of key name to name (convenience passthrough). |
| <a name="output_private_key_secret_ids"></a> [private\_key\_secret\_ids](#output\_private\_key\_secret\_ids) | Map of key name to the vaulted private key secret's versioned id (generated, vault-stored keys only). |
| <a name="output_private_key_secret_versionless_ids"></a> [private\_key\_secret\_versionless\_ids](#output\_private\_key\_secret\_versionless\_ids) | Map of key name to the vaulted private key secret's versionless id (always resolves to the latest version). |
| <a name="output_public_key_fingerprints_md5"></a> [public\_key\_fingerprints\_md5](#output\_public\_key\_fingerprints\_md5) | Map of GENERATED key name to the MD5 public key fingerprint. |
| <a name="output_public_key_fingerprints_sha256"></a> [public\_key\_fingerprints\_sha256](#output\_public\_key\_fingerprints\_sha256) | Map of GENERATED key name to the SHA256 public key fingerprint. |
| <a name="output_public_keys_openssh"></a> [public\_keys\_openssh](#output\_public\_keys\_openssh) | Map of key name to the OpenSSH public key text (what a VM's admin\_ssh\_key consumes). |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The resource group the SSH public keys live in, parsed from resource\_group\_id. |
| <a name="output_ssh_public_keys"></a> [ssh\_public\_keys](#output\_ssh\_public\_keys) | The Azure SSH public key resources, keyed by name. Full resource objects (public material only). |
<!-- END_TF_DOCS -->
