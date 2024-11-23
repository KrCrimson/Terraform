# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    powerbi = {
      source  = "codingones/powerbi"
      version = "~> 1.0"
    }
  }
}

# Configuración de proveedores
provider "aws" {
  region = var.aws_region
}

provider "powerbi" {
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

# Bucket S3 para almacenar archivos Excel
resource "aws_s3_bucket" "excel_storage" {
  bucket = var.bucket_name
}

# Configuración del bucket
resource "aws_s3_bucket_versioning" "excel_versioning" {
  bucket = aws_s3_bucket.excel_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Política de acceso al bucket
resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.excel_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPowerBIAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.powerbi_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.excel_storage.arn,
          "${aws_s3_bucket.excel_storage.arn}/*"
        ]
      }
    ]
  })
}

# Rol IAM para PowerBI
resource "aws_iam_role" "powerbi_role" {
  name = "PowerBI-AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "powerbi.microsoft.com"
        }
      }
    ]
  })
}

# Workspace de PowerBI
resource "powerbi_workspace" "reporting" {
  name        = var.workspace_name
  description = "Workspace para reportes de datos Excel"
}

# Dataset en PowerBI
resource "powerbi_dataset" "excel_data" {
  workspace_id = powerbi_workspace.reporting.id
  name        = "DatosExcel"
}

# variables.tf
variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "client_id" {
  description = "Azure AD client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure AD client secret"
  type        = string
  sensitive   = true
}

variable "workspace_name" {
  description = "Nombre del workspace de PowerBI"
  type        = string
}

# outputs.tf
output "s3_bucket_name" {
  value = aws_s3_bucket.excel_storage.id
}

output "powerbi_workspace_id" {
  value = powerbi_workspace.reporting.id
}