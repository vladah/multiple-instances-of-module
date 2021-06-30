variable "server_name" {
  type = string
}

variable "server_type" {
  type    = string
  default = "t2.micro"
}

# variable "server_ami" {
#   type = string
# }

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.server_type

  tags = {
    Name = "Server ${var.server_name}"
  }
}

output "ser_name" {
  value = aws_instance.server.tags.Name
}

output "ser_id" {
  value = aws_instance.server.id
}
