locals {
  rg      = provider::azurerm::parse_resource_id(var.resource_group_id)
  rg_name = local.rg.resource_group_name

  # Entries without a supplied public key get a generated pair. Gating is on input attributes only,
  # so the for_each keys stay known at plan time.
  generated = { for k, v in var.ssh_keys : k => v if v.public_key == null }

  private_secret_names = { for k, v in local.generated : k => coalesce(v.secret_name, replace(k, "_", "-")) }
  public_secret_names  = { for k, v in local.generated : k => coalesce(v.public_secret_name, "${local.private_secret_names[k]}-pub") }
}

# Ephemeral generation: the key pair is created during the run and NEVER stored in plan or state.
# Both halves are written to the vault write-only below; the public half is then read back (public
# material, safe to persist) to feed the Azure resource. Azure's SSH public key resource only accepts
# ssh-rsa at 2048-bit or larger, so the algorithm is fixed to RSA and only the size is configurable.
#
# An ephemeral resource regenerates every run, but value_wo is only sent when value_wo_version
# changes, so the vault content is stable until you bump the version, which rotates the whole pair
# (both halves are written from the same ephemeral instance, so they always match).
ephemeral "tls_private_key" "this" {
  for_each = local.generated

  algorithm = "RSA"
  rsa_bits  = each.value.rsa_bits
}

# The private half: write-only into the vault, never in state, never in the plan.
resource "azurerm_key_vault_secret" "private_key" {
  for_each = local.generated

  key_vault_id = var.key_vault_id
  tags         = merge(var.tags, coalesce(each.value.tags, {}))
  name         = local.private_secret_names[each.key]

  value_wo = (
    each.value.secret_format == "openssh" ? ephemeral.tls_private_key.this[each.key].private_key_openssh :
    each.value.secret_format == "pkcs8" ? ephemeral.tls_private_key.this[each.key].private_key_pem_pkcs8 :
    ephemeral.tls_private_key.this[each.key].private_key_pem
  )
  value_wo_version = each.value.value_wo_version

  content_type    = each.value.secret_content_type
  expiration_date = each.value.secret_expiration_date
  not_before_date = each.value.secret_not_before_date

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "ssh_keys \"${each.key}\" is generated, and generated key material lives in a key vault: set key_vault_id (or bring your own public_key)."
    }
  }
}

# The public half: also written write-only, purely as the state-free bridge to the Azure resource.
resource "azurerm_key_vault_secret" "public_key" {
  for_each = local.generated

  key_vault_id = var.key_vault_id
  tags         = merge(var.tags, coalesce(each.value.tags, {}))
  name         = local.public_secret_names[each.key]

  value_wo         = ephemeral.tls_private_key.this[each.key].public_key_openssh
  value_wo_version = each.value.value_wo_version

  content_type = "text/plain"

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "ssh_keys \"${each.key}\" is generated, and generated key material lives in a key vault: set key_vault_id (or bring your own public_key)."
    }
  }
}

# Read the public half back as a persisted value (an ephemeral value cannot feed a persisted argument,
# and the public key is public material, so persisting it is harmless).
data "azurerm_key_vault_secret" "public_key" {
  for_each = local.generated

  key_vault_id = var.key_vault_id
  name         = local.public_secret_names[each.key]

  depends_on = [azurerm_key_vault_secret.public_key]

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "ssh_keys \"${each.key}\" is generated, and generated key material lives in a key vault: set key_vault_id (or bring your own public_key)."
    }
  }
}

resource "azurerm_ssh_public_key" "this" {
  for_each = var.ssh_keys

  resource_group_name = local.rg_name
  location            = var.location
  tags                = merge(var.tags, coalesce(each.value.tags, {}))
  name                = each.key

  # nonsensitive() is deliberate: the data source marks every secret value sensitive, but this half is
  # the PUBLIC key, and leaving the taint would force sensitive outputs across the module.
  public_key = each.value.public_key != null ? each.value.public_key : nonsensitive(trimspace(data.azurerm_key_vault_secret.public_key[each.key].value))
}
