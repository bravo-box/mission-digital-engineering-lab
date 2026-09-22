locals {
  subnet_names = {
    matlab_vms     = "matlab-vms"
    matlab_cluster = "matlab-cluster"
    storage        = "storage"
    registry       = "registry"
    foundry        = "foundry"
    key_vault      = "key-vault"
  }

  private_endpoint_subnets = ["matlab_cluster", "storage", "registry", "foundry", "key_vault"]
}

data "azurerm_virtual_network" "lab" {
  name                = var.virtual_network_name
  resource_group_name = var.virtual_network_resource_group_name
}

resource "azurerm_subnet" "lab" {
  for_each = local.subnet_names

  name                 = each.value
  resource_group_name  = data.azurerm_virtual_network.lab.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.lab.name
  address_prefixes     = [var.subnet_address_prefixes[each.key]]

  private_endpoint_network_policies = contains(local.private_endpoint_subnets, each.key) ? "Disabled" : "Enabled"
}

resource "azurerm_network_security_group" "lab" {
  for_each = local.subnet_names

  name                = "nsg-${var.name_prefix}-${each.value}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowVnetInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyInternetInBound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "lab" {
  for_each = azurerm_subnet.lab

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.lab[each.key].id
}

resource "azurerm_subnet" "bastion" {
  count = var.deploy_bastion ? 1 : 0

  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_virtual_network.lab.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.lab.name
  address_prefixes     = [var.bastion_subnet_address_prefix]
}

resource "azurerm_public_ip" "bastion" {
  count = var.deploy_bastion ? 1 : 0

  name                = "pip-${var.name_prefix}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "lab" {
  count = var.deploy_bastion ? 1 : 0

  name                = "bas-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku
  tunneling_enabled   = var.bastion_sku == "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}
