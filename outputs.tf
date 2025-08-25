output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = module.apploadbalancing.alb_dns_name
}

output "management_public_ip" {
  description = "Public IP of the Management instance."
  value       = module.compute.mgmt_public_ip
}
