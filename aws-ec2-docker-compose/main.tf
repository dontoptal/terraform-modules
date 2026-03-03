locals {
  docker_compose_yaml_base64 = base64encode(var.docker_compose_yaml)
}

module "ec2" {
  source = "github.com/dontoptal/terraform-modules//aws-ec2?ref=aws-ec2-v1.1.1"
  aws_region = var.aws_region
  name = var.name
  prefix = var.prefix
  suffix = var.suffix
  tags = var.tags
  aws_log_group = var.aws_log_group
  access_key = var.access_key
  instance_type = var.instance_type
  published_ports = var.published_ports
  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids
  secrets = var.secrets
  environment = var.environment
  install_script = <<EOF
  dnf update -y
  dnf install -y docker git
  service docker start
  usermod -aG docker ec2-user

  # Install docker-compose
  curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq

  chmod +x /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/yq
  yum install -y jq
  
  # Move your docker-compose.yml
  mkdir -p /home/ec2-user/myapp
  echo '${local.docker_compose_yaml_base64}' | base64 -d > /tmp/docker-compose.yml

  yq eval '
    . as $root
    | .services |= (
        to_entries
        | map(
            .value.logging = {
              "driver": "awslogs",
              "options": {
                "awslogs-region": "$AWS_REGION",
                "awslogs-group": "$AWS_LOG_GROUP",
                "awslogs-stream": "$EC2_HOSTNAME/" + .key
              }
            }
          )
        | from_entries
      )
  ' "/tmp/docker-compose.yml" > /home/ec2-user/myapp/docker-compose.yml
  EOF

  maintenance_script = <<EOF
  ensure_services_are_up_to_date_and_running() {
    cp .env myapp/.env
    cd myapp/

    sudo service docker start
    docker_login
    docker-compose pull
    docker-compose up -d --build
  }

  docker_login() {
    aws ecr get-login-password --region ${var.aws_region} \
      | docker login \
          --username AWS \
          --password-stdin ${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com
  }

  ensure_services_are_up_to_date_and_running
  EOF

  iam_role_arn = var.iam_role_arn
}

output ec2_instance {
  value = module.ec2.ec2_instance
}
