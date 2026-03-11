# Cluster name - must be unique and comply with EKS naming rules
cluster_name = "enbuild-eks"

# VPC Configuration
# Set create_vpc to false and provide vpc_id + subnet_ids to use existing VPC
create_vpc = true
# vpc_id     = "vpc-xxxxxxxx"            # Required when create_vpc = false
# subnet_ids = ["subnet-xxx1", "subnet-xxx2", "subnet-xxx3"]  # Required when create_vpc = false
vpc_cidr = "10.0.0.0/16"

# EKS Cluster Configuration
cluster_version                  = "1.32"
cluster_enabled_log_types         = ["audit", "api", "authenticator"]
authentication_mode               = "API"
cluster_endpoint_private_access   = true
cluster_endpoint_public_access   = true

deletion_protection = false

# Node Group Configuration
eks_node_groups_min_size     = 1
eks_node_groups_max_size     = 5
eks_node_groups_desired_size = 1

# NAT Gateway Configuration
# Not needed when using existing VPC without private subnets
enable_nat_gateway   = true
single_nat_gateway   = true

instance_types = ["t3.large"]

# Registry1 Mirror Configuration
create_registry1_mirror     = false
registry1_mirror_proxy_address = "http://44.210.192.97:5000"
