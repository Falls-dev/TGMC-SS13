#!/bin/sh
# TGS PreSynchronize: Генерирует чеинжлоги и постит их в игру и в Дискорд
#
# Петухон модули:
#   PyYAML - для взаимодействия с YAML файлами (чейнжлоги)
#
# Discord: установите CHANGELOG_DISCORD_HOOK полной ссылкой на вебхук
# Без него скрипт будет генерировать ченжлоги, но не будет постить их в Дискорд

# Дискорд вебхук, уберите решётку перед строкой ниже
# CHANGELOG_DISCORD_HOOK="${CHANGELOG_DISCORD_HOOK:-https://discord.com/api/webhooks/12345/abcdefg}"

has_python="$(command -v python3)"
has_git="$(command -v git)"
has_sudo="$(command -v sudo)"
has_pip="$(command -v pip3)"

set -e

if ! { [ -n "$has_python" ] && [ -n "$has_pip" ] && [ -n "$has_git" ]; }; then
	echo "Installing apt dependencies..."
	if [ -z "$has_sudo" ]; then
		apt update
		apt install -y python3 python3-pip git
		rm -rf /var/lib/apt/lists/*
	else
		sudo apt update
		sudo apt install -y python3 python3-pip git
		sudo rm -rf /var/lib/apt/lists/*
	fi
fi

echo "Installing pip dependencies (PyYAML for changelog script)..."
pip3 install -r tools/requirements-changelog.txt

cd "$1"

# Если есть вебхук то скрипт сжирает *.yml и постит сообщение в Дискорд
if [ -n "$CHANGELOG_DISCORD_HOOK" ]; then
	echo "Posting pending changelogs to Discord..."
	# Failures here must not block archive compile / deploy.
	set +e
	CHANGELOG_DISCORD_HOOK="$CHANGELOG_DISCORD_HOOK" \
		python3 tools/ss13_discord_changelog.py html/changelogs --webhook "$CHANGELOG_DISCORD_HOOK"
	set -e
else
	echo "CHANGELOG_DISCORD_HOOK empty; skipping Discord changelog post."
fi

echo "Running changelog script..."
python3 tools/ss13_genchangelog.py html/changelogs

echo "Committing changes..."
git add html

# we now don't care about failures
set +e
git commit -m "Automatic changelog compile, [ci skip]"
exit 0
