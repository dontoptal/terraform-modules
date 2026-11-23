variable "name" {
  type        = string
  description = "Name of the URL check. Used for resource names and as the CanaryName metric dimension."
}

variable "url" {
  type        = string
  description = "URL to request on every check. Must start with http:// or https://."

  validation {
    condition     = can(regex("^https?://", var.url))
    error_message = "url must start with http:// or https://."
  }
}

variable "prefix" {
  type        = string
  default     = ""
  description = "Prefix for resource names."
}

variable "suffix" {
  type        = string
  default     = ""
  description = "Suffix for resource names."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to all resources."
}

variable "schedule_expression" {
  type        = string
  default     = "rate(5 minutes)"
  description = "EventBridge schedule expression that determines how often the URL is checked."
}

variable "method" {
  type        = string
  default     = "GET"
  description = "HTTP method used for the request (GET or HEAD)."

  validation {
    condition     = contains(["GET", "HEAD"], upper(var.method))
    error_message = "method must be GET or HEAD."
  }
}

variable "expected_status_code" {
  type        = number
  default     = 200
  description = "HTTP status code that counts as a successful check."

  validation {
    condition     = var.expected_status_code >= 100 && var.expected_status_code <= 599
    error_message = "expected_status_code must be a valid HTTP status code between 100 and 599."
  }
}

variable "headers" {
  type        = map(string)
  default     = {}
  description = "Additional HTTP request headers. Note that these are stored in the Lambda configuration and Terraform state."
}

variable "request_timeout" {
  type        = number
  default     = 10
  description = "Timeout in seconds for each HTTP request. Should be lower than lambda_timeout."

  validation {
    condition     = var.request_timeout > 0
    error_message = "request_timeout must be greater than zero."
  }
}

variable "lambda_timeout" {
  type        = number
  default     = 30
  description = "Lambda function timeout in seconds."

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  type        = number
  default     = 128
  description = "Memory allocated to the Lambda function in MB."

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240 MB."
  }
}

variable "metrics_namespace" {
  type        = string
  default     = "URLCanary"
  description = "CloudWatch namespace for the published metrics. Must not start with AWS/."

  validation {
    condition     = length(var.metrics_namespace) > 0 && length(var.metrics_namespace) <= 255 && !startswith(var.metrics_namespace, "AWS/")
    error_message = "metrics_namespace must be 1-255 characters and must not start with AWS/."
  }
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "Number of days to retain the Lambda CloudWatch log group."

  validation {
    condition     = var.log_retention_days > 0
    error_message = "log_retention_days must be greater than zero."
  }
}

variable "alarm_sns_topic_arn" {
  type        = string
  default     = null
  description = "ARN of an SNS topic to notify when the availability alarm fires. No alarm is created when null."
}

variable "alarm_period" {
  type        = number
  default     = 300
  description = "Length in seconds of each CloudWatch alarm evaluation period."

  validation {
    condition     = contains([10, 20, 30], var.alarm_period) || var.alarm_period % 60 == 0
    error_message = "alarm_period must be 10, 20, 30, or a multiple of 60 seconds."
  }
}

variable "alarm_evaluation_periods" {
  type        = number
  default     = 1
  description = "Number of consecutive periods with failed checks before the alarm fires."

  validation {
    condition     = var.alarm_evaluation_periods >= 1
    error_message = "alarm_evaluation_periods must be at least 1."
  }
}
