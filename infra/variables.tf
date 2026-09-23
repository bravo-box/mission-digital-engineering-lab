variable "azure_environment" {
  description = "Azure cloud to deploy into. Defaults to Azure Government."
  type        = string
  default     = "usgovernment"

  validation {
    condition     = contains(["public", "usgovernment", "china"], var.azure_environment)
    error_message = "azure_environment must be one of: public, usgovernment, china."
  }
}

variable "subscription_id" {
  description = "Subscription the lab is deployed into. Defaults to the subscription selected in the Azure CLI."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the lab resources (for example usgovvirginia)."
  type        = string
  default     = "usgovvirginia"
}

variable "name_prefix" {
  description = "Prefix applied to every resource name. Keep it short, lowercase and alphanumeric."
  type        = string
  default     = "delab"

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.name_prefix))
    error_message = "name_prefix must be 2-12 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Resource group that will hold the lab resources. Created by this configuration."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Existing virtual network
# ---------------------------------------------------------------------------

variable "virtual_network_name" {
  description = "Name of the existing virtual network the lab subnets are added to."
  type        = string
}

variable "virtual_network_resource_group_name" {
  description = "Resource group of the existing virtual network."
  type        = string
}

variable "subnet_address_prefixes" {
  description = "Address prefix for each lab subnet. Every prefix must sit inside the existing virtual network address space."
  type = object({
    matlab_vms     = string
    matlab_cluster = string
    storage        = string
    registry       = string
    foundry        = string
    key_vault      = string
    api_management = optional(string, "10.100.6.0/24")
  })

  default = {
    matlab_vms     = "10.100.1.0/24"
    matlab_cluster = "10.100.2.0/23"
    storage        = "10.100.4.0/26"
    registry       = "10.100.4.64/26"
    foundry        = "10.100.4.128/26"
    key_vault      = "10.100.4.192/26"
    api_management = "10.100.6.0/24"
  }
}

# ---------------------------------------------------------------------------
# Bastion
# ---------------------------------------------------------------------------

variable "deploy_bastion" {
  description = "Deploy Azure Bastion (and its AzureBastionSubnet) to reach the lab virtual machines."
  type        = bool
  default     = false
}

variable "bastion_subnet_address_prefix" {
  description = "Address prefix for AzureBastionSubnet. Required when deploy_bastion is true and must be /26 or larger."
  type        = string
  default     = "10.100.5.0/26"
}

variable "bastion_sku" {
  description = "Azure Bastion SKU. Basic or Standard."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "bastion_sku must be Basic or Standard."
  }
}

# ---------------------------------------------------------------------------
# Storage / registry / foundry
# ---------------------------------------------------------------------------

variable "storage_account_replication_type" {
  description = "Replication type for the lab data storage account."
  type        = string
  default     = "ZRS"
}

variable "foundry_sku" {
  description = "SKU for the Azure AI Foundry (AI Services) account."
  type        = string
  default     = "S0"
}

variable "api_management_sku" {
  description = "API Management SKU. Developer is intended for lab use; use Premium for production."
  type        = string
  default     = "Developer_1"

  validation {
    condition     = can(regex("^(Developer|Premium)_[1-9][0-9]*$", var.api_management_sku))
    error_message = "api_management_sku must use a VNet-capable Developer or Premium SKU, such as Developer_1 or Premium_1."
  }
}

variable "api_management_publisher_name" {
  description = "Publisher name displayed by API Management."
  type        = string
  default     = "Digital Engineering Lab"
}

variable "api_management_publisher_email" {
  description = "Publisher email used by API Management."
  type        = string
  default     = "admin@example.com"
}

variable "key_vault_admin_object_ids" {
  description = "Additional Entra ID object IDs granted Key Vault Administrator on the lab key vault."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# AKS
# ---------------------------------------------------------------------------

variable "aks_kubernetes_version" {
  description = "Kubernetes version for the MATLAB parallel server cluster. Null keeps the AKS default."
  type        = string
  default     = null
}

variable "aks_system_node_count" {
  description = "Number of nodes in the AKS system node pool."
  type        = number
  default     = 2
}

variable "aks_system_node_size" {
  description = "VM size for the AKS system node pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "aks_service_cidr" {
  description = "Service CIDR for the AKS cluster. Must not overlap the virtual network address space."
  type        = string
  default     = "172.16.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "DNS service IP for the AKS cluster. Must sit inside aks_service_cidr."
  type        = string
  default     = "172.16.0.10"
}

variable "aks_outbound_type" {
  description = "Egress model for the AKS cluster. Use userDefinedRouting when egress is forced through a firewall."
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.aks_outbound_type)
    error_message = "aks_outbound_type must be loadBalancer or userDefinedRouting."
  }
}

variable "aks_pod_cidr" {
  description = "Pod CIDR used by the Azure CNI overlay network."
  type        = string
  default     = "10.244.0.0/16"
}

variable "aks_admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster admin through Azure AD integration."
  type        = list(string)
  default     = []
}

variable "aks_local_account_disabled" {
  description = "Disable the local AKS admin account so only Entra ID identities can authenticate."
  type        = bool
  default     = true
}

variable "aks_matlab_node_count" {
  description = "Initial node count of the MATLAB worker node pool."
  type        = number
  default     = 2
}

variable "aks_matlab_node_size" {
  description = "VM size of the MATLAB worker node pool."
  type        = string
  default     = "Standard_D8s_v5"
}
