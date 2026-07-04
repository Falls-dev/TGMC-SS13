#!/bin/sh
# TGS PreSynchronize: compile YAML changelogs and optionally post new entries to Discord.
#
# Python third-party modules (install via pip):
#   PyYAML  — only external dependency for tools/ss13_genchangelog.py
#
# Discord notifications (optional): set CHANGELOG_DISCORD_HOOK in config/config.txt
# on the server (see config/ported_features.txt).

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

echo "Running changelog script..."
python3 tools/ss13_genchangelog.py html/changelogs

echo "Committing changes..."
git add html

# we now don't care about failures
set +e
git commit -m "Automatic changelog compile, [ci skip]"
exit 0
