# Deployment Guide

## 前提条件

### 服务器要求
- **OS**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **Docker**: 20.10+ with BuildKit enabled
- **Docker Compose**: v2.0+ (或使用 `docker compose`)
- **SSH**: 允许密钥认证
- **端口**: 8080 (应用), 22 (SSH)

### 本地要求
- Docker CLI
- GitHub CLI (`gh`) - 可选，用于触发 workflow

## 环境配置

### 1. 准备服务器

```bash
# 登录目标服务器
ssh user@server

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# 创建部署目录
sudo mkdir -p /opt/ci-pipeline
sudo chown -R $USER:$USER /opt/ci-pipeline

# 拉取镜像测试
docker run hello-world
```

### 2. 配置 SSH 访问

```bash
# 本地生成密钥（如果还没有）
ssh-keygen -t ed25519 -C "ci-deploy@example.com"

# 复制公钥到服务器
ssh-copy-id user@server

# 测试免密登录
ssh user@server
```

### 3. 设置环境变量

在服务器创建 `.env` 文件：

```bash
cd /opt/ci-pipeline
cp env.example .env
# 编辑 .env，填写实际值

# 确保 .env 不被提交
echo ".env" >> .gitignore
```

### 4. 配置 GitHub Secrets

进入仓库 Settings → Secrets and variables → Actions:

| Secret Key | Value | 描述 |
|-----------|-------|------|
| `DOCKER_USERNAME` | your-docker-username | Docker Hub 用户名 |
| `DOCKER_PASSWORD` | your-access-token | Docker Hub Access Token |
| `SSH_PRIVATE_KEY` | (你的私钥内容) | 部署 SSH 私钥 |
| `DEV_HOST` | dev.example.com | Dev 服务器地址 |
| `DEV_USER` | deployer | Dev SSH 用户 |
| `STAGING_HOST` | staging.example.com | Staging 服务器地址 |
| `STAGING_USER` | deployer | Staging SSH 用户 |
| `PROD_HOST` | prod.example.com | Prod 服务器地址 |
| `PROD_USER` | deployer | Prod SSH 用户 |
| `NOTIFICATION_WEBHOOK` | https://hooks.slack.com/... | 通知 webhook（可选） |

**注意**:
- `SSH_PRIVATE_KEY` 是完整私钥内容（包括 `-----BEGIN...` 行）
- 使用 Deploy Keys 而非个人账户密钥更安全

## 部署流程

### 首次部署

```bash
# 1. 手动触发 CD workflow
gh workflow run cd.yml -f environment=dev -f image_tag=latest

# 2. 或者通过 GitHub UI
# - 进入 Actions 标签
# - 选择 "CD Pipeline"
# - 点击 "Run workflow"
# - 选择 environment: dev
```

### 后续部署

#### 自动部署（dev & staging）
- main 分支自动触发 staging 部署
- 使用 GitHub CLI 触发 dev 部署

#### 手动生产部署
```bash
# 使用 GitHub CLI
gh workflow run cd.yml -f environment=prod -f image_tag=v1.0.0

# 或者通过 GitHub UI 手动触发并等待 Approval
```

### 监控部署

1. **查看进度**:
```bash
# GitHub Actions UI → 查看实时日志
```

2. **验证部署**:
```bash
curl https://your-domain.com/health
# 期望返回: {"status":"healthy",...}
```

3. **查看容器状态**:
```bash
ssh user@server
docker ps
docker logs ci-pipeline
```

## 蓝绿部署详解

生产环境使用蓝绿部署策略：

1. 拉取新镜像
2. 在新容器启动（端口 8081）
3. 健康检查（`curl http://localhost:8081/health`）
4. 切换：停止旧容器，重命名新容器
5. 验证外部健康检查

**回滚**:
如果新版本有问题，快速切换回旧版：
```bash
ssh user@prod-server
# 如果有旧容器镜像
docker-compose -f docker-compose.prod.yml up -d previous_version
```

