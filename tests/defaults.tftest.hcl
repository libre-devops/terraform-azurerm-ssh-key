# Tests for the module. azurerm is mocked (no credentials, no cloud); the tls provider runs for real
# so key generation is exercised. command = apply is used so the write-only vault path executes:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  location          = "uksouth"
  tags              = { Environment = "tst" }
  key_vault_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.KeyVault/vaults/kv-ldo-uks-tst-001"
}

# The secure default: a generated key lands as an Azure resource plus a write-only vault secret.
run "generated_key_defaults" {
  command = apply

  variables {
    ssh_keys = {
      ssh_app_key = {}
    }
  }

  assert {
    condition     = startswith(azurerm_ssh_public_key.this["ssh_app_key"].public_key, "ssh-rsa ")
    error_message = "The generated public key should be ssh-rsa (the only format Azure accepts)."
  }

  assert {
    condition     = tls_private_key.this["ssh_app_key"].rsa_bits == 4096
    error_message = "Generated keys should default to RSA 4096."
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["ssh_app_key"].name == "ssh-app-key"
    error_message = "The secret name should default to the key name with underscores dashed (vault names forbid underscores)."
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["ssh_app_key"].value_wo_version == 1
    error_message = "value_wo_version should default to 1."
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["ssh_app_key"].content_type == "application/x-pem-file"
    error_message = "The secret content type should default to the PEM media type."
  }

  assert {
    condition     = azurerm_ssh_public_key.this["ssh_app_key"].tags["Environment"] == "tst"
    error_message = "Module tags should apply to the Azure resource."
  }
}

# Bring your own: only the Azure resource exists, no key pair and no secret.
run "byo_public_key" {
  command = apply

  variables {
    ssh_keys = {
      byo-key = {
        public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtbmPhzCR+ZpI/Y4H1IvPEI+tvGT4R5ReLtj5QZVcRXJiRdIbYsb6sjaYu8JcR6vzSHAlJcx0zmcSP4SR7HqtuXbODv+OvVpBCoil9LWbCfOgOQ6XZ3oSFYe8lFllbFLiM7I+ok+s7Cygnu58fil7pDdBFrS7DZRjvT87RrOX0dp2LDNNN7LYFy5nwHvkBv9z36q9RFGcP4e0XDNtU0+LGnolz4oDWkJt/0POaHIxnJJX7ge0r0bReZq/t1XRr/RrhPYk6gkWsSkfbwwxGPA2UdxFRDVn2aMx6Hz8gQfcHRS2kEvKRMIgQfBOmB6OInLCLaUZRWm5YdEBZXwtdREor example"
      }
    }
  }

  assert {
    condition     = length(tls_private_key.this) == 0 && length(azurerm_key_vault_secret.private_key) == 0
    error_message = "A bring-your-own key should create no key pair and no secret."
  }

  assert {
    condition     = length(azurerm_ssh_public_key.this) == 1
    error_message = "The Azure SSH public key resource should be created."
  }
}

# Generated key with the vault storage options exercised.
run "secret_options" {
  command = apply

  variables {
    ssh_keys = {
      rotated = {
        rsa_bits               = 2048
        secret_name            = "ssh-rotated-custom"
        secret_format          = "openssh"
        secret_content_type    = "text/plain"
        secret_expiration_date = "2027-01-01T00:00:00Z"
        value_wo_version       = 2
      }
    }
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["rotated"].name == "ssh-rotated-custom"
    error_message = "An explicit secret_name should be used."
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["rotated"].value_wo_version == 2
    error_message = "A custom value_wo_version should pass through."
  }
}

# Generating without a vault fails the plan via the precondition (secure by default).
run "rejects_generated_without_vault" {
  command = plan

  variables {
    key_vault_id = null
    ssh_keys = {
      stateonly = {}
    }
  }

  expect_failures = [azurerm_key_vault_secret.private_key]
}

# Explicitly opting out of vault storage is allowed but flagged by the check.
run "flags_unvaulted_generated_key" {
  command = plan

  variables {
    key_vault_id = null
    ssh_keys = {
      stateonly = { store_private_key_in_key_vault = false }
    }
  }

  expect_failures = [check.generated_keys_are_vaulted]
}

# Weak RSA sizes are rejected by variable validation.
run "rejects_weak_rsa" {
  command = plan

  variables {
    ssh_keys = {
      weak = { rsa_bits = 1024 }
    }
  }

  expect_failures = [var.ssh_keys]
}
