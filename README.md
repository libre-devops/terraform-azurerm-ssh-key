```hcl
###############################################
# Generate private keys (optional)                         #
############################################################
resource "tls_private_key" "ssh_key" {
  for_each = {
    for k in var.ssh_keys : k.name => k
    if k.create_private_key
  }

  algorithm = each.value.private_key_algorithm
}

############################################################
# Azure SSH public-key resources (optional)                 #
############################################################
resource "azurerm_ssh_public_key" "ssh_key" {
  for_each = {
    for k in var.ssh_keys : k.name => k
    if k.create_public_key
  }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  # Use generated key when we created one, otherwise the supplied value
  public_key = each.value.create_private_key ? tls_private_key.ssh_key[each.key].public_key_openssh : each.value.provided_public_key
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_ssh_public_key.ssh_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ssh_public_key) | resource |
| [tls_private_key.ssh_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for azurerm\_ssh\_public\_key resources | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | Name of the Azure Resource Group that will hold azurerm\_ssh\_public\_key resources | `string` | n/a | yes |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | List of SSH-key definitions.<br/><br/>Required per-item fields<br/>  * name                ΓÇô Friendly/unique key name (also Azure resource name)<br/>  * create\_private\_key  ΓÇô true \| false<br/>  * create\_public\_key   ΓÇô true \| false<br/><br/>Optional per-item fields<br/>  * private\_key\_algorithm ΓÇô tls algorithm ("RSA", "ED25519", ΓÇª). Default = "RSA".<br/>  * provided\_public\_key   ΓÇô Required **only** when create\_public\_key = true<br/>                             and create\_private\_key = false. | <pre>list(object({<br/>    name                  = string<br/>    create_private_key    = optional(bool, true)<br/>    create_public_key     = optional(bool, true)<br/>    private_key_algorithm = optional(string, "ED25519")<br/>    provided_public_key   = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to azurerm\_ssh\_public\_key resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_key_algorithms"></a> [private\_key\_algorithms](#output\_private\_key\_algorithms) | Algorithm used for each generated key (e.g. RSA, ED25519) |
| <a name="output_private_key_ecdsa_curves"></a> [private\_key\_ecdsa\_curves](#output\_private\_key\_ecdsa\_curves) | ECDSA curve (only set when algorithm is ECDSA) |
| <a name="output_private_key_resource_ids"></a> [private\_key\_resource\_ids](#output\_private\_key\_resource\_ids) | Terraform resource IDs for each tls\_private\_key instance |
| <a name="output_private_key_rsa_bits"></a> [private\_key\_rsa\_bits](#output\_private\_key\_rsa\_bits) | RSA key length (only set when algorithm is RSA) |
| <a name="output_private_keys_openssh"></a> [private\_keys\_openssh](#output\_private\_keys\_openssh) | OpenSSH-formatted private keys (sensitive), keyed by SSH-key name |
| <a name="output_private_keys_pem"></a> [private\_keys\_pem](#output\_private\_keys\_pem) | PEM-encoded private keys (sensitive), keyed by SSH-key name |
| <a name="output_private_keys_pem_pkcs8"></a> [private\_keys\_pem\_pkcs8](#output\_private\_keys\_pem\_pkcs8) | PKCS#8-formatted private keys (sensitive), keyed by SSH-key name |
| <a name="output_public_key_fingerprint_md5"></a> [public\_key\_fingerprint\_md5](#output\_public\_key\_fingerprint\_md5) | MD5 fingerprints of generated public keys, keyed by SSH-key name |
| <a name="output_public_key_fingerprint_sha256"></a> [public\_key\_fingerprint\_sha256](#output\_public\_key\_fingerprint\_sha256) | SHA-256 fingerprints of generated public keys, keyed by SSH-key name |
| <a name="output_public_keys_openssh"></a> [public\_keys\_openssh](#output\_public\_keys\_openssh) | OpenSSH public keys, keyed by SSH-key name |
| <a name="output_public_keys_pem"></a> [public\_keys\_pem](#output\_public\_keys\_pem) | PEM-encoded public keys, keyed by SSH-key name |
| <a name="output_ssh_public_key_ids"></a> [ssh\_public\_key\_ids](#output\_ssh\_public\_key\_ids) | azurerm\_ssh\_public\_key IDs, keyed by SSH-key name |
| <a name="output_ssh_public_key_names"></a> [ssh\_public\_key\_names](#output\_ssh\_public\_key\_names) | azurerm\_ssh\_public\_key resource names, keyed by SSH-key name |
| <a name="output_ssh_public_key_texts"></a> [ssh\_public\_key\_texts](#output\_ssh\_public\_key\_texts) | OpenSSH public-key text, keyed by SSH-key name |
