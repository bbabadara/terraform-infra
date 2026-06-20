variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "Type EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nom de la clé SSH AWS"
  type        = string
}

variable "project_name" {
  default = "3tiers-app"
}