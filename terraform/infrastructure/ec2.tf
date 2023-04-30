# ---------- Linux AMI, Role, Key Pair
data "aws_ssm_parameter" "linuxAmiMaster" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_iam_role" "ec2-role" {
  name = "ec2-role"
}

resource "aws_iam_instance_profile" "session_manager" {
  name = "session_manager"
  role = data.aws_iam_role.ec2-role.name
}

resource "aws_key_pair" "instance_key" {
  key_name   = "hackers-playground"
  public_key = file("~/.ssh/hackers-playground.pub")
}

# ---------- Bastion
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.linuxAmiMaster.value
  iam_instance_profile        = aws_iam_instance_profile.session_manager.name
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.instance_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.bastion_instance_sg.id]
  tags = {
    Name = "bastion"
  }
  depends_on = [aws_route_table_association.public_rt_association]
}

resource "aws_security_group" "bastion_instance_sg" {
  name        = "bastion-instance-sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.sandbox_vpc.id
  ingress {
    description = "Allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow anyone on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- Kali
resource "aws_instance" "kali_vm" {
  ami                         = "ami-03a63adf60b12f091"
  iam_instance_profile        = aws_iam_instance_profile.session_manager.name
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.instance_key.key_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.kali_instance_sg.id]
  subnet_id                   = aws_subnet.private_subnet.id
  tags = {
    Name = "kali-vm-1"
  }
  depends_on = [aws_route_table_association.private_rt_association]
}

resource "aws_security_group" "kali_instance_sg" {
  name        = "kali-instance-sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.sandbox_vpc.id
  ingress {
    description = "Allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
  ingress {
    description = "Allow anyone on port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
