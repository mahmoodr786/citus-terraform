variable "region" {
  default = "us-east-1"
}
variable "ami_id" {
  default = "ami-051027b61544b3d11"
}
variable "keypair" {
  default = "citus-keypair"
}
variable "instance_type" {
  default = "m7i.2xlarge"
}
variable "volume_size" {
  default = 1000 # 1TB
}
variable "volume_type" {
  default = "gp3"
}
variable "ssh_user" {
  default = "ubuntu"
}