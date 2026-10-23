output "vpc_id" {
  description = "核心 VPC ID，供各模式 data source 反查定位。"
  value       = huaweicloud_vpc.this.id
}

output "private_subnet_ids" {
  description = "私网子网 ID 列表，工作负载落点。"
  value       = huaweicloud_vpc_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "公网子网 ID 列表。"
  value       = huaweicloud_vpc_subnet.public[*].id
}

output "cce_cluster_id" {
  description = "CCE 集群 ID。"
  value       = huaweicloud_cce_cluster.this.id
}

output "cce_cluster_name" {
  description = "CCE 集群名称，kubectl 配置使用。"
  value       = huaweicloud_cce_cluster.this.name
}

output "node_security_group_id" {
  description = "节点安全组 ID，供工作负载安全组规则引用。"
  value       = huaweicloud_networking_secgroup.node.id
}

output "swr_organization" {
  description = "SWR 镜像组织名。"
  value       = huaweicloud_swr_organization.this.name
}

output "swr_login_endpoint" {
  description = "SWR 登录地址（区域相关），用于 docker login 推送镜像。"
  value       = "swr.${var.region}.myhuaweicloud.com"
}
