output "ec2_public_ip" {
  value = aws_instance.instance.public_ip
}

output "iam_role" {
  value = var.iam_role_arn != null ? var.iam_role_arn : aws_iam_role.ec2_role[0].arn
}

output "ec2_instance" {
  value = aws_instance.instance
}
