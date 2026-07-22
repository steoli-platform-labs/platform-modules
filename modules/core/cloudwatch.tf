# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Cloudwatch
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
resource "aws_cloudwatch_log_group" "vpn" {
  for_each = var.vpn_connections

  name              = "/${var.prefix}/vpn/${each.key}"
  retention_in_days = lookup(each.value, "log_retention_in_days", var.vpn_log_retention_in_days)
}

resource "aws_cloudwatch_log_group" "instance_scheduler" {
  count = var.create_instance_scheduler ? 1 : 0

  name              = "/${var.prefix}/lambda/${aws_lambda_function.instance_scheduler[0].function_name}"
  retention_in_days = 14
}


resource "aws_cloudwatch_event_rule" "start" {
  count = var.create_instance_scheduler && !var.start_disabled ? 1 : 0

  name                = "${var.prefix}_instance_scheduler_start"
  description         = "Instance scheduler - START"
  schedule_expression = var.start_expression
  depends_on          = [aws_lambda_function.instance_scheduler]
}


resource "aws_cloudwatch_event_rule" "stop" {
  count = var.create_instance_scheduler ? 1 : 0

  name                = "${var.prefix}_instance_scheduler_stop"
  description         = "Instance scheduler - STOP"
  schedule_expression = var.stop_expression
  depends_on          = [aws_lambda_function.instance_scheduler]
}


resource "aws_cloudwatch_event_target" "start" {
  count = var.create_instance_scheduler && !var.start_disabled ? 1 : 0

  target_id = "start"
  rule      = aws_cloudwatch_event_rule.start[0].name
  arn       = aws_lambda_function.instance_scheduler[0].arn
  input     = "{\"action\":\"start\"}"
}

resource "aws_cloudwatch_event_target" "stop" {
  count = var.create_instance_scheduler ? 1 : 0

  target_id = "stop"
  rule      = aws_cloudwatch_event_rule.stop[0].name
  arn       = aws_lambda_function.instance_scheduler[0].arn
  input     = "{\"action\":\"stop\"}"
}