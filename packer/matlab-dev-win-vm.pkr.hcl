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
  description = "Size of the temporary Windows build virtual machine."
}

variable "image_name" {
  type        = string
  default     = "matlab-dev-windows2022"
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

  validation {
    condition     = can(regex("^R20[0-9][0-9](a|b)$", var.matlab_release))
    error_message = "The matlab_release value must be a valid MATLAB release such as R2024b."
  }
}

variable "matlab_products" {
  type        = string
  default     = "MATLAB Parallel_Computing_Toolbox MATLAB_Parallel_Server Simulink"
  description = "Space-separated list of MathWorks products installed with mpm."
}

variable "matlab_source_location" {
  type        = string
  default     = ""
  description = "Optional source URL passed to mpm. Empty downloads products from MathWorks."
}

variable "build_subnet_id" {
  type        = string
  default     = ""
  description = "Optional existing subnet ID to build in when the build must stay on the private network."
}

variable "image_publisher" {
  type        = string
  default     = "MicrosoftWindowsServer"
  description = "Publisher of the Windows base image."
}

variable "image_offer" {
  type        = string
  default     = "WindowsServer"
  description = "Offer of the Windows base image."
}

variable "image_sku" {
  type        = string
  default     = "2022-datacenter-g2"
  description = "SKU of the Windows base image."
}

variable "os_disk_size_gb" {
  type        = number
  default     = 128
  description = "OS disk size for the temporary build VM and resulting image."
}

variable "packer_admin_username" {
  type        = string
  default     = "packer"
  description = "Temporary administrator account used by Packer over WinRM."
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

source "azure-arm" "matlab_dev_windows" {
  use_azure_cli_auth     = true
  cloud_environment_name = var.cloud_environment_name
  subscription_id        = var.subscription_id

  build_resource_group_name = var.build_resource_group_name == "" ? null : var.build_resource_group_name
  location                  = var.build_resource_group_name == "" ? var.location : null
  vm_size                   = var.vm_size

  communicator   = "winrm"
  winrm_username = var.packer_admin_username
  winrm_insecure = true
  winrm_use_ssl  = true
  winrm_timeout  = "30m"

  os_type         = "Windows"
  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku
  os_disk_size_gb = var.os_disk_size_gb

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

  azure_tags = {
    workload = "digital-engineering-lab"
    role     = "matlab-dev-win-vm"
  }
}

build {
  name    = "matlab-dev-win-vm"
  sources = ["source.azure-arm.matlab_dev_windows"]

  provisioner "powershell" {
    environment_vars = [
      "MATLAB_RELEASE=${var.matlab_release}",
      "MATLAB_PRODUCTS=${var.matlab_products}",
      "MATLAB_SOURCE_LOCATION=${var.matlab_source_location}",
    ]
    script = "${path.root}/scripts/install-matlab-windows.ps1"
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"Write-Output 'restarted'\""
    restart_timeout       = "15m"
  }

  provisioner "powershell" {
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "$services = 'RdAgent', 'WindowsAzureGuestAgent'",
      "foreach ($serviceName in $services) { $service = Get-Service -Name $serviceName; $service.WaitForStatus('Running', '00:05:00') }",
      "& \"$env:SystemRoot\\System32\\Sysprep\\Sysprep.exe\" /oobe /generalize /quiet /quit",
      "$deadline = (Get-Date).AddMinutes(10)",
      "do { $imageState = (Get-ItemProperty 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State').ImageState; if ($imageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Start-Sleep -Seconds 10 } } while ($imageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE' -and (Get-Date) -lt $deadline)",
      "if ($imageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { throw \"Sysprep did not complete. Final image state: $imageState\" }",
    ]
  }
}
