variable "project_name" { type = string }
variable "vpc_cidr" { type = string }

# Exactly two AZs expected for this POC
variable "azs" {
  type = list(string)
  validation {
    condition     = length(var.azs) == 2
    error_message = "Provide exactly two AZ names."
  }
}

# /24s per tier, one per AZ
variable "mgmt_cidrs" {
  type = list(string)
  validation {
    condition     = length(var.mgmt_cidrs) == 2
    error_message = "mgmt_cidrs must have two /24 CIDRs (one per AZ)."
  }
}

variable "app_cidrs" {
  type = list(string)
  validation {
    condition     = length(var.app_cidrs) == 2
    error_message = "app_cidrs must have two /24 CIDRs (one per AZ)."
  }
}

variable "be_cidrs" {
  type = list(string)
  validation {
    condition     = length(var.be_cidrs) == 2
    error_message = "be_cidrs must have two /24 CIDRs (one per AZ)."
  }
}

variable "enable_nat_per_az" {
  type    = bool
  default = true
}
