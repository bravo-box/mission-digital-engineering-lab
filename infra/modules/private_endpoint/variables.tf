variable "name" {
  description = "Name of the private endpoint."
  type        = string
}

variable "location" {
  description = "Azure region of the private endpoint."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group hosting the private endpoint."
  type        = string
}

variable "subnet_id" {
  description = "Subnet the private endpoint NIC is placed in."
  type        = string
}

variable "private_connection_resource_id" {
  description = "Resource ID of the service the private endpoint connects to."
  type        = string
}

variable "subresource_names" {
  description = "Target sub-resources, for example [\"blob\"] or [\"vault\"]."
  type        = list(string)
}

variable "private_dns_zone_ids" {
  description = "Private DNS zones the endpoint registers A records in."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to the private endpoint."
  type        = map(string)
  default     = {}
}
