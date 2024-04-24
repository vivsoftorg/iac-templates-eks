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
  validation_error = var.create_registry1_mirror && (var.registry1_mirror_proxy_address == "" || length(trimspace(var.registry1_mirror_proxy_address)) == 0)
  mirror_config = {
    mirorr     = <<-EOT
        mkdir -p /etc/containerd/certs.d/registry1.dso.mil
        echo -ne 'server = "https://registry1.dso.mil"\n[host."${var.registry1_mirror_proxy_address}"]\n  capabilities = ["pull", "resolve"]\n  skip_verify = true' > /etc/containerd/certs.d/registry1.dso.mil/hosts.toml
      EOT
    non_mirror = <<-EOT
        echo "No mirror proxy address provided"
      EOT
  }

  mirror_proxy_config = var.create_registry1_mirror ? local.mirror_config.mirorr : local.mirror_config.non_mirror

}
data "aws_iam_policy" "ebs_csi" {
  name = "AmazonEBSCSIDriverPolicy"
}