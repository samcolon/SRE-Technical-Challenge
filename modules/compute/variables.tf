variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "mgmt_public_subnet_ids" { type = list(string) }
variable "app_subnet_ids" { type = list(string) }
variable "allowed_ssh_cidr" { type = string } # your IP/CIDR

variable "alb_sg_id" { type = string }
variable "target_group_arn" { type = string }
variable "app_user_data_path" { type = string } # path to script that installs Apache
