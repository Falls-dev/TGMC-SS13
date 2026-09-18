# Aperture TTS

Один Docker Compose поднимает оба контейнера:

1. **tts** - движок синтеза (Silero), порт `5003` только внутри сети
2. **tts-api** - публичный HTTP API (авторизация, нарезка предложений, ffmpeg/OGG), порт `5002` снаружи

```
Клиент ---> tts-api:5002 ---> tts:5003 ---> Silero ---> WAV
              |               |
              *< фильтры/OGG <*
```

## Запуск

1. Устанавливаем докер [Docker](https://docs.docker.com/get-docker/)
2. В корне репозитория:

```bash
docker compose up -d --build
```

Первый запуск долгий: сборка образов + скачивание модели Silero.
Модели кэшируются в `tts/persistent_data/tts_models`.

3. Проверка:

```bash
curl http://localhost:5002/health-check
```

Остановить:

```bash
docker compose down
```

Пересобрать после правок кода:

```bash
docker compose up -d --build
```

## Как это работает

| Сервис | Роль | Порт |
|--------|------|------|
| `tts` | Генерация WAV через Silero TTS | `5003` (внутренний) |
| `tts-api` | Токен, разбиение текста, вызов `tts`, ffmpeg суёт всё в OGG | `5002` (наружу) |

Поток запроса:

1. Идёт запрос в `http://localhost:5002/tts` с заголовком `Authorization`
2. `tts-api` режет текст на предложения используя `pysbd`
3. Каждое предложение уходит на `http://tts:5003/generate-tts`
4. `tts` синтезирует WAV звуки
5. `tts-api` склеивает куски, прогоняет через ffmpeg и отдаёт OGG файл обратно

Имя хоста `tts` - это имя сервиса в Compose: контейнеры видят друг друга по DNS внутри одной сети.

`tts-api` стартует только после того как `tts` встанет (`depends_on` + healthcheck).

## Конфиги

| Переменная | Значение |
|------------|----------|
| `TTS_HTTP_URL` | `http://localhost:5002` |
| `TTS_HTTP_TOKEN` | `coolio` (по умолчанию) |

Пример:

```bash
curl -H "Authorization: coolio" \
  "http://localhost:5002/tts?voice=xenia" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Привет, мир\"}" \
  --output out.ogg
```

## Установка

Необходимо задать токен перед развёрткой докера:

```bash
# Windows PowerShell
$env:TTS_AUTHORIZATION_TOKEN="РАНДОМНЫЙ-ТОКЕН"
docker compose up -d --build
```

```bash
# Linux / macOS
TTS_AUTHORIZATION_TOKEN="РАНДОМНЫЙ-ТОКЕН" docker compose up -d --build
```

## Эндпоинты апишки

- `GET /health-check` - жив ли API
- `GET /tts` - обычный TTS (нужен токен в `Authorization`)
- `GET /tts-blips` - blips-режим
- `GET /tts-voices` - список голосов

## GPU (опционально)

Если есть видюха от нвидиа то в `docker-compose.yml` у сервиса `tts` уберите комменты в блоке `deploy.resources...nvidia`, если стоит [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).
