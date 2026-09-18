packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2.0"
    }
  }
}

variable "cloud_environment_name" {
  type        = string
  default     = "Usgovernment"
  description = "Azure cloud to build in (Public, Usgovernment, China)."
}

variable "subscription_id" {
  type        = string
  default     = ""
  description = "Subscription used for the build. Empty uses the Azure CLI subscription."
}

variable "build_resource_group_name" {
  type        = string
  default     = "rg-delab-packer"
  description = "Existing resource group created by scripts/create-packer-rg.sh."
}

variable "location" {
  type        = string
  default     = "usgovvirginia"
  description = "Region used for the build. Only used when build_resource_group_name is empty."
}

variable "managed_image_resource_group_name" {
  type        = string
  default     = ""
  description = "Resource group the managed image is published to. Defaults to build_resource_group_name."
}

variable "vm_size" {
  type        = string
  default     = "Standard_D8s_v5"
  description = "Size of the temporary build virtual machine."
}

variable "image_name" {
  type        = string
  default     = "matlab-dev-ubuntu2204"
  description = "Name of the managed image or gallery image definition."
}

variable "gallery_name" {
  type        = string
  default     = ""
  description = "Azure Compute Gallery to publish to. Empty publishes a managed image instead."
}

variable "gallery_resource_group_name" {
  type        = string
  default     = "rg-delab-packer"
  description = "Resource group of the Azure Compute Gallery."
}

variable "gallery_image_version" {
  type        = string
  default     = "1.0.0"
  description = "Image version published to the Azure Compute Gallery."
}

variable "gallery_replication_regions" {
  type        = list(string)
  default     = ["usgovvirginia"]
  description = "Regions the gallery image version is replicated to."
}

variable "matlab_release" {
  type        = string
  default     = "R2024b"
  description = "MATLAB release installed by the MathWorks package manager."
}

variable "matlab_products" {
  type        = string
  default     = "MATLAB Parallel_Computing_Toolbox MATLAB_Parallel_Server Simulink"
  description = "Space separated list of MathWorks products installed with mpm."
}

variable "build_subnet_id" {
  type        = string
  default     = ""
  description = "Optional existing subnet ID to build in when the build must stay on the private network."
}

locals {
  managed_image_resource_group_name = var.managed_image_resource_group_name != "" ? var.managed_image_resource_group_name : var.build_resource_group_name

  build_vnet = var.build_subnet_id == "" ? {} : {
    virtual_network_name                = split("/", var.build_subnet_id)[8]
    virtual_network_subnet_name         = split("/", var.build_subnet_id)[10]
    virtual_network_resource_group_name = split("/", var.build_subnet_id)[4]
  }

  shared_image = var.gallery_name == "" ? [] : [{
    gallery_name        = var.gallery_name
    resource_group_name = var.gallery_resource_group_name
    image_name          = var.image_name
    image_version       = var.gallery_image_version
    replication_regions = var.gallery_replication_regions
  }]
}

source "azure-arm" "matlab_dev" {
  use_azure_cli_auth     = true
  cloud_environment_name = var.cloud_environment_name
  subscription_id        = var.subscription_id

  # location and build_resource_group_name are mutually exclusive: an existing
  # resource group is used when one is supplied, otherwise Packer creates a
  # temporary resource group in the requested region.
  build_resource_group_name = var.build_resource_group_name == "" ? null : var.build_resource_group_name
  location                  = var.build_resource_group_name == "" ? var.location : null
  vm_size                   = var.vm_size

  os_type         = "Linux"
  image_publisher = "canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"

  managed_image_name                = var.gallery_name == "" ? var.image_name : null
  managed_image_resource_group_name = var.gallery_name == "" ? local.managed_image_resource_group_name : null

  dynamic "shared_image_gallery_destination" {
    for_each = local.shared_image
    content {
      gallery_name        = shared_image_gallery_destination.value.gallery_name
      resource_group      = shared_image_gallery_destination.value.resource_group_name
      image_name          = shared_image_gallery_destination.value.image_name
      image_version       = shared_image_gallery_destination.value.image_version
      replication_regions = shared_image_gallery_destination.value.replication_regions
    }
  }

  # When a subnet is supplied the build VM stays private: no public IP is
  # created and Packer connects over the virtual network.
  virtual_network_name                = try(local.build_vnet.virtual_network_name, null)
  virtual_network_subnet_name         = try(local.build_vnet.virtual_network_subnet_name, null)
  virtual_network_resource_group_name = try(local.build_vnet.virtual_network_resource_group_name, null)

  azure_tags = {
    workload = "digital-engineering-lab"
    role     = "matlab-dev-vm"
  }
}

build {
  name    = "matlab-dev-vm"
  sources = ["source.azure-arm.matlab_dev"]

  provisioner "shell" {
    environment_vars = [
      "MATLAB_RELEASE=${var.matlab_release}",
      "MATLAB_PRODUCTS=${var.matlab_products}",
    ]
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh -c '{{ .Path }}'"
    script          = "${path.root}/scripts/install-matlab.sh"
  }

  # Required so that the generalised image boots cleanly.
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh -c '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync",
    ]
    inline_shebang = "/bin/sh -x"
  }
}
