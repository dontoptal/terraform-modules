variable "docker_compose_yaml" {
  type = string
}

variable "name" {
  type = string
}

variable "prefix" {
  type = string
  default = ""
}

variable "suffix" {
  type = string
  default = ""
}

variable "published_ports" {
  type = list(number)
  default = []
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "aws_region" {
  type = string
}

variable "aws_account" {
  type = string
}

variable "aws_log_group" {
  type = string
}

variable "aws_log_retention_days" {
  type = number
  default = 90
  description = "Number of days to retain CloudWatch log streams (log_retention). Used by the EC2 instance for log retention."
}

variable "cloudwatch_agent_enabled" {
  type = bool
  default = true
  description = "Install and configure the CloudWatch agent to ship /var/log/*.log to the CloudWatch log group. Set to false to skip installing the agent. Docker container logs are shipped by the awslogs driver regardless."
}

variable "cloudwatch_metrics_enabled" {
  type = bool
  default = false
  description = "Have the CloudWatch agent also publish memory and disk usage metrics (dimensioned by InstanceId). Requires cloudwatch_agent_enabled."
}

variable "cloudwatch_metrics_interval" {
  type = number
  default = 60
  description = "Seconds between metric collections when cloudwatch_metrics_enabled is true."
}

variable "cloudwatch_metrics_namespace" {
  type = string
  default = "CWAgent"
  description = "CloudWatch namespace for metrics published by the agent when cloudwatch_metrics_enabled is true."
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "ami_id" {
  type = string
  default = null
  description = "AMI ID to launch the instance from. If not set, the built-in Amazon Linux 2023 AMI for aws_region is used. The AMI must be dnf-based (e.g. Amazon Linux 2023), as the install scripts use dnf."
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

variable "subnet_ids"{
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

variable "install_script" {
  type = string
  default = ""
  description = "Additional bash script to run during install, after Docker Compose setup."
}

variable "maintenance_script" {
  type = string
  default = ""
  description = "Additional bash script to run as part of the maintenance cycle, after docker-compose up."
}
