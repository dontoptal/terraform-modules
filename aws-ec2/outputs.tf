output "ec2_public_ip" {
  value = aws_instance.instance.public_ip
}

output "ec2_ipv6_addresses" {
  value       = aws_instance.instance.ipv6_addresses
  description = "IPv6 addresses assigned to the instance (empty when ipv6_enabled is false)"
}

output "iam_role" {
  value = var.iam_role_arn != null ? var.iam_role_arn : aws_iam_role.ec2_role[0].arn
}

output "ec2_instance" {
  value = aws_instance.instance
}

output "volume_attachments" {
  value = length(var.volumes) > 0 ? aws_volume_attachment.volume_attach : {}
  description = "Map of volume attachment resources (empty if no volumes attached)"
}
