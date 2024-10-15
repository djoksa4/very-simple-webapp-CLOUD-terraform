resource "aws_db_subnet_group" "main" {
  name       = "main_db_subnet_group"
  subnet_ids = [aws_subnet.priv-subnet-a.id, aws_subnet.priv-subnet-b.id]
}

resource "aws_db_instance" "this" {
  allocated_storage      = 20
  max_allocated_storage  = 20
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  db_name                = "counterdb"
  username               = "postgres"
  password               = "postgres" # Ensure this is securely managed
  publicly_accessible    = false
  storage_type           = "gp2"
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.rds.id]

  db_subnet_group_name = aws_db_subnet_group.main.name

  skip_final_snapshot = true
}