# AWS EC2 Docker Compose Terraform Module

This Terraform module (`aws-ec2-docker-compose`) provisions an EC2 instance pre-configured to run dockerized workloads using Docker Compose. It is designed for automated deployment of services defined in a `docker-compose.yml`, with support for periodic updates and secrets management from AWS Secrets Manager.

## Features
- Provisions an EC2 instance with Docker and Docker Compose installed
- Accepts a `docker-compose.yml` (as a string variable)
- Periodically refreshes secrets, pulls new images, and restarts services
- Automatically configures AWS CloudWatch logging for all Docker Compose services
- Injects secrets from AWS Secrets Manager as environment variables
- Supports custom VPC, subnet, and tagging
- Restricts ingress sources per port via `ingress_rules`, including a `"*"` catchall for all other ports
- Assigns an IPv6 address to the instance by default (`ipv6_enabled`), with IPv6 egress and inbound rules to match
- Allows existing IAM instance profile to be attached, or creates a new one
- Supports static environment variables
- Supports custom install and maintenance scripts (`install_script`, `maintenance_script`)
- **Supports configurable CloudWatch log retention days via `aws_log_retention_days` (default: 90)**
- **Optional CloudWatch agent: can be disabled (`cloudwatch_agent_enabled`) or extended to publish memory/disk metrics (`cloudwatch_metrics_enabled`)**

## Usage Example
```hcl
module "ec2_docker_compose" {
  source               = "./aws-ec2-docker-compose"
  name                 = "my-app"
  prefix               = "dev-"
  suffix               = "-01"
  aws_region           = "us-east-1"
  aws_account          = "123456789012"
  aws_log_group        = "/aws/my-app/logs"
  aws_log_retention_days = 30 # <--- Optional! Default: 90
  cloudwatch_metrics_enabled = true # <--- Optional! Publish memory/disk metrics. Default: false
  published_ports      = [80, 443]
  ipv6_enabled = true # <--- Default. Set false for IPv4-only subnets
  ingress_rules = {
    "*"   = { cidr_blocks = ["10.0.0.0/8"], ipv6_cidr_blocks = ["2001:db8::/32"] }
    "22"  = { cidr_blocks = ["203.0.113.0/24"] } # SSH from admin CIDR only
    "443" = { security_groups = ["sg-0abc123def456789"] }
  }
  vpc_id               = "vpc-xxxxxxxx"
  subnet_ids           = ["subnet-xxxxxxxx"]
  docker_compose_yaml  = file("./docker-compose.yml")
  secrets = {
    "APP" = "my/app/secrets"
  }
  tags = {
    Environment = "dev"
    Project     = "my-app"
  }
  environment = {
    ENVIRONMENT = "dev"
    FOO         = "bar"
  }
  install_script = <<EOF
    # Custom install commands here
    echo "Custom install logic"
  EOF
  maintenance_script = <<EOF
    # Custom maintenance commands here
    echo "Custom maintenance logic"
  EOF
}
```

