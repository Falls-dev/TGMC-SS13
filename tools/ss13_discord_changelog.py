'''
Usage:
    $ python ss13_discord_changelog.py html/changelogs/ --webhook URL
    $ CHANGELOG_DISCORD_HOOK=URL python ss13_discord_changelog.py html/changelogs/

ss13_discord_changelog.py - Post pending YAML changelogs to a Discord webhook.

Based on ss13_genchangelog.py. Reads the same pending html/changelogs/*.yml
files that Auto Changelog creates from PR :cl: blocks, formats them, and
POSTs to Discord. Does NOT compile/archive/delete YAML — run
ss13_genchangelog.py after this (PreSynchronize does that).

Pipeline:
  1. PR merged with :cl: ... /:cl: in the body
  2. .github auto_changelog writes html/changelogs/AutoChangeLog-pr-N.yml
  3. TGS PreSynchronize:
       a) this script → Discord
       b) ss13_genchangelog.py → html/changelogs/archive/YYYY-MM.yml (+ delete YAML)
'''

from __future__ import print_function

import argparse
import glob
import json
import os
import sys
import time
import urllib.error
import urllib.request

import yaml

# Discord webhook content hard limit is 2000 characters.
DISCORD_MESSAGE_LIMIT = 2000

# Canonical YAML keys (from tools/pull_request_hooks/changelogConfig.js) plus
# PR-template aliases (add/fix/del/…).
PREFIX_EMOJI = {
    'rscadd': '\u2705',          # ✅
    'add': '\u2705',
    'rscdel': '\u274c',          # ❌
    'del': '\u274c',
    'qol': '\u2747\ufe0f',       # ❇️
    'balance': '\u2696\ufe0f',   # ⚖️
    'bugfix': '\u267f',          # ♿
    'fix': '\u267f',
    'sound': '\U0001f50a',       # 🔊
    'soundadd': '\U0001f50a',
    'sounddel': '\U0001f507',    # 🔇
    'image': '\U0001f5bc\ufe0f', # 🖼️
    'imageadd': '\U0001f4e5',    # 📥
    'imagedel': '\U0001f4e4',    # 📤
    'expansion': '\U0001f5fa\ufe0f',  # 🗺️
    'map': '\U0001f5fa\ufe0f',
    'spellcheck': '\U0001f4cb',  # 📋
    'typo': '\U0001f5a5\ufe0f',  # 🖥️
    'code_imp': '\U0001f4bb',    # 💻
    'code': '\U0001f6dc',        # 🛜
    'refactor': '\u267b\ufe0f',  # ♻️
    'config': '\U0001f9f0',      # 🧰
    'admin': '\U0001f6e1\ufe0f', # 🛡️
    'server': '\U0001f4be',      # 💾
    'wip': '\u2622\ufe0f',       # ☢️
    'experiment': '\u26a0\ufe0f',  # ⚠️
}


def dict_to_tuples(inp):
    return [(k, v) for k, v in inp.items()]


def collect_pending_entries(yml_dir):
    """Read pending changelog YAML files (same set genchangelog consumes)."""
    entries = []
    pattern = os.path.join(yml_dir, '*.yml')
    for file_name in sorted(glob.glob(pattern)):
        name, _ext = os.path.splitext(os.path.basename(file_name))
        if name.startswith('.') or name == 'example':
            continue

        file_name = os.path.abspath(file_name)
        print(' Reading {}...'.format(file_name))
        with open(file_name, 'r', encoding='utf-8') as handle:
            cl = yaml.load(handle, Loader=yaml.SafeLoader)

        if not cl or not cl.get('changes'):
            print('  Skipping (empty).')
            continue

        author = cl.get('author') or 'Unknown'
        for change in cl['changes']:
            change_type, change_text = dict_to_tuples(change)[0]
            entries.append({
                'author': author,
                'type': change_type,
                'text': change_text,
                'source': os.path.basename(file_name),
            })
        print('  Queued {} change(s) from {}.'.format(len(cl['changes']), author))

    return entries


def format_discord_changelog(entries):
    """Group by author; one emoji line per change."""
    by_author = {}
    for entry in entries:
        by_author.setdefault(entry['author'], []).append(entry)

    lines = ['**Changelog**']
    for author in sorted(by_author.keys()):
        if lines:
            lines.append('')
        lines.append('{}:'.format(author))
        for entry in by_author[author]:
            emoji = PREFIX_EMOJI.get(entry['type'], '\U0001f4dd')  # 📝
            # Discord markdown: keep change text plain (no @everyone etc.).
            text = (
                str(entry['text'])
                .replace('@everyone', '(@everyone)')
                .replace('@here', '(@here)')
            )
            lines.append('* {}: {}'.format(emoji, text))
    return '\n'.join(lines).strip()


