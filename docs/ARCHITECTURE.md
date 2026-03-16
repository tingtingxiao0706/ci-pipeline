# Architecture Documentation

## 系统架构

本 CI/CD 流水线采用模块化设计，将构建、测试、部署流程分解为多个独立且可复用的组件。

### 核心架构图

```
┌─────────────────┐
│   Developer     │
│   (Push/PR)     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│         GitHub Actions CI Pipeline          │
├─────────────────────────────────────────────┤
│  Code Quality ──→ Lint (black, ruff)       │
│  Type Check ────→ mypy                      │
│  Security ──────→ bandit, secrets check    │
│  Tests ─────────→ pytest + coverage         │
│  Build ─────────→ Docker multi-stage build │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│         GitHub Actions CD Pipeline          │
├─────────────────────────────────────────────┤
│   deploy-dev    │ dev   │ Manual           │
│   deploy-staging│ stage │ Auto from main   │
│   deploy-prod   │ prod  │ Manual approval  │
└─────────────────┴───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│          Target Environments                │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐   │
│  │   Dev   │  │ Staging  │  │  Prod   │   │
│  └─────────┘  └──────────┘  └─────────┘   │
└─────────────────────────────────────────────┘
```

## 组件说明

### 1. 应用层 (app/)

- **main.py**: Flask Web 应用，提供 `/health` 健康检查端点
- **logic.py**: 核心业务逻辑（纯函数，易于测试）
- **__init__.py**: 包初始化和版本信息

### 2. 构建系统 (scripts/)

| 脚本 | 用途 | 输出 |
|------|------|------|
| `lint.sh` | 代码格式化检查 (black) + 语法检查 (ruff) | 通过/失败 |
| `typecheck.sh` | 静态类型分析 (mypy) | 通过/失败 |
| `security.sh` | 安全漏洞扫描 (bandit) + 密钥泄露检查 | JSON 报告 |
| `test.sh` | 单元测试 + 覆盖率 | coverage.xml, HTML 报告 |
| `build.sh` | 多阶段 Docker 构建 + 源码归档 | dist/ 目录 |
| `deploy.sh` | 手动部署到指定环境 | SSH 部署 |
| `run-local.sh` | 本地 CI 模拟器 | 彩色输出 |

### 3. CI 流水线 (.github/workflows/ci.yml)

#### Jobs
- **code-quality**: 并行执行 black 和 ruff 检查
- **type-check**: mypy 类型检查
- **security**: bandit 安全扫描
- **test**: pytest 测试，要求覆盖率 ≥80%
- **build**: 构建 Docker 镜像并上传 Artifacts
- **summary**: 汇总所有 job 状态

#### 特性
- ✅ 并发执行（code-quality/type-check/security/test）
- ✅ 失败快速退出
- ✅ Artifacts 上传（测试报告、构建产物）
- ✅ Codecov 集成（可选）
- ✅ Auto-cancel 重复运行

### 4. CD 流水线 (.github/workflows/cd.yml)

#### Jobs
- **deploy-dev**: 开发环境部署
- **deploy-staging**: 预发布环境部署
- **deploy-prod**: 生产环境部署（需手动 approval）
- **cleanup**: 清理旧镜像

#### 部署策略
1. **Build & Push**: 使用 Docker BuildKit，启用层缓存
2. **Blue-Green**: 生产环境使用蓝绿部署，零停机
3. **Health Check**: 部署后自动验证 `/health` 端点
4. **Notifications**: Slack/Teams webhook 通知

### 5. 容器化

#### Dockerfile 多阶段构建
- **builder**: 安装 build 依赖，编译 Python 包到用户目录
- **runtime**: 复制 Python 包，运行非 root 用户，使用 gunicorn

#### docker-compose
本地开发使用，提供：
- 容器编排
- 自动重启策略
- 健康检查
- 环境变量注入
- 网络隔离

### 6. 配置管理

#### config/
- `project.conf`: Shell 可读取的项目配置
- `env.example`: 环境变量模板（添加到 .gitignore）
- `env`: 实际环境变量（不提交）

#### deployments/
- `dev.yml`: Dev 服务器配置
- `staging.yml`: Staging 服务器配置
- `prod.yml`: Production 服务器配置

## 数据流

```
代码提交 → CI 检查 → 构建镜像 → (manual trigger) →
蓝绿部署 → 健康检查 → 通知团队
```

## 缓存策略

### 1. Python pip 缓存
```yaml
- uses: actions/setup-python@v4
  with:
    cache: 'pip'
    cache-dependency-path: 'requirements.txt'
```

### 2. Docker 层缓存
```yaml
cache-from: type=registry,ref=registry/image:cache-tag
cache-to: type=registry,ref=registry/image:cache-tag,mode=max
```

### 3. 依赖缓存 (本地)
`~/.local/` 目录持久化，避免重复安装

## 安全最佳实践

1. **Secret Management**: 使用 GitHub Secrets，不硬编码
2. **SSH Keys**: 使用 deploy keys 而非密码
3. **Non-root User**: Docker 容器使用非 root 用户运行
4. **Dependency Scanning**: Bandit 扫描依赖漏洞
5. **Secret Detection**: 禁止提交 .env, .key, .pem 文件
6. **Principle of Least Privilege**: 不同环境使用不同的部署凭据

## 可扩展性

### 添加新语言支持
1. 更新 `Dockerfile`：添加对应语言运行时
2. 更新 `requirements.txt`：添加语言包管理器依赖
3. 添加对应语言的 linter/formatter 到 `ci.yml`

### 添加新环境
1. 创建 `deployments/{new-env}.yml`
2. 在 `cd.yml` 中添加部署 job
3. 配置 GitHub Secrets

### 集成其他工具
- **Slack**: 使用 webhook 或 `slack-github-action`
- **SonarQube**: 添加 sonar 扫描 job
- **Snyk**: 添加 Snyk 安全扫描
- **Prometheus**: 暴露 metrics 端点

## 监控与告警

### 应用层
- `/health` 端点用于负载均衡器健康检查
- 建议添加 `/metrics`（Prometheus 格式）

### CI/CD 层
- GitHub Actions 自带监控和失败通知
- 建议设置仓库 Webhook 到 Slack/Teams
- 定期审查 Artifacts 保留策略（默认 90 天）

## 性能优化点

1. **并行化**: CI 阶段尽可能并行
2. **缓存**: pip, Docker layer, package manager
3. **资源限制**: GitHub Actions 使用合理 size (ubuntu-latest)
4. **Artifacts 清理**: `cleanup` job 定期清理旧镜像
5. **轻量基础镜像**: 使用 `python:3.11-slim` 而非完整镜像

## 故障恢复

### 回滚
```bash
# SSH 到服务器手动回滚
docker-compose -f docker-compose.yml up -d previous_version
```

### 紧急停止
```bash
# 在服务器执行
docker-compose stop
```

### 重建 CI/CD 流水线
如果 GitHub Actions 配置损坏，可直接从仓库恢复：
```bash
gh repo view --json defaultBranchRef
# 重新创建 branches 或恢复 .github/workflows/
```
