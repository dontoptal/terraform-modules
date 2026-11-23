output "canary_name" {
  description = "Name used for the URL check and as the CanaryName metric dimension."
  value       = local.name
}

output "function_name" {
  description = "Name of the Lambda function that performs the check."
  value       = aws_lambda_function.check.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function that performs the check."
  value       = aws_lambda_function.check.arn
}

output "role_arn" {
  description = "ARN of the IAM role used by the check function."
  value       = aws_iam_role.check.arn
}

output "log_group_name" {
  description = "CloudWatch log group for the check function."
  value       = aws_cloudwatch_log_group.check.name
}

output "schedule_rule_arn" {
  description = "ARN of the EventBridge rule that schedules the check."
  value       = aws_cloudwatch_event_rule.check.arn
}

output "metric_namespace" {
  description = "CloudWatch namespace that receives the check metrics."
  value       = var.metrics_namespace
}

output "metric_dimensions" {
  description = "Dimensions attached to every published metric."
  value = {
    CanaryName = local.name
  }
}

output "alarm_arn" {
  description = "ARN of the availability alarm, or null when alarm_sns_topic_arn is not set."
  value       = var.alarm_sns_topic_arn != null ? aws_cloudwatch_metric_alarm.check[0].arn : null
}
