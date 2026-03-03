FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim
WORKDIR /app

# rootfs read-only 
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder /install /usr/local
COPY app/ .

EXPOSE 8080
USER 1000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
