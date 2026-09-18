# Scripts

Every script authenticates with the Azure CLI user and targets Azure Government
(`AzureUSGovernment`) by default. Override with `--cloud` or `AZURE_CLOUD`.

| Script | Purpose |
| --- | --- |
| `creating-lz.sh` | Create the landing zone resource group and virtual network the Terraform points at |
| `deploy-terraform.sh` | Plan, deploy or destroy the `/infra` Terraform environment |
| `create-packer-rg.sh` | Create the resource group (and optional compute gallery) that Packer images land in |
| `common.sh` | Shared helpers, sourced by the other scripts |

Run any script with `--help` for the full list of options.

```bash
./creating-lz.sh --resource-group rg-delab-network --name vnet-delab --address-space 10.100.0.0/16
./deploy-terraform.sh plan
./deploy-terraform.sh deploy --auto-approve
./deploy-terraform.sh destroy
./create-packer-rg.sh --resource-group rg-delab-packer --gallery sigdelab
```
