#!/bin/bash
set -euo pipefail

map=${1:?Missing map name}
map_config="_maps/$map.json"

echo "Testing $map"
mkdir -p ci_test
run_dir=$(mktemp -d ci_test/run.XXXXXX)

tools/deploy.sh "$run_dir"
mkdir "$run_dir/config" "$run_dir/data"
cp tools/ci/ci_config.txt "$run_dir/config/config.txt"
cp config/shipmaps.txt "$run_dir/config/shipmaps.txt"
cp "$map_config" "$run_dir/data/next_map.json"

daemon_status=0
(
	cd "$run_dir"
	DreamDaemon tgmc.dmb -close -trusted -verbose -params 'log-directory=ci'
) || daemon_status=$?

marker="$run_dir/data/logs/ci/clean_run.lk"
if (( daemon_status != 0 )) || [[ ! -s "$marker" ]]; then
	printf 'Integration tests failed for %s (DreamDaemon exit %s). See logs under %s/data/logs/ci.\n' "$map" "$daemon_status" "$run_dir" >&2
	exit 1
fi

cat "$marker"
