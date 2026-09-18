# Helm charts

Charts for workloads deployed onto the private AKS cluster created by
`/infra`.

| Chart | Description |
| --- | --- |
| `matlab-parallel-server` | MATLAB Parallel Server workers scheduled onto the `matlab` node pool |

## Usage

The API server is private, so run these commands from inside the virtual
network (for example a `matlab-vms` development VM):

```bash
az aks get-credentials \
  --resource-group "$(terraform -chdir=../infra output -raw resource_group_name)" \
  --name "$(terraform -chdir=../infra output -raw aks_cluster_name)"

helm lint matlab-parallel-server --set image.repository=<registry>/matlab-parallel-server

helm upgrade --install matlab matlab-parallel-server \
  --namespace matlab --create-namespace \
  --set image.repository="$(terraform -chdir=../infra output -raw container_registry_login_server)/matlab-parallel-server" \
  --set matlab.licenseServer="27000@lic01.example.local"
```

Images must be pushed into the lab container registry first: the cluster has no
public network access.
