variable "install_script" {
  type = string
  default = ""
}

variable "maintenance_script" {
  type = string
  default = ""
}

variable "published_ports" {
  type = list(number)
  default = []
}

variable "name" {
  type = string
}

variable "suffix" {
  type = string
  default = ""
}

variable "prefix" {
  type = string
  default = ""
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "aws_account" {
  type = string
  default = null
}

variable "aws_log_group" {
  type = string
}

variable "aws_log_retention_days" {
  type = number
  default = 90
  description = "Number of days to retain CloudWatch log streams (log_retention). Used by the EC2 instance for log retention."
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "access_key" {
  type = string
  default = null
}

variable "secrets" {
  type = map(string)
  default = {}
  description = "Pull in values from aws secrets.  Map keys will be used to prefix the keys in the secrets then they will be made available as environment variables which can be referenced from the docker-compose file."
}

variable "sync_period" {
  type = number
  default = 600
  description = "Seconds between 'sync' events.  The system periodically pulls secrets and docker images and restarts/configures running services as appropriate.  This setting controls how frequently"
}

variable "permissions_boundary" {
  type = string
  default = null
  description = "Permissions boundary to apply to the ec2 user"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "iam_role_arn" {
  type = string
  default = null
  description = "ARN of an existing IAM instance profile to attach to the EC2 instance. If set, no IAM role or instance profile will be created. Set to the instance profile name or ARN."
}

variable "environment" {
  type = map(string)
  default = {}
  description = "Static environment variables to make available to the scripts"
}
