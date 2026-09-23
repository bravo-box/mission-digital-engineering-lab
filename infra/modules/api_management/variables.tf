variable "name_prefix" {
  description = "Prefix applied to API Management resource names."
  type        = string
}

variable "suffix" {
  description = "Random suffix used to keep resource names unique."
  type        = string
}

variable "location" {
  description = "Azure region for API Management."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for API Management."
  type        = string
}

variable "subnet_id" {
  description = "Subnet used for API Management VNet injection."
  type        = string
}

variable "sku_name" {
  description = "VNet-capable API Management SKU."
  type        = string
}

variable "publisher_name" {
  description = "Publisher name displayed by API Management."
  type        = string
}

variable "publisher_email" {
  description = "Publisher email used by API Management."
  type        = string
}

variable "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  type        = string
}

variable "foundry_endpoint" {
  description = "Endpoint of the Foundry account."
  type        = string
}

variable "private_dns_zone_name" {
  description = "Private DNS zone used for API Management service hostnames."
  type        = string
}

variable "managed_identity_audience" {
  description = "Cognitive Services token audience for the target Azure cloud."
  type        = string
}

variable "tags" {
  description = "Tags applied to API Management resources."
  type        = map(string)
  default     = {}
}
