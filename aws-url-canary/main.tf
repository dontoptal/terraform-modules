terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

locals {
  name           = "${var.prefix}${var.name}${var.suffix}"
  role_name      = "${local.name}-role"
  log_group_name = "/aws/lambda/${local.name}"

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      TfModule  = "dontoptal:Terraform-Modules/aws-url-canary"
    }
  )

  check_url_code = <<EOF
import json
import os
import time
import urllib.error
import urllib.request

import boto3

cloudwatch = boto3.client("cloudwatch")


def handler(event, context):
    url = os.environ["TARGET_URL"]
    canary_name = os.environ["CANARY_NAME"]
    namespace = os.environ["METRIC_NAMESPACE"]
    expected_status = int(os.environ["EXPECTED_STATUS_CODE"])
    request_timeout = float(os.environ["REQUEST_TIMEOUT"])
    method = os.environ["REQUEST_METHOD"]
    headers = json.loads(os.environ["REQUEST_HEADERS"])

    status_code = 0
    error = None
    started = time.monotonic()

    try:
        request = urllib.request.Request(url, method=method, headers=headers)
        with urllib.request.urlopen(request, timeout=request_timeout) as response:
            status_code = response.status
        success = status_code == expected_status
        if not success:
            error = "expected status code {}, got {}".format(expected_status, status_code)
    except urllib.error.HTTPError as exc:
        status_code = exc.code
        success = False
        error = "{}: {}".format(type(exc).__name__, exc)
    except Exception as exc:
        success = False
        error = "{}: {}".format(type(exc).__name__, exc)

    latency_ms = round((time.monotonic() - started) * 1000, 2)
    dimensions = [{"Name": "CanaryName", "Value": canary_name}]

    cloudwatch.put_metric_data(
        Namespace=namespace,
        MetricData=[
            {
                "MetricName": "Success",
                "Dimensions": dimensions,
                "Unit": "None",
                "Value": 1.0 if success else 0.0,
            },
            {
                "MetricName": "Latency",
                "Dimensions": dimensions,
                "Unit": "Milliseconds",
                "Value": latency_ms,
            },
            {
                "MetricName": "StatusCode",
                "Dimensions": dimensions,
                "Unit": "None",
                "Value": status_code,
            },
        ],
    )

    result = {
        "url": url,
        "status_code": status_code,
        "success": success,
        "latency_ms": latency_ms,
    }
    if error:
        result["error"] = error
    print(json.dumps(result))
    return result
EOF
}

data "archive_file" "check_url" {
  type        = "zip"
  output_path = "${path.root}/.terraform/${local.name}-url-canary.zip"

  source {
    filename = "index.py"
    content  = local.check_url_code
  }
}

resource "aws_cloudwatch_log_group" "check" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_iam_role" "check" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.check.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "put_metrics" {
  name = "put-url-canary-metrics"
  role = aws_iam_role.check.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "cloudwatch:PutMetricData"
      Resource = "*"
      Condition = {
        StringEquals = {
          "cloudwatch:namespace" = var.metrics_namespace
        }
      }
    }]
  })
}

resource "aws_lambda_function" "check" {
  function_name = local.name
  role          = aws_iam_role.check.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  description   = "Checks ${var.url} and publishes the result to CloudWatch metrics."

  filename         = data.archive_file.check_url.output_path
  source_code_hash = data.archive_file.check_url.output_base64sha256

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      TARGET_URL           = var.url
      CANARY_NAME          = local.name
      METRIC_NAMESPACE     = var.metrics_namespace
      EXPECTED_STATUS_CODE = tostring(var.expected_status_code)
      REQUEST_TIMEOUT      = tostring(var.request_timeout)
      REQUEST_METHOD       = upper(var.method)
      REQUEST_HEADERS      = jsonencode(var.headers)
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.check,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy.put_metrics,
  ]
}

resource "aws_cloudwatch_event_rule" "check" {
  name                = "${local.name}-schedule"
  description         = "Runs the ${local.name} URL check."
  schedule_expression = var.schedule_expression

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "check" {
  rule      = aws_cloudwatch_event_rule.check.name
  target_id = local.name
  arn       = aws_lambda_function.check.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check.arn
}

resource "aws_cloudwatch_metric_alarm" "check" {
  count = var.alarm_sns_topic_arn != null ? 1 : 0

  alarm_name          = "${local.name}-failed-checks"
  alarm_description   = "The ${local.name} URL check for ${var.url} has failed."
  namespace           = var.metrics_namespace
  metric_name         = "Success"
  statistic           = "Minimum"
  period              = var.alarm_period
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    CanaryName = local.name
  }

  alarm_actions = [var.alarm_sns_topic_arn]

  tags = local.common_tags
}
