# Client Web App

Monorepo with separately scoped application and infrastructure code:

- [`app/`](app/README.md) — .NET API and its Docker image.
- [`infra/`](infra/README.md) — Terraform for AWS networking, EKS, ECR, and ALB.
- [`workloads/client-webapp/`](workloads/client-webapp/README.md) — independent Terraform root for the API Deployment and Service.

The application pipeline builds and pushes an immutable image to ECR. Apply the ClientWebApi workload root only after that image exists.
