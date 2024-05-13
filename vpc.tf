resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-main"
  }
}

resource "aws_subnet" "public_us_east_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-public-us-east-1a"
  }
}

resource "aws_subnet" "public_us_east_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = local.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-public-us-east-1b"
  }
}

resource "aws_subnet" "private_us_east_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = local.availability_zones[0]

  tags = {
    Name = "tf-private-us-east-1a"
  }
}

resource "aws_subnet" "private_us_east_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = local.availability_zones[1]

  tags = {
    Name = "tf-private-us-east-1b"
  }
}

resource "aws_internet_gateway" "default_internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-default-internet-gateway"
  }
}

resource "aws_eip" "public_us_east_1a_nat_eip" {
}

resource "aws_nat_gateway" "public_us_east_1a_nat_gateway" {
  allocation_id = aws_eip.public_us_east_1a_nat_eip.id
  subnet_id     = aws_subnet.public_us_east_1a.id

  tags = {
    "Name" = "tf-nat-gateway"
  }
}

resource "aws_eip" "public_us_east_1b_nat_eip" {
}

resource "aws_nat_gateway" "public_us_east_1b_nat_gateway" {
  allocation_id = aws_eip.public_us_east_1b_nat_eip.id
  subnet_id     = aws_subnet.public_us_east_1b.id

  tags = {
    "Name" = "tf-nat-gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_internet_gateway.id
  }

  tags = {
    Name = "tf-public-route-table"
  }
}

resource "aws_route_table" "private_us_east_1a_route_table" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_us_east_1a_nat_gateway.id
  }

  tags = {
    Name = "tf-private-us-east-1a-route-table"
  }
}

resource "aws_route_table" "private_us_east_1b_route_table" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_us_east_1b_nat_gateway.id
  }

  tags = {
    Name = "tf-private-us-east-1b-route-table"
  }
}

resource "aws_route_table_association" "public_us_east_1a_subnet_route_table_association" {
  subnet_id      = aws_subnet.public_us_east_1a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_us_east_1b_subnet_route_table_association" {
  subnet_id      = aws_subnet.public_us_east_1b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_us_east_1a_subnet_route_table_association" {
  subnet_id      = aws_subnet.private_us_east_1a.id
  route_table_id = aws_route_table.private_us_east_1a_route_table.id
}

resource "aws_route_table_association" "private_us_east_1b_subnet_route_table_association" {
  subnet_id      = aws_subnet.private_us_east_1b.id
  route_table_id = aws_route_table.private_us_east_1b_route_table.id
}
