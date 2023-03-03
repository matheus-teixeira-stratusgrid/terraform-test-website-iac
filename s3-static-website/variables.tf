variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "endpoint" {
  description = "Endpoint url"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "env_name" {
  description = "Deployment Environment"
  type        = string
}

variable "source_repo" {
  description = "IaC repository location"
  type        = string
}

variable "developer" {
  description = "Code author name"
  type        = string
}