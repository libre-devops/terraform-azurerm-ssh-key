output "private_key_algorithms" {
  description = "Algorithm used for each generated key (e.g. RSA, ED25519)"
  value       = { for name, r in tls_private_key.ssh_key : name => r.algorithm }
}

output "private_key_ecdsa_curves" {
  description = "ECDSA curve (only set when algorithm is ECDSA)"
  value       = { for name, r in tls_private_key.ssh_key : name => r.ecdsa_curve }
}

output "private_key_resource_ids" {
  description = "Terraform resource IDs for each tls_private_key instance"
  value       = { for name, r in tls_private_key.ssh_key : name => r.id }
}

output "private_key_rsa_bits" {
  description = "RSA key length (only set when algorithm is RSA)"
  value       = { for name, r in tls_private_key.ssh_key : name => r.rsa_bits }
}

output "private_keys_openssh" {
  description = "OpenSSH-formatted private keys (sensitive), keyed by SSH-key name"
  sensitive   = true
  value       = { for name, r in tls_private_key.ssh_key : name => r.private_key_openssh }
}

output "private_keys_pem" {
  description = "PEM-encoded private keys (sensitive), keyed by SSH-key name"
  sensitive   = true
  value       = { for name, r in tls_private_key.ssh_key : name => r.private_key_pem }
}

output "private_keys_pem_pkcs8" {
  description = "PKCS#8-formatted private keys (sensitive), keyed by SSH-key name"
  sensitive   = true
  value       = { for name, r in tls_private_key.ssh_key : name => r.private_key_pem_pkcs8 }
}

output "public_key_fingerprint_md5" {
  description = "MD5 fingerprints of generated public keys, keyed by SSH-key name"
  value       = { for name, r in tls_private_key.ssh_key : name => r.public_key_fingerprint_md5 }
}

output "public_key_fingerprint_sha256" {
  description = "SHA-256 fingerprints of generated public keys, keyed by SSH-key name"
  value       = { for name, r in tls_private_key.ssh_key : name => r.public_key_fingerprint_sha256 }
}

output "public_keys_openssh" {
  description = "OpenSSH public keys, keyed by SSH-key name"
  value       = { for name, r in tls_private_key.ssh_key : name => r.public_key_openssh }
}

output "public_keys_pem" {
  description = "PEM-encoded public keys, keyed by SSH-key name"
  value       = { for name, r in tls_private_key.ssh_key : name => r.public_key_pem }
}

output "ssh_public_key_ids" {
  description = "azurerm_ssh_public_key IDs, keyed by SSH-key name"
  value       = { for k in azurerm_ssh_public_key.ssh_key : k.name => k.id }
}

output "ssh_public_key_names" {
  description = "azurerm_ssh_public_key resource names, keyed by SSH-key name"
  value       = { for k in azurerm_ssh_public_key.ssh_key : k.name => k.name }
}

output "ssh_public_key_texts" {
  description = "OpenSSH public-key text, keyed by SSH-key name"
  value       = { for k in azurerm_ssh_public_key.ssh_key : k.name => k.public_key }
}
