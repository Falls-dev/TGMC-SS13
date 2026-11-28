# Cobalt для TGMC

Команда **Play Internet Sound** с правом `R_SOUND` передаёт ссылку серверу Cobalt для извлечения аудио. TGMC принимает ответы `redirect` и `tunnel` и передаёт полученный URL клиентам игры. Для этой команды достаточно настроенного Cobalt API.

## Запуск

Подготовьте Linux-хост с Docker и Docker Compose, домен и HTTPS-прокси. В примере Cobalt работает на том же хосте, что и прокси. Замените `cobalt.example.org` своим доменом.

1. Создайте на хосте каталог вне рабочего дерева TGMC и сгенерируйте ключ в `keys.json`.

   ```sh
   umask 077
   mkdir tgmc-cobalt
   cd tgmc-cobalt
   COBALT_KEY=$(cat /proc/sys/kernel/random/uuid)
   printf '{"%s":{"name":"TGMC","limit":10}}\n' "$COBALT_KEY" > keys.json
   ```

2. Создайте в этом каталоге `compose.yaml`. Конфигурация использует образ и формат ключей из примеров Cobalt. [Запуск Cobalt](https://github.com/imputnet/cobalt/blob/main/docs/run-an-instance.md) · [Настройка ключей](https://github.com/imputnet/cobalt/blob/main/docs/protect-an-instance.md#configure-api-keys).

   ```yaml
   services:
     cobalt:
       image: ghcr.io/imputnet/cobalt:11
       init: true
       read_only: true
       restart: unless-stopped
       ports:
         - "127.0.0.1:9000:9000"
       environment:
         API_URL: "https://cobalt.example.org/"
         API_KEY_URL: "file:///keys.json"
         API_AUTH_REQUIRED: "1"
       volumes:
         - ./keys.json:/keys.json:ro
   ```

3. Проверьте, что пользователь контейнера может читать файл. Если проверка не проходит, узнайте UID через `docker compose run --rm --no-deps cobalt id` и дайте разрешение на чтение только этому пользователю. Храните файл ключей и игровую конфигурацию с ключом вне Git.

   ```sh
   docker compose run --rm --no-deps cobalt sh -c 'test -r /keys.json'
   docker compose up -d
   docker compose logs --tail 50 cobalt
   ```

4. Направьте HTTPS-прокси на `127.0.0.1:9000`. Для Caddy добавьте этот блок в конфигурацию действующего сервиса после настройки DNS. Домены API и файлового туннеля должны быть доступны игрокам, поскольку аудио загружает клиент. Оставьте `API_URL` равным публичному HTTPS-адресу. [Настройка обратного прокси Caddy](https://caddyserver.com/docs/quick-starts/reverse-proxy#https-from-client-to-proxy).

   ```caddyfile
   cobalt.example.org {
       reverse_proxy 127.0.0.1:9000
   }
   ```

## Подключение TGMC

В конфигурации игрового сервера [`config/config.txt`](../config/config.txt) укажите адрес корневого эндпоинта и UUID из `keys.json`. TGMC добавляет схему `Api-Key` к ключу при запросе.

```text
COBALT_BASE_API https://cobalt.example.org/
COBALT_API_KEY ВАШ-UUID
```

Проверьте настройки при следующем запуске игрового инстанса. Для диагностики сначала запросите сведения о Cobalt с хоста TGMC.

```sh
curl --fail --silent --show-error "https://cobalt.example.org/"
```

`GET /` возвращает сведения о версии и сервисах. Затем на тестовом инстансе запустите **Play Internet Sound** со ссылкой на короткий доступный ролик поддерживаемого сервиса. Если API отвечает, а звука нет, проверьте доступность возвращённого домена с игрового клиента и настройки громкости. Если обработка ссылки прерывается, проверьте логи Cobalt, совпадение ключей и поддержку выбранного источника. Подробности запроса и схемы ответов приведены в [документации API](https://github.com/imputnet/cobalt/blob/main/docs/api.md).
