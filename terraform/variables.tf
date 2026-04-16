variable "aws_region" {
  type        = string
  description = "AWS region for the cluster"
  default     = "us-east-1"
}

variable "name_prefix" {
  type        = string
  default     = "test-rke2"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.60.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.60.10.0/24", "10.60.11.0/24", "10.60.12.0/24"]
}

variable "instance_type_server" {
  type        = string
  default     = "t3.large"
}

variable "instance_type_agent" {
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "server_count" {
  type    = number
  default = 3
}

variable "agent_count" {
  type    = number
  default = 3
}

variable "root_volume_size" {
  type    = number
  default = 80
}
