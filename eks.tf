data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.eks_cluster_name}-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" {
  name               = "${local.eks_cluster_name}-node"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
  ])

  role       = aws_iam_role.eks_node.name
  policy_arn = each.value
}

resource "aws_eks_cluster" "this" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_kubernetes_version

  vpc_config {
    subnet_ids              = aws_subnet.private_app[*].id
    endpoint_private_access = true
    endpoint_public_access  = var.eks_endpoint_public_access
  }

  tags = merge(local.common_tags, {
    Name = local.eks_cluster_name
  })

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_eks_addon" "this" {
  for_each = toset(["coredns", "kube-proxy", "vpc-cni"])

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.default]
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private_app[*].id
  instance_types  = [var.eks_node_instance_type]
  capacity_type   = "ON_DEMAND"
  disk_size       = var.eks_node_disk_size

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.common_tags, {
    Name = "${local.eks_cluster_name}-default"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_node,
    # The private-app route tables send 0.0.0.0/0 to the NAT Gateway.
    # Wait for those routes before EKS launches nodes in these subnets.
    aws_route_table_association.private_app,
  ]
}