def split_discord_messages(text, limit=DISCORD_MESSAGE_LIMIT):
    """Split text into Discord-safe chunks (each <= limit chars).

    Prefers splitting on newlines. A single line longer than the limit is
    hard-sliced. Empty trailing/leading blank lines inside a chunk are fine.
    """
    if len(text) <= limit:
        return [text]

    chunks = []
    current = []
    current_len = 0
    for line in text.split('\n'):
        # +1 for the newline that joins current lines (except first).
        line_len = len(line) + (1 if current else 0)
        if len(line) > limit:
            if current:
                chunks.append('\n'.join(current))
                current = []
                current_len = 0
            for index in range(0, len(line), limit):
                chunks.append(line[index:index + limit])
            continue
        if current_len + line_len > limit and current:
            chunks.append('\n'.join(current))
            current = [line]
            current_len = len(line)
        else:
            current.append(line)
            current_len += line_len
    if current:
        chunks.append('\n'.join(current))

    # Safety: never return an over-limit chunk.
    safe = []
    for chunk in chunks:
        if len(chunk) <= limit:
            safe.append(chunk)
        else:
            for index in range(0, len(chunk), limit):
                safe.append(chunk[index:index + limit])
    return safe


def post_discord_webhook(webhook_url, content):
    payload = json.dumps({'content': content}, ensure_ascii=False).encode('utf-8')
    request = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={
            'Content-Type': 'application/json',
            'User-Agent': 'TGMC-ss13_discord_changelog',
        },
        method='POST',
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        # Discord returns 204 No Content on success.
        return response.getcode()


def safe_print(text):
    """Avoid UnicodeEncodeError on Windows consoles (cp1251 etc.)."""
    try:
        print(text)
    except UnicodeEncodeError:
        encoding = getattr(sys.stdout, 'encoding', None) or 'utf-8'
        sys.stdout.buffer.write((text + '\n').encode(encoding, errors='replace'))


def send_to_discord(webhook_url, entries, dry_run=False):
    body = format_discord_changelog(entries)
    messages = split_discord_messages(body)

    if dry_run:
        safe_print('--- dry-run ({} message(s)) ---'.format(len(messages)))
        for index, message in enumerate(messages, start=1):
            safe_print('[{}/{}]\n{}\n'.format(index, len(messages), message))
        return

    print('Posting changelog to Discord ({} message(s))...'.format(len(messages)))
    for index, message in enumerate(messages, start=1):
        code = post_discord_webhook(webhook_url, message)
        print('  Posted Discord message {}/{} (HTTP {}).'.format(index, len(messages), code))
        # Soft rate-limit cushion between multi-chunk posts.
        if index < len(messages):
            time.sleep(0.6)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description='Post pending SS13 YAML changelogs to a Discord webhook.'
    )
    parser.add_argument(
        'ymlDir',
        help='Directory of pending YAML changelogs (e.g. html/changelogs).',
    )
    parser.add_argument(
        '--webhook',
        default=os.environ.get('CHANGELOG_DISCORD_HOOK', ''),
        help='Discord webhook URL (or set CHANGELOG_DISCORD_HOOK).',
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Print the Discord payload instead of sending it.',
    )
    args = parser.parse_args(argv)

    yml_dir = args.ymlDir
    if not os.path.isdir(yml_dir):
        print('Not a directory: {}'.format(yml_dir), file=sys.stderr)
        return 1

    print('Collecting pending changelogs from {}...'.format(yml_dir))
    entries = collect_pending_entries(yml_dir)
    if not entries:
        print('No pending changelog entries; nothing to post.')
        return 0

    webhook_url = (args.webhook or '').strip()
    if not webhook_url and not args.dry_run:
        print(
            'No webhook URL (pass --webhook or set CHANGELOG_DISCORD_HOOK); skipping.',
            file=sys.stderr,
        )
        return 0

    try:
        send_to_discord(webhook_url, entries, dry_run=args.dry_run)
    except (urllib.error.URLError, urllib.error.HTTPError, OSError) as exc:
        print('Failed to post changelog to Discord:', file=sys.stderr)
        print(exc, file=sys.stderr)
        # Non-zero so PreSynchronize can log it, but callers may ignore.
        return 2

    return 0


if __name__ == '__main__':
    sys.exit(main())
