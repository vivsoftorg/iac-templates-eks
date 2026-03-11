resource "aws_iam_policy" "sops" {
  name   = "${local.name}-kms"
  policy = data.aws_iam_policy_document.sops.json
  tags   = local.tags
}

# EBS CSI Driver - uses EKS Pod Identity for IAM
module "aws_ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.7"

  name = "${local.name}-ebs-csi"

  attach_aws_ebs_csi_policy = true

  associations = {
    ebs-csi = {
      cluster_name    = var.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "sops" {
  statement {
    sid = ""
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "null_resource" "create_target_dir" {
  provisioner "local-exec" {
    command = "mkdir -p target"
  }
}

# Private Key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "pem" {
  filename        = "target/${var.cluster_name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

resource "aws_key_pair" "eks-node" {
  key_name   = "${local.name}-eks-node-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

module "eks" {
  # Using terraform-aws-modules/eks/aws version 21.15.1
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  subnet_ids = var.create_vpc ? module.vpc[0].private_subnets : var.subnet_ids
  vpc_id     = var.create_vpc ? module.vpc[0].vpc_id : var.vpc_id

  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    eks_managed_node = {
      min_size     = var.eks_node_groups_min_size
      max_size     = var.eks_node_groups_max_size
      desired_size = var.eks_node_groups_desired_size

      instance_types             = var.instance_types
      capacity_type              = "ON_DEMAND"
      key_name                   = aws_key_pair.eks-node.key_name
      enable_bootstrap_user_data = false
      pre_bootstrap_user_data    = local.mirror_proxy_config
      use_custom_launch_template = false
      disk_size                  = 100

      # Needed by the aws-ebs-csi-driver and BigBang
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = data.aws_iam_policy.ebs_csi.arn
        SopsKMSPolicy            = aws_iam_policy.sops.arn
      }
    }
  }
  tags                                     = local.tags
  create_kms_key                           = true
  kms_key_description                      = "KMS key for ENBUILD managed EKS cluster"
  enable_cluster_creator_admin_permissions = false
  kms_key_owners                           = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root", data.aws_caller_identity.current.arn]
  kms_key_administrators                   = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root", data.aws_caller_identity.current.arn]
  kms_key_users                            = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root", data.aws_caller_identity.current.arn]
  prefix_separator                         = var.prefix_separator
  name                                     = var.cluster_name
  kubernetes_version                       = var.cluster_version
  enabled_log_types                        = var.cluster_enabled_log_types
  deletion_protection                      = var.deletion_protection
  force_update_version                     = var.force_update_version
  authentication_mode                      = var.authentication_mode
  upgrade_policy                           = var.upgrade_policy
  compute_config                           = var.compute_config
  control_plane_scaling_config             = var.control_plane_scaling_config
  remote_network_config                    = var.remote_network_config
  zonal_shift_config                       = var.zonal_shift_config
  additional_security_group_ids            = var.cluster_additional_security_group_ids
  control_plane_subnet_ids                 = var.control_plane_subnet_ids
  endpoint_private_access                  = var.cluster_endpoint_private_access
  endpoint_public_access                   = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs             = var.cluster_endpoint_public_access_cidrs
  ip_family                                = var.cluster_ip_family
  service_ipv4_cidr                        = var.cluster_service_ipv4_cidr
  service_ipv6_cidr                        = var.cluster_service_ipv6_cidr
  outpost_config                           = var.outpost_config
  encryption_config                        = var.cluster_encryption_config
  attach_encryption_policy                 = var.attach_cluster_encryption_policy
  cluster_tags                             = var.cluster_tags
  create_primary_security_group_tags       = var.create_cluster_primary_security_group_tags
  timeouts                                 = var.cluster_timeouts
  access_entries = merge(
    var.access_entries,
    {
      "deployer-admin" = {
        principal_arn = data.aws_caller_identity.current.arn
        type          = "STANDARD"
        user_name     = local.username[0]
        policy_associations = {
          clusteradmin = {
            policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
          admin = {
            policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    }
  )
  kms_key_deletion_window_in_days              = var.kms_key_deletion_window_in_days
  enable_kms_key_rotation                      = var.enable_kms_key_rotation
  kms_key_rotation_period_in_days              = var.kms_key_rotation_period_in_days
  kms_key_enable_default_policy                = var.kms_key_enable_default_policy
  kms_key_service_users                        = var.kms_key_service_users
  kms_key_source_policy_documents              = var.kms_key_source_policy_documents
  kms_key_override_policy_documents            = var.kms_key_override_policy_documents
  kms_key_aliases                              = var.kms_key_aliases
  create_cloudwatch_log_group                  = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days       = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id              = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_class                   = var.cloudwatch_log_group_class
  cloudwatch_log_group_tags                    = var.cloudwatch_log_group_tags
  create_security_group                        = var.create_cluster_security_group
  security_group_id                            = var.cluster_security_group_id
  security_group_name                          = var.cluster_security_group_name
  security_group_use_name_prefix               = var.cluster_security_group_use_name_prefix
  security_group_description                   = var.cluster_security_group_description
  security_group_additional_rules              = var.cluster_security_group_additional_rules
  security_group_tags                          = var.cluster_security_group_tags
  create_cni_ipv6_iam_policy                   = var.create_cni_ipv6_iam_policy
  create_node_security_group                   = var.create_node_security_group
  node_security_group_id                       = var.node_security_group_id
  node_security_group_name                     = var.node_security_group_name
  node_security_group_use_name_prefix          = var.node_security_group_use_name_prefix
  node_security_group_description              = var.node_security_group_description
  node_security_group_additional_rules         = var.node_security_group_additional_rules
  node_security_group_enable_recommended_rules = var.node_security_group_enable_recommended_rules
  node_security_group_tags                     = var.node_security_group_tags
  enable_irsa                                  = var.enable_irsa
  openid_connect_audiences                     = var.openid_connect_audiences
  include_oidc_root_ca_thumbprint              = var.include_oidc_root_ca_thumbprint
  custom_oidc_thumbprints                      = var.custom_oidc_thumbprints
  create_iam_role                              = var.create_iam_role
  iam_role_arn                                 = var.iam_role_arn
  iam_role_name                                = var.iam_role_name
  iam_role_use_name_prefix                     = var.iam_role_use_name_prefix
  iam_role_path                                = var.iam_role_path
  iam_role_description                         = var.iam_role_description
  iam_role_permissions_boundary                = var.iam_role_permissions_boundary
  iam_role_additional_policies                 = var.iam_role_additional_policies
  iam_role_tags                                = var.iam_role_tags
  encryption_policy_use_name_prefix            = var.cluster_encryption_policy_use_name_prefix
  encryption_policy_name                       = var.cluster_encryption_policy_name
  encryption_policy_description                = var.cluster_encryption_policy_description
  encryption_policy_path                       = var.cluster_encryption_policy_path
  encryption_policy_tags                       = var.cluster_encryption_policy_tags
  dataplane_wait_duration                      = var.dataplane_wait_duration
  enable_auto_mode_custom_tags                 = var.enable_auto_mode_custom_tags
  create_auto_mode_iam_resources               = var.create_auto_mode_iam_resources
  create_node_iam_role                         = var.create_node_iam_role
  node_iam_role_name                           = var.node_iam_role_name
  node_iam_role_use_name_prefix                = var.node_iam_role_use_name_prefix
  node_iam_role_path                           = var.node_iam_role_path
  node_iam_role_description                    = var.node_iam_role_description
  node_iam_role_permissions_boundary           = var.node_iam_role_permissions_boundary
  node_iam_role_additional_policies            = var.node_iam_role_additional_policies
  node_iam_role_tags                           = var.node_iam_role_tags
  addons_timeouts                              = var.cluster_addons_timeouts
  identity_providers                           = var.cluster_identity_providers
  fargate_profiles                             = var.fargate_profiles
  self_managed_node_groups                     = var.self_managed_node_groups
  // eks_managed_node_groups             = var.eks_managed_node_groups (inline above)
}


resource "null_resource" "generate_kubeconfig" {
  count = var.create_kubeconfig ? 1 : 0
  triggers = {
    eks_cluster_id = module.eks.cluster_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks.cluster_name}  --kubeconfig target/kubeconfig.yaml
    EOT
  }
}
