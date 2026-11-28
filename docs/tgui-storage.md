# Хранилище TGUI на GitHub Pages

TGUI хранит вкладки, настройки и историю чата в IndexedDB в браузере игрока. На GitHub Pages публикуется [статический `iframe.html`](../tgui/public/iframe.html) с кодом доступа к хранилищу. Используйте файл из той же версии TGMC, которую запускаете.

## Публикация

**Через существующий workflow TGMC.** [Generate documentation](../.github/workflows/generate_documentation.yml) при push в `master` собирает документацию, копирует `tgui/public/iframe.html` в её корень и публикует результат в `gh-pages`. Для этой схемы в репозитории выберите **Settings → Pages → Deploy from a branch → `gh-pages` → `/(root)`**. После первого успешного запуска `gh-pages` появится в списке веток. Пример пути для этого репозитория — `https://falls-dev.github.io/TGMC-SS13/iframe.html`. Workflow пересобирает ветку целиком, поэтому обновляйте исходник в `tgui/public/iframe.html`.

**Через отдельный репозиторий Pages.** Создайте, например, `tgmc-storage` под своим GitHub-аккаунтом. Скопируйте `tgui/public/iframe.html` как `iframe.html` в корень ветки `main` и опубликуйте её через **Settings → Pages → Deploy from a branch → `main` → `/(root)`**. Для обновления публикуйте копию iframe из нового коммита TGMC. Пример итогового пути — `https://OWNER.github.io/tgmc-storage/iframe.html`. [Публикация из ветки](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

Сайты `github.io` с одинаковыми схемой, именем хоста и портом имеют один origin даже при разных путях. Например, `/server-a/iframe.html` и `/server-b/iframe.html` на `OWNER.github.io` могут использовать общее хранилище в клиенте. Для разделения истории используйте для каждого сервера отдельный доверенный HTTPS-хост, например собственный поддомен, настроенный на Pages. При смене origin прежние данные остаются привязанными к старому адресу. [Собственные домены GitHub Pages](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/about-custom-domains-and-github-pages).

## Настройка TGMC

Возьмите итоговую ссылку из **Settings → Pages** и добавьте к ней `/iframe.html`. Используйте прямой HTTPS-адрес файла и проверьте, что `HEAD` возвращает `200`, тип `text/html` и разрешает кросс-доменный запрос. В клиентах BYOND origin родительского окна может передаваться как `null`. [HTTPS на GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/securing-your-github-pages-site-with-https).

```sh
curl --head --header "Origin: null" "https://OWNER.github.io/tgmc-storage/iframe.html"
```

Замените действующее значение в [`config/resources.txt`](../config/resources.txt).

```text
STORAGE_CDN_IFRAME https://OWNER.github.io/tgmc-storage/iframe.html
```

После запуска тестового инстанса подключитесь игровым клиентом, поменяйте настройку чата и переподключитесь. В инструментах разработчика клиента проверьте загрузку iframe с заданного адреса и сохранение настройки между подключениями. Если настройки сохраняются, но iframe недоступен, возможно, клиент переключился на резервное хранилище BYOND. [Выбор хранилища в TGUI](../tgui/packages/common/storage.ts).
