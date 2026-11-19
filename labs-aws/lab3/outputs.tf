output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}
