data "aws_vpc" "production" {
  tags = {
    Name = "Production"
  }
}
data "aws_subnet" "az1" {
  vpc_id = data.aws_vpc.production.id
  tags = {
    Name = "PRD_PRV_AZ1"
  }
}
data "aws_subnet" "az2" {
  vpc_id = data.aws_vpc.production.id
  tags = {
    Name = "PRD_PRV_AZ2"
  }
}
data "aws_subnet" "az3" {
  vpc_id = data.aws_vpc.production.id
  tags = {
    Name = "PRD_PRV_AZ3"
  }
}
data "aws_iam_instance_profile" "iam_profile" {
  name = "AWS_SSM_Profile"
}
data "aws_security_group" "sg" {
  name   = "PRD_PRV_SG"
  vpc_id = data.aws_vpc.production.id
}
data "aws_kms_key" "kms_key" {
  key_id = "arn:aws:kms:us-east-1:000000000000:key/01234yf4-756a-4b36-a97e-36c723c93d71"
}