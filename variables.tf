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
  description = "The Key Vault generated private keys are written into (as write-only secrets, never stored in the secret resource's state). Required unless every generated key opts out with store_private_key_in_key_vault = false."
  type        = string
  default     = null
}

variable "ssh_keys" {
  description = <<DESC
The SSH keys to manage, keyed by the Azure SSH public key resource name. Two modes per entry:

- Bring your own: set public_key (ssh-rsa, at least 2048-bit, per the Azure resource's contract) and
  only the Azure public key resource is created; no private key exists anywhere.
- Generate (when public_key is null, the default): the module generates an RSA key pair (Azure only
  accepts ssh-rsa public keys, so the algorithm is fixed; size via rsa_bits, default 4096), creates
  the Azure public key resource, and BY DEFAULT writes the private key into key_vault_id through the
  provider's write-only value_wo argument, so the secret resource never stores it. NOTE the honest
  caveat: the tls_private_key resource itself keeps the key material in Terraform state (that is what
  makes deriving the public key possible); protect the state, or bring your own public key for a
  state-free result. The module deliberately exports NO private key material.

Generated-key attributes: rsa_bits; store_private_key_in_key_vault (default true; opting out leaves
the private key ONLY in state, which a check flags); secret_name (defaults to the key name with
underscores dashed, since vault secret names forbid underscores); secret_format (pem, openssh, or
pkcs8; default pem); secret_content_type; secret_expiration_date / secret_not_before_date;
value_wo_version (bump alongside key replacement to rotate the stored secret). tags merge over the
module tags on the Azure resource and the secret.
DESC

  type = map(object({
    public_key = optional(string)
    rsa_bits   = optional(number, 4096)

    store_private_key_in_key_vault = optional(bool, true)
    secret_name                    = optional(string)
    secret_format                  = optional(string, "pem")
    secret_content_type            = optional(string, "application/x-pem-file")
    secret_expiration_date         = optional(string)
    secret_not_before_date         = optional(string)
    value_wo_version               = optional(number, 1)

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
