data "aws_iam_policy_document" "ws_messenger_lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions = ["execute-api:*"]
    effect  = "Allow"
    resources = [
      "${aws_apigatewayv2_stage.ws_messenger_api_stage.execution_arn}/*/*/*"
    ]
  }
}

data "archive_file" "ws_messenger_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda.js"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_policy" "ws_messenger_lambda_policy" {
  name   = "WsMessengerLambdaPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_messenger_lambda_policy.json
}

resource "aws_iam_role" "ws_messenger_lambda_role" {
  name = "WsMessengerLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.ws_messenger_lambda_policy.arn]
}

resource "aws_lambda_function" "ws_messenger_lambda" {
  filename         = data.archive_file.ws_messenger_zip.output_path
  function_name    = "ws-messenger"
  role             = aws_iam_role.ws_messenger_lambda_role.arn
  handler          = "lambda.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.ws_messenger_zip.output_base64sha256
  publish          = true
}

resource "aws_lambda_provisioned_concurrency_config" "_" {
  function_name                     = aws_lambda_function.ws_messenger_lambda.function_name
  provisioned_concurrent_executions = 1
  qualifier                         = aws_lambda_function.ws_messenger_lambda.version


}

resource "aws_cloudwatch_log_group" "ws_messenger_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ws_messenger_lambda.function_name}"
  retention_in_days = 30
}
