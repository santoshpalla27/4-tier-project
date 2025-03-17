provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./vpc"
  cidr_block = "10.0.0.0/16"
  public_subnet_cidr = ["10.0.1.0/24" , "10.0.2.0/24","10.0.3.0/24" , "10.0.4.0/24"]
  private_subnet_cidr = ["10.0.5.0/24" , "10.0.6.0/24","10.0.7.0/24" , "10.0.8.0/24"]
  availability_zone = ["us-east-1a", "us-east-1b"] 
}

module "ec2-frotend" {
  source = "./ec2"
  ami = "ami-08b5b3a93ed654d19"
  instance_type = "t2.micro"
  key_name = "santosh"
  security_group_id = module.vpc.frotend_sg_security_groups
  subnet_id = module.vpc.public_subnet_ids[0]
  name = "frotend"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html  
              EOF
}

module "ec2-backend" {
  source = "./ec2"
  ami = "ami-08b5b3a93ed654d19"
  instance_type = "t2.micro"
  key_name = "santosh"
  security_group_id = module.vpc.backend_sg_security_groups
  subnet_id = module.vpc.private_subnet_ids[0]
  name = "backend"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html  
              EOF
}

module "cache-ec2" {
  source = "./ec2"
  ami = "ami-08b5b3a93ed654d19"
  instance_type = "t2.micro"
  key_name = "santosh"
  security_group_id = module.vpc.cache_sg_security_groups
  subnet_id = module.vpc.private_subnet_ids[1]
  name = "cache"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html  
              EOF
}

resource "aws_db_instance" "database" {
  identifier = "database"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  username = "admin"
  password = "admin123"
  multi_az = false
  publicly_accessible = false
  skip_final_snapshot = true
  vpc_security_group_ids = [module.vpc.database_sg_security_groups]
  db_subnet_group_name = module.vpc.rds_subnet_group
  tags = {
    Name = "database"
  }
}




