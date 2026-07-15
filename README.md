# AWS VPC Starter

This is a Terraform starter for a typical client-facing AWS web application with:

- Public entrypoint for a client-facing webapp
- Internal-only webapp entrypoint
- Internet-facing Lambda entrypoint pattern
- Private database tier

## Web API

The repository includes a minimal production-oriented .NET 10 API in `src/ClientWebApi`.
It listens on port `8080`, matching `client_webapp_port` in the Terraform configuration,
and is designed to sit behind the private ALB target group.

- `GET /` returns the service identity.
- `GET /health` is the liveness endpoint.
- `GET /ready` is the readiness endpoint; configure the ALB target group to use this path.
- JSON logs go to standard output; uncaught exceptions are returned as RFC 7807 problem details.

Run locally:

```bash
dotnet run --project src/ClientWebApi
curl http://localhost:8080/ready
```

Build and run the production image:

```bash
docker build --tag client-web-api .
docker run --rm --publish 8080:8080 client-web-api
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

Private data subnets:
  AZ A: 10.20.50.0/24
  AZ B: 10.20.51.0/24

Reserved for future:
  10.20.20.0/24   public expansion
  10.20.40.0/24   private app expansion
  10.20.60.0/24   private data expansion
  10.20.70.0/24+  shared services, endpoints, admin, observability
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
  |        |         |
  |        |         +-- Lambda ENIs, if Lambda needs VPC access
  |        +------------ Internal webapp
  +--------------------- Client-facing webapp targets
  |
  v
Private data subnets
  |
  v
RDS / private database
```

Recommended entrypoint mapping:

- Client-facing webapp: internet-facing ALB in public subnets, app compute in private app subnets.
- Internal webapp: internal ALB in private app subnets, reachable from VPN, Direct Connect, peered VPCs, or allowed private CIDRs.
- Internet-facing Lambda: API Gateway or Lambda Function URL as the public entrypoint. Put the Lambda in private app subnets only if it must reach the private DB or other VPC resources.
- Private DB: RDS/Aurora in private data subnets with no public access.

## Routing Between Subnets

Subnets inside the same VPC already have a built-in route:

```text
10.20.0.0/16 -> local
```

That route exists in every route table automatically. It is what lets the public ALB subnet talk to the private app subnet, and the private app subnet talk to the private DB subnet.

You do not add a route like this manually:

```text
10.20.30.0/24 -> private app subnet
```

AWS handles intra-VPC routing through the `local` route. Security Groups decide whether the traffic is allowed.

## Cost Note

NAT Gateways are not free. For a real client-facing webapp, NAT Gateways are common. For a cheap playground, set:

```hcl
enable_nat_gateway = false
```

Then prefer VPC endpoints for AWS APIs, or keep Lambda outside the VPC unless it needs private resources.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust the region, environment name, allowed internal CIDRs, and DB port.
