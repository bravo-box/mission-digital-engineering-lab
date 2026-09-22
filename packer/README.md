# VM images (Packer)

Packer templates that build the MATLAB development VM images used in the
`matlab-vms` subnet.

| Template | Image |
| --- | --- |
| `matlab-dev-linux-vm.pkr.hcl` | Ubuntu 24.04 LTS with MATLAB, Parallel Computing Toolbox, MATLAB Parallel Server, and Simulink |
| `matlab-dev-win-vm.pkr.hcl` | Windows Server 2022 with MATLAB, Parallel Computing Toolbox, MATLAB Parallel Server and Simulink |

The Linux template is adapted from the MathWorks
[`build-azure-matlab.pkr.hcl`](https://github.com/mathworks-ref-arch/matlab-on-azure/blob/master/packer/v1/build-azure-matlab.pkr.hcl)
reference while retaining this lab's Azure Government, private networking, and
Azure Compute Gallery options.

## Usage

```bash
az cloud set --name AzureUSGovernment
az login

../scripts/create-packer-rg.sh --resource-group rg-delab-packer

packer init matlab-dev-linux-vm.pkr.hcl
packer validate matlab-dev-linux-vm.pkr.hcl
packer build \
  -var "build_resource_group_name=rg-delab-packer" \
  matlab-dev-linux-vm.pkr.hcl
```

To build the Windows development image, substitute
`matlab-dev-win-vm.pkr.hcl` in the `init`, `validate`, and `build` commands.
The Windows template follows the MathWorks Azure reference architecture: it
installs MATLAB with the MathWorks package manager, restarts Windows, waits for
the Azure guest services, and runs Sysprep before image capture.

Builds authenticate as the Azure CLI user (`use_azure_cli_auth = true`) and
target Azure Government by default (`cloud_environment_name = "Usgovernment"`).

Create a private VM from the resulting managed image:

```bash
../scripts/create-matlab-vm.sh --name matlab-dev-01
```

## Private builds

Set `build_subnet_id` to a subnet resource ID to keep the temporary build VM on
the private network instead of giving it a public IP:

```bash
SUBNET_ID=$(terraform -chdir=../infra output -json subnet_ids | jq -r '."matlab-vms"')
packer build -var "build_subnet_id=${SUBNET_ID}" matlab-dev-linux-vm.pkr.hcl
```

The build VM still needs outbound access to the MathWorks package manager, so
run private builds through the environment's egress path (firewall or proxy).

To let Packer create a temporary build resource group instead, leave
`build_resource_group_name` empty and supply `location` together with either
`managed_image_resource_group_name` or `gallery_name`.

## Publishing to a compute gallery

```bash
../scripts/create-packer-rg.sh --gallery sigdelab
packer build -var "gallery_name=sigdelab" -var "gallery_image_version=1.0.0" matlab-dev-linux-vm.pkr.hcl
../scripts/create-matlab-vm.sh --name matlab-dev-01 --gallery sigdelab --image-version 1.0.0
```

Licensing is not baked into the image: set `MLM_LICENSE_FILE` on the deployed
VM to point at the network license manager.

Override `matlab_release`, `matlab_products`, `matlab_source_location`, or the
base-image variables with `-var` arguments or a Packer variable file. Each
successful build writes `matlab-dev-linux-manifest.json` with the image inputs
used for the build.
