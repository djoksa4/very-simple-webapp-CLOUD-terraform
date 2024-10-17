
#### ALB DNS name (used in frontend JS code to send backend requests to) ########################
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}


#### RDS endpoint (used in backend Python code to communicate with the DB) ######################
output "rds_enpoint" {
  value = aws_db_instance.this.endpoint
}