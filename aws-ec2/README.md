# AWS EC2 Terraform Module

This Terraform module provisions an Amazon EC2 instance with optional IAM role/profile attachment, security group, and user data script for use cases such as service deployments or custom automation. It is designed to be flexible and reusable for a variety of workloads.

## Features
- Provisions a single EC2 instance with selectable instance type and AMI (Amazon Linux 2023 by default for supported regions)
- Creates and attaches a security group allowing SSH (if `access_key` is set) and any additional published ports
- Optionally creates and attaches an IAM role and instance profile, or attaches an existing one
- Supports execution of custom install and maintenance scripts via user data
- Automatically fetches secrets from AWS Secrets Manager and exposes them as environment variables
- Tags resources appropriately for traceability

## Usage Example
```hcl
module "ec2" {
  source            = "./aws-ec2"
  name              = "app-server"
  vpc_id            = "vpc-12345678"
  subnet_ids        = ["subnet-1234abcd"]
  aws_region        = "us-east-1"
  aws_log_group     = "/aws/custom/app-server"
  published_ports   = [8080, 443]
  access_key        = "my-ssh-key"
  instance_type     = "t3.micro"
  tags = {
    Environment = "dev"
    Project     = "example"
  }
  secrets = {
    "APP" = "my/app/secret"
  }
}
```

## Variables
| Name                 | Type          | Default       | Description |
|----------------------|---------------|---------------|-------------|
| `install_script`     | string        | `""`         | Bash commands to run during instance provisioning (install phase) |
| `maintenance_script` | string        | `""`         | Bash commands to run periodically (maintenance phase) |
| `published_ports`    | list(number)  | `[]`          | TCP ports to open to the world (besides SSH) |
| `name`               | string        | required      | Name for resources |
| `prefix`             | string        | `""`         | Prefix for resource names |
| `suffix`             | string        | `""`         | Suffix for resource names |
| `tags`               | map(string)   | `{}`          | Additional AWS tags |
| `aws_region`         | string        | `"us-east-1"`| AWS region |
| `aws_account`        | string        | `null`        | AWS account number (optional) |
| `aws_log_group`      | string        | required      | CloudWatch log group name |
| `instance_type`      | string        | `"t3.micro"` | EC2 instance type |
| `access_key`         | string        | `null`        | SSH key name for instance access (enables port 22/SSH) |
| `secrets`            | map(string)   | `{}`          | Map of environment prefix to AWS Secrets Manager secret ID |
| `sync_period`        | number        | `600`         | Seconds between maintenance/script runs |
| `permissions_boundary`| string       | `null`        | IAM permissions boundary ARN (optional) |
| `vpc_id`             | string        | required      | VPC ID for the instance |
| `subnet_ids`         | list(string)  | required      | List of subnet IDs (first is used) |
| `iam_role_arn`       | string        | `null`        | Existing IAM role/profile ARN to attach (skips creation if set) |

## Outputs
| Name            | Description |
|-----------------|-------------|
| `ec2_public_ip` | The public IP address of the EC2 instance |
| `iam_role`      | The IAM role ARN used by the instance |
| `ec2_instance`  | The full aws_instance resource |

## Secrets Handling
Secrets defined in the `secrets` variable are fetched from AWS Secrets Manager. Each secret is loaded and its key-value pairs are converted to environment variables, prefixed and uppercased. For example, if you define:
```hcl
secrets = {
  "APP" = "my/app/secret"
}
```
Then the key `password` in the secret will become `APP_PASSWORD` in the instance environment.

## User Data Scripts
- `install_script`: Runs once at instance provisioning, suitable for package installs, etc.
- `maintenance_script`: Runs periodically in the background (default: every 600 seconds), suitable for updates, checks, etc.

## Requirements
- Terraform 0.13+
- AWS provider
- Supported regions: `us-east-1`, `eu-west-1` (for built-in AMI map, can be extended)

## Notes
- By default, the EC2 instance receives a basic CloudWatch Agent role for logging.
- SSH access is only enabled if you set `access_key`.
- Extend the AMI map in `main.tf` if you need other regions.

## License
MIT or as specified by the repository.
