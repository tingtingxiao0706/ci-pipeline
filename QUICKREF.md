# Project Quick Reference

## 快速命令

### 本地开发
```bash
# 安装依赖
make install

# 运行测试
make test

# 格式代码
make format

# Lint 检查
make lint

# 类型检查
make typecheck

# 安全扫描
make security

# Docker 运行
make docker-run

# 完整 CI 本地模拟
make ci-local

# 清理
make clean
```

### GitHub Actions
```bash
# 触发 CD 部署
gh workflow run cd.yml -f environment=dev -f image_tag=latest
gh workflow run cd.yml -f environment=staging
gh workflow run cd.yml -f environment=prod  # 需要 Approval

# 查看 Actions 状态
gh run list
gh run view <run-id>

# 查看日志
gh run view <run-id> --log
```

### Docker
```bash
# 构建镜像
docker build -t ci-pipeline:latest .

# 推送镜像
docker push yourusername/ci-pipeline:latest

# 运行容器
docker run -p 8080:8080 ci-pipeline:latest

# 查看日志
docker logs -f <container-id>
```

## 文件说明

| 文件/目录 | 用途 |
|-----------|------|
| `.github/workflows/ci.yml` | CI 流水线（代码检查、测试、构建） |
| `.github/workflows/cd.yml` | CD 流水线（多环境部署） |
| `scripts/*.sh` | Shell 脚本（测试、构建、部署） |
| `app/` | Flask 应用源码 |
| `tests/` | pytest 测试用例 |
| `config/` | 配置模板 |
| `deployments/` | 各环境部署清单 |
| `Dockerfile` | 多阶段 Docker 构建 |
| `docker-compose.yml` | 本地开发编排 |
| `requirements*.txt` | Python 依赖 |
| `pyproject.toml` | 项目元数据和工具配置 |

## 环境变量

| 变量名 | 描述 | 必需 | 默认值 |
|--------|------|------|--------|
| `ENVIRONMENT` | 环境：dev/staging/prod | ❌ | dev |
| `PORT` | 应用监听端口 | ❌ | 8080 |
| `DATABASE_URL` | 数据库连接串 | ❌ | postgresql://... |
| `SECRET_KEY` | 应用密钥 | ✅ | - |
| `DEBUG` | 调试模式 | ❌ | false |
| `DOCKER_USERNAME` | Docker Hub 用户名 | CI 需要 | - |
| `DOCKER_PASSWORD` | Docker Hub 密码/Token | CI 需要 | - |

## 端口分配

| 服务 | 端口 | 用途 |
|------|------|------|
| Flask 应用 | 8080 | 主服务端口 |
| 健康检查 | /health | 监控探针 |
| API | /api/* | REST API |
| SSH | 22 | 部署通道 |

## CI 流程时序图

```
Push/PR
   ↓
Parallel Jobs:
├─ Code Quality (black, ruff)
├─ Type Check (mypy)
├─ Security (bandit)
└─ Tests (pytest, coverage)
   ↓ (all passed)
Build Job
   ↓ (artifacts ready)
CD Pipeline (manual trigger)
   ↓
Deploy to Target Env
   ↓
Health Check → Notify
```

## 故障排查速查

| 问题 | 检查点 | 解决 |
|------|--------|------|
| CI 失败 | 查看 Artifacts 日志 | 本地运行 run-local.sh |
| 测试覆盖率不足 | `pytest --cov-report=term-missing` | 补充测试用例 |
| Docker 构建慢 | BuildKit 缓存是否命中 | 检查 cache-from/to |
| 部署失败 | SSH 连接测试 | `ssh -v user@host` |
| 健康检查超时 | 容器日志 | `docker logs <container>` |
| 权限错误 | 用户组 | `sudo usermod -aG docker $USER` |

## 覆盖率报告路径

- **HTML**: `coverage/html/index.html`
- **XML**: `coverage/coverage.xml` (CI 上传)
- **终端**: `pytest --cov-report=term-missing`

## 联系人

- **维护者**: AI Assistant
- **仓库**: `your-org/ci-pipeline`
- **文档**: `docs/` 目录
- **Issue**: GitHub Issues

## 更新日志

### v1.0.0 (2026-03-16)
- ✅ 初始发布
- ✅ 完整 CI/CD 流水线
- ✅ 多环境部署（dev/staging/prod）
- ✅ 蓝绿部署策略
- ✅ 缓存优化
- ✅ 本地测试支持（act）
- ✅ 通知机制

---

**TIP**: 使用 `make help` 查看所有可用命令
