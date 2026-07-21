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
  description = "Private app subnet IDs for app compute, internal services, and VPC-attached Lambda functions."
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs."
  value       = aws_subnet.private_db[*].id
}

output "db_subnet_group_name" {
  description = "DB subnet group name for RDS/Aurora."
  value       = aws_db_subnet_group.private.name
}

output "security_group_ids" {
  description = "Security groups for each workload tier."
  value = {
    client_web_alb = aws_security_group.client_web_alb.id
    client_webapp  = aws_security_group.client_webapp.id
    lambda         = aws_security_group.lambda.id
    database       = aws_security_group.database.id
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
