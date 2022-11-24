provider "aws" {
  region = "us-west-2"
}

variable "defaulttag" {
  type = string
  default = "dev-mastodon"
}

resource "aws_vpc" "main" {
    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default"

    tags = {
      Name = "${var.defaulttag}"
    }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_subnet" "pub1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_subnet" "pub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_subnet" "priv1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.100.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_subnet" "priv2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.200.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.pub1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.pub2.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "allow_ssh_https" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_security_group" "allow_postgres" {
  name        = "postgres"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_security_group" "allow_redis" {
  name        = "redis"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.priv1.id, aws_subnet.priv2.id]

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.priv1.id, aws_subnet.priv2.id]
}

resource "aws_db_instance" "mastodon-db" {
  identifier             = "mastodon-db"
  db_name                = "mastodon_production"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.allow_postgres.id]
  username               = "mastodon"
  password               = "change-later"
  db_subnet_group_name   = "${aws_db_subnet_group.main.name}"
  publicly_accessible    = false

  tags = {
    Name = "${var.defaulttag}"
  }
}

resource "aws_elasticache_cluster" "mastodon-redis" {
  cluster_id           = "mastodon-redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  security_group_ids = [aws_security_group.allow_redis.id]
  subnet_group_name   = "${aws_elasticache_subnet_group.main.name}"
}