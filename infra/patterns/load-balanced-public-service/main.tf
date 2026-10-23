# ============================================================================
# 模式：负载均衡公共服务（Load balanced public service）
# 原 AWS 形态：ECS Fargate 服务 + Application Load Balancer + Cloud Map
# 华为云形态：CCE Deployment（多副本） + Service（ELB 自动创建注解） + SWR 镜像
# 工作负载以 kubectl 清单交付（k8s/deployment.yaml），Terraform 仅管理镜像仓库。
# ============================================================================

variable "region" {
  type    = string
  default = "cn-north-4"
}

variable "project_name" {
  type    = string
  default = "core-infra"
}

variable "swr_organization" {
  type    = string
  default = "container-patterns"
}

provider "huaweicloud" {
  region = var.region
}

# 该模式专属的镜像仓库（与核心基础设施解耦，独立 workspace 部署）
resource "huaweicloud_swr_repository" "web" {
  organization = var.swr_organization
  name         = "web-frontend"
  description  = "负载均衡公共服务示例镜像"
}

output "image_url" {
  description = "推送镜像后的完整地址，供 k8s 清单 image 字段引用。"
  value       = "${var.swr_organization}/${huaweicloud_swr_repository.web.name}"
}
