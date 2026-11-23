# Changelog

## 1.6.0
- Add optional `root_volume_size` variable, passed through to the aws-ec2 module. Defaults to the AMI's root volume size.
- Updated aws-ec2 dependency to 1.6.0.

## 1.5.0
- The docker-compose.yml is now embedded in the user data as a plain-text heredoc rather than base64, so changes to it are readable in `terraform plan` diffs.
- Note: changing how the file is embedded alters `user_data`, so existing instances will be replaced once on upgrade.

## 1.4.0
- Add optional `ami_id` variable, passed through to the aws-ec2 module. Defaults to the built-in AMI for the region.
- Updated aws-ec2 dependency to 1.5.0.

## 1.3.0
- Add `cloudwatch_agent_enabled`, `cloudwatch_metrics_enabled`, `cloudwatch_metrics_interval` and `cloudwatch_metrics_namespace` variables, passed through to the aws-ec2 module.
- Updated aws-ec2 dependency to 1.4.0.

## 1.2.4
- Fix: Updated aws-ec2 dependency to 1.2.3 for shell script indentation fix.

## 1.2.3
- Fix: Added docker garbage collection to prevent disk usage spiralling

## 1.2.2
- Fix: Quote variable values in generated `.env` file for improved Bash compatibility.

## 1.2.1
- Add `aws_log_retention_days` variable (default: 90) and propagate to EC2 module for CloudWatch log retention configuration.

## 1.2.0
- Add `install_script` and `maintenance_script` variables for custom user logic.
- Documented the new variables in README and variables.tf.

## 1.1.0
- Updated to use aws-ec2-v1.2.0 module.
- Add support for `sync_period` variable.
- Maintenance script now ensures it returns to the parent directory after running.
- Install script logs installed docker-compose.yml for debugging.
- Improved logging and output during initial install.

## 1.0.1
- Remove indenting on the .env file.

## 1.0.0
- Initial release.
