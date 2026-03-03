# AWS EC2 Docker Compose Terraform Module

This Terraform module (`aws-ec2-docker-compose`) provisions an EC2 instance pre-configured to run dockerized workloads using Docker Compose. It is designed for automated deployment of services defined in a `docker-compose.yml`, with support for periodic updates and secrets management from AWS Secrets Manager.

## Features
- Provisions an EC2 instance with Docker and Docker Compose installed
- Accepts a `docker-compose.yml` (as a string variable)
- Periodically refreshes secrets, pulls new images, and restarts services
- Automatically configures AWS CloudWatch logging for all Docker Compose services
- Injects secrets from AWS Secrets Manager as environment variables
- Supports custom VPC, subnet, and tagging
- Allows existing IAM instance profile to be attached, or creates a new one
- Supports static environment variables

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
  published_ports      = [80, 443]
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
}
```

## Variables
| Name                  | Type           | Description |
|-----------------------|----------------|-------------|
| `docker_compose_yaml` | string         | Contents of your `docker-compose.yml` file |
| `name`                | string         | Name for resources |
| `prefix`              | string         | Prefix for resource names (optional) |
| `suffix`              | string         | Suffix for resource names (optional) |
| `published_ports`     | list(number)   | TCP ports to open to the world (besides SSH) |
| `tags`                | map(string)    | Additional AWS tags |
| `aws_region`          | string         | AWS region |
| `aws_account`         | string         | AWS Account number |
| `aws_log_group`       | string         | CloudWatch log group name |
| `instance_type`       | string         | EC2 instance type (default: t3.micro) |
| `access_key`          | string         | SSH key name for instance access (optional) |
| `secrets`             | map(string)    | Map of env var prefix to AWS Secrets Manager secret ID |
| `sync_period`         | number         | Seconds between periodic maintenance (default: 600) |
| `permissions_boundary`| string         | IAM permissions boundary ARN (optional) |
| `vpc_id`              | string         | VPC ID for the instance |
| `subnet_ids`          | list(string)   | List of subnet IDs (first is used) |
| `iam_role_arn`        | string         | Existing IAM role/profile ARN to attach (optional) |
| `environment`         | map(string)    | Static environment variables to make available to the scripts |

See `variables.tf` for full details.

## Outputs
| Name          | Description |
|---------------|-------------|
| `ec2_instance`| The full aws_instance resource for the EC2 host |

## How It Works
- The module renders your `docker-compose.yml` (passed as a variable) onto the EC2 instance.
- Each service is configured for AWS CloudWatch logging automatically.
- Secrets from AWS Secrets Manager are fetched and injected as environment variables, prefixed with your chosen key (e.g. `APP_DATABASE_PASSWORD`).
- The instance runs a periodic maintenance script that pulls new images, refreshes secrets, and restarts services as necessary.
- Static environment variables provided via the `environment` variable are made available to the scripts.

## Requirements
- Terraform 0.13+
- AWS provider
- Supported regions: see underlying EC2 module for AMI map (defaults to Amazon Linux 2023)

## Notes
- SSH access (port 22) is only enabled if `access_key` is set.
- Extend the AMI map in the underlying EC2 module if you need other regions.
- You may use your own IAM role/profile by setting `iam_role_arn`.

## License
MIT or as specified by the repository.
