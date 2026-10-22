# Changelog

## 1.0.0 (2026-10-22)

### Added
- Initial release of aws-bootstrap module
- S3 bucket creation for Terraform state storage with:
  - Server-side encryption (AES256)
  - Versioning support (configurable via `enable_versioning`)
  - Public access blocking for security
- DynamoDB table creation for state locking with PAY_PER_REQUEST billing
- Configurable project and environment naming via `project` and `env` variables
- Support for custom resource tagging via `tags` variable
- Comprehensive outputs including:
  - S3 bucket name and ARN
  - DynamoDB table name and ARN
  - AWS region
  - Ready-to-use backend configuration block
- Automatic tagging with `ManagedBy`, `TfModule`, `Project`, and `Environment`
- Complete README with usage examples and best practices
- Variables extracted to separate `variables.tf` file
- Outputs extracted to separate `outputs.tf` file

### Changed
- Refactored from inline variables to separate `variables.tf` file for better organization
- Updated S3 bucket configuration to use separate resources for versioning and encryption (AWS provider v4+ compatibility)
- Added `required_version` constraint for Terraform >= 0.13

### Security
- Enabled S3 bucket public access blocking by default
- Enforced server-side encryption on state bucket
