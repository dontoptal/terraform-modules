locals {
  published_ports = concat(
    var.published_ports,
    (var.access_key != null) ? [ 22 ] : []
  )

  # Map of Amazon Linux 2023 AMI IDs per region
  ami_ids = {
    "eu-west-1" = "ami-09c20105c9b62f893"
    "us-east-1" = "ami-0f3caa1cf4417e51b"
  }

  # Extract role name from ARN if provided (for instance profile)
  iam_role_name_from_arn = var.iam_role_arn != null ? (
    length(regexall("([^/:]+)$", var.iam_role_arn)) > 0 ? regex("([^/:]+)$", var.iam_role_arn)[0] : var.iam_role_arn
  ) : null
}

# Security group allowing SSH + Published Ports
resource "aws_security_group" "ec2_sg" {
  name   = "${var.prefix}${var.name}${var.suffix}"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = local.published_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM role for EC2 if you want CloudWatch Logs later
resource "aws_iam_role" "ec2_role" {
  count = var.iam_role_arn != null ? 0 : 1
  name = "${var.prefix}${var.name}-ec2-role${var.suffix}"

  permissions_boundary = var.permissions_boundary
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  count = var.iam_role_arn != null ? 0 : 1
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.prefix}${var.name}${var.suffix}"
  role = var.iam_role_arn != null ? local.iam_role_name_from_arn : aws_iam_role.ec2_role[0].name
}

# EC2 instance
resource "aws_instance" "instance" {
  ami           = local.ami_ids[var.aws_region] # Amazon Linux 2 per region
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name      = var.access_key

  user_data_replace_on_change = true
  user_data = local.setup_ec2_for_docker_compose_script

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}${var.name}${var.suffix}",
      ManagedBy = "terraform"
      TfModule = "donuk:Terraform-Modules/aws-ec2"
    }
  )
}
locals {
  setup_ec2_for_docker_compose_script = <<EOF
#!/bin/bash

BOOT_SCRIPT=/var/lib/cloud/scripts/per-boot/run-services.sh

export AWS_REGION="${var.aws_region}"
export AWS_LOG_GROUP="${var.aws_log_group}"
export EC2_HOSTNAME="${var.prefix}${var.name}${var.suffix}"

main() {
  install_requirements
  install_boot_script "$BOOT_SCRIPT"
  run_boot_script "$BOOT_SCRIPT"
}

install_requirements() {
  noop
  ${var.install_script}
}

install_boot_script() {
  SCRIPT="$1"

  cat > "$SCRIPT" <<'BASH'
  #!/bin/bash -x

  PATH=$PATH:/usr/local/bin/
  export AWS_REGION="${var.aws_region}"
  export AWS_LOG_GROUP="${var.aws_log_group}"
  export EC2_HOSTNAME="${var.prefix}${var.name}${var.suffix}"

  main() {
    cd /home/ec2-user/

    while true; do 
      get_all_secrets > .env
      maintenance
      sleep ${var.sync_period}
    done
  }

  maintenance() {
    noop
    ${var.maintenance_script}
  }

  get_secret_as_env() {
    SECRET_ID="$1"
    PREFIX="$2"
    SECRET_JSON="$(aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id "$SECRET_ID" --query 'SecretString' --output text)"
    echo "$SECRET_JSON" | jq -r --arg prefix "$PREFIX" '
      to_entries[]
      | "\($prefix)_\(.key
          | ascii_upcase
          | gsub("[^A-Z0-9]"; "_")
        )=\(.value | @sh)"
    '
  }

  noop() {
    true
  }

  get_all_secrets() {
    noop

    ${join("\n", [
      for prefix, secret_id in var.secrets:
      "get_secret_as_env ${secret_id} ${prefix}"
    ])}
  }

  main
BASH

  chmod +x "$SCRIPT"
}

run_boot_script() {
  SCRIPT="$1"
  "$SCRIPT"
}

noop() {
  true
}

main
  EOF
}
