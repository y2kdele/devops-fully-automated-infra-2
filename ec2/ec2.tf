variable "name" {
  type        = string
  description = "name tag value"
}

variable "tags" {
  type        = map(any)
  description = "tags for the vpc module"
}

variable "iam_role_name" {
  type        = string
  description = "iam role name to attach to the instance profile"
}

variable "key_pair_name" {
  type        = string
  description = "keypair to utilize"

}
variable "aws_security_group" {
  type = string
  description = " describe security group"
}

resource "aws_security_group" "jenkins-sg" {
  name        = var.aws_security_group
  description = "Allow  traffic for http and ssh"
  vpc_id = var.vpc


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks =  [
      "0.0.0.0/0",
      "10.0.2.183"
    ]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    description = "allow inbound traffic for node-exporter"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    description = "allow inbound traffic for jenkins"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "jenkins_server" {
  name = join("", [var.name, "-", "iam-instance-profile"])
  role = var.iam_role_name
}



resource "aws_instance" "web_server" {
  ami                    = "ami-0cc87e5027adcdca8"
  instance_type          = "t3.small"
  metadata_options {
    
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = file("scripts/userdata.sh")
  iam_instance_profile   = aws_iam_instance_profile.jenkins_server.name
  tags                   = merge(var.tags, { Name = join("", [var.name, "-", "webserver"]) }, { Environment = var.name })


  # best practices as per checkov scanner

  monitoring    = true
  ebs_optimized = true
  root_block_device {
    encrypted = true
  }

}
