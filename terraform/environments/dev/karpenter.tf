# Karpenter node IAM role
resource "aws_iam_role" "karpenter_node" {
  name = "${local.name}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile 
resource "aws_iam_instance_profile" "karpenter_node" {
  name = "${local.name}-karpenter-node"
  role = aws_iam_role.karpenter_node.name
  tags = local.tags
}

# EKS access entry
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.karpenter_node.arn
  type          = "EC2_LINUX"
  tags          = local.tags
}



# SQS interruption queue + EventBridge rules
resource "aws_sqs_queue" "karpenter" {
  name                      = "${local.name}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
  tags                      = local.tags
}

resource "aws_sqs_queue_policy" "karpenter" {
  queue_url = aws_sqs_queue.karpenter.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.karpenter.arn
    }]
  })
}

locals {
  karpenter_interruption_rules = {
    spot_interruption     = { source = ["aws.ec2"], detail_type = ["EC2 Spot Instance Interruption Warning"] }
    instance_rebalance    = { source = ["aws.ec2"], detail_type = ["EC2 Instance Rebalance Recommendation"] }
    instance_state_change = { source = ["aws.ec2"], detail_type = ["EC2 Instance State-change Notification"] }
  }
}

resource "aws_cloudwatch_event_rule" "karpenter" {
  for_each = local.karpenter_interruption_rules

  name = "${local.name}-karpenter-${each.key}"
  event_pattern = jsonencode({
    source        = each.value.source
    "detail-type" = each.value.detail_type
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "karpenter" {
  for_each = aws_cloudwatch_event_rule.karpenter

  rule      = each.value.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter.arn
}



# Karpenter controller IAM policy + Pod Identity
resource "aws_iam_policy" "karpenter_controller" {
  name        = "${local.name}-karpenter-controller"
  description = "IAM policy for the Karpenter controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Actions"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances", "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate", "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates", "ec2:DescribeImages",
          "ec2:DescribeInstances", "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings", "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets", "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSpotPriceHistory", "ec2:CreateTags",
          "pricing:GetProducts", "ssm:GetParameter",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2TerminateKarpenterNodes"
        Effect = "Allow"
        Action = ["ec2:TerminateInstances"]
        Resource = "*"
        Condition = {
          StringLike = { "ec2:ResourceTag/karpenter.sh/nodepool" = "*" }
        }
      },
      {
        Sid      = "AllowPassNodeRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = aws_iam_role.karpenter_node.arn
      },
      {
        Sid      = "AllowEKSClusterLookup"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "*"
      },
      {
        Sid    = "AllowInstanceProfileManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile", "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowInterruptionQueue"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:ReceiveMessage",
        ]
        Resource = aws_sqs_queue.karpenter.arn
      },
    ]
  })

  tags = local.tags
}

module "karpenter_pod_identity" {
  source = "../../modules/pod-identity"

  cluster_name    = module.eks.cluster_name
  role_name       = "${local.name}-karpenter-controller"
  namespace       = "karpenter"
  service_account = "karpenter"
  policy_arns     = [aws_iam_policy.karpenter_controller.arn]

  tags = local.tags

  depends_on = [module.addon_pod_identity_agent]
}
