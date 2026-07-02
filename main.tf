locals {
  rg      = provider::azurerm::parse_resource_id(var.resource_group_id)
  rg_name = local.rg.resource_group_name

  # Entries without a supplied public key get a generated pair. Gating is on input attributes only,
  # so the for_each keys stay known at plan time.
  generated = { for k, v in var.ssh_keys : k => v if v.public_key == null }

  # Generated keys whose private half is written to the vault (the secure default; opting out is
  # flagged by a check).
  stored = { for k, v in local.generated : k => v if v.store_private_key_in_key_vault }
}

# Key pairs for the generated entries. Azure's SSH public key resource only accepts ssh-rsa (at least
# 2048-bit), so the algorithm is fixed to RSA and only the size is configurable. NOTE: this resource
# keeps the key material in Terraform state; that is inherent to deriving the public key from a
# managed key pair. The write-only vault secret below keeps the SECRET resource clean, and the module
# exports no private key material.
resource "tls_private_key" "this" {
  for_each = local.generated

  algorithm = "RSA"
  rsa_bits  = each.value.rsa_bits
}

resource "azurerm_ssh_public_key" "this" {
  for_each = var.ssh_keys

  resource_group_name = local.rg_name
  location            = var.location
  tags                = merge(var.tags, coalesce(each.value.tags, {}))
  name                = each.key

  public_key = each.value.public_key != null ? each.value.public_key : tls_private_key.this[each.key].public_key_openssh
}

# The helper: generated private keys land in the vault through value_wo (write-only, never stored in
# this resource's state or shown in the plan). Bump value_wo_version alongside a key replacement to
# rotate the stored secret.
resource "azurerm_key_vault_secret" "private_key" {
  for_each = local.stored

  key_vault_id = var.key_vault_id
  tags         = merge(var.tags, coalesce(each.value.tags, {}))
  name         = coalesce(each.value.secret_name, replace(each.key, "_", "-"))

  value_wo = (
    each.value.secret_format == "openssh" ? tls_private_key.this[each.key].private_key_openssh :
    each.value.secret_format == "pkcs8" ? tls_private_key.this[each.key].private_key_pem_pkcs8 :
    tls_private_key.this[each.key].private_key_pem
  )
  value_wo_version = each.value.value_wo_version

  content_type    = each.value.secret_content_type
  expiration_date = each.value.secret_expiration_date
  not_before_date = each.value.secret_not_before_date

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "ssh_keys \"${each.key}\" stores its generated private key in a key vault by default: set key_vault_id, or opt out explicitly with store_private_key_in_key_vault = false."
    }
  }
}
