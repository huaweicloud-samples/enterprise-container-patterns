# 华为云部署指导书

本指导书说明如何在华为云上将「容器模式目录」参考实现从零部署到可用。整体分为三步：准备基础环境、构建并推送镜像、部署工作负载。

## 一、前置准备

1. 注册华为云账号并完成企业实名认证。
2. 安装并配置命令行工具：
   - `terraform` >= 1.5（用于核心基础设施）
   - `kubectl`（用于交付 CCE 工作负载）
   - `docker`（用于构建并推送镜像）
3. 配置访问凭据（从环境变量注入，不落盘、不回显）：
   - 在本地终端设置 `访问凭据` / `访问凭据`，并在 `terraform` 执行环境中引用；禁止将真实密钥写入任何文件或报告。
4. 确认目标区域（默认 `cn-north-4`）的节点规格 `s6.large.2` 可售。

## 二、部署核心基础设施

核心基础设施（VPC、子网、安全组、CCE 集群与节点池、SWR 组织与仓库、NAT 出口）以 Terraform 管理：

```shell
cd infra/core
terraform init
terraform plan
terraform apply --auto-approve
```

`apply` 完成后记录输出的 `cce_cluster_name` 与 `swr_login_endpoint`，供后续步骤使用。

> 费用提示：核心基础设施含 CCE 节点池（按节点规格计费）、NAT + EIP（按流量）、SWR（按存储）。默认 2 节点 `s6.large.2`（约 ¥0.4/小时/节点）合计约 ¥1/小时左右，远低于 ¥10/小时 阈值，可直接部署，无需额外成本确认。调试结束后请执行 `terraform destroy` 释放资源，避免持续计费。

## 三、获取集群访问配置

```shell
# 通过华为云命令行获取 kubeconfig（凭据仅在运行期内存中使用）
hcloud cce kubeconfig get --cluster <cce_cluster_name> --file ./kubeconfig.yaml
export KUBECONFIG=$PWD/kubeconfig.yaml
kubectl get nodes
```

## 四、构建并推送镜像

登录 SWR 后将示例镜像推送至对应仓库（每个模式一个仓库）：

```shell
REGION=cn-north-4
ORG=container-patterns
docker login swr.${REGION}.myhuaweicloud.com \
  -u <访问凭据> -p <访问凭据>

# 示例应用（负载均衡 / 服务发现后端 / sidecar 应用容器）
docker build -t swr.${REGION}.myhuaweicloud.com/${ORG}/sample-app:latest \
  src/sample-app/backend
docker push swr.${REGION}.myhuaweicloud.com/${ORG}/sample-app:latest

# 前端（服务发现）
docker build -t swr.${REGION}.myhuaweicloud.com/${ORG}/service-discovery-frontend:latest \
  src/sample-app/frontend
docker push swr.${REGION}.myhuaweicloud.com/${ORG}/service-discovery-frontend:latest

# Nginx Sidecar
docker build -t swr.${REGION}.myhuaweicloud.com/${ORG}/nginx-sidecar:latest \
  src/sample-app/nginx-sidecar
docker push swr.${REGION}.myhuaweicloud.com/${ORG}/nginx-sidecar:latest

# 定时任务
docker build -t swr.${REGION}.myhuaweicloud.com/${ORG}/cron-job:latest \
  src/sample-app/cron-job
docker push swr.${REGION}.myhuaweicloud.com/${ORG}/cron-job:latest
```

> 说明：各模式 Terraform 已创建对应 SWR 仓库；镜像推送地址以 `terraform output` 为准。

## 五、部署参考模式

每种模式的工作负载清单位于 `infra/patterns/<模式>/k8s/`：

```shell
# 负载均衡公共服务
kubectl apply -f infra/patterns/load-balanced-public-service/k8s/deployment.yaml

# Nginx Sidecar 反向代理
kubectl apply -f infra/patterns/nginx-sidecar-reverse-proxy/k8s/deployment.yaml

# 服务发现
kubectl apply -f infra/patterns/service-discovery/k8s/deployment.yaml

# 定时任务
kubectl apply -f infra/patterns/scheduled-cron-job/k8s/cronjob.yaml
```

## 六、验证

```shell
# 工作负载状态
kubectl get pods,svc,cronjob -n default

# 负载均衡公共服务：获取 ELB 公网地址并访问
kubectl get svc web-frontend -n default \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
curl http://<上述IP>/

# 服务发现：查看前端 Pod 日志确认其成功访问后端
kubectl logs deploy/frontend -n default --tail=20

# 定时任务：观察最近一次调度产生的 Pod
kubectl get jobs -n default
```

## 七、清理资源

```shell
# 删除工作负载
kubectl delete -f infra/patterns/load-balanced-public-service/k8s/deployment.yaml
kubectl delete -f infra/patterns/nginx-sidecar-reverse-proxy/k8s/deployment.yaml
kubectl delete -f infra/patterns/service-discovery/k8s/deployment.yaml
kubectl delete -f infra/patterns/scheduled-cron-job/k8s/cronjob.yaml

# 释放核心基础设施（停止计费）
cd infra/core && terraform destroy --auto-approve
```
