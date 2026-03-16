# CI/CD Pipeline Project

一个完整的、生产级的 GitHub Actions CI/CD 流水线实现，支持多环境部署、安全扫描、自动化测试和蓝绿部署策略。

## 📋 项目特性

### CI 阶段
- ✅ **代码质量检查**：使用 black 进行代码格式化检查
- ✅ **静态类型检查**：使用 mypy 进行类型检查
- ✅ **安全扫描**：使用 bandit 进行安全漏洞检测
- ✅ **自动化测试**：pytest 测试 + 覆盖率报告
- ✅ **构建优化**：多阶段 Docker 构建 + 层缓存

### CD 阶段
- ✅ **多环境部署**：支持 dev/staging/prod 环境
- ✅ **生产手动审批**：prod 环境需要手动确认
- ✅ **蓝绿部署**：零停机部署策略
- ✅ **缓存优化**：Docker BuildKit 高级缓存
- ✅ **健康检查**：部署后自动验证
- ✅ **失败通知**：集成 Slack/Teams webhook

### 本地开发支持
- ✅ **act 兼容**：支持本地测试 GitHub Actions 工作流
- ✅ **一键运行**：提供 run-local.sh 脚本
- ✅ **环境管理**：env.example 模板

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone <your-repo>
cd ci-pipeline
```

### 2. 配置环境变量
```bash
cp env.example .env
# 编辑 .env，填写必要的环境变量
```

### 3. 本地运行 CI
```bash
# Linux/macOS
./run-local.sh

# Windows (Git Bash)
bash run-local.sh
```

### 4. 使用 Docker Compose 本地测试
```bash
docker-compose up -d
curl http://localhost:8080/health
```

## 📁 项目结构

```
ci-pipeline/
├── .github/
│   └── workflows/
│       ├── ci.yml          # CI 流水线
│       └── cd.yml          # CD 流水线
├── app/                    # 应用代码
│   ├── __init__.py
│   ├── main.py            # Flask Web 应用
│   └── logic.py           # 业务逻辑
├── scripts/               # Shell 脚本
│   ├── lint.sh           # 代码质量检查
│   ├── typecheck.sh      # 类型检查
│   ├── security.sh       # 安全扫描
│   ├── test.sh           # 测试与覆盖率
│   ├── build.sh          # 构建脚本
│   ├── deploy.sh         # 部署脚本
│   └── run-local.sh      # 本地 CI 运行器
├── env.example            # 环境变量模板
├── project.conf           # 项目配置
├── deployments/           # 部署清单
│   ├── dev.yml
│   ├── staging.yml
│   └── prod.yml
├── docs/                  # 文档
│   ├── ARCHITECTURE.md   # 架构设计
│   ├── DEPLOYMENT.md     # 部署指南
│   ├── TESTING.md        # 测试指南
│   └── CONTRIBUTING.md   # 贡献指南
├── tests/                 # 测试文件
│   └── test_main.py
├── Dockerfile
├── docker-compose.yml
├── requirements.txt      # 开发依赖
├── requirements-app.txt # 应用依赖
├── pyproject.toml
└── README.md
```

## 🛠️ 技术栈

- **CI/CD**: GitHub Actions
- **容器**: Docker + Docker Compose
- **构建**: Docker BuildKit, Python build
- **代码质量**: black, ruff
- **类型检查**: mypy
- **安全**: bandit
- **测试**: pytest, pytest-cov
- **部署**: SSH + Blue-Green strategy
- **通知**: Slack/Teams webhook

## 📊 CI 流水线

### 触发条件
- `push` 到 main/develop 分支
- `pull_request` 到 main 分支
- 手动触发

### 并行阶段
1. **Code Quality** (black + ruff)
2. **Type Check** (mypy)
3. **Security Scan** (bandit + secrets check)
4. **Tests & Coverage** (pytest >= 80%)
5. **Build** (Docker multi-stage build)
6. **Summary** ( Pipeline 状态汇总)

所有阶段通过后才会进入 CD 阶段。

## 🚢 CD 流水线

### 环境

| 环境 | 触发方式 | 审批 | 策略 |
|------|----------|------|------|
| dev | 手动 `workflow_dispatch` | ❌ 无需 | 直接部署 |
| staging | 手动 / main 分支推送 | ❌ 无需 | 直接部署 |
| prod | **仅手动触发** | ✅ **需要审批** | 蓝绿部署 |

### 部署流程

1. **构建并推送镜像**
   - 使用 BuildKit 高级缓存
   - 标签：`{env}-{sha}` 和 `{env}-latest`

2. **SSH 到目标服务器**
   - 使用 SSH 私钥认证
   - 自动 pull 新镜像
   - 零停机部署

3. **健康检查**
   - 自动调用 `/health` 端点
   - 30s 超时，3 次重试

4. **通知**
   - 发送到 Slack/Teams webhook
   - 包含 commit SHA 和环境信息

### 手动触发 CD

```bash
# GitHub CLI
gh workflow run cd.yml -f environment=staging -f image_tag=latest

