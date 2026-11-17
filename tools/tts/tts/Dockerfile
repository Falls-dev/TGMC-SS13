FROM python:3.11-slim-bookworm

RUN printf 'Acquire::Retries "5";\nAcquire::http::Timeout "30";\n' > /etc/apt/apt.conf.d/80-retries && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ffmpeg libsndfile1 curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

COPY requirements.txt .
# CPU-сборка torch — нормальный дефолт для VPS без NVIDIA GPU
RUN pip install --no-cache-dir -r requirements.txt \
        --extra-index-url https://download.pytorch.org/whl/cpu

COPY . .
ENV TTS_HOME=/root/tts_data
ENV PYTHONUNBUFFERED=1

EXPOSE 5003
CMD ["python", "tts.py"]
