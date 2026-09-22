# Scripts

The Azure deployment scripts authenticate with the Azure CLI user and target
Azure Government (`AzureUSGovernment`) by default. Override with `--cloud` or
`AZURE_CLOUD`.

| Script | Purpose |
| --- | --- |
| `creating-lz.sh` | Create the landing zone resource group and virtual network the Terraform points at |
| `deploy-terraform.sh` | Plan, deploy or destroy the `/infra` Terraform environment |
| `create-packer-rg.sh` | Create the resource group (and optional compute gallery) that Packer images land in |
| `create-matlab-vm.sh` | Create a private Linux or Windows VM from a managed Packer image |
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
./create-matlab-vm.sh --name matlab-dev-01
./install-docker-ubuntu.sh
```

`create-matlab-vm.sh` uses the `matlab-vms` subnet from the Terraform outputs,
creates no public IP and passes the managed image's full Azure resource ID to
`az vm create`. It defaults to the `matlab-dev-linux` image produced by
`packer/matlab-dev-linux-vm.pkr.hcl`:

```bash
./create-matlab-vm.sh --name matlab-linux-01 --os linux
```

Use `--os windows` for the `matlab-dev-windows2022` image. The script securely
prompts for the Windows administrator password:

```bash
./create-matlab-vm.sh \
  --name matlab-windows-01 \
  --os windows
```

For non-interactive use, supply the password through the `ADMIN_PASSWORD`
environment variable without storing it in the repository.

To deploy another managed image, pass its complete resource ID:

```bash
./create-matlab-vm.sh \
  --name matlab-linux-02 \
  --os linux \
  --image-id /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/images/<image-name>
```

Pass `--subnet-id` when the subnet is not managed by this repository's
Terraform configuration. Run `./create-matlab-vm.sh --help` for all image,
network, operating system, VM size, authentication, cloud and subscription
options.

`install-docker-ubuntu.sh` installs from Docker's official apt repository,
enables the Docker service and adds the invoking user to the `docker` group.
Log out and back in after it completes. When provisioning as `root`, identify
the non-root development user explicitly:

```bash
./install-docker-ubuntu.sh --user azureuser
```
