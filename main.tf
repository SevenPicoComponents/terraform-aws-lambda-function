

resource "aws_cloudwatch_log_group" "this" {
  count             = module.this.enabled ? 1 : 0
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  tags              = module.this.tags
}

resource "aws_lambda_function" "this" {
  count      = module.this.enabled ? 1 : 0
  depends_on = [aws_cloudwatch_log_group.this]

  architectures                  = var.architectures
  description                    = var.description
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = var.handler
  image_uri                      = var.image_uri
  kms_key_arn                    = var.kms_key_arn
  layers                         = var.layers
  memory_size                    = var.memory_size
  package_type                   = var.package_type
  publish                        = var.publish
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = aws_iam_role.this[0].arn
  runtime                        = var.runtime
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  source_code_hash               = var.source_code_hash
  tags                           = var.tags
  timeout                        = var.timeout

  dynamic "environment" {
    for_each = var.lambda_environment != null ? [var.lambda_environment] : []
    content {
      variables = environment.value.variables
    }
  }

  dynamic "image_config" {
    for_each = length(var.image_config) > 0 ? [true] : []
    content {
      command           = lookup(var.image_config, "command", null)
      entry_point       = lookup(var.image_config, "entry_point", null)
      working_directory = lookup(var.image_config, "working_directory", null)
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config_mode != null ? [true] : []
    content {
      mode = var.tracing_config_mode
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }
}

data "aws_partition" "this" { count = local.enabled ? 1 : 0 }
data "aws_region" "this" { count = local.enabled ? 1 : 0 }
data "aws_caller_identity" "this" { count = local.enabled ? 1 : 0 }

locals {
  enabled     = module.this.enabled
  account_id  = local.enabled ? data.aws_caller_identity.this[0].account_id : ""
  partition   = local.enabled ? data.aws_partition.this[0].partition : ""
  region_name = local.enabled ? data.aws_region.this[0].name : ""
}
