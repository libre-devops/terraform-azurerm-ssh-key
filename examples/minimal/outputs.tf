output "ids" {
  description = "Map of key name to Azure SSH public key resource id."
  value       = module.ssh_key.ids
}

output "public_keys_openssh" {
  description = "Map of key name to the OpenSSH public key text."
  value       = module.ssh_key.public_keys_openssh
}
