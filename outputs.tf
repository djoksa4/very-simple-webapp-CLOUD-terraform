output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "rds_enpoint" {
  value = aws_db_instance.this.endpoint
}