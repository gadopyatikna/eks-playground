variable "aws_region" {
  description = "AWS region containing the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "Name of the existing EKS cluster to receive this workload."
  type        = string
}

variable "client_webapp_image" {
  description = "Immutable container image URI for ClientWebApi."
  type        = string
}

variable "client_webapp_replicas" {
  description = "Number of ClientWebApi Pods."
  type        = number
  default     = 2
}

variable "client_webapp_port" {
  description = "HTTP port served by ClientWebApi."
  type        = number
  default     = 8080
}

variable "client_webapp_target_group_arn" {
  description = "Existing ALB target group ARN to bind to the ClientWebApi Service."
  type        = string
}
