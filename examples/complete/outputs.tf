output "ids" {
  description = "Map of key name to Azure SSH public key resource id."
  value       = module.ssh_key.ids
}

output "ids_zipmap" {
  description = "Map of key name to { name, id }."
  value       = module.ssh_key.ids_zipmap
}

output "public_keys_openssh" {
  description = "Map of key name to the OpenSSH public key text."
  value       = module.ssh_key.public_keys_openssh
}

output "public_key_fingerprints_sha256" {
  description = "Map of generated key name to the SHA256 fingerprint."
  value       = module.ssh_key.public_key_fingerprints_sha256
}

output "private_key_secret_ids" {
  description = "Map of key name to the vaulted private key secret id (no value; write-only)."
  value       = module.ssh_key.private_key_secret_ids
}

output "private_key_secret_versionless_ids" {
  description = "Map of key name to the vaulted private key secret's versionless id."
  value       = module.ssh_key.private_key_secret_versionless_ids
}
