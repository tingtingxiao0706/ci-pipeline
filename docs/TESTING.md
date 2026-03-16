# Testing Guide

## 测试策略

本项目采用多层测试策略，确保代码质量和可靠性：

```
单元测试 (pytest)
  ├── 核心逻辑测试
  ├── API 端点测试
  └── Mock 外部依赖

集成测试 (pytest + Docker)
  └── 数据库、缓存连接测试

静态分析
  ├── Linting (black, ruff)
  ├── Type checking (mypy)
  └── Security scanning (bandit)

覆盖率要求
  └── 所有业务逻辑 >= 80%
```

## 运行测试

### 本地运行所有测试

```bash
# 安装开发依赖
pip install -r requirements.txt
pip install -r requirements-app.txt

# 运行所有测试并查看覆盖率
pytest tests/ -v --cov=app --cov-report=html

# 打开 HTML 报告
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage\html\index.html  # Windows
```

### 运行特定测试

```bash
# 单个文件
pytest tests/test_main.py -v

# 单个测试函数
pytest tests/test_main.py::TestMain::test_calculate_sum -v

# 使用关键字匹配
pytest -k "test_process" -v
```

### 带覆盖率阈值检查

```bash
# 设置阈值（默认 80%）
COVERAGE_THRESHOLD=90 pytest tests/ --cov=app --cov-fail-under=90
```

## 使用 run-local.sh

本地模拟完整的 CI 流程：

```bash
bash run-local.sh
```

该脚本会按顺序执行：
1. Code Quality (black, ruff)
2. Type Check (mypy)
3. Security Scan (bandit)
4. Tests & Coverage
5. Build (Docker)

## 使用 act 测试 GitHub Actions

