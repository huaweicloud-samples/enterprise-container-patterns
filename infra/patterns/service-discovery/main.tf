# ============================================================================
# 模式：服务发现（Service Discovery）
# 原 AWS 形态：ECS 服务注册到 Cloud Map 私有命名空间，按服务名互相寻址
# 华为云形态：CCE 内置 CoreDNS，Service 名称即为集群内 DNS 记录，
#            通过 <service>.<namespace>.svc.cluster.local 互相寻址（无需额外组件）
# 工作负载以 kubectl 清单交付（k8s/ 目录）。
# ============================================================================

variable "region" {
  type    = string
  default = "cn-north-4"
}

variable "swr_organization" {
  type    = string
  default = "container-patterns"
}

provider "huaweicloud" {
  region = var.region
}

resource "huaweicloud_swr_repository" "frontend" {
  organization = var.swr_organization
  name         = "service-discovery-frontend"
  description  = "服务发现前端示例镜像"
}

resource "huaweicloud_swr_repository" "backend" {
  organization = var.swr_organization
  name         = "service-discovery-backend"
  description  = "服务发现后端示例镜像"
}

output "frontend_image" {
  value = "${var.swr_organization}/${huaweicloud_swr_repository.frontend.name}"
}

output "backend_image" {
  value = "${var.swr_organization}/${huaweicloud_swr_repository.backend.name}"
}
