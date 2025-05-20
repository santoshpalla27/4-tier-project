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

# IAM Role for EC2 to describe EC2 instances
resource "aws_iam_role" "ec2_describe_role" {
  name = "ec2-describe-instances-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2-Describe-Instances-Role"
  }
}

# Policy allowing EC2 instances to describe other EC2 instances
resource "aws_iam_policy" "ec2_describe_policy" {
  name        = "ec2-describe-instances-policy"
  description = "Allow EC2 instances to describe other EC2 instances"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ec2_describe_policy_attach" {
  role       = aws_iam_role.ec2_describe_role.name
  policy_arn = aws_iam_policy.ec2_describe_policy.arn
}

# Create the instance profile
resource "aws_iam_instance_profile" "ec2_describe_profile" {
  name = "ec2-describe-instances-profile"
  role = aws_iam_role.ec2_describe_role.name
}

# Output the instance profile name (to use when launching instances)
output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_describe_profile.name
}


module "ec2-frotend" {
  source = "./ec2"
  ami = "ami-08b5b3a93ed654d19"
  instance_type = "t2.micro"
  key_name = "santosh"
  security_group_id = module.vpc.frotend_sg_security_groups
  subnet_id = module.vpc.public_subnet_ids[0]
  name = "frotend"
  depends_on = [ module.ec2-backend ]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install ansible git -y
              git clone https://github.com/santoshpalla27/4-tier-project.git
              cd 4-tier-project/ansible
              /usr/bin/ansible-playbook frontend.yaml
              EOF
  instance_profile_name = aws_iam_instance_profile.ec2_describe_profile.name
}

module "ec2-backend" {
  source = "./ec2"
  ami = "ami-08b5b3a93ed654d19"
  instance_type = "t2.micro"
  key_name = "santosh"
  security_group_id = module.vpc.backend_sg_security_groups
  subnet_id = module.vpc.private_subnet_ids[0]
  name = "backend"
  depends_on = [ aws_db_instance.database , module.cache-ec2 ]
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install ansible git -y
              git clone https://github.com/santoshpalla27/4-tier-project.git
              cd 4-tier-project/ansible
              /usr/bin/ansible-playbook backend.yaml 
              EOF
   instance_profile_name = aws_iam_instance_profile.ec2_describe_profile.name
}

module "cache-ec2" {
  source = "./ec2"
  count = 4
  ami = "ami-08b5b3a93ed654d19"
  instance_type = "t2.micro"
  key_name = "santosh"
  security_group_id = module.vpc.cache_sg_security_groups
  subnet_id = module.vpc.private_subnet_ids[count.index % 2]
  name = "cache${count.index}"
  instance_profile_name = aws_iam_instance_profile.ec2_describe_profile.name
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install ansible git -y
              git clone https://github.com/santoshpalla27/4-tier-project.git
              cd 4-tier-project/ansible
              /usr/bin/ansible-playbook redis.yaml
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




