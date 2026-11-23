# AWS EC2 Terraform Module

This Terraform module provisions an Amazon EC2 instance with optional IAM role/profile attachment, security group, and user data script for use cases such as service deployments or custom automation. It is designed to be flexible and reusable for a variety of workloads.

## Features
- Provisions a single EC2 instance with selectable instance type and AMI (Amazon Linux 2023 by default for supported regions)
- Creates and attaches a security group allowing SSH (if `access_key` is set) and any additional published ports
- Optionally creates and attaches an IAM role and instance profile, or attaches an existing one
- Supports execution of custom install and maintenance scripts via user data
- Automatically fetches secrets from AWS Secrets Manager and exposes them as environment variables
- **Allows setting static environment variables via the `environment` variable**
- **Supports configurable CloudWatch log retention days via `aws_log_retention_days` (default: 90)**
- **Optional CloudWatch agent: can be disabled (`cloudwatch_agent_enabled`) or extended to publish memory/disk metrics (`cloudwatch_metrics_enabled`)**
- Tags resources appropriately for traceability

## Usage Example
```hcl
module "ec2" {
  source            = "github.com/dontoptal/terraform-modules//aws-ec2?ref=aws-ec2-v1.5.0"
  name              = "app-server"
  vpc_id            = "vpc-12345678"
  subnet_ids        = ["subnet-1234abcd"]
  aws_region        = "us-east-1"
  aws_log_group     = "/aws/custom/app-server"
  aws_log_retention_days = 60 # <--- Optional! Default: 90
  cloudwatch_metrics_enabled = true # <--- Optional! Publish memory/disk metrics. Default: false
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
  environment = {
    FOO = "bar"
    BAZ = "qux"
  }
  volumes = {
    "/mnt/data" = {
      id          = "vol-1234567890abcdef0"
      device_name = "/dev/sdf"
      format      = false  # Must be pre-formatted (default)
    }
    "/mnt/logs" = {
      id          = "vol-0987654321fedcba0"
      device_name = "/dev/sdg"
      format      = true   # Will auto-format with ext4 if unformatted
    }
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
| `aws_log_retention_days` | number     | `90`          | Number of days to retain CloudWatch log streams |
| `cloudwatch_agent_enabled` | bool    | `true`        | Install the CloudWatch agent and ship `/var/log/*.log` to the log group |
| `cloudwatch_metrics_enabled` | bool  | `false`       | Also publish memory (`mem_used_percent`) and disk (`used_percent`) metrics, dimensioned by `InstanceId`. Requires the agent to be enabled |
| `cloudwatch_metrics_interval` | number | `60`        | Seconds between metric collections |
| `cloudwatch_metrics_namespace` | string | `"CWAgent"` | CloudWatch namespace for published metrics |
| `instance_type`      | string        | `"t3.micro"` | EC2 instance type |
| `ami_id`             | string        | `null`        | AMI ID to use. Defaults to the built-in Amazon Linux 2023 AMI for `aws_region`. Must be dnf-based |
| `root_volume_size`   | number        | `null`        | Root EBS volume size in GiB. `null` keeps the AMI's size. Must be at least the AMI snapshot size; changing it forces instance replacement |
| `access_key`         | string        | `null`        | SSH key name for instance access (enables port 22/SSH) |
| `secrets`            | map(string)   | `{}`          | Map of environment prefix to AWS Secrets Manager secret ID |
| `environment`        | map(string)   | `{}`          | Static environment variables to make available to the scripts |
| `volumes`            | map(object)   | `{}`          | Map of mount points to volume config. Key is mount point, value has: `id`, `device_name`, `format` (optional bool, default false). **Volumes must be pre-formatted unless `format=true`** |
| `sync_period`        | number        | `600`         | Seconds between maintenance/script runs |
| `permissions_boundary`| string       | `null`        | IAM permissions boundary ARN (optional) |
| `vpc_id`             | string        | required      | VPC ID for the instance |
| `subnet_ids`         | list(string)  | required      | List of subnet IDs (first is used) |
| `iam_role_arn`       | string        | `null`        | Existing IAM role/profile ARN to attach (skips creation if set) |

## Outputs
| Name            | Description |
|-----------------|-------------|
| `ec2_public_ip` | The public IP address of the EC2 instance |
| `iam_role`          | The IAM role ARN used by the instance |
| `ec2_instance`      | The full aws_instance resource |
| `volume_attachments`| Map of volume attachment resources (empty if no volumes attached) |

## Volume Management

**Important**: By default, EBS volumes must be pre-formatted with a filesystem before being attached. The module will fail if it attempts to mount an unformatted volume unless you set `format = true` for that volume.

### Auto-formatting (optional)
Set `format = true` in the volume configuration to automatically create an ext4 filesystem on unformatted volumes. **Warning**: This will destroy any existing data if the volume appears unformatted.

### Manual formatting
To format a new EBS volume manually:
1. Attach it to a temporary EC2 instance
2. Run: `sudo mkfs -t ext4 /dev/xvdf` (adjust device name as needed)
3. Detach and use with this module

The module will automatically:
- Wait for volumes to attach
- Handle device name translation (e.g., `/dev/sdf` → `/dev/xvdf`)
- Mount volumes at specified mount points
- Add entries to `/etc/fstab` for persistence across reboots

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
- Supported regions: `us-east-1`, `eu-west-1` (for the built-in AMI map; use `ami_id` for other regions)

## Notes
- By default, the EC2 instance receives a basic CloudWatch Agent role for logging.
- SSH access is only enabled if you set `access_key`.
- Set `ami_id` to use your own AMI or to run in a region not in the built-in AMI map.

## Root Volume Size
The root disk size comes from the AMI unless `root_volume_size` is set. Use it to give the instance more space at launch, for example for Docker images and logs. The value must be at least the size of the AMI snapshot. Changing it on an existing instance forces replacement: the AWS provider otherwise resizes the volume in place, leaving the AL2023 partition and filesystem at their old size. Recreating the instance lets cloud-init grow the filesystem on first boot. EBS storage is billed for the provisioned GiB, so a larger root volume increases the monthly cost even if the space is unused.

## License
MIT or as specified by the repository.
