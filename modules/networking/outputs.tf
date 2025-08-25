output "vpc_id" {
  value = aws_vpc.this.id
}

output "mgmt_public_subnet_ids" {
  value = [for s in aws_subnet.mgmt : s.id]
}

output "app_private_subnet_ids" {
  value = [for s in aws_subnet.app : s.id]
}

output "backend_private_subnet_ids" {
  value = [for s in aws_subnet.backend : s.id]
}
