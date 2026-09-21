variable "name_prefix" {
  description = "Prefix applied to AKS resource names."
  type        = string
}

variable "suffix" {
  description = "Random suffix used to make the cluster name unique."
  type        = string
}

variable "location" {
  description = "Azure region for AKS resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for AKS resources."
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID used by AKS Entra ID integration."
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the AKS subnet."
  type        = string
}

variable "container_registry_id" {
  description = "Resource ID of the container registry."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Null uses the AKS default."
  type        = string
  default     = null
}

variable "system_node_count" {
  description = "Number of nodes in the system node pool."
  type        = number
}

variable "system_node_size" {
  description = "VM size for the system node pool."
  type        = string
}

variable "service_cidr" {
  description = "Service CIDR for the cluster."
  type        = string
}

variable "dns_service_ip" {
  description = "DNS service IP inside the service CIDR."
  type        = string
}

variable "outbound_type" {
  description = "Egress model for the cluster."
  type        = string
}

variable "pod_cidr" {
  description = "Pod CIDR for Azure CNI overlay."
  type        = string
}

variable "admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster admin."
  type        = list(string)
}

variable "local_account_disabled" {
  description = "Whether the local AKS admin account is disabled."
  type        = bool
}

variable "matlab_node_count" {
  description = "Initial node count of the MATLAB worker pool."
  type        = number
}

variable "matlab_node_size" {
  description = "VM size of the MATLAB worker pool."
  type        = string
}

variable "tags" {
  description = "Tags applied to AKS resources."
  type        = map(string)
  default     = {}
}
