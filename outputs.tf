# No private key material is ever exported. The old module's sensitive private-key outputs are gone
# deliberately: generated private keys go to the key vault (write-only), and everything here is
# public material, metadata, and ids.

output "ssh_public_keys" {
  description = "The Azure SSH public key resources, keyed by name. Full resource objects (public material only)."
  value       = azurerm_ssh_public_key.this
}

output "ids" {
  description = "Map of key name to Azure SSH public key resource id."
  value       = { for k, r in azurerm_ssh_public_key.this : k => r.id }
}

output "ids_zipmap" {
  description = "Map of key name to { name, id }, for easy composition with other modules."
  value       = { for k, r in azurerm_ssh_public_key.this : k => { name = r.name, id = r.id } }
}

output "names" {
  description = "Map of key name to name (convenience passthrough)."
  value       = { for k, r in azurerm_ssh_public_key.this : k => r.name }
}

output "public_keys_openssh" {
  description = "Map of key name to the OpenSSH public key text (what a VM's admin_ssh_key consumes)."
  value       = { for k, r in azurerm_ssh_public_key.this : k => r.public_key }
}

output "public_key_fingerprints_sha256" {
  description = "Map of GENERATED key name to the SHA256 public key fingerprint."
  value       = { for k, r in tls_private_key.this : k => r.public_key_fingerprint_sha256 }
}

output "public_key_fingerprints_md5" {
  description = "Map of GENERATED key name to the MD5 public key fingerprint."
  value       = { for k, r in tls_private_key.this : k => r.public_key_fingerprint_md5 }
}

output "private_key_secret_ids" {
  description = "Map of key name to the vaulted private key secret's versioned id (generated, vault-stored keys only)."
  value       = { for k, s in azurerm_key_vault_secret.private_key : k => s.id }
}

output "private_key_secret_versionless_ids" {
  description = "Map of key name to the vaulted private key secret's versionless id (always resolves to the latest version)."
  value       = { for k, s in azurerm_key_vault_secret.private_key : k => s.versionless_id }
}

output "resource_group_name" {
  description = "The resource group the SSH public keys live in, parsed from resource_group_id."
  value       = local.rg_name
}