## Variables
| Name                  | Type           | Description |
|-----------------------|----------------|-------------|
| `docker_compose_yaml` | string         | Contents of your `docker-compose.yml` file |
| `name`                | string         | Name for resources |
| `prefix`              | string         | Prefix for resource names (optional) |
| `suffix`              | string         | Suffix for resource names (optional) |
| `published_ports`     | list(number)   | TCP ports to open (besides SSH); sources are set by `ingress_rules` |
| `ingress_rules`       | map(object)    | Per-port sources (`cidr_blocks`, `ipv6_cidr_blocks`, `security_groups`, `prefix_list_ids`, optional `description`), keyed by port string or `"*"` for the catchall. Defaults to `["0.0.0.0/0"]` and `["::/0"]` for the catchall; `{}` closes all ingress |
| `ipv6_enabled`        | bool           | Assign one IPv6 address and allow `::/0` egress (default: `true`). Set `false` for IPv4-only VPCs/subnets |
| `tags`                | map(string)    | Additional AWS tags |
| `aws_region`          | string         | AWS region |
| `aws_account`         | string         | AWS Account number |
| `aws_log_group`       | string         | CloudWatch log group name |
| `aws_log_retention_days` | number      | Number of days to retain log streams (default: 90) |
| `cloudwatch_agent_enabled` | bool      | Install the CloudWatch agent to ship `/var/log/*.log` (default: true). Container logs use the awslogs driver regardless |
| `cloudwatch_metrics_enabled` | bool    | Also publish memory and disk usage metrics via the agent (default: false) |
| `cloudwatch_metrics_interval` | number | Seconds between metric collections (default: 60) |
| `cloudwatch_metrics_namespace` | string | CloudWatch namespace for metrics (default: `CWAgent`) |
| `instance_type`       | string         | EC2 instance type (default: t3.micro) |
| `ami_id`              | string         | AMI ID to use (default: built-in Amazon Linux 2023 AMI for the region). Must be dnf-based |
| `root_volume_size`    | number         | Root EBS volume size in GiB (default: `null`, inherit from the AMI). Must be at least the AMI snapshot size; changing it forces instance replacement |
| `access_key`          | string         | SSH key name for instance access (optional) |
| `secrets`             | map(string)    | Map of env var prefix to AWS Secrets Manager secret ID |
| `sync_period`         | number         | Seconds between periodic maintenance (default: 600) |
| `permissions_boundary`| string         | IAM permissions boundary ARN (optional) |
| `vpc_id`              | string         | VPC ID for the instance |
| `subnet_ids`          | list(string)   | List of subnet IDs (first is used) |
| `iam_role_arn`        | string         | Existing IAM role/profile ARN to attach (optional) |
| `environment`         | map(string)    | Static environment variables to make available to the scripts |
| `install_script`      | string         | Additional bash script to run during install, after Docker Compose setup |
| `maintenance_script`  | string         | Additional bash script to run as part of the maintenance cycle, after docker-compose up |

See `variables.tf` for full details.

## Outputs
| Name          | Description |
|---------------|-------------|
| `ec2_instance`| The full aws_instance resource for the EC2 host |
| `ec2_ipv6_addresses` | IPv6 addresses assigned to the instance (empty when `ipv6_enabled = false`) |

## How It Works
- The module renders your `docker-compose.yml` (passed as a variable) onto the EC2 instance.
- Each service is configured for AWS CloudWatch logging automatically.
- Secrets from AWS Secrets Manager are fetched and injected as environment variables, prefixed with your chosen key (e.g. `APP_DATABASE_PASSWORD`).
- The instance runs a periodic maintenance script that pulls new images, refreshes secrets, and restarts services as necessary.
- Static environment variables provided via the `environment` variable are made available to the scripts.
- You can append custom logic to the install and maintenance phases via `install_script` and `maintenance_script` variables.
- **You can control CloudWatch log retention days using the `aws_log_retention_days` variable (default: 90)**

## Requirements
- Terraform 0.13+
- AWS provider
- Supported regions: see underlying EC2 module for AMI map (defaults to Amazon Linux 2023)

## Notes
- SSH access (port 22) is only enabled if `access_key` is set.
- Set `ami_id` to use your own AMI or to run in a region not in the built-in AMI map.
- You may use your own IAM role/profile by setting `iam_role_arn`.
- `ingress_rules` restricts who can reach the published ports. `"*"` is the catchall for any port without its own rule (including SSH); a numeric key overrides it for that port and also opens that port. The default catchall allows `0.0.0.0/0` and `::/0`; set `ingress_rules = {}` to close all ingress.
- IPv6 is enabled by default. The VPC and subnet need an IPv6 CIDR block and a route to `::/0`; set `ipv6_enabled = false` in IPv4-only networks.

## License
MIT or as specified by the repository.
