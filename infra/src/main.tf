#-------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}
#-------------------------------------------------------------------------------------
locals {
  name             = lower("${var.cluster_name}")
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 100)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 200)]
  username         = regex("user/([^/]+)$", data.aws_caller_identity.current.arn)
  tags             = merge(var.tags, { "Owner" = local.username[0] })

}

data "aws_iam_policy" "ebs_csi" {
  name = "AmazonEBSCSIDriverPolicy"
}