locals {
  account_name = substr("st${var.name_prefix}data${var.suffix}", 0, 24)
}

resource "azurerm_storage_account" "data" {
  name                = local.account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  account_tier                     = "Standard"
  account_kind                     = "StorageV2"
  account_replication_type         = var.replication_type
  is_hns_enabled                   = true
  min_tls_version                  = "TLS1_2"
  https_traffic_only_enabled       = true
  shared_access_key_enabled        = false
  default_to_oauth_authentication  = true
  allow_nested_items_to_be_public  = false
  public_network_access_enabled    = false
  cross_tenant_replication_enabled = false

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }
}

module "private_endpoint_blob" {
  source = "../private_endpoint"

  name                           = "pe-${var.name_prefix}-storage-blob"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.subnet_id
  private_connection_resource_id = azurerm_storage_account.data.id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [var.blob_private_dns_zone_id]
  tags                           = var.tags
}

module "private_endpoint_dfs" {
  source = "../private_endpoint"

  name                           = "pe-${var.name_prefix}-storage-dfs"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  subnet_id                      = var.subnet_id
  private_connection_resource_id = azurerm_storage_account.data.id
  subresource_names              = ["dfs"]
  private_dns_zone_ids           = [var.dfs_private_dns_zone_id]
  tags                           = var.tags
}
