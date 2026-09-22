# mission-digital-engineering-lab

A repo built for standing up a digital engineering lab in Azure Government using MATLAB.

The lab attaches to an **existing virtual network**, and every resource is
deployed with public network access disabled so that all traffic stays on the
virtual network through private endpoints and private links.

## Repository layout

| Path | Contents |
| --- | --- |
| `infra/` | Terraform configuration that deploys the lab into an existing virtual network |
| `packer/` | Packer templates that build the MATLAB development VM images |
| `helm-charts/` | Helm charts for workloads that run on the lab AKS cluster |
| `scripts/` | Scripts that drive the landing zone, Terraform and Packer workflows |

## What gets deployed

Subnets added to the existing virtual network:

| Subnet | Purpose |
| --- | --- |
| `matlab-vms` | Development VMs running MATLAB for digital engineers |
| `matlab-cluster` | Private AKS cluster for MATLAB Parallel Server workloads |
| `storage` | Private endpoints for the data storage account (key based access disabled) |
| `registry` | Private endpoint for the container registry (container images and OCI artifacts for air-gap support) |
| `foundry` | Private endpoint for the Azure AI Foundry (AI Services) account used for LLMs |
| `key-vault` | Private endpoint for the lab key vault |

`AzureBastionSubnet` and an Azure Bastion host are added when
`deploy_bastion = true`.

## Quick start

All tooling authenticates as the Azure CLI user against Azure Government
(`AzureUSGovernment`) by default.

### Development container

The repository includes a development container with Terraform, Packer, the
Azure CLI, kubectl, Helm, jq and ShellCheck. Open the repository in a
devcontainer-capable editor, then authenticate from the container:

```bash
az cloud set --name AzureUSGovernment
az login
```

Azure CLI credentials and the Terraform provider cache are kept in named
volumes, so they survive container rebuilds. The commands below can then be run
directly from the container terminal.

The same setup and deployment commands are available from **Tasks: Run Task**
in VS Code. Tasks are provided for copying `terraform.tfvars`, creating the
landing zone and Packer resource group, planning/deploying/destroying Terraform,
and installing Docker on an Ubuntu host. Terraform deploy and destroy tasks
retain their interactive approval prompts.

```bash
# 1. Create the landing zone virtual network (skip if one already exists)
./scripts/creating-lz.sh --resource-group rg-delab-network --name vnet-delab

# 2. Configure the lab
cp infra/terraform.tfvars.example infra/terraform.tfvars
$EDITOR infra/terraform.tfvars

# 3. Plan and deploy
./scripts/deploy-terraform.sh plan
./scripts/deploy-terraform.sh deploy

# 4. Build MATLAB VM images
./scripts/create-packer-rg.sh --resource-group rg-delab-packer
packer init packer/matlab-dev-vm.pkr.hcl
packer build packer/matlab-dev-vm.pkr.hcl

# 5. Deploy workloads to the cluster
helm upgrade --install matlab helm-charts/matlab-parallel-server \
  --set image.repository=<registry-login-server>/matlab-parallel-server
```

Tear the environment down with `./scripts/deploy-terraform.sh destroy`.

See [`infra/README.md`](infra/README.md) for the Terraform inputs and the
private networking design.
