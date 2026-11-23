# AWS URL Canary Terraform Module

A lightweight alternative to CloudWatch Synthetics canaries. This module schedules a Lambda function that requests a URL, publishes the result to CloudWatch metrics, and can raise a CloudWatch alarm to an SNS topic when checks fail.

## Features
- Periodically requests a URL using an EventBridge schedule (every 5 minutes by default)
- Publishes `Success`, `Latency`, and `StatusCode` metrics to a configurable CloudWatch namespace
- Optional CloudWatch alarm on failed checks, delivered to an SNS topic
- Uses only the Python standard library plus boto3 (provided by the Lambda runtime); no external dependencies or image builds
- Dedicated IAM role scoped to publishing metrics in the configured namespace
- Managed CloudWatch log group for the check function
- Supports custom tags, naming prefix/suffix, request method, headers, timeout, and expected status code

## Usage Example
```hcl
module "url_canary" {
  source = "github.com/dontoptal/terraform-modules//aws-url-canary?ref=aws-url-canary-v0.1.0"

  name                  = "myapp-health"
  url                   = "https://example.com/health"
  schedule_expression   = "rate(5 minutes)"
  alarm_sns_topic_arn   = aws_sns_topic.alerts.arn

  tags = {
    Environment = "prod"
    Project     = "example"
  }
}
```

Without an alarm (metrics and logs only), omit `alarm_sns_topic_arn`.

## Variables
| Name                      | Type        | Default             | Description |
|---------------------------|-------------|---------------------|-------------|
| `name`                    | string      | required            | Name of the check, used in resource names and as the `CanaryName` metric dimension |
| `url`                     | string      | required            | URL to request; must start with `http://` or `https://` |
| `prefix`                  | string      | `""`                | Prefix for resource names |
| `suffix`                  | string      | `""`                | Suffix for resource names |
| `tags`                    | map(string) | `{}`                | Additional tags to apply to all resources |
| `schedule_expression`     | string      | `"rate(5 minutes)"` | EventBridge schedule expression for the check |
| `method`                  | string      | `"GET"`             | HTTP method (`GET` or `HEAD`) |
| `expected_status_code`    | number      | `200`               | HTTP status code that counts as a successful check |
| `headers`                 | map(string) | `{}`                | Additional HTTP request headers; stored in Lambda config and Terraform state |
| `request_timeout`         | number      | `10`                | Per-request timeout in seconds; should be lower than `lambda_timeout` |
| `lambda_timeout`          | number      | `30`                | Lambda timeout in seconds |
| `lambda_memory_size`      | number      | `128`               | Lambda memory in MB |
| `metrics_namespace`       | string      | `"URLCanary"`       | CloudWatch namespace for published metrics; must not start with `AWS/` |
| `log_retention_days`      | number      | `14`                | CloudWatch log retention in days |
| `alarm_sns_topic_arn`     | string      | `null`              | SNS topic ARN for failure notifications; no alarm when omitted |
| `alarm_period`            | number      | `300`               | Alarm evaluation period in seconds |
| `alarm_evaluation_periods`| number      | `1`                 | Consecutive failed periods before the alarm fires |

## Outputs
| Name                | Description |
|---------------------|-------------|
| `canary_name`       | Name used for the check and the metric dimension |
| `function_name`     | Name of the check Lambda function |
| `function_arn`      | ARN of the check Lambda function |
| `role_arn`          | ARN of the Lambda execution role |
| `log_group_name`    | CloudWatch log group for the function |
| `schedule_rule_arn` | ARN of the EventBridge scheduling rule |
| `metric_namespace`  | Namespace receiving the metrics |
| `metric_dimensions` | Dimensions attached to every metric |
| `alarm_arn`         | Alarm ARN, or `null` when no SNS topic is configured |

## How It Works

An EventBridge rule invokes the Lambda function on the configured schedule. The function requests the URL and publishes three metrics, all dimensioned by `CanaryName`:

| Metric      | Unit          | Meaning |
|-------------|---------------|---------|
| `Success`   | None          | `1` when the response status matches `expected_status_code`, otherwise `0` |
| `Latency`   | Milliseconds  | Time taken by the request, including failed requests |
| `StatusCode`| None          | HTTP status received, or `0` when no HTTP response was returned |

Network errors, timeouts, redirects that end in an unexpected status, and unexpected status codes all count as failures. Failures are still reported as metrics and logged; the function itself does not throw, so EventBridge does not retry a check that has already been recorded.

When `alarm_sns_topic_arn` is provided, an alarm watches the minimum `Success` value. It fires when any datapoint in the evaluation window is `0`, and also treats missing datapoints (for example, if the function is throttled) as breaching.

## Requirements
- Terraform >= 0.13
- AWS Provider >= 3.0
- Archive Provider >= 2.0 (used to package the inline function code)
- An SNS topic in the same region if `alarm_sns_topic_arn` is set

## Notes
- The function code is embedded in the module and zipped locally into `.terraform/`; no build step or checked-in deployment package is needed.
- The module uses the `python3.12` Lambda runtime.
- `headers` values are visible in the Lambda configuration and Terraform state. Use a different mechanism for secrets.
- Keep `alarm_period` aligned with `schedule_expression` (for example, 300 seconds for a 5-minute schedule) so each evaluation window covers at least one check.

## License
MIT or as specified by the repository.
