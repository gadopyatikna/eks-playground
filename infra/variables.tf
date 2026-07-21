variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for resources."
  type        = string
  default     = "client-webapp"
}

variable "environment" {
  description = "Environment name, such as dev, staging, or prod."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 2 && var.availability_zone_count <= 3
    error_message = "availability_zone_count must be 2 or 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateways for private subnet outbound internet access. NAT Gateways cost money."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway instead of one per AZ. Cheaper, but less available."
  type        = bool
  default     = true
}

variable "client_webapp_port" {
  description = "Port exposed by the client-facing webapp targets."
  type        = number
  default     = 8080
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the public ALB HTTPS listener. The certificate must be in the deployment region."
  type        = string
}

variable "tags" {
  description = "Extra tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "eks_kubernetes_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.36"
}

variable "eks_endpoint_public_access" {
  description = "Whether the EKS API endpoint is reachable from the internet. Restrict it before production use."
  type        = bool
  default     = true
}

variable "eks_node_instance_type" {
  description = "Instance type used by the default managed EKS node group."
  type        = string
  default     = "t3.medium"
}

variable "eks_node_disk_size" {
  description = "Root EBS volume size, in GiB, for each managed node."
  type        = number
  default     = 20
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the default managed node group."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in the default managed node group."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in the default managed node group."
  type        = number
  default     = 2
}
