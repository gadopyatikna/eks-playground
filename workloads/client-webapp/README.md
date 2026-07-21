# ClientWebApi workload

This Terraform root deploys ClientWebApi to an existing EKS cluster. It is deliberately separate from `infra/`: the cluster and ECR repository can be created first, while this root is applied only after an immutable application image exists.

From the repository root:

```bash
cp workloads/client-webapp/terraform.tfvars.example workloads/client-webapp/terraform.tfvars
terraform -chdir=workloads/client-webapp init
terraform -chdir=workloads/client-webapp apply
```

`eks_cluster_name` and `client_webapp_image` are required. Use an immutable ECR tag such as a Git SHA.
