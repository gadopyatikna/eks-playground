output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs for internet-facing ALBs and NAT Gateways."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs for EKS nodes and application workloads."
  value       = aws_subnet.private_app[*].id
}

output "security_group_ids" {
  description = "Security groups for each workload tier."
  value = {
    client_web_alb = aws_security_group.client_web_alb.id
  }
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64-encoded EKS cluster certificate authority data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "client_webapp_url" {
  description = "Public HTTPS URL of the client webapp ALB."
  value       = "https://${aws_lb.client_webapp.dns_name}"
}

output "client_webapp_ecr_repository_url" {
  description = "ECR repository to which the ClientWebApi image must be pushed."
  value       = aws_ecr_repository.client_webapp.repository_url
}

output "client_webapp_target_group_arn" {
  description = "ALB target group ARN to bind to the ClientWebApi Kubernetes Service."
  value       = aws_lb_target_group.client_webapp.arn
}
