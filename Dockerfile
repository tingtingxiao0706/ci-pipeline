# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends gcc && rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt
COPY requirements-app.txt .
RUN pip install --user --no-cache-dir -r requirements-app.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for gunicorn
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash app && chown -R app:app /app

# Copy Python packages from builder to app user's home
COPY --from=builder /root/.local /home/app/.local
RUN chown -R app:app /home/app/.local
ENV PATH=/home/app/.local/bin:$PATH

# Copy application code
COPY --chown=app:app app/ ./app/
COPY --chown=app:app tests/ ./tests/

# Switch to non-root user
USER app

# Expose port
EXPOSE 8080

# Run the application with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "app.main:wsgi_app"]
