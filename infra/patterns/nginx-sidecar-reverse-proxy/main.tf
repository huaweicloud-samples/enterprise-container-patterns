# ============================================================================
# 模式：Nginx 反向代理 Sidecar（多容器 Pod）
# 原 AWS 形态：ECS Fargate 任务定义中声明 nginx + app 两个容器（共享网络命名空间）
# 华为云形态：CCE Pod 内两个容器天然共享网络命名空间（sidecar 模式原生支持）
# 工作负载以 kubectl 清单交付（k8s/deployment.yaml）。
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

# 应用本体镜像仓库（sample-app）由 infra/core 统一创建并持有，
# 此处不重复声明，否则两个工作区会争抢同一 SWR 仓库导致创建冲突。
variable "app_image_repository" {
  type    = string
  default = "sample-app"
}

# 该模式独有镜像：nginx 反向代理 sidecar
resource "huaweicloud_swr_repository" "nginx" {
  organization = var.swr_organization
  name         = "nginx-sidecar"
  description  = "反向代理 sidecar 镜像"
}

output "nginx_image" {
  value = "${var.swr_organization}/${huaweicloud_swr_repository.nginx.name}"
}

output "app_image" {
  value = "${var.swr_organization}/${var.app_image_repository}"
}
