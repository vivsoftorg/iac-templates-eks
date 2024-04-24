inputs = {
  create_vpc = true
  vpc_cidr   = "10.0.0.0/16"

  // if you don't want to create a new VPC, provide the vpc_id and subnet_ids and set create_vpc to false
  // create_vpc = false
  // vpc_id  = "vpc-39b8da44"
  // subnet_ids = ["subnet-1242491c", "subnet-5817463e"]

  cluster_name                    = "enbuild-eks"
  cluster_version                 = "1.29"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  eks_node_groups_min_size        = 1
  eks_node_groups_max_size        = 5
  eks_node_groups_desired_size    = 1
  enable_nat_gateway              = true
  single_nat_gateway              = true
  instance_types                  = ["t3.large"]
  // if you want to setup a mirror for https://registry1.dso.mil container registry, set the following variables
  create_registry1_mirror = false
  registry1_mirror_proxy_address  = "http://44.210.192.97:5000"
}