[act](https://github.com/nektos/act) 允许在本地运行 GitHub Actions。

```bash
# 安装 act
brew install act  # macOS
# 或下载二进制文件

# 创建 secrets 文件
cat > .secrets <<EOF
DOCKER_USERNAME=demo
DOCKER_PASSWORD=demo
EOF

# 运行特定 job
act -j code-quality

# 运行所有 CI 相关 jobs
act -W ci.yml

# 监听文件变化自动重试
act -W --bind

# 使用不同的容器运行时
act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

## 编写新测试

### 项目结构
```
tests/
├── __init__.py
├── conftest.py          # pytest fixtures
├── test_main.py        # 示例测试
└── test_api.py         # API 测试（未来）
```

### 示例测试

```python
# tests/test_logic.py
import pytest
from app.logic import calculate_sum, find_max, process_data

class TestCalculateSum:
    def test_positive_numbers(self):
        assert calculate_sum([1, 2, 3]) == 6

    def test_empty_list(self):
        assert calculate_sum([]) == 0

    def test_negative_numbers(self):
        assert calculate_sum([-1, -2, -3]) == -6

class TestFindMax:
    def test_normal_case(self):
        assert find_max([1, 2, 3]) == 3

    def test_single_element(self):
        assert find_max([42]) == 42

    def test_empty_list(self):
        assert find_max([]) is None

    def test_duplicate_max(self):
        assert find_max([1, 2, 2, 1]) == 2

class TestProcessData:
    def test_complete(self):
        result = process_data([1, 2, 3, 4, 5])
        assert result == {
            'total': 15,
            'max': 5,
            'average': 3.0,
            'count': 5
        }

    def test_single_item(self):
        result = process_data([10])
        assert result == {
            'total': 10,
            'max': 10,
            'average': 10.0,
            'count': 1
        }

    def test_empty(self):
        result = process_data([])
        assert result == {
            'total': 0,
            'max': None,
            'average': 0,
            'count': 0
        }
```

### Fixtures

```python
# tests/conftest.py
import pytest
from app.logic import process_data

@pytest.fixture
def sample_numbers():
    """提供示例数字列表"""
    return [1, 2, 3, 4, 5]

@pytest.fixture
def empty_data():
    """空数据集"""
    return []

# 使用
def test_with_fixture(sample_numbers):
    result = process_data(sample_numbers)
    assert result['count'] == 5
```

### 测试 API

```python
# tests/test_api.py
import pytest
from app.main import app

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_info_endpoint(client):
    response = client.get('/api/info')
    assert response.status_code == 200
    data = response.get_json()
    assert 'version' in data

def test_process_endpoint(client):
    response = client.post(
        '/api/process',
        json={'numbers': [1, 2, 3]},
        content_type='application/json'
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data['total'] == 6
    assert data['max'] == 3
```

## Mocking 外部依赖

```python
from unittest.mock import patch, MagicMock

@patch('app.logic.requests.get')
def test_external_api_call(mock_get):
    # 配置 mock 返回值
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {'data': 'test'}
    mock_get.return_value = mock_response

    # 调用被测试函数
    result = call_external_api()

    # 验证
    mock_get.assert_called_once_with('http://api.example.com/data')
    assert result == {'data': 'test'}
```

## 性能测试（可选）

```python
# tests/test_performance.py
import time
import pytest

@pytest.mark.slow
def test_performance():
    large_list = list(range(1000000))
    start = time.time()
    result = process_data(large_list)
    duration = time.time() - start
    assert duration < 1.0  # 应在 1 秒内完成
    assert result['count'] == 1000000
```

运行性能测试：
```bash
pytest tests/test_performance.py -m slow
```

## 测试覆盖率

### 查看详细报告
```bash
# HTML 报告
pytest --cov=app --cov-report=html
open coverage/html/index.html

# 终端显示缺失行
pytest --cov=app --cov-report=term-missing

# XML 格式（CI 使用）
pytest --cov=app --cov-report=xml
```

### 忽略不需要覆盖的文件

在 `pyproject.toml` 中：

```toml
[tool.coverage.run]
omit = [
    "tests/*",
    "app/__init__.py",
    "app/main.py"  # 如果需要单独忽略
]
```

### 分支覆盖率

```bash
pytest --cov=app --cov-branch
```

## 持续集成中的测试

CI 流程中测试阶段：

```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        cache: 'pip'
    - run: pip install -r requirements.txt
    - run: pytest tests/ \
        --cov=app \
        --cov-report=xml \
        --cov-fail-under=80 \
        --junitxml=junit.xml
    - uses: codecov/codecov-action@v3
      with:
        file: coverage.xml
```

## 测试数据管理

### 工厂模式生成测试数据

```python
# tests/factories.py
import factory
from app.logic import SomeModel

class SomeModelFactory(factory.Factory):
    class Meta:
        model = SomeModel

    id = factory.Sequence(lambda n: n)
    name = factory.Faker('name')
    email = factory.Faker('email')

# 使用
def test_something():
    obj = SomeModelFactory()
    assert obj.id is not None
```

### 使用 pytest fixtures 初始化数据库

```python
@pytest.fixture(scope='session')
def db_engine():
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)
    yield engine
    Base.metadata.drop_all(engine)

@pytest.fixture
def db_session(db_engine):
    Session = sessionmaker(bind=db_engine)
    session = Session()
    yield session
    session.rollback()
    session.close()
```

## 测试最佳实践

1. **AAA 模式**: Arrange, Act, Assert
   ```python
   def test_something():
       # Arrange: 准备数据
       input = [1, 2, 3]
       expected = {'total': 6, ...}

       # Act: 执行
       result = process_data(input)

       # Assert: 验证
       assert result == expected
   ```

2. **单一职责**: 每个测试只验证一个行为

3. **使用描述性名称**: `test_process_empty_data_returns_zero` 而非 `test_process1`

4. **DRY 但不失清晰**: 使用 fixtures 而非过度抽象

5. **测试边界条件**:
   - 空列表
   - 极大/极小值
   - 异常输入

6. **Mock 外部调用**: 使用 `unittest.mock` 或 `pytest-mock`

7. **避免测试实现细节**: 测试行为而非内部状态

## 调试失败的测试

```bash
# 只运行失败的测试（-x 第一次失败即停止）
pytest -x

# 进入 pdb 调试器
pytest --pdb

# 显示 print 输出
pytest -s

# 详细输出
pytest -vv

# 只运行特定模式
pytest -k "process_data"
```

## 类型检查

```bash
# 运行 mypy
mypy app/ tests/

# 严格模式
mypy app/ tests/ --strict

# 生成类型.stub文件
mypy app/ --export-public-types
```

## 安全问题测试

```bash
# Bandit 安全扫描
bandit -r app/

# 生成 JSON 报告
bandit -r app/ -f json -o security-report.json

# 忽略特定测试
bandit -r app/ -x tests/,migrations/
```

## 覆盖率目标

- **核心逻辑**: 100%
- **API 路由**: 100%
- **错误处理**: 100%
- **整体项目**: >= 80%

如果覆盖率不达标，CI 将失败，需要：
1. 添加缺失的测试
2. 或调整阈值（不推荐）

## 代码 Lint

```bash
# Black 格式检查（不修改）
black --check app/ tests/

# Black 自动格式化
black app/ tests/

# Ruff linter
ruff check app/ tests/

# 自动修复
ruff check app/ tests/ --fix
```

## CI 中的测试

所有测试在 GitHub Actions 中自动运行。查看结果：
1. 进入仓库 Actions 标签
2. 选择 CI Pipeline
3. 查看 "Tests & Coverage" job
4. 下载 artifacts 查看详细报告

## 贡献测试

在新功能 PR 中必须包含：
- ✅ 单元测试覆盖新代码
- ✅ 集成测试（如涉及多个模块）
- ✅ 所有 CI 检查通过
- ✅ 覆盖率不下降

## 测试覆盖率历史

可以通过 Codecov 查看覆盖率趋势并设置阈值：

```bash
# 安装 Codecov 上传器
pip install codecov

# 上传
codecov
```

## 常见问题

**Q: 如何测试私有方法？**
A: 通常不直接测试私有方法，通过公共接口验证。如果必要，使用名称改写 `module._ClassName__method`。

**Q: 如何测试需要网络请求的函数？**
A: 使用 `pytest-mock` 或 `responses` 库 mock HTTP 请求。

**Q: 测试数据库操作？**
A: 使用 SQLite 内存数据库或 fixtures 创建测试数据库。

**Q: 并行运行测试？**
A: `pytest -n auto`（需要 pytest-xdist 插件）
