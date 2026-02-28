locals {
  name = "${var.project}-${var.environment}"

  azs = [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c",
  ]

  public_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
