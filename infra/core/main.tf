# ============================================================================
# 核心基础设施（华为云）—— 容器模式目录共享底座
# 管理：VPC / 子网 / 安全组 / CCE 集群与节点池 / SWR 镜像组织 / 容器镜像仓库
# 说明：CCE 工作负载（Deployment / Service / CronJob）不在 Terraform 内声明，
#       交由 kubectl 清单交付（详见各模式 k8s/ 目录与 src/manifests/）。
# ============================================================================

locals {
  tags = {
    Blueprint  = "container-patterns"
    ManagedBy = "terraform"
    Project    = var.project_name
  }
}

# ---------------------------------------------------------------------------
# 网络：VPC + 公网/私网子网
# ---------------------------------------------------------------------------
resource "huaweicloud_vpc" "this" {
  name = var.project_name
  cidr = var.vpc_cidr
  tags = local.tags
}

resource "huaweicloud_vpc_subnet" "public" {
  count      = length(var.public_subnet_cidrs)
  name       = "${var.project_name}-public-${count.index}"
  vpc_id     = huaweicloud_vpc.this.id
  cidr       = var.public_subnet_cidrs[count.index]
  gateway_ip = cidrhost(var.public_subnet_cidrs[count.index], 1)
  tags       = local.tags
}

resource "huaweicloud_vpc_subnet" "private" {
  count      = length(var.private_subnet_cidrs)
  name       = "${var.project_name}-private-${count.index}"
  vpc_id     = huaweicloud_vpc.this.id
  cidr       = var.private_subnet_cidrs[count.index]
  gateway_ip = cidrhost(var.private_subnet_cidrs[count.index], 1)
  tags       = local.tags
}

# 公网出口：NAT 网关 + SNAT（私网子网通过 EIP 访问公网拉取基础镜像）
resource "huaweicloud_vpc_eip" "nat" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.project_name}-nat-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
  tags = local.tags
}

resource "huaweicloud_nat_gateway" "this" {
  name        = "${var.project_name}-nat"
  spec        = "1"
  vpc_id      = huaweicloud_vpc.this.id
  subnet_id   = huaweicloud_vpc_subnet.public[0].id
  tags        = local.tags
}

resource "huaweicloud_nat_snat_rule" "this" {
  nat_gateway_id = huaweicloud_nat_gateway.this.id
  source_type    = 0
  cidr           = var.private_subnet_cidrs[0]
  floating_ip_id = huaweicloud_vpc_eip.nat.id
}

# ---------------------------------------------------------------------------
# 安全组（注意：huaweicloud_networking_secgroup，非 vpc_secgroup）
# ---------------------------------------------------------------------------
resource "huaweicloud_networking_secgroup" "node" {
  name        = "${var.project_name}-node-sg"
  description = "CCE 节点安全组"
  tags        = local.tags
}

resource "huaweicloud_networking_secgroup_rule" "node_egress_all" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "0"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.node.id
  description       = "节点全出方向"
}

resource "huaweicloud_networking_secgroup_rule" "node_ingress_intra" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "0"
  remote_group_id   = huaweicloud_networking_secgroup.node.id
  security_group_id = huaweicloud_networking_secgroup.node.id
  description       = "节点组内互访"
}

# ---------------------------------------------------------------------------
# 容器镜像仓库：SWR 组织 + 示例仓库
# ---------------------------------------------------------------------------
resource "huaweicloud_swr_organization" "this" {
  name        = var.swr_organization
}

resource "huaweicloud_swr_repository" "app" {
  organization = huaweicloud_swr_organization.this.name
  name         = "sample-app"
  description  = "示例应用镜像"
}

# ---------------------------------------------------------------------------
# CCE：集群 + 节点池
# 注意：节点池必须含 root_volume 块；运行期节点数由弹性伸缩改写，
#       故配置 lifecycle.ignore_changes = [initial_node_count]（满足 C10）。
# ---------------------------------------------------------------------------
# 说明：CCE 默认使用系统预置委托 cce_admin_trust 访问其他云服务，
#       无需自定义 IAM 委托；故此处不声明 huaweicloud_iam_agency，
#       集群创建时不显式指定 agency_name（走系统默认）。

# 节点登录密钥（验证用途；仅公钥入云，私钥留本地、不参与交付物）
resource "huaweicloud_compute_keypair" "cce" {
  name       = "${var.project_name}-cce-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA59Eig6oEYh3OkkvKHCZ7FIfO5R+u6ceG9jruie0/24 zhangcheng@zhangchengdeMacBook-Air.local"
}

resource "huaweicloud_cce_cluster" "this" {
  name                   = "${var.project_name}-cce"
  cluster_type           = "VirtualMachine"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc.this.id
  subnet_id              = huaweicloud_vpc_subnet.private[0].id
  container_network_type = "vpc-router"
  # 注意：不显式设置 enterprise_project_id。
  # 该字段在 create 后未被 provider 稳定写回 state，后续 update 会误触发 EPS 企业项目迁移
  # （EPS.0004 Permission error，当前凭据无 EPS 迁移权限）。交由账号默认企业项目即可。
  tags                   = local.tags
}

resource "huaweicloud_cce_node_pool" "this" {
  cluster_id        = huaweicloud_cce_cluster.this.id
  name              = "${var.project_name}-nodepool"
  flavor_id         = var.node_flavor
  initial_node_count = var.node_count
  availability_zone  = "cn-north-4a"
  # CCE v1.28+（含当前默认 v1.35）已移除对 EulerOS 2.9 的支持（nftables 需内核 5.13+，而 EulerOS 2.9 内核不满足）。
  # 改用当前版本支持的 Huawei Cloud EulerOS 2.0（HCE 2.0）。
  os                = "Huawei Cloud EulerOS 2.0"
  key_pair          = huaweicloud_compute_keypair.cce.name

  subnet_id = huaweicloud_vpc_subnet.private[0].id
  security_groups = [huaweicloud_networking_secgroup.node.id]

  root_volume {
    size       = 50
    volumetype = "SAS"
  }

  data_volumes {
    size       = 100
    volumetype = "SAS"
  }

  lifecycle {
    # 运行期弹性伸缩会改写节点数，Terraform 不回滚（C10）
    ignore_changes = [initial_node_count]
  }

  tags = local.tags
}
