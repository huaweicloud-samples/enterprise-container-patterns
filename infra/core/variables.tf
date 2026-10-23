variable "region" {
  description = "部署区域。建议与镜像、规格可售性一致的区域，如 cn-north-4。"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "核心基础设施统一标签前缀，用于 data source 反查定位。"
  type        = string
  default     = "core-infra"
}

variable "vpc_cidr" {
  description = "VPC 网段。"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "两个可用区的公网子网网段。"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "两个可用区的私网子网网段（容器工作负载落位于此）。"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "swr_organization" {
  description = "容器镜像组织（SoftWare Repository 命名空间）。"
  type        = string
  default     = "container-patterns"
}

variable "node_flavor" {
  description = "节点池计算规格（须为所选区域真实可售规格，已核验）。"
  type        = string
  default     = "s6.large.2"
}

variable "node_count" {
  description = "节点池初始节点数。运行期由弹性伸缩改写，故在节点池上配置 ignore_changes。"
  type        = number
  default     = 2
}
