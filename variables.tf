variable "aws_profile" {
  description = "Name of the AWS CLI profile to use (from your ~/.aws/config and credentials)."
  type        = string
}

variable "region" {
  description = "AWS region for this POC."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "coalfire-poc"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP or CIDR allowed to SSH into the Management instance."
  type        = string
}
