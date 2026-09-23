# Lab infrastructure (Terraform)

Deploys the digital engineering lab into an **existing** virtual network. Every
service is private: public network access is disabled and access is provided
through private endpoints resolved by private DNS zones linked to the virtual
network.

## Resources

- Seven subnets in the existing virtual network (`matlab-vms`, `matlab-cluster`,
  `storage`, `registry`, `foundry`, `key-vault`, `api-management`), each with a network security
  group that denies inbound traffic from the internet.
- Optional `AzureBastionSubnet`, public IP and Azure Bastion host
  (`deploy_bastion = true`).
- Private AKS cluster in `matlab-cluster` with a `system` node pool and a
  `matlab` worker node pool labelled `workload=matlab-parallel`, Azure CNI
  overlay networking, Entra ID (Azure AD) RBAC and workload identity. Private
  endpoint network policies are disabled on this subnet so AKS can create its
  managed API server private endpoint.
- Premium Azure Container Registry with public access disabled, used for the
  cluster images and OCI artifacts that support air-gapped imports. The cluster
  kubelet identity is granted `AcrPull`.
- Storage account with `shared_access_key_enabled = false` (Entra ID auth only),
  hierarchical namespace, and private endpoints for `blob` and `dfs`.
- Key vault with RBAC authorization, purge protection and a private endpoint.
- Azure AI Foundry (AI Services) account with local authentication disabled and
  a private endpoint registered in the `cognitiveservices`, `openai` and
  `services.ai` private DNS zones.
- API Management AI gateway in internal VNet mode with public network access
  disabled, a subscription-key-protected API, a published `Foundry Models`
  developer portal product, and private access to the Foundry endpoint. APIM
  uses its system-assigned managed identity and the `Cognitive Services User`
  role for model inference; no Foundry keys are stored or forwarded.
- Private DNS zones for each service, including the APIM gateway, developer
  portal, and management endpoints, linked to the existing virtual network.
  Zone names are selected automatically for the target cloud.

## Usage

```bash
az cloud set --name AzureUSGovernment
az login

cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars

../scripts/deploy-terraform.sh plan
../scripts/deploy-terraform.sh deploy
```

The provider authenticates with the Azure CLI user
(`use_cli = true`) and targets Azure Government by default
(`azure_environment = "usgovernment"`). Storage data-plane operations also use
the CLI user's Entra ID credentials because account keys are disabled.

## Required inputs

| Variable | Description |
| --- | --- |
| `virtual_network_name` | Name of the existing virtual network |
| `virtual_network_resource_group_name` | Resource group of that virtual network |

## Commonly changed inputs

| Variable | Default | Description |
| --- | --- | --- |
| `azure_environment` | `usgovernment` | Target cloud (`public`, `usgovernment`, `china`) |
| `location` | `usgovvirginia` | Region for the lab resources |
| `name_prefix` | `delab` | Prefix used for every resource name |
| `subnet_address_prefixes` | see `variables.tf` | Address prefix of each lab subnet |
| `api_management_sku` | `Developer_1` | VNet-capable APIM SKU (`Premium_1` or higher is recommended for production) |
| `api_management_publisher_email` | `admin@example.com` | Publisher contact shown by API Management |
| `deploy_bastion` | `false` | Deploy Azure Bastion and `AzureBastionSubnet` |
| `bastion_subnet_address_prefix` | `10.100.5.0/26` | Prefix for `AzureBastionSubnet` (/26 or larger) |
| `aks_outbound_type` | `loadBalancer` | Set to `userDefinedRouting` when egress is forced through a firewall |
| `aks_admin_group_object_ids` | `[]` | Entra ID groups granted cluster admin |
| `key_vault_admin_object_ids` | `[]` | Extra principals granted Key Vault Administrator |

Run `terraform fmt -recursive` and `terraform validate` before committing
changes.

## Module layout

Each infrastructure component is isolated under `modules/` with its resources,
inputs, and outputs split across `main.tf`, `variables.tf`, and `outputs.tf`.
The root module creates shared resources and composes the `network`, `storage`,
`registry`, `key_vault`, `foundry`, `api_management`, and `aks` modules. The reusable
`private_endpoint` module is consumed by service modules.

## Notes

- Because the AKS API server and the container registry are private, `kubectl`
  and `docker`/`oras` must run from inside the virtual network (for example a
  `matlab-vms` development VM reached through Bastion).
- The storage account has key based access disabled, so data plane operations
  require Entra ID credentials and an appropriate data plane role such as
  `Storage Blob Data Contributor`.
- Invoke chat completions through
  `<api_management_foundry_api_url>/deployments/<deployment-name>/chat/completions?api-version=<version>`
  with an `Ocp-Apim-Subscription-Key` header. APIM replaces client credentials
  with a managed identity token when it calls Foundry.
- Use the `api_management_developer_portal_url` output to discover the API and
  subscribe to the published `Foundry Models` product from inside the virtual
  network.
