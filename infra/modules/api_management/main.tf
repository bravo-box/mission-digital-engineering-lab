locals {
  foundry_openai_endpoint = "${trimsuffix(var.foundry_endpoint, "/")}/openai"
}

resource "azurerm_api_management" "gateway" {
  name                = "apim-${var.name_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags

  public_network_access_enabled = false
  virtual_network_type          = "Internal"

  identity {
    type = "SystemAssigned"
  }

  virtual_network_configuration {
    subnet_id = var.subnet_id
  }
}

resource "azurerm_private_dns_a_record" "gateway" {
  name                = azurerm_api_management.gateway.name
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = azurerm_api_management.gateway.private_ip_addresses
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "developer_portal" {
  name                = "${azurerm_api_management.gateway.name}.developer"
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = azurerm_api_management.gateway.private_ip_addresses
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "portal" {
  name                = "${azurerm_api_management.gateway.name}.portal"
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = azurerm_api_management.gateway.private_ip_addresses
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "management" {
  name                = "${azurerm_api_management.gateway.name}.management"
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = azurerm_api_management.gateway.private_ip_addresses
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "scm" {
  name                = "${azurerm_api_management.gateway.name}.scm"
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = azurerm_api_management.gateway.private_ip_addresses
  tags                = var.tags
}

resource "azurerm_role_assignment" "foundry_user" {
  scope                = var.foundry_account_id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_api_management.gateway.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_api_management_api" "foundry" {
  name                  = "foundry-model-inference"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.gateway.name
  revision              = "1"
  display_name          = "Foundry Model Inference"
  description           = "Invokes Foundry model deployments through API Management."
  path                  = "openai"
  protocols             = ["https"]
  service_url           = local.foundry_openai_endpoint
  subscription_required = true
}

resource "azurerm_api_management_product" "foundry" {
  product_id            = "foundry-models"
  api_management_name   = azurerm_api_management.gateway.name
  resource_group_name   = var.resource_group_name
  display_name          = "Foundry Models"
  description           = "Subscription-key access to Foundry model inference through the AI gateway."
  approval_required     = false
  published             = true
  subscription_required = true
  subscriptions_limit   = 1
}

resource "azurerm_api_management_product_api" "foundry" {
  api_name            = azurerm_api_management_api.foundry.name
  product_id          = azurerm_api_management_product.foundry.product_id
  api_management_name = azurerm_api_management.gateway.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_api_operation" "chat_completions" {
  operation_id        = "chat-completions"
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.gateway.name
  resource_group_name = var.resource_group_name
  display_name        = "Create chat completion"
  method              = "POST"
  url_template        = "/deployments/{deployment-name}/chat/completions"

  template_parameter {
    name     = "deployment-name"
    type     = "string"
    required = true
  }

  request {
    query_parameter {
      name     = "api-version"
      type     = "string"
      required = true
    }

    representation {
      content_type = "application/json"
    }
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_operation" "embeddings" {
  operation_id        = "embeddings"
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.gateway.name
  resource_group_name = var.resource_group_name
  display_name        = "Create embeddings"
  method              = "POST"
  url_template        = "/deployments/{deployment-name}/embeddings"

  template_parameter {
    name     = "deployment-name"
    type     = "string"
    required = true
  }

  request {
    query_parameter {
      name     = "api-version"
      type     = "string"
      required = true
    }

    representation {
      content_type = "application/json"
    }
  }

  response {
    status_code = 200
  }
}

resource "azurerm_api_management_api_policy" "foundry" {
  api_name            = azurerm_api_management_api.foundry.name
  api_management_name = azurerm_api_management.gateway.name
  resource_group_name = var.resource_group_name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <set-backend-service base-url="${local.foundry_openai_endpoint}" />
        <authentication-managed-identity resource="${var.managed_identity_audience}" />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML

  depends_on = [azurerm_role_assignment.foundry_user]
}
