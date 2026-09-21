variable "name_prefix" {
  description = "Prefix applied to key vault resource names."
  type        = string
}

variable "suffix" {
  description = "Random suffix used to make the key vault name unique."
  type        = string
}

variable "location" {
  description = "Azure region for key vault resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for key vault resources."
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID used by the key vault."
  type        = string
}

variable "current_principal_id" {
  description = "Object ID of the principal running Terraform."
  type        = string
}

variable "admin_object_ids" {
  description = "Additional object IDs granted Key Vault Administrator."
  type        = list(string)
}

variable "subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Resource ID of the key vault private DNS zone."
  type        = string
}

variable "tags" {
  description = "Tags applied to key vault resources."
  type        = map(string)
  default     = {}
}
