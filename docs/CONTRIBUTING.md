# Contributing Guide

感谢您为 CI/CD Pipeline 项目做贡献！🎉

## 行为准则

本项目遵守 [Contributor Covenant](https://www.contributor-covenant.org/)。请保持尊重和专业。

## 如何贡献

### 报告 Bug

1. 检查 [Issues](https://github.com/your-org/ci-pipeline/issues) 是否已存在
2. 如不存在，创建新 Issue，提供：
   - 清晰的问题描述
   - 复现步骤
   - 预期行为 vs 实际行为
   - 环境信息（OS, Python 版本等）
   - 日志、错误信息

### 提出新功能

1. 讨论先于实现：先创建 Issue 讨论可行性
2. 避免重复功能
3. 确保与项目架构一致

### 提交 Pull Request

#### 开发流程

```bash
# 1. Fork 项目
# 2. 克隆到本地
git clone https://github.com/your-username/ci-pipeline.git
cd ci-pipeline

# 3. 创建特性分支
git checkout -b feature/my-new-feature

# 4. 安装依赖
pip install -r requirements.txt
pip install -r requirements-app.txt

# 5. 编写代码和测试
# ...

# 6. 本地运行 CI
bash run-local.sh

# 7. 确保所有检查通过
# - black --check 无错误
# - ruff check 无警告
# - mypy 通过
# - pytest 全部通过且覆盖率不下降

# 8. 提交代码
git add .
git commit -m "feat: add new feature XYZ"

# 9. 推送到 fork
git push origin feature/my-new-feature

# 10. 创建 Pull Request 到主仓库
```

#### Commit Message 约定

使用 [Conventional Commits](https://www.conventionalcommits.org/)：

```
type(scope): description

[optional body]

[optional footer]
```

**Types**:
- `feat`: 新功能
- `fix`: bug 修复
- `docs`: 文档变更
- `style`: 代码格式（不影响功能的修改）
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 添加测试
- `chore`: 构建/工具变更

**Examples**:
```
feat(ci): add security scanning with bandit
fix(deploy): handle SSH connection errors gracefully
docs(readme): add quick start guide
test(api): add coverage for error responses
```

#### PR 要求

- [ ] 关联的 Issue 已填写（如适用）
- [ ] 所有 CI 检查通过
- [ ] 代码覆盖率不下降（或下降 <1%）
- [ ] 添加了必要的测试（新功能需 >=80% 覆盖率）
- [ ] 更新了相关文档
- [ ] Commit 信息清晰
- [ ] 没有 merge 冲突

### 代码规范

#### Python
- 遵循 PEP 8
- 使用类型提示（mypy 检查）
- 函数长度 <= 50 行
- 类单一职责
- 使用黑魔法（metaclass, eval 等）需注释解释

#### Shell 脚本
- 使用 `set -e` 失败即退出
- 使用 `set -u` 未定义变量报错
- 使用 `set -o pipefail` 管道错误检测
- 函数需有文档注释
- 使用 `local` 变量
- 避免无用代码

#### YAML
- 2 空格缩进
- 使用单引号
- 列表项对齐
- keys 使用 snake_case

## 开发环境设置

### 本地开发

```bash
# 1. 克隆仓库
git clone https://github.com/your-org/ci-pipeline.git
cd ci-pipeline

# 2. 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/macOS
# venv\Scripts\activate  # Windows

# 3. 安装依赖
pip install -r requirements.txt

# 4. 安装 pre-commit hooks
pre-commit install

# 5. 运行本地 CI
bash run-local.sh
```

### 使用 Docker Compose 开发

```bash
# 构建并启动
docker-compose up -d

# 进入容器调试
docker-compose exec app bash

# 查看日志
docker-compose logs -f app

# 停止
docker-compose down
```

## 文档贡献

### 修改文档

1. 文档使用 Markdown
2. 中文文档使用 UTF-8 编码
3. 代码块指定语言高亮：
   ```markdown
   ```bash
   ls -la
   ```
   ```
4. 更新目录（如适用）
5. 预览渲染效果（GitHub 会自动渲染）

### 新增文档

- 放在 `docs/` 目录
- 更新 `README.md` 链接
- 遵循现有风格

## 发布流程

### 版本号规范

使用 [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

例如：1.2.3
- MAJOR: 不兼容的 API 修改
- MINOR: 向下兼容的功能性新增
- PATCH: 向下兼容的问题修正
```

### 发布准备

1. 更新 `CHANGELOG.md`（如果存在）
2. 确保所有 tests 通过
3. 更新版本号：
   - `pyproject.toml`: `version = "x.y.z"`
   - `app/__init__.py`: `__version__ = "x.y.z"`
   - `README.md`: 更新版本号（如适用）

4. 创建 release commit：
```bash
git add .
git commit -m "chore: prepare release v1.2.3"
git push origin main
```

5. 创建 GitHub Release：
```bash
gh release create v1.2.3 --generate-notes
```

### Hotfix 流程

```bash
git checkout main
git pull origin main
git checkout -b hotfix/issue-123
# 修复 bug
git commit -m "fix: resolve issue 123"
git push origin hotfix/issue-123
# 创建 PR 到 main
# 合并后打 hotfix 标签
gh release create v1.2.4 --notes "Hotfix for issue 123"
```

## 代码审查

### PR 审查清单

- [ ] **功能正确性**: 代码是否按预期工作？
- [ ] **测试覆盖率**: 新增代码是否有测试？
- [ ] **性能影响**: 会不会引入性能退化？
- [ ] **安全性**: 是否有安全风险？
- [ ] **可维护性**: 代码是否清晰易懂？
- [ ] **向后兼容**: 是否破坏现有 API？

### 审查者职责

- 仔细阅读代码
- 提出问题而非直接拒绝
- 确保 CI 通过
- 合并前确保至少 1 个批准（视团队规模）

### PR 作者响应

- 对所有评论进行回复
- 如不同意，礼貌讨论
- 尽快处理审查意见
- 需要帮助时及时提出

## 常见问题

### 我的 CI 失败了怎么办？

1. 本地运行 `bash run-local.sh` 调试
2. 查看 Artifacts 中的详细日志
3. 检查错误信息并修复
4. 推送新提交自动触发重新运行

### 如何跳过某个 CI 检查？

不推荐，但可使用 `[skip ci]` 在 commit message 前面（需配置）。更好的方式是修复问题。

### 如何添加新的 linter？

1. 在 `requirements.txt` 添加包
2. 在 `ci.yml` 添加新 job 或 step
3. 更新文档

## 获取帮助

- **文档**: 查看 `docs/` 目录
- **Issues**: 提问前先搜索现有 issues
- **Discussions**: GitHub Discussions
- **Chat**: Slack/Teams（如团队配置）

## 许可证

MIT License - 详见 LICENSE 文件

---

再次感谢您的贡献！🚀
