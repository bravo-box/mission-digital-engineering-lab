variable "name_prefix" {
  description = "Prefix applied to registry resource names."
  type        = string
}

variable "suffix" {
  description = "Random suffix used to make the registry name unique."
  type        = string
}

variable "location" {
  description = "Azure region for registry resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for registry resources."
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Resource ID of the registry private DNS zone."
  type        = string
}

variable "tags" {
  description = "Tags applied to registry resources."
  type        = map(string)
  default     = {}
}
