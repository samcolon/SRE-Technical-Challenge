# --- AMI lookup for Amazon Linux 2023 (x86_64)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64*"]
  }
}

# --- Management SSH key: place PUBLIC key at <repo-root>/envs/mgmt_id_rsa.pub
resource "aws_key_pair" "mgmt" {
  key_name   = "${var.project_name}-mgmt"
  public_key = file("${path.root}/envs/mgmt_id_rsa.pub")
}

# --- Security Group for Management instance
resource "aws_security_group" "mgmt" {
  name        = "${var.project_name}-mgmt-sg"
  description = "SSH bastion access"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH from operator IP"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-mgmt-sg" }
}

# --- Management EC2 instance (public)
resource "aws_instance" "mgmt" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t2.micro"
  subnet_id                   = var.mgmt_public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.mgmt.id]
  key_name                    = aws_key_pair.mgmt.key_name
  associate_public_ip_address = true

  tags = { Name = "${var.project_name}-mgmt" }
}

# --- App tier Security Group (no inline ingress; rules created below)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "App instances"
  vpc_id      = var.vpc_id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-app-sg" }
}

# Allow HTTP from ALB SG -> App SG
resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = var.alb_sg_id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "HTTP from ALB"
}

# Allow SSH from Management SG -> App SG
resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_mgmt" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.mgmt.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from management"
}

# --- Launch Template for app ASG
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.mgmt.key_name

  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = base64encode(file(var.app_user_data_path))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-app" }
  }
}

# --- App Auto Scaling Group (min 2, max 6)
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  max_size            = 6
  min_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = var.app_subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arn]

  health_check_type         = "ELB" # use LB/TG health checks
  health_check_grace_period = 90

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}

output "mgmt_public_ip" {
  value = aws_instance.mgmt.public_ip
}
