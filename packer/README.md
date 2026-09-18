# VM images (Packer)

Packer templates that build the MATLAB development VM images used in the
`matlab-vms` subnet.

| Template | Image |
| --- | --- |
| `matlab-dev-vm.pkr.hcl` | Ubuntu 22.04 LTS with MATLAB, Parallel Computing Toolbox and MATLAB Parallel Server |

## Usage

```bash
az cloud set --name AzureUSGovernment
az login

../scripts/create-packer-rg.sh --resource-group rg-delab-packer

packer init matlab-dev-vm.pkr.hcl
packer validate matlab-dev-vm.pkr.hcl
packer build \
  -var "build_resource_group_name=rg-delab-packer" \
  -var "location=usgovvirginia" \
  matlab-dev-vm.pkr.hcl
```

Builds authenticate as the Azure CLI user (`use_azure_cli_auth = true`) and
target Azure Government by default (`cloud_environment_name = "Usgovernment"`).

## Private builds

Set `build_subnet_id` to a subnet resource ID to keep the temporary build VM on
the private network instead of giving it a public IP:

```bash
packer build -var "build_subnet_id=$(terraform -chdir=../infra output -raw ...)" matlab-dev-vm.pkr.hcl
```

The build VM still needs outbound access to the MathWorks package manager, so
run private builds through the environment's egress path (firewall or proxy).

## Publishing to a compute gallery

```bash
../scripts/create-packer-rg.sh --gallery sigdelab
packer build -var "gallery_name=sigdelab" -var "gallery_image_version=1.0.0" matlab-dev-vm.pkr.hcl
```

Licensing is not baked into the image: set `MLM_LICENSE_FILE` on the deployed
VM to point at the network license manager.
