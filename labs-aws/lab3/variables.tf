variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "student" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.student))
    error_message = "student deve avere 3-8 caratteri minuscoli o numeri."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnets" {
  type = map(object({
    cidr = string
  }))
  default = {
    web = { cidr = "10.0.1.0/24" }
    db  = { cidr = "10.0.2.0/24" }
  }
}

variable "allowed_ports" {
  type    = list(number)
  default = [80]
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Se il tipo non è disponibile: aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true --query 'InstanceTypes[].InstanceType'"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
