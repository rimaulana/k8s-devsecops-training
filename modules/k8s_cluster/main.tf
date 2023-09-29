provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}


locals {
  name     = basename(path.cwd)
  region   = var.region

  tags = var.tags
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  control_plane_subnet_ids = var.control_plane_subnet_ids
  subnet_ids = var.node_subnet_ids
  
  cluster_security_group_additional_rules = {
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from Codebuild security group"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = var.codebuild_security_group
    }
  }
  
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = module.eks_blueprints_addons.karpenter.node_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
     # We need to add in codebuild role arn for it to deploy app
    {
      rolearn  = var.codebuild_role_arn
      username = "Codebuild"
      groups = [
        "system:masters",
      ]
    },
  ]
  
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3a.large", "t3.large"]

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }
  
  eks_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    infra_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      name                        = "infra"
      use_custom_launch_template  = false
      subnet_ids                  = var.node_subnet_ids
      min_size                    = 1
      max_size                    = 10
      desired_size                = 3
      disk_size                   = 100
      
      labels = {
        purpose = "infra"
      }
      
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  })
}

################################################################################
# IRSA for EKS Managed Addons
################################################################################
data "aws_iam_policy_document" "vpc_cni_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "vpc_cni_role" {
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role_policy.json
}

resource "aws_iam_role" "ebs_csi_role" {
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "vpc_cni_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_role.name
}

resource "aws_iam_role_policy_attachment" "ebs_csi_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # We want to wait for the managed node group to be created first
  create_delay_dependencies = [for prof in module.eks.eks_managed_node_groups : prof.node_group_arn]

  # EKS Add-ons
  eks_addons = {
    coredns = {
      most_recent    = true
    }
    vpc-cni    = {
      most_recent    = true # To ensure access to the latest settings provided
      service_account_role_arn = aws_iam_role.vpc_cni_role.arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    kube-proxy = {
      most_recent    = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = aws_iam_role.ebs_csi_role.arn
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = var.vpc_id
      },
      {
        name  = "podDisruptionBudget.maxUnavailable"
        value = 1
      },
    ]
  }
  
  enable_karpenter = true

  enable_metrics_server = true
  
  enable_external_dns   = true
  external_dns = {
    values = [
        <<-EOT
          policy: sync
        EOT
      ]
  }
  
  helm_releases = {
    sonarqube = {
      description      = "A Helm chart for sonarqube"
      namespace        = "sonarqube"
      create_namespace = true
      chart            = "sonarqube"
      chart_version    = "10.2.0+738"
      repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
      values = [
        <<-EOT
          ingress:
            enabled: true
            ingressClassName: "nginx"
            hosts:
            - name: "sonarqube.devsecops-training.com"
        EOT
      ]
    }
  }
  enable_ingress_nginx = true
  ingress_nginx = {
    values = [
        <<-EOT
          controller:
            service:
              annotations:
                service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
                service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
                service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
                service.beta.kubernetes.io/aws-load-balancer-type: "external"
        EOT
      ]
  }
  tags = local.tags
}

################################################################################
# EBS CSI Driver
################################################################################
resource "kubectl_manifest" "ebs_csi_storage_class" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ebs-csi
      annotations:
        storageclass.kubernetes.io/is-default-class: "true"
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
  YAML

  depends_on = [
    module.eks
  ]
}

################################################################################
# EXTERNAL DNS
################################################################################
data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns-sa"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "external_dns_role" {
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
  inline_policy {
    name = "external-dns-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "route53:ChangeResourceRecordSets"
          ],
          Resource = [
            "arn:aws:route53:::hostedzone/*"
          ]
        },
        {
          Effect = "Allow",
          Action = [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ],
          Resource = [
            "*"
          ]
        }
      ]
    })
  }
}

resource "kubectl_manifest" "external_dns_irsa" {
  apply_only = true
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      annotations:
        meta.helm.sh/release-name: external-dns
        meta.helm.sh/release-namespace: external-dns
        eks.amazonaws.com/role-arn: ${aws_iam_role.external_dns_role.arn}
      labels:
        app.kubernetes.io/instance: external-dns
        app.kubernetes.io/managed-by: Helm
        app.kubernetes.io/name: external-dns
        app.kubernetes.io/version: 0.13.5
        helm.sh/chart: external-dns-1.13.0
      name: external-dns-sa
      namespace: external-dns
  YAML

  depends_on = [
    module.eks_blueprints_addons
  ]
}

################################################################################
# Karpenter
################################################################################

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["t"]
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["4", "8",]
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
        - key: "karpenter.sh/capacity-type" # If not included, the webhook for the AWS cloud provider will default to on-demand
          operator: In
          values: ["spot", "on-demand"]
      kubeletConfiguration:
        containerRuntime: containerd
        maxPods: 110
      limits:
        resources:
          cpu: 1000
      consolidation:
        enabled: true
      providerRef:
        name: default
      ttlSecondsUntilExpired: 604800 # 7 Days = 7 * 24 * 60 * 60 Seconds
  YAML

  depends_on = [
    module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${module.eks.cluster_name}
        type: private
      securityGroupSelector:
        Name: "eks-cluster-sg-${module.eks.cluster_name}*"
        kubernetes.io/cluster/${module.eks.cluster_name}: owned
      instanceProfile: ${module.eks_blueprints_addons.karpenter.node_instance_profile_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML
  
  depends_on = [
    module.eks_blueprints_addons
  ]
}