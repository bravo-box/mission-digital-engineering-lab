variable "name_prefix" {
  description = "Prefix applied to storage resource names."
  type        = string
}

variable "suffix" {
  description = "Random suffix used to make the storage account name unique."
  type        = string
}

variable "location" {
  description = "Azure region for storage resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for storage resources."
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  type        = string
}

variable "replication_type" {
  description = "Storage account replication type."
  type        = string
}

variable "blob_private_dns_zone_id" {
  description = "Resource ID of the blob private DNS zone."
  type        = string
}

variable "dfs_private_dns_zone_id" {
  description = "Resource ID of the DFS private DNS zone."
  type        = string
}

variable "tags" {
  description = "Tags applied to storage resources."
  type        = map(string)
  default     = {}
}