# GitHub UI
# 进入 Actions → CD Pipeline → Run workflow
# 选择 environment: dev/staging/prod
```

## 🔐 密钥配置

在 GitHub Settings → Secrets and variables → Actions 中配置：

| Secret 名称 | 描述 | 必需 |
|-------------|------|------|
| `DOCKER_USERNAME` | Docker Hub 用户名 | ✅ |
| `DOCKER_PASSWORD` | Docker Hub 访问令牌 | ✅ |
| `SSH_PRIVATE_KEY` | 部署服务器的 SSH 私钥 | ✅ |
| `DEV_HOST` | Dev 服务器地址 | dev 部署 |
| `DEV_USER` | Dev SSH 用户名 | dev 部署 |
| `STAGING_HOST` | Staging 服务器地址 | staging 部署 |
| `STAGING_USER` | Staging SSH 用户名 | staging 部署 |
| `PROD_HOST` | Prod 服务器地址 | prod 部署 |
| `PROD_USER` | Prod SSH 用户名 | prod 部署 |
| `NOTIFICATION_WEBHOOK` | Slack/Teams webhook URL | 可选 |

## 🧪 测试

### 运行单元测试
```bash
pytest tests/ -v --cov=app --cov-report=html
```

### 查看覆盖率报告
```bash
open coverage/html/index.html
```

### 本地运行完整 CI
```bash
./run-local.sh
```

### 使用 act 测试 GitHub Actions
```bash
# 安装 act
brew install act  # macOS
# or download from https://github.com/nektos/act

# 运行 CI workflow
act -j code-quality  # 运行单个 job
act -j test         # 运行测试 job
act -W              # 监听文件变化

# 使用自定义 secrets
cat > .secrets/ci <<EOF
DOCKER_USERNAME=your_user
DOCKER_PASSWORD=your_token
EOF

act -s .secrets/ci
```

## 📈 覆盖率要求

当前项目配置覆盖率阈值为 **80%**。可在 `scripts/test.sh` 中调整：

```bash
COVERAGE_THRESHOLD=90
```

## 🔧 自定义脚本

### 添加新的 CI 阶段
1. 创建 `scripts/your-script.sh`
2. 在 `.github/workflows/ci.yml` 中添加新 job
3. 更新 `needs` 依赖关系

### 添加新的部署环境
1. 创建 `deployments/{env}.yml`
2. 在 `.github/workflows/cd.yml` 中添加对应 job
3. 配置 GitHub Secrets

## 🐛 故障排除

### CI 失败
- 查看 Artifacts 中的日志和报告
- 本地运行 `./run-local.sh` 调试

### Docker 构建慢
- 检查 Docker BuildKit 缓存是否启用
- 调整 `cache-from` 和 `cache-to` 策略
- 使用更小的基础镜像（alpine）

### 部署失败
- 检查 SSH 连接：`ssh -i key user@host`
- 验证目标服务器 Docker 是否运行
- 查看部署日志：`docker-compose logs -f`

## 📝 许可证

MIT License - 详见 LICENSE 文件

## 🙏 致谢

本项目模板基于行业最佳实践构建，适用于大多数 Python + Docker 项目。可根据实际需求灵活调整。

---

**维护者**: AI Assistant
**最后更新**: 2026-03-16
