# ============================================================================
# 模式：定时任务（Scheduled / Cron Job）
# 原 AWS 形态：ECS 计划任务（EventBridge 规则调度 Fargate 任务）/ AWS Copilot cron-job
# 华为云形态（推荐）：CCE 原生 CronJob，由集群控制面按 cron 调度 Pod
# 备选形态：函数工作流（FunctionGraph）定时器触发函数，适合无长时计算、短任务
# 工作负载以 kubectl 清单交付（k8s/cronjob.yaml）。
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

resource "huaweicloud_swr_repository" "job" {
  organization = var.swr_organization
  name         = "cron-job"
  description  = "定时任务示例镜像"
}

output "job_image" {
  value = "${var.swr_organization}/${huaweicloud_swr_repository.job.name}"
}
