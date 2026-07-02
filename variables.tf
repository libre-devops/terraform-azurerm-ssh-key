variable "resource_group_id" {
  description = "Resource id of the resource group to create the SSH public key resources in. The name is parsed from it (pass the rg module's ids output)."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group id of the form /subscriptions/<sub>/resourceGroups/<name>."
  }
}

variable "location" {
  description = "Azure region for the SSH public key resources."
  type        = string
}

variable "tags" {
  description = "Tags applied to every SSH public key resource (merged with any per-key tags)."
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "The Key Vault generated key material lives in: both halves are written as write-only secrets, and the public half is read back to feed the Azure resource. Required when any key is generated (bring-your-own keys need no vault)."
  type        = string
  default     = null
}

variable "ssh_keys" {
  description = <<DESC
The SSH keys to manage, keyed by the Azure SSH public key resource name. Two modes per entry:

- Bring your own: set public_key (ssh-rsa, at least 2048-bit, per the Azure resource's contract) and
  only the Azure public key resource is created; no private key exists anywhere.
- Generate (when public_key is null, the default): the key pair is generated EPHEMERALLY (never in
  plan or state) and both halves are written into key_vault_id through the provider's write-only
  value_wo argument; the public half is read back (public material, safe to persist) to create the
  Azure public key resource. Azure only accepts ssh-rsa public keys, so the algorithm is fixed and
  only rsa_bits varies (default 4096). Rotation is one knob: bump value_wo_version and a freshly
  generated pair replaces both secrets and the Azure resource's key. The module deliberately exports
  NO private key material.

Generated-key attributes: rsa_bits; secret_name (defaults to the key name with underscores dashed,
since vault secret names forbid underscores); public_secret_name (defaults to the private name with a
-pub suffix); secret_format for the private half (pem, openssh, or pkcs8; default pem);
secret_content_type; secret_expiration_date / secret_not_before_date; value_wo_version (bump to
rotate the pair). tags merge over the module tags on the Azure resource and the secrets.
DESC

  type = map(object({
    public_key = optional(string)
    rsa_bits   = optional(number, 4096)

    secret_name            = optional(string)
    public_secret_name     = optional(string)
    secret_format          = optional(string, "pem")
    secret_content_type    = optional(string, "application/x-pem-file")
    secret_expiration_date = optional(string)
    secret_not_before_date = optional(string)
    value_wo_version       = optional(number, 1)

    tags = optional(map(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for k in values(var.ssh_keys) : k.rsa_bits >= 2048])
    error_message = "rsa_bits must be at least 2048 (the Azure SSH public key resource rejects smaller keys)."
  }

  validation {
    condition     = alltrue([for k in values(var.ssh_keys) : contains(["pem", "openssh", "pkcs8"], k.secret_format)])
    error_message = "secret_format must be pem, openssh, or pkcs8."
  }

  validation {
    condition     = alltrue([for k in values(var.ssh_keys) : k.public_key == null || can(regex("^ssh-rsa ", coalesce(k.public_key, "ssh-rsa ")))])
    error_message = "A supplied public_key must be in ssh-rsa format (the Azure SSH public key resource only accepts ssh-rsa, at least 2048-bit)."
  }

  validation {
    condition     = alltrue([for k in values(var.ssh_keys) : k.value_wo_version >= 1])
    error_message = "value_wo_version must be a positive integer (start at 1 and increment to rotate)."
  }
}
