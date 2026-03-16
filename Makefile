# Makefile for CI/CD Pipeline Project

.PHONY: help install test lint typecheck security build ci-local clean docker-build docker-run

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install development dependencies
	pip install -r requirements.txt
	pip install -r requirements-app.txt

test: ## Run tests with coverage
	pytest tests/ --cov=app --cov-report=html --cov-report=term-missing

lint: ## Run code formatters and linters
	black --check app/ tests/
	ruff check app/ tests/

lint-fix: ## Auto-fix linting issues
	black app/ tests/
	ruff check app/ tests/ --fix

typecheck: ## Run static type checking
	mypy app/ tests/ --ignore-missing-imports --pretty

security: ## Run security scan
	bandit -r app/ -f json -o security-report.json

build: ## Build Docker image
	docker-compose build

docker-run: build ## Build and run with Docker Compose
	docker-compose up -d
	@echo "App running at http://localhost:8080"
	@echo "Health check: http://localhost:8080/health"

docker-stop: ## Stop Docker Compose
	docker-compose down

docker-logs: ## View Docker logs
	docker-compose logs -f app

ci-local: ## Run full CI pipeline locally
	bash scripts/run-local.sh

clean: ## Clean build artifacts and caches
	rm -rf build/ dist/ coverage/ .coverage .mypy_cache .pytest_cache
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

format: ## Auto-format code with black
	black app/ tests/

all: format lint typecheck security test build ## Run all checks and build
