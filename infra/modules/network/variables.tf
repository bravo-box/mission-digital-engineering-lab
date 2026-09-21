variable "name_prefix" {
  description = "Prefix applied to network resource names."
  type        = string
}

variable "location" {
  description = "Azure region for network resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for network resources."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the existing virtual network."
  type        = string
}

variable "virtual_network_resource_group_name" {
  description = "Resource group of the existing virtual network."
  type        = string
}

variable "subnet_address_prefixes" {
  description = "Address prefix for each lab subnet."
  type = object({
    matlab_vms     = string
    matlab_cluster = string
    storage        = string
    registry       = string
    foundry        = string
    key_vault      = string
  })
}

variable "deploy_bastion" {
  description = "Whether to deploy Azure Bastion."
  type        = bool
}

variable "bastion_subnet_address_prefix" {
  description = "Address prefix for AzureBastionSubnet."
  type        = string
}

variable "bastion_sku" {
  description = "Azure Bastion SKU."
  type        = string
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
