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
    client_web_alb  = aws_security_group.client_web_alb.id
    client_webapp   = aws_security_group.client_webapp.id
    internal_alb    = aws_security_group.internal_web_alb.id
    internal_webapp = aws_security_group.internal_webapp.id
    lambda          = aws_security_group.lambda.id
    database        = aws_security_group.database.id
  }
}

