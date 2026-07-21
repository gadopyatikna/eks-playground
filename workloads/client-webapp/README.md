# ClientWebApi workload

This Terraform root deploys ClientWebApi to an existing EKS cluster. It is deliberately separate from `infra/`: the cluster and ECR repository can be created first, while this root is applied only after an immutable application image exists.

From the repository root:

```bash
cp workloads/client-webapp/terraform.tfvars.example workloads/client-webapp/terraform.tfvars
terraform -chdir=workloads/client-webapp init
terraform -chdir=workloads/client-webapp apply
```

`eks_cluster_name`, `client_webapp_image`, and `client_webapp_target_group_arn` are required. Get the first and third values from the platform root:

```bash
terraform -chdir=infra output -raw eks_cluster_name
terraform -chdir=infra output -raw client_webapp_target_group_arn
```

The TargetGroupBinding registers the selected Pod IPs in the existing public ALB target group.
