output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
