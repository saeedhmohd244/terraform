provider "aws" {
    region = "us-east-1"
}

//creating an s3 bucket
   resource "aws_s3_bucket" "mybucket" {
     bucket = "mybucket123"
     acl    = "read"
     versioning {
       enabled = true
     }
   }

//creating a vpc
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr_block
}

//creating a subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true    
}

//creating a internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

//creating a routetable
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.myvpc.id
}

//Associate Subnets with the Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.route.id
}

//setting security groups
resource "aws_security_group" "sg" {
    name        = "my-sg"
    description = "Allow inbound traffic on port 22 and 80"
    vpc_id      = aws_vpc.myvpc.id

    ingress {
    description  = "ssh"
    from_port    = 22
    to_port      = 22
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
    }

    ingress {
        description  = "http"
        from_port    = 80
        to_port      = 80
        protocol     = "tcp"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    ingress {
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

//creating key pair
resource "aws_key_pair" "keypair" {
    public_key = file("~/.ssh/id_rsa.pub")
}

// creating a ec2 instance
resource "aws_instance" "server" {
  ami           = var.ami
  instance_type = var.instance_type

  # Use security group IDs, not names
  vpc_security_group_ids = [aws_security_group.sg.id]
  
  subnet_id = aws_subnet.public.id
  key_name  = aws_key_pair.keypair.id

  tags = {
    Name = "terraform"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.server.id
  }

  provisioner "file" {
    source      = "/mnt/c/Users/saeedh/Downloads/shellscripts/jenkins.sh"
    destination = "/home/ubuntu/jenkins.sh/"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x jenkins.sh",
      "sudojenkins.sh",
    ]
  }
}
