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
