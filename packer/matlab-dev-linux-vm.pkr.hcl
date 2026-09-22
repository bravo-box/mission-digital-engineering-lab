# Adapted for this lab from the MathWorks matlab-on-azure Linux Packer template:
# https://github.com/mathworks-ref-arch/matlab-on-azure/blob/master/packer/v1/build-azure-matlab.pkr.hcl

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
  sensitive   = true
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

variable "os_disk_size_gb" {
  type        = number
  default     = 128
  description = "Size of the temporary build VM operating system disk."
}

variable "image_publisher" {
  type        = string
  default     = "Canonical"
  description = "Publisher of the Linux base image."
}

variable "image_offer" {
  type        = string
  default     = "ubuntu-24_04-lts"
  description = "Offer of the Linux base image."
}

variable "image_sku" {
  type        = string
  default     = "server-gen1"
  description = "SKU of the Linux base image."
}

variable "image_name" {
  type        = string
  default     = "matlab-dev-linux"
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
  default     = "R2026a"
  description = "MATLAB release installed by the MathWorks package manager."

  validation {
    condition     = can(regex("^R20[0-9][0-9](a|b)$", var.matlab_release))
    error_message = "The matlab_release value must be a valid MATLAB release such as R2026a."
  }
}

variable "matlab_products" {
  type        = string
  default     = "MATLAB Parallel_Computing_Toolbox MATLAB_Parallel_Server Simulink"
  description = "Space-separated list of MathWorks products installed with mpm."

  validation {
    condition     = length(trimspace(var.matlab_products)) > 0
    error_message = "The matlab_products value must contain at least one MathWorks product."
  }
}

variable "matlab_install_dir" {
  type        = string
  default     = "/usr/local/matlab"
  description = "Installation directory used by the MathWorks package manager."
}

variable "matlab_source_location" {
  type        = string
  default     = ""
  description = "Optional MATLAB product source location passed to mpm with --source."
}

variable "mpm_url" {
  type        = string
  default     = "https://www.mathworks.com/mpm/glnxa64/mpm"
  description = "URL used to download the MathWorks package manager."
}

variable "build_subnet_id" {
  type        = string
  default     = ""
  description = "Optional existing subnet ID used to build without a public IP."

  validation {
    condition     = var.build_subnet_id == "" || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.build_subnet_id))
    error_message = "The build_subnet_id value must be empty or a complete Azure subnet resource ID."
  }
}

variable "user_assigned_managed_identities" {
  type        = list(string)
  default     = []
  description = "Resource IDs of user-assigned managed identities attached to the build VM."
  sensitive   = true
}

variable "azure_tags" {
  type = map(string)
  default = {
    workload = "digital-engineering-lab"
    role     = "matlab-dev-linux-vm"
    source   = "packer"
  }
  description = "Tags applied to resources created by Packer."
}

variable "manifest_output_file" {
  type        = string
  default     = "matlab-dev-linux-manifest.json"
  description = "Path of the Packer build manifest."
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

source "azure-arm" "matlab_dev_linux" {
  use_azure_cli_auth     = true
  cloud_environment_name = var.cloud_environment_name
  subscription_id        = var.subscription_id

  build_resource_group_name = var.build_resource_group_name == "" ? null : var.build_resource_group_name
  location                  = var.build_resource_group_name == "" ? var.location : null
  vm_size                   = var.vm_size
  os_disk_size_gb           = var.os_disk_size_gb

  communicator    = "ssh"
  ssh_username    = "ubuntu"
  os_type         = "Linux"
  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku

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

  virtual_network_name                = try(local.build_vnet.virtual_network_name, null)
  virtual_network_subnet_name         = try(local.build_vnet.virtual_network_subnet_name, null)
  virtual_network_resource_group_name = try(local.build_vnet.virtual_network_resource_group_name, null)

  user_assigned_managed_identities = var.user_assigned_managed_identities
  azure_tags                       = var.azure_tags
}

build {
  name    = "matlab-dev-linux-vm"
  sources = ["source.azure-arm.matlab_dev_linux"]

  provisioner "shell" {
    inline = ["/usr/bin/cloud-init status --wait"]
  }

  provisioner "shell" {
    environment_vars = [
      "MATLAB_RELEASE=${var.matlab_release}",
      "MATLAB_PRODUCTS=${var.matlab_products}",
      "MATLAB_INSTALL_DIR=${var.matlab_install_dir}",
      "MATLAB_SOURCE_LOCATION=${var.matlab_source_location}",
      "MPM_URL=${var.mpm_url}",
    ]
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E bash '{{ .Path }}'"
    script          = "${path.root}/scripts/install-matlab.sh"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh -c '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync",
    ]
    inline_shebang = "/bin/sh -x"
  }

  post-processor "manifest" {
    output     = var.manifest_output_file
    strip_path = true
    custom_data = {
      image_name            = var.image_name
      matlab_release        = var.matlab_release
      matlab_products       = var.matlab_products
      source_image          = "${var.image_publisher}:${var.image_offer}:${var.image_sku}"
      target_cloud          = var.cloud_environment_name
      target_resource_group = local.managed_image_resource_group_name
    }
  }
}
