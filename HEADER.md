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
