variable "name_prefix" {
  description = "Prefix applied to Foundry resource names."
  type        = string
}

variable "suffix" {
  description = "Random suffix used to make the Foundry account name unique."
  type        = string
}

variable "location" {
  description = "Azure region for Foundry resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for Foundry resources."
  type        = string
}

variable "sku" {
  description = "SKU for the Foundry account."
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  type        = string
}

variable "private_dns_zone_ids" {
  description = "Resource IDs of the Foundry private DNS zones."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to Foundry resources."
  type        = map(string)
  default     = {}
}
