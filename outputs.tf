output "aws_vpc" {
  value = data.aws_vpc.production
}

output "aws_subnet_az1" {
  value = data.aws_subnet.az1
}
output "aws_subnet_az2" {
  value = data.aws_subnet.az2
}
output "aws_subnet_az3" {
  value = data.aws_subnet.az3
}
output "iam_profile" {
  value = data.aws_iam_instance_profile.iam_profile
}
output "sg" {
  value = data.aws_security_group.sg
}