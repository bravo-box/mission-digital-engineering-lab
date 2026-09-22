# Scripts

The Azure deployment scripts authenticate with the Azure CLI user and target
Azure Government (`AzureUSGovernment`) by default. Override with `--cloud` or
`AZURE_CLOUD`.

| Script | Purpose |
| --- | --- |
| `creating-lz.sh` | Create the landing zone resource group and virtual network the Terraform points at |
| `deploy-terraform.sh` | Plan, deploy or destroy the `/infra` Terraform environment |
| `create-packer-rg.sh` | Create the resource group (and optional compute gallery) that Packer images land in |
| `install-docker-ubuntu.sh` | Install Docker Engine, Buildx and Compose on Ubuntu 26.04 LTS for devcontainers |
| `common.sh` | Shared helpers, sourced by the other scripts |

Run any script with `--help` for the full list of options.

In VS Code, use **Tasks: Run Task** to run the common setup and infrastructure
operations without assembling command-line arguments. The Azure resource tasks
prompt for names and location, and the Terraform deploy and destroy tasks keep
Terraform's approval prompt enabled.

```bash
./creating-lz.sh --resource-group rg-delab-network --name vnet-delab --address-space 10.100.0.0/16
./deploy-terraform.sh plan
./deploy-terraform.sh deploy --auto-approve
./deploy-terraform.sh destroy
./create-packer-rg.sh --resource-group rg-delab-packer --gallery sigdelab
./install-docker-ubuntu.sh
```

`install-docker-ubuntu.sh` installs from Docker's official apt repository,
enables the Docker service and adds the invoking user to the `docker` group.
Log out and back in after it completes. When provisioning as `root`, identify
the non-root development user explicitly:

```bash
./install-docker-ubuntu.sh --user azureuser
```
