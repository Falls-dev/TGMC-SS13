<p align="center">
  <img src="html/images/tgmclogo.png" alt="Эмблема TerraGov Marine Corps" width="160">
</p>

# TerraGov Marine Corps

Русскоязычный форк TGMC для Space Station 13. Морпехи ТерраГова сражаются с ксеноморфами на картах со своими задачами, от обороны корабля до высадки на планету.

## Быстрый старт

Установите Git и [BYOND](https://www.byond.com/download/). Версии BYOND, Node.js и rust-g, используемые при сборке, указаны в [`dependencies.sh`](dependencies.sh).

```sh
git clone https://github.com/Falls-dev/TGMC-SS13.git
cd TGMC-SS13
```

### Windows

1. Запустите `BUILD.cmd` из корня репозитория. Скрипт соберёт игру и интерфейсы TGUI.
2. Запустите `bin\server.cmd`. Подключитесь из Dream Seeker к `byond://127.0.0.1:1337`.

### Linux

Установите Linux-версию BYOND и Node.js по версиям из `dependencies.sh`. Загрузите окружение установленного BYOND через `source /путь/к/byond/bin/byondsetup`. Если подходящей `librust_g.so` ещё нет, скрипт `bash tools/ci/install_rust_g.sh` установит её в `~/.byond/bin`. Затем выполните из корня репозитория.

```sh
tools/build/build
tools/build/build server
```

## Среда разработки

- [Сборка и выбор версии BYOND](tools/build/README.md). Команды сборки для Windows, Linux и VS Code.
- [Руководство для контрибьюторов](CONTRIBUTING.md). Стиль кода, работа с картами и подготовка pull request.
- [Документация TGUI](tgui/README.md). Устройство интерфейсов и запуск инструментов разработки.

## Сообщество

- [Задачи и баги форка](https://github.com/Falls-dev/TGMC-SS13/issues). При отправке бага приложите шаги, версию сборки и ожидаемое поведение.
- [Discord оригинального TGMC](https://discord.gg/2dFpfNE). Обсуждение игры и разработки с сообществом апстрима.

## Полезное

- [Настройка своего Cobalt](docs/cobalt.md). Воспроизведение интернет-аудио через собственный сервис.
- [Хранилище TGUI на GitHub Pages](docs/tgui-storage.md). Публикация iframe для истории и настроек чата.
- [Апстрим TerraGov Marine Corps](https://github.com/tgstation/TerraGov-Marine-Corps). Исходный проект и история изменений.

## Лицензия

Оригинальный TGMC основан на [Colonial Marines от июля 2018 года](https://github.com/MrStonedOne/cmhistory). Вклады лицензированы под [GNU AGPL v3](LICENSE), если для них не указана другая лицензия.

- Графика после [коммита `92ee94d`](https://github.com/tgstation/TerraGov-Marine-Corps/commit/92ee94da6e144d4420c1ec4f83a4ee785d61dc9b), а также спрайты из [#367](https://github.com/tgstation/TerraGov-Marine-Corps/pull/367), [коммита `36b8db4`](https://github.com/tgstation/TerraGov-Marine-Corps/commit/36b8db4952be79a79b28a6738889d9e9eb23b12a) и [коммита `d407e97`](https://github.com/tgstation/TerraGov-Marine-Corps/commit/d407e97e26ee5e6bb1daf945a8eb3bd9a6b11976) — [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).
- Звуки из [#5261](https://github.com/tgstation/TerraGov-Marine-Corps/pull/5261) и [#5861](https://github.com/tgstation/TerraGov-Marine-Corps/pull/5861), а также иконки из [#6010](https://github.com/tgstation/TerraGov-Marine-Corps/pull/6010) — [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
- Спрайты Rouny из [#6938](https://github.com/tgstation/TerraGov-Marine-Corps/pull/6938) — [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- Звуки из [#5604](https://github.com/tgstation/TerraGov-Marine-Corps/pull/5604) от [Freesound](https://freesound.org/people/nicStage/sounds/127731/) — [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- [TGS DMAPI](code/modules/tgs/LICENSE) — MIT.

Дополнительные условия для отдельных ассетов приведены в [кредитах звуков](sound/credits.md), [CC BY-NC 3.0](LICENSE-CC-BY-NC-3.0) и [CC BY-NC-SA 3.0](LICENSE-CC-BY-NC-SA-3.0).
