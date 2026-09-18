locals {
  storage_account_name = substr("st${var.name_prefix}data${local.suffix}", 0, 24)
}

# Data storage account. Key based access is disabled, so every client must use
# Entra ID (Azure AD) credentials, and the account is only reachable privately.
resource "azurerm_storage_account" "data" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = local.tags

  account_tier                     = "Standard"
  account_kind                     = "StorageV2"
  account_replication_type         = var.storage_account_replication_type
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

module "pe_storage_blob" {
  source = "./modules/private_endpoint"

  name                           = "pe-${var.name_prefix}-storage-blob"
  location                       = azurerm_resource_group.lab.location
  resource_group_name            = azurerm_resource_group.lab.name
  subnet_id                      = azurerm_subnet.lab["storage"].id
  private_connection_resource_id = azurerm_storage_account.data.id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.lab["blob"].id]
  tags                           = local.tags
}

module "pe_storage_dfs" {
  source = "./modules/private_endpoint"

  name                           = "pe-${var.name_prefix}-storage-dfs"
  location                       = azurerm_resource_group.lab.location
  resource_group_name            = azurerm_resource_group.lab.name
  subnet_id                      = azurerm_subnet.lab["storage"].id
  private_connection_resource_id = azurerm_storage_account.data.id
  subresource_names              = ["dfs"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.lab["dfs"].id]
  tags                           = local.tags
}
