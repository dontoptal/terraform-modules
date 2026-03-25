# Changelog

## 1.2.2
- Fix: Quote variable values in generated `.env` file for improved Bash compatibility.

## 1.2.1
- Add `aws_log_retention_days` variable (default: 90) to control CloudWatch log retention days for agent configuration.

## 1.2.0
- Add support for CloudWatch Agent installation and logs collection.
- Add `LOG_FILE` variable for install and run scripts with output redirection.
- `.env` file now includes EC2 config (`AWS_REGION`, `AWS_LOG_GROUP`, `EC2_HOSTNAME`).
- Improved environment variable and secret injection.

## 1.1.1
- Removed indenting from the .env file output.

## 1.1.0
- Added the `environment` variable for passing static environment variables to the instance.

## 1.0.0
- Initial release.
