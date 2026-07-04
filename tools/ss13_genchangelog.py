'''
Usage:
    $ python ss13_genchangelog.py html/changelogs/

ss13_genchangelog.py - Generate changelog from YAML.

Copyright 2013 Rob "N3X15" Nelson <nexis@7chan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
'''

from __future__ import print_function
import yaml, os, glob, sys, re, time, argparse, json, urllib.request, urllib.error
from datetime import datetime, date, timedelta
from time import time

today = date.today()
repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
DISCORD_MESSAGE_LIMIT = 1900

fileDateFormat = "%Y-%m"

opt = argparse.ArgumentParser()
opt.add_argument('ymlDir', help='The directory of YAML changelogs we will use.')

args = opt.parse_args()
archiveDir = os.path.join(args.ymlDir, 'archive')

all_changelog_entries = {}

# Do not change the order, add to the bottom of the array if necessary
validPrefixes = [
    'add',
    'fix',
    'del',
    'sound',
    'image',
    'map',
    'code',
    'typo',
    'bugfix',
    'wip',
    'qol',
    'soundadd',
    'sounddel',
    'rscadd',
    'rscdel',
    'imageadd',
    'imagedel',
    'expansion',
    'spellcheck',
    'experiment',
    'balance',
    'code_imp',
    'refactor',
    'config',
    'admin',
    'server'
]

def dictToTuples(inp):
    return [(k, v) for k, v in inp.items()]

PREFIX_LABEL = {
    'rscadd': 'add',
    'add': 'add',
    'bugfix': 'fix',
    'fix': 'fix',
    'rscdel': 'del',
    'del': 'del',
    'soundadd': 'sound',
    'sounddel': 'sound',
    'sound': 'sound',
    'imageadd': 'image',
    'imagedel': 'image',
    'image': 'image',
    'expansion': 'map',
    'map': 'map',
    'spellcheck': 'typo',
    'typo': 'typo',
    'code_imp': 'code',
    'code': 'code',
}

