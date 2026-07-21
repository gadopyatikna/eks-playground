# Client Web App

Monorepo with separately scoped application and infrastructure code:

- [`app/`](app/README.md) — .NET API and its Docker image.
- [`infra/`](infra/README.md) — Terraform for AWS networking, EKS, ECR, and ALB.

The application pipeline builds and pushes an immutable image to ECR. The infrastructure configuration deploys that image to EKS by setting `client_webapp_image`.
