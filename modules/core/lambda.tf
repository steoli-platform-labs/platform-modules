# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Lambda
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
data "archive_file" "instance_scheduler" {
  count = var.create_instance_scheduler ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/functions/instance_scheduler.py"
  output_path = "${path.module}/build/${var.prefix}_instance_scheduler.zip"
}

resource "aws_lambda_function" "instance_scheduler" {
  count = var.create_instance_scheduler ? 1 : 0

  function_name    = "${var.prefix}_instance_scheduler"
  filename         = data.archive_file.instance_scheduler[0].output_path
  source_code_hash = data.archive_file.instance_scheduler[0].output_base64sha256
  role             = aws_iam_role.instance_scheduler[0].arn
  runtime          = var.runtime
  handler          = "instance_scheduler.lambda_handler"
  timeout          = var.lambda_timeout

  environment {
    variables = {
      TIMEZONE = var.timezone,
      TAG      = var.tag,
      DRYRUN   = var.dryrun
    }
  }

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_start_scheduler" {
  count = var.create_instance_scheduler && !var.start_disabled ? 1 : 0

  statement_id  = "AllowStartFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instance_scheduler[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start[0].arn
}


resource "aws_lambda_permission" "allow_cloudwatch_stop_scheduler" {
  count = var.create_instance_scheduler ? 1 : 0

  statement_id  = "AllowStopFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instance_scheduler[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop[0].arn
}
