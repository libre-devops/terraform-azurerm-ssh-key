# Tests for the module. azurerm is mocked (no credentials, no cloud); the tls provider runs for real
# so ephemeral key generation is exercised. command = apply is used so the ephemeral resource opens
# and the write-only vault path executes:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {
  # The read-back data source must return a PARSEABLE ssh-rsa key: the Azure resource's provider-side
  # validation parses public_key, so the default random-string mock would fail it.
  mock_data "azurerm_key_vault_secret" {
    defaults = {
      value = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtbmPhzCR+ZpI/Y4H1IvPEI+tvGT4R5ReLtj5QZVcRXJiRdIbYsb6sjaYu8JcR6vzSHAlJcx0zmcSP4SR7HqtuXbODv+OvVpBCoil9LWbCfOgOQ6XZ3oSFYe8lFllbFLiM7I+ok+s7Cygnu58fil7pDdBFrS7DZRjvT87RrOX0dp2LDNNN7LYFy5nwHvkBv9z36q9RFGcP4e0XDNtU0+LGnolz4oDWkJt/0POaHIxnJJX7ge0r0bReZq/t1XRr/RrhPYk6gkWsSkfbwwxGPA2UdxFRDVn2aMx6Hz8gQfcHRS2kEvKRMIgQfBOmB6OInLCLaUZRWm5YdEBZXwtdREor example"
    }
  }
}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  location          = "uksouth"
  tags              = { Environment = "tst" }
  key_vault_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.KeyVault/vaults/kv-ldo-uks-tst-001"
}

# The secure default: an ephemerally generated key lands as two write-only vault secrets plus the
# Azure resource fed from the read-back public half. No tls resource exists in state at all.
run "generated_key_defaults" {
  command = apply

  variables {
    ssh_keys = {
      ssh_app_key = {}
    }
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["ssh_app_key"].name == "ssh-app-key"
    error_message = "The private secret name should default to the key name with underscores dashed."
  }

  assert {
    condition     = azurerm_key_vault_secret.public_key["ssh_app_key"].name == "ssh-app-key-pub"
    error_message = "The public secret name should default to the private name with a -pub suffix."
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["ssh_app_key"].value_wo_version == 1
    error_message = "value_wo_version should default to 1."
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["ssh_app_key"].content_type == "application/x-pem-file"
    error_message = "The private secret content type should default to the PEM media type."
  }

  assert {
    condition     = startswith(azurerm_ssh_public_key.this["ssh_app_key"].public_key, "ssh-rsa ")
    error_message = "The Azure resource should carry the public key read back from the vault."
  }

  assert {
    condition     = azurerm_ssh_public_key.this["ssh_app_key"].tags["Environment"] == "tst"
    error_message = "Module tags should apply to the Azure resource."
  }
}

# Bring your own: only the Azure resource exists, no secrets and no vault needed.
run "byo_public_key" {
  command = apply

  variables {
    key_vault_id = null
    ssh_keys = {
      byo-key = {
        public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtbmPhzCR+ZpI/Y4H1IvPEI+tvGT4R5ReLtj5QZVcRXJiRdIbYsb6sjaYu8JcR6vzSHAlJcx0zmcSP4SR7HqtuXbODv+OvVpBCoil9LWbCfOgOQ6XZ3oSFYe8lFllbFLiM7I+ok+s7Cygnu58fil7pDdBFrS7DZRjvT87RrOX0dp2LDNNN7LYFy5nwHvkBv9z36q9RFGcP4e0XDNtU0+LGnolz4oDWkJt/0POaHIxnJJX7ge0r0bReZq/t1XRr/RrhPYk6gkWsSkfbwwxGPA2UdxFRDVn2aMx6Hz8gQfcHRS2kEvKRMIgQfBOmB6OInLCLaUZRWm5YdEBZXwtdREor example"
      }
    }
  }

  assert {
    condition     = length(azurerm_key_vault_secret.private_key) == 0 && length(azurerm_key_vault_secret.public_key) == 0
    error_message = "A bring-your-own key should create no secrets."
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
    condition     = azurerm_key_vault_secret.public_key["rotated"].name == "ssh-rotated-custom-pub"
    error_message = "The public secret should follow the explicit private name."
  }

  assert {
    condition     = azurerm_key_vault_secret.private_key["rotated"].value_wo_version == 2 && azurerm_key_vault_secret.public_key["rotated"].value_wo_version == 2
    error_message = "The rotation version should apply to both halves."
  }
}

# Generating without a vault fails the plan: generated key material has nowhere safe to live.
run "rejects_generated_without_vault" {
  command = plan

  variables {
    key_vault_id = null
    ssh_keys = {
      nowhere = {}
    }
  }

  # The deferred data source never evaluates once the secrets' preconditions fail, so only the two
  # secret resources report.
  expect_failures = [
    azurerm_key_vault_secret.private_key,
    azurerm_key_vault_secret.public_key,
  ]
}

# ED25519 end to end: the provider's client-side public_key validation accepts ssh-ed25519 (BYO
# carries a real ed25519 key through the Azure resource), and generation accepts the algorithm.
run "ed25519_supported" {
  command = apply

  variables {
    ssh_keys = {
      byo-ed = {
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMYVf/be1JH06E7HqRjPvFq8uvTBtXqOtEhvONICACzt probe"
      }
      generated-ed = {
        algorithm = "ED25519"
      }
    }
  }

  assert {
    condition     = startswith(azurerm_ssh_public_key.this["byo-ed"].public_key, "ssh-ed25519 ")
    error_message = "A bring-your-own ed25519 key should pass the provider's public_key validation."
  }

  assert {
    condition     = length(azurerm_key_vault_secret.private_key) == 1 && azurerm_key_vault_secret.private_key["generated-ed"].name == "generated-ed"
    error_message = "The generated ed25519 key should land in the vault like any other."
  }
}

# An unknown algorithm is rejected by variable validation.
run "rejects_unknown_algorithm" {
  command = plan

  variables {
    ssh_keys = {
      dsa = { algorithm = "DSA" }
    }
  }

  expect_failures = [var.ssh_keys]
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
