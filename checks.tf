# check blocks run after every plan and apply and warn (without blocking) on configuration that would
# quietly weaken the module's posture.

# The module does nothing without at least one key.
check "creates_at_least_one_key" {
  assert {
    condition     = length(var.ssh_keys) > 0
    error_message = "No SSH keys would be created: set ssh_keys."
  }
}

# A generated key that opts out of vault storage leaves its private half ONLY in Terraform state.
check "generated_keys_are_vaulted" {
  assert {
    condition     = alltrue([for k, v in local.generated : v.store_private_key_in_key_vault])
    error_message = "These generated keys opt out of key vault storage, so their private keys live only in Terraform state: ${join(", ", sort([for k, v in local.generated : k if !v.store_private_key_in_key_vault]))}. Protect the state, or store them in a vault."
  }
}

# Vault storage flags on bring-your-own keys are inert (there is no private key to store).
check "byo_keys_have_nothing_to_store" {
  assert {
    condition     = alltrue([for k, v in var.ssh_keys : v.public_key == null || v.secret_name == null])
    error_message = "These bring-your-own keys set secret_name, but no private key exists to store for a supplied public key: ${join(", ", sort([for k, v in var.ssh_keys : k if v.public_key != null && v.secret_name != null]))}."
  }
}
