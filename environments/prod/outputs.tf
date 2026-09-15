output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}

output "execute_api_arn_iam_route" {
  value = module.api_gateway.execute_api_arn_iam_route
}

output "vpc_link_security_group_id" {
  value = aws_security_group.vpc_link.id
}

output "vpc_link_security_group_name" {
  value = aws_security_group.vpc_link.name
}
