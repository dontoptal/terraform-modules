# Changelog

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
