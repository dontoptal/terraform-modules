# Changelog

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
