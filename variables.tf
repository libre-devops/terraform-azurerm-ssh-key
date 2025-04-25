variable "location" {
  description = "Azure region for azurerm_ssh_public_key resources"
  type        = string
}

variable "rg_name" {
  description = "Name of the Azure Resource Group that will hold azurerm_ssh_public_key resources"
  type        = string
}

variable "ssh_keys" {
  description = <<EOT
List of SSH-key definitions.

Required per-item fields
  * name                – Friendly/unique key name (also Azure resource name)
  * create_private_key  – true | false
  * create_public_key   – true | false

Optional per-item fields
  * private_key_algorithm – tls algorithm ("RSA", "ED25519", …). Default = "RSA".
  * provided_public_key   – Required **only** when create_public_key = true
                             and create_private_key = false.
EOT

  type = list(object({
    name                  = string
    create_private_key    = optional(bool, true)
    create_public_key     = optional(bool, true)
    private_key_algorithm = optional(string, "ED25519")
    provided_public_key   = optional(string)
  }))
}

variable "tags" {
  description = "Tags applied to azurerm_ssh_public_key resources"
  type        = map(string)
  default     = {}
}
