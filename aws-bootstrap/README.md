# AWS Bootstrap Terraform Module

This Terraform module creates the foundational AWS resources needed for remote Terraform state management: an S3 bucket for storing state files and a DynamoDB table for state locking. This is typically the first module you run when setting up a new AWS environment for Terraform.

## Features
- Creates an S3 bucket with versioning and encryption for Terraform state storage
- Creates a DynamoDB table for state locking to prevent concurrent modifications
- Configurable project and environment naming for multi-environment setups
- Blocks all public access to the S3 bucket for security
- Outputs backend configuration for easy integration with other Terraform projects
- Supports custom tagging for resource organization

## Usage Example

### Initial Bootstrap
```hcl
module "bootstrap" {
  source = "github.com/dontoptal/terraform-modules//aws-bootstrap?ref=aws-bootstrap-v1.0.0"
  
  project = "myapp"
  env     = "prod"
  
  tags = {
    Owner = "platform-team"
    CostCenter = "engineering"
  }
}
```

### Using the Backend in Other Projects
After running the bootstrap module, use the output to configure your backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-prod"
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "myapp-terraform-locks-prod"
    encrypt        = true
  }
}
```

Or use the `backend_config` output directly:
```bash
terraform output -raw backend_config
```

## Variables

| Name                | Type        | Default     | Description |
|---------------------|-------------|-------------|-------------|
| `project`           | string      | `"default"` | Project prefix for resource names |
| `env`               | string      | `"default"` | Environment suffix for resource names |
| `enable_versioning` | bool        | `true`      | Enable S3 bucket versioning for state history |
| `tags`              | map(string) | `{}`        | Additional tags to apply to all resources |

## Outputs

| Name                  | Description |
|-----------------------|-------------|
| `s3_bucket_name`      | Name of the S3 bucket for Terraform state |
| `s3_bucket_arn`       | ARN of the S3 bucket |
| `dynamodb_table_name` | Name of the DynamoDB table for state locking |
| `dynamodb_table_arn`  | ARN of the DynamoDB table |
| `region`              | AWS region where resources were created |
| `backend_config`      | Ready-to-use backend configuration block |

## Resource Naming

Resources are named using the pattern: `{project}-{resource-type}-{env}`

Examples:
- S3 Bucket: `myapp-terraform-state-prod`
- DynamoDB Table: `myapp-terraform-locks-prod`

## Security Features

- **Encryption**: S3 bucket uses AES256 server-side encryption
- **Versioning**: Enabled by default to maintain state file history
- **Public Access**: All public access is blocked on the S3 bucket
- **State Locking**: DynamoDB table prevents concurrent state modifications

## Workflow

1. **Bootstrap**: Run this module first to create state backend resources
2. **Migrate**: After resources are created, configure the backend in this module's own configuration and run `terraform init -migrate-state`
3. **Use**: Reference the created bucket and table in other Terraform projects

### Example: Self-Referencing Backend

After initial creation, you can configure this module to use its own backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-prod"
    key            = "bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "myapp-terraform-locks-prod"
    encrypt        = true
  }
}

module "bootstrap" {
  source = "github.com/dontoptal/terraform-modules//aws-bootstrap?ref=aws-bootstrap-v1.0.0"
  
  project = "myapp"
  env     = "prod"
}
```

Then run:
```bash
terraform init -migrate-state
```

## Requirements

- Terraform >= 0.13
- AWS Provider >= 3.0
- AWS credentials configured with permissions to create S3 buckets and DynamoDB tables

## Cost Considerations

- **S3**: Pay for storage used (typically minimal for state files)
- **DynamoDB**: Uses PAY_PER_REQUEST billing mode (pay only for reads/writes)
- **Versioning**: May increase S3 costs over time; consider lifecycle policies for old versions

## Notes

- This module should be run once per environment (dev, staging, prod, etc.)
- The S3 bucket name must be globally unique across all AWS accounts
- DynamoDB table uses on-demand billing to minimize costs for low-traffic state operations
- Consider enabling S3 lifecycle policies to manage old state file versions

## License

MIT or as specified by the repository.
