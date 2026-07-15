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

variable "allowed_internal_cidrs" {
  description = "CIDRs allowed to reach internal webapp entrypoints, such as VPN, office, or trusted VPC CIDRs."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "client_webapp_port" {
  description = "Port exposed by the client-facing webapp targets."
  type        = number
  default     = 8080
}

variable "internal_webapp_port" {
  description = "Port exposed by the internal webapp targets."
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Private database port. Defaults to PostgreSQL."
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Extra tags to apply to all resources."
  type        = map(string)
  default     = {}
}