PREFIX_EMOJI = {
    'rscadd': '\U00002705',      # ✅
    'add': '\U00002705',
    'rscdel': '\U0000274c',      # ❌
    'del': '\U0000274c',
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

def read_config_txt():
    """Read key/value pairs from config/config.txt (comments and $include skipped)."""
    config_path = os.path.join(repo_root, 'config', 'config.txt')
    entries = {}
    if not os.path.isfile(config_path):
        return entries
    with open(config_path, 'r', encoding='utf-8') as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith('#'):
                continue
            if line.startswith('$include'):
                continue
            if ' ' not in line:
                entries[line] = True
                continue
            key, value = line.split(' ', 1)
            entries[key.strip()] = value.strip()
    return entries

def format_discord_changelog(entries):
    """Format new changelog rows for Discord."""
    by_author = {}
    for entry in entries:
        by_author.setdefault(entry['author'], []).append(entry)

    lines = []
    for author in sorted(by_author.keys()):
        lines.append('{}:'.format(author))
        for entry in by_author[author]:
            change_type = entry['type']
            label = PREFIX_LABEL.get(change_type, change_type)
            emoji = PREFIX_EMOJI.get(change_type, PREFIX_EMOJI.get(label, '\U0001f4dd'))
            lines.append('* {}: {}'.format(emoji, entry['text']))
        lines.append('')
    return '\n'.join(lines).strip()

def split_discord_messages(text, limit=DISCORD_MESSAGE_LIMIT):
    if len(text) <= limit:
        return [text]

    chunks = []
    current = []
    current_len = 0
    for line in text.split('\n'):
        line_len = len(line) + (1 if current else 0)
        if line_len > limit:
            # Extremely long single line — hard split.
            for i in range(0, len(line), limit):
                part = line[i:i + limit]
                if current:
                    chunks.append('\n'.join(current))
                    current = []
                    current_len = 0
                chunks.append(part)
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
    return chunks

def post_discord_webhook(webhook_url, content):
    payload = json.dumps({'content': content}).encode('utf-8')
    request = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={
            'Content-Type': 'application/json',
            'User-Agent': 'TGMC-ss13_genchangelog',
        },
        method='POST',
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()

def send_changelog_to_discord(entries):
    config = read_config_txt()
    webhook_url = config.get('CHANGELOG_DISCORD_HOOK')
    if not webhook_url:
        print('CHANGELOG_DISCORD_HOOK not set in config/config.txt, skipping Discord notification.')
        return

    body = format_discord_changelog(entries)
    messages = split_discord_messages(body)
    print('Posting changelog to Discord ({} message(s))...'.format(len(messages)))
    for index, message in enumerate(messages, start=1):
        post_discord_webhook(webhook_url, message)
        print('  Posted Discord message {}/{}.'.format(index, len(messages)))

discord_new_entries = []

old_changelog_cache = os.path.join(args.ymlDir, '.all_changelog.yml')

if os.path.isfile(old_changelog_cache):
    try:
        print('Reading old changelog cache...')
        data = {}
        with open(old_changelog_cache,encoding='utf-8') as f:
            (_, all_changelog_entries) = yaml.load_all(f, Loader=yaml.SafeLoader)

            # Categorize changes by year and month
            for _date in all_changelog_entries.keys():
                ty = type(_date).__name__
                formattedDate = _date.strftime(fileDateFormat)
                if not formattedDate in data:
                    data[formattedDate] = {}
                data[formattedDate][_date] = all_changelog_entries[_date]
            # Write files with changes by year and month
            for month in data.keys():
                print("Writing " + month + ".yml...")
                if not os.path.exists(archiveDir):
                    os.makedirs(archiveDir)
                currentFile = os.path.join(archiveDir, month + '.yml')
                with open(currentFile, 'w', encoding='utf-8') as f:
                    yaml.dump(data[month], f, default_flow_style=False)
        # Remove the old changelog cache, as we won't use it anymore
        print("Removing old changelog cache...")
        os.remove(old_changelog_cache)
        old_changelog_html = os.path.join(args.ymlDir, '..', 'changelog.html')
        if os.path.isfile(old_changelog_html):
            print("Removing old changelog html...")
            os.remove(old_changelog_html)
    except Exception as e:
        print("Failed to read old changelog cache:")
        print(e, file=sys.stderr)

print('Reading changelogs...')
for fileName in glob.glob(os.path.join(args.ymlDir, "*.yml")):
    name, ext = os.path.splitext(os.path.basename(fileName))
    if name.startswith('.'): continue
    if name == 'example': continue
    fileName = os.path.abspath(fileName)
    formattedDate = today.strftime(fileDateFormat)
    monthFile = os.path.join(archiveDir, formattedDate + '.yml')
    print(' Reading {}...'.format(fileName))
    cl = {}
    with open(fileName, 'r',encoding='utf-8') as f:
        cl = yaml.load(f, Loader=yaml.SafeLoader)
    currentEntries = {}
    if os.path.exists(monthFile):
        with open(monthFile,'r',encoding='utf-8') as f:
            currentEntries = yaml.load(f, Loader=yaml.SafeLoader)
    if today not in currentEntries:
        currentEntries[today] = {}
    author_entries = currentEntries[today].get(cl['author'], [])
    if len(cl['changes']):
        new = 0
        for change in cl['changes']:
            if change not in author_entries:
                (change_type, change_text) = dictToTuples(change)[0]
                if change_type not in validPrefixes:
                    print('  {0}: Invalid prefix {1}'.format(fileName, change_type), file=sys.stderr)
                author_entries += [change]
                discord_new_entries.append({
                    'author': cl['author'],
                    'type': change_type,
                    'text': change_text,
                })
                new += 1
        currentEntries[today][cl['author']] = author_entries
        if new > 0:
            print('  Added {0} new changelog entries.'.format(new))

    if cl.get('delete-after', False):
        if os.path.isfile(fileName):
            print('  Deleting {0} (delete-after set)...'.format(fileName))
            os.remove(fileName)

    with open(monthFile, 'w', encoding='utf-8') as f:
        yaml.dump(currentEntries, f, default_flow_style=False)

if discord_new_entries:
    try:
        send_changelog_to_discord(discord_new_entries)
    except Exception as e:
        print('Failed to post changelog to Discord (continuing):', file=sys.stderr)
        print(e, file=sys.stderr)
