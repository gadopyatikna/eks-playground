# AWS VPC + EKS Starter

This is a Terraform starter for a typical client-facing AWS web application with:

- Public entrypoint for a client-facing webapp
- Minimal Amazon EKS cluster with a managed node group

## EKS

The default configuration creates a two-node EKS managed node group in the private app subnets, along with the required IAM roles and the `vpc-cni`, `coredns`, and `kube-proxy` add-ons. The Kubernetes API has both private access and public access enabled by default, which makes initial administration simple; set `eks_endpoint_public_access = false` after ensuring you have private access (VPN, bastion, or a connected VPC).

EKS worker nodes in private subnets require outbound access to pull container images and reach AWS APIs. Enable a NAT Gateway before applying:

```hcl
enable_nat_gateway = true
single_nat_gateway = true
```

The connection is network routing rather than a direct EKS-to-NAT resource link:

```text
EKS managed node -> private app subnet -> private app route table
  -> 0.0.0.0/0 via NAT Gateway -> Internet Gateway -> AWS APIs / container registries
```

After `terraform apply`, configure kubectl:

```bash
aws eks update-kubeconfig --region us-east-1 --name client-webapp-dev-eks
kubectl get nodes
```

## Public ALB and TLS

The public ALB terminates TLS with the ACM certificate supplied in `acm_certificate_arn`. Its HTTP listener permanently redirects requests to HTTPS, and the HTTPS listener forwards HTTP traffic to the `client-webapp` target group on port `8080`.

Terraform installs the AWS Load Balancer Controller with an IAM role for service accounts (IRSA). The ClientWebApi workload uses a TargetGroupBinding to register its selected Pod IPs in this target group.

## Deploy ClientWebApi to EKS

The `infra/` root creates the EKS platform and an immutable ECR repository, but never starts the application. The separate [`workloads/client-webapp/`](../workloads/client-webapp/README.md) root creates the namespace, Deployment, and Service after the image is available. Run the following commands from the repository root.

```bash
ECR_REPOSITORY=$(terraform -chdir=infra output -raw client_webapp_ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${ECR_REPOSITORY%/*}"
docker build --file app/Dockerfile --tag client-web-api:git-sha app
docker tag client-web-api:git-sha "$ECR_REPOSITORY:git-sha"
docker push "$ECR_REPOSITORY:git-sha"
```

Then copy `workloads/client-webapp/terraform.tfvars.example` to `workloads/client-webapp/terraform.tfvars`, set the immutable image URI, and deploy the workload:

```bash
terraform -chdir=workloads/client-webapp init
terraform -chdir=workloads/client-webapp apply
```

## AWS Reserved IPv4 Addresses

In every AWS subnet, AWS reserves 5 IPv4 addresses:

- Network address: `x.x.x.0`
- VPC router: `x.x.x.1`
- DNS resolver: `x.x.x.2`
- Future use: `x.x.x.3`
- Broadcast address: last IP in the subnet, even though AWS VPCs do not support broadcast

Example for `10.20.0.0/24`, usable addresses are `10.20.0.4` through `10.20.0.254`.

## CIDR Choices

Default VPC range:

```text
10.20.0.0/16
```

Why this shape:

- `10.0.0.0/8` is standard private RFC1918 space.
- `10.20.0.0/16` is easy to read and unlikely to collide with the very common `10.0.0.0/16`, `10.1.0.0/16`, `10.100.0.0/16`, and `192.168.0.0/16` ranges.
- A `/16` gives enough room for multiple subnet tiers, AZs, future services, VPC endpoints, and expansion.
- Avoid using `172.17.0.0/16` because Docker commonly uses it.
- Avoid `192.168.0.0/16` for client-connected environments because many home and office networks use it.

Default subnet layout:

```text
VPC: 10.20.0.0/16

Public subnets:
  AZ A: 10.20.10.0/24
  AZ B: 10.20.11.0/24

Private app subnets:
  AZ A: 10.20.30.0/24
  AZ B: 10.20.31.0/24

Reserved for future:
  10.20.20.0/24   public expansion
  10.20.40.0/24   private app expansion
  10.20.50.0/24+  data, shared services, endpoints, admin, observability
```

## Architecture

```text
Internet
  |
  v
Public ALB / API Gateway
  |
  v
Private app subnets
  |
  +-- EKS nodes and ClientWebApi Pods
```

Recommended entrypoint mapping:

- Client-facing webapp: internet-facing ALB in public subnets, app compute in private app subnets.

## Routing Between Subnets

Subnets inside the same VPC already have a built-in route:

```text
10.20.0.0/16 -> local
```

That route exists in every route table automatically. It is what lets the public ALB subnet talk to the private app subnet.

You do not add a route like this manually:

```text
10.20.30.0/24 -> private app subnet
```

AWS handles intra-VPC routing through the `local` route. Security Groups decide whether the traffic is allowed.

## Cost Note

NAT Gateways are not free. EKS nodes in private subnets need outbound access, so this configuration enables a NAT Gateway.

```hcl
enable_nat_gateway = true
```

VPC endpoints for ECR, S3, and CloudWatch can reduce NAT data-processing charges.

## Usage

```bash
terraform -chdir=infra init
terraform -chdir=infra plan
terraform -chdir=infra apply
```

Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and adjust the region and environment name.
