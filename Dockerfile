# ---------- Stage 1: Builder ----------
FROM python:3.11-slim AS builder

WORKDIR /build

# Copy dependency trước để tận dụng Docker layer cache
COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    --prefix=/install \
    -r requirements.txt


# ---------- Stage 2: Production ----------
FROM python:3.11-slim

WORKDIR /app

# Chỉ lấy dependencies đã cài từ builder
COPY --from=builder /install /usr/local

# Copy source code cần để chạy service
COPY app/ app/
COPY utils/ utils/

RUN useradd --system --no-create-home appuser

USER appuser

EXPOSE 8000

# Liveness healthcheck, không cần curl
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import os, urllib.request; port=os.getenv('PORT', '8000'); urllib.request.urlopen(f'http://localhost:{port}/health')"

# PORT được lấy từ environment khi chạy container
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]