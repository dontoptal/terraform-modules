variable "docker_compose_yaml" {
  type = string

  validation {
    condition     = !can(regex("(?m)^DOCKER_COMPOSE_YAML_EOF$", var.docker_compose_yaml))
    error_message = "docker_compose_yaml must not contain a line consisting solely of DOCKER_COMPOSE_YAML_EOF."
  }
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

variable "ingress_rules" {
  type = map(object({
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    prefix_list_ids  = optional(list(string), [])
    description      = optional(string)
  }))
  default = {
    "*" = {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  description = "Sources allowed to reach TCP ingress, passed through to the aws-ec2 module. Keys are port numbers as strings (e.g. \"443\") or \"*\" for the catchall used by any port without its own rule, including SSH when access_key is set. A numeric key also opens that port even if it is not listed in published_ports. The default catchall allows both IPv4 and IPv6 from anywhere; an empty map closes all ingress."

  validation {
    condition = alltrue([
      for port in keys(var.ingress_rules) :
      port == "*" || try(tonumber(port) >= 1 && tonumber(port) <= 65535 && tostring(tonumber(port)) == port, false)
    ])
    error_message = "ingress_rules keys must be \"*\" or a port number from 1 to 65535 written as a plain decimal string (e.g. \"443\")."
  }

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) :
      length(rule.cidr_blocks) + length(rule.ipv6_cidr_blocks) + length(rule.security_groups) + length(rule.prefix_list_ids) > 0
    ])
    error_message = "Each ingress_rules entry must include at least one of cidr_blocks, ipv6_cidr_blocks, security_groups or prefix_list_ids."
  }
}

variable "ipv6_enabled" {
  type        = bool
  default     = true
  description = "Assign one IPv6 address to the instance and allow IPv6 egress (::/0), passed through to the aws-ec2 module. Requires an IPv6 CIDR block on the VPC and subnet, plus a route to ::/0. Set to false for IPv4-only subnets."
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

variable "root_volume_size" {
  type        = number
  default     = null
  description = "Size of the root EBS volume in GiB. Null inherits the size from the AMI. Must be at least as large as the AMI snapshot. Changing this on an existing instance forces replacement so cloud-init can grow the filesystem on first boot."
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