## 本地测试

### 1. 运行本地 CI
```bash
bash run-local.sh
```

### 2. 使用 act 模拟
```bash
# 安装 act
brew install act  # macOS
# 或从 https://github.com/nektos/act 下载

# 运行单个 job
act -j code-quality

# 运行所有 CI jobs
act -W ci.yml

# 带 secrets
cat > .secrets <<EOF
DOCKER_USERNAME=demo
DOCKER_PASSWORD=demo
EOF
act -s .secrets
```

### 3. Docker Compose 本地开发
```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f app

# 测试
curl http://localhost:8080/health
curl http://localhost:8080/api/info

# 停止
docker-compose down
```

## 高级配置

### 自定义部署清单

编辑 `deployments/{env}.yml`:

```yaml
# 示例：添加数据库配置
environment: staging
server: staging-user@staging.example.com
deploy_dir: /opt/ci-pipeline
docker_compose: true
health_check_url: http://staging.example.com/health

# 自定义变量
DB_BACKUP: true
ROLLBACK_TIMEOUT: 300
```

### 自定义 Docker 标签

在 `cd.yml` workflow dispatch 中输入 `image_tag`，例如 `v1.2.3` 或 `release-2024-01-15`。

### 扩展通知

除了 Slack webhook，还可以集成：
- **Email**: Use `dawidd6/action-send-mail`
- **Discord**: Use `Ilshidur/action-discord`
- **Teams**: Use `microsoft/teams-webhook`

示例在 `cd.yml` 中添加：
```yaml
- name: Notify Teams
  uses: Ilshidur/action-discord@master
  env:
    DISCORD_WEBHOOK: ${{ secrets.TEAMS_WEBHOOK }}
  with:
    args: '🚀 Deployment to ${{ env.ENVIRONMENT }} succeeded!'
```

## 故障排除

### SSH 连接失败
```bash
# 检查 SSH 密钥
ssh -v user@server

# 确保公钥在服务器的 ~/.ssh/authorized_keys
cat ~/.ssh/id_ed25519.pub | ssh user@server "cat >> ~/.ssh/authorized_keys"

# 检查权限
ssh user@server "ls -la ~/.ssh/"
# 应该: authorized_keys 600, .ssh 700
```

### Docker 权限错误
```bash
# 确保用户在 docker 组
groups $USER  # 应该包含 docker
# 如果没有
sudo usermod -aG docker $USER
newgrp docker
```

### 健康检查失败
```bash
# SSH 到服务器检查容器
ssh user@server
docker ps
docker logs ci-pipeline

# 手动测试健康端点
curl http://localhost:8080/health

# 查看容器内部
docker exec -it ci-pipeline bash
# 检查应用日志
cat logs/app.log
```

### CI 覆盖率不达标
```bash
# 本地运行查看详细报告
./run-local.sh
# 查看 HTML 报告
xdg-open coverage/html/index.html
```

### 构建缓存失效
```bash
# 检查 BuildKit 是否启用
echo $DOCKER_BUILDKIT  # 应该是 1

# 在 CD job 开头添加
- name: Enable BuildKit
  run: echo 'DOCKER_BUILDKIT=1' >> $GITHUB_ENV
```

## 生产就绪检查清单

- [ ] 所有服务器已配置 HTTPS (使用 nginx/Traefik)
- [ ] CI 覆盖率 >80%
- [ ] Docker 镜像扫描通过（无高危 CVE）
- [ ] Secrets 已全部配置在 GitHub
- [ ] 监控已设置（健康检查 + 日志聚合）
- [ ] 回滚流程已演练
- [ ] 数据库备份策略已配置
- [ ] 日志已收集到中央系统（如 ELK）
- [ ] 性能基线已建立
- [ ] 团队已收到通知配置

## 相关链接

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker 最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [蓝绿部署](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/compare-load-balancers.html)
- [GitHub CLI](https://cli.github.com/)
