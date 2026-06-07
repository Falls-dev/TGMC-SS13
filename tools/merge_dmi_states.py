#!/usr/bin/env python3
"""Copy missing icon states from source DMI into target DMI."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / 'dmi'))
import dmi as dmi_mod

PIG_STATES = ['pig', 'pig_dead', 'pig_mini', 'pig_mini_dead']

def merge_states(target_path, source_path, state_names):
    target = dmi_mod.Dmi.from_file(target_path)
    source = dmi_mod.Dmi.from_file(source_path)
    existing = {s.name for s in target.states}
    added = []
    for name in state_names:
        if name in existing:
            print(f'  skip {name!r} (already in target)')
            continue
        src_state = source.get_state(name)
        dst_state = target.state(name, dirs=src_state.dirs, loop=src_state.loop,
                                 rewind=src_state.rewind, movement=src_state.movement)
        dst_state.delays = list(src_state.delays)
        dst_state.hotspots = src_state.hotspots
        for frame in src_state.frames:
            dst_state.frames.append(frame.copy())
        added.append(name)
        print(f'  added {name!r}')
    if not added:
        print('Nothing to add.')
        return False
    target.to_file(target_path)
    print(f'Wrote {target_path} (+{len(added)} states)')
    return True

if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    target = root / 'icons/mob/animal.dmi'
    source = root / 'icons/mob/animal.dmi.bak'
    print(f'Merging into {target} from {source}')
    merge_states(str(target), str(source), PIG_STATES)
