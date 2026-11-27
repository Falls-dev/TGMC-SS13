import { useState } from 'react';
import {
  Box,
  Button,
  Flex,
  Icon,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Entry = {
  key: string;
  name: string;
  desc?: string;
  category: string;
  kind: string;
  icon: string;
};

type EntryState = {
  cost: number;
  unit: 'plasma' | 'psy';
  cooldown: number;
  ok: boolean;
};

type Pattern = { id: string; name: string; grid: string[] };

type BuildData = {
  entries: Entry[];
  patterns: Pattern[];
  categories: string[];
  states: Record<string, EntryState>;
  ghost_mode: boolean;
  demolish_mode: boolean;
  auto_rebuild: boolean;
  pattern: string;
  selected: string;
  favorites: string[];
  can_pattern: boolean;
  quickbuild: boolean;
  quickbuild_points: number;
  plasma: number;
  psy_points: number;
  range: number;
  can_undo: boolean;
  can_redo: boolean;
};

const FAVORITES = 'Favorites';

const PATTERN_BOX = 34; // px, внутри кнопки 44x44 остаётся запас на рамку

/** Сетка масштабируется под размер шаблона, чтобы никогда не вылезать за кнопку. */
const PatternGrid = (props: { grid: string[] }) => {
  const rows = [...props.grid].reverse();
  const cols = Math.max(1, ...rows.map((row) => row.length));
  const count = Math.max(rows.length, cols, 1);
  const gap = count > 6 ? 0 : 1;
  const cell = Math.max(
    2,
    Math.floor((PATTERN_BOX - gap * (count - 1)) / count),
  );
  return (
    <Box
      style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${cols}, ${cell}px)`,
        gridAutoRows: `${cell}px`,
        gap: `${gap}px`,
        maxWidth: `${PATTERN_BOX}px`,
        maxHeight: `${PATTERN_BOX}px`,
        overflow: 'hidden',
        lineHeight: 0,
      }}
    >
      {rows.map((row, y) =>
        Array.from({ length: cols }, (_, x) => (
          <Box
            key={`${y}-${x}`}
            style={{
              background:
                row[x] === 'X' ? 'rgba(220, 235, 220, 0.9)' : 'rgba(255, 255, 255, 0.08)',
              borderRadius: '1px',
            }}
          />
        )),
      )}
    </Box>
  );
};

const EntryButton = (props: { entry: Entry }) => {
  const { entry } = props;
  const { act, data } = useBackend<BuildData>();
  const state = data.states[entry.key];
  const selected = !data.demolish_mode && data.selected === entry.key;
  const favorite = data.favorites.includes(entry.key);
  const unit = state?.unit === 'psy' ? 'psy' : 'pl';
  const label = state?.cooldown
    ? `${state.cooldown}s`
    : state?.cost
      ? `${state.cost} ${unit}`
      : 'free';

  return (
    <Box
      style={{
        position: 'relative',
        width: '64px',
        textAlign: 'center',
        opacity: state?.ok ? 1 : 0.6,
      }}
    >
      <Button
        selected={selected}
        tooltip={entry.desc ? `${entry.name}: ${entry.desc}` : entry.name}
        onClick={() => act('select_entry', { key: entry.key })}
        style={{ width: '100%', padding: '4px 0' }}
      >
        <Box className={entry.icon} />
        <Box fontSize="10px" color={state?.ok ? 'label' : 'bad'}>
          {label}
        </Box>
      </Button>
      <Icon
        name="star"
        color={favorite ? 'yellow' : 'grey'}
        onClick={() => act('toggle_favorite', { key: entry.key })}
        style={{
          position: 'absolute',
          top: '2px',
          right: '4px',
          cursor: 'pointer',
          fontSize: '11px',
        }}
      />
      <Box fontSize="10px" style={{ overflow: 'hidden', whiteSpace: 'nowrap' }}>
        {entry.name}
      </Box>
    </Box>
  );
};

export const XenoBuildMenu = () => {
  const { act, data } = useBackend<BuildData>();
  const {
    entries,
    patterns,
    categories,
    favorites,
    ghost_mode,
    demolish_mode,
    auto_rebuild,
    pattern,
    can_pattern,
    can_undo,
    can_redo,
    quickbuild,
    quickbuild_points,
    plasma,
    psy_points,
    range,
  } = data;

  const tabs = [
    FAVORITES,
    ...categories.filter((cat) => entries.some((e) => e.category === cat)),
  ];
  const [tab, setTab] = useState(FAVORITES);
  const activeTab = tabs.includes(tab) ? tab : FAVORITES;
  const shown = entries.filter((e) =>
    activeTab === FAVORITES
      ? favorites.includes(e.key)
      : e.category === activeTab,
  );
  const direct = !ghost_mode && (pattern === 'single' || can_pattern);

  return (
    <Window theme="xeno" title="Hive Construction" width={380} height={480}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section>
              <Flex align="center" justify="space-between" wrap>
                <Flex.Item>
                  <Button.Checkbox
                    checked={ghost_mode}
                    disabled={demolish_mode}
                    tooltip="Only place blueprints instead of building directly"
                    onClick={() => act('toggle_ghost')}
                  >
                    Blueprint mode
                  </Button.Checkbox>
                </Flex.Item>
                <Flex.Item>
                  <Button.Checkbox
                    checked={auto_rebuild}
                    disabled={demolish_mode}
                    tooltip="Structures built in this mode leave a new blueprint when destroyed, even without weeds, so builders restore them"
                    onClick={() => act('toggle_auto_rebuild')}
                  >
                    Auto-rebuild
                  </Button.Checkbox>
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="hammer"
                    color={demolish_mode ? 'bad' : undefined}
                    selected={demolish_mode}
                    tooltip="Mark resin structures for demolition. Placing over a blueprint cancels it"
                    onClick={() => act('toggle_demolish')}
                  >
                    Demolish
                  </Button>
                </Flex.Item>
              </Flex>
              <Flex align="center" justify="space-between" mt={1}>
                <Flex.Item color="label" fontSize="11px">
                  Plasma {Math.round(plasma)} | Psy {Math.round(psy_points)} |
                  Reach {range}
                  {quickbuild && ` | Quick-build ${quickbuild_points}`}
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="undo"
                    compact
                    disabled={!can_undo}
                    tooltip="Undo the last construction edit (Ctrl+Z)"
                    onClick={() => act('undo')}
                  />
                  <Button
                    icon="redo"
                    compact
                    disabled={!can_redo}
                    tooltip="Redo the last undone construction edit (Ctrl+Y)"
                    onClick={() => act('redo')}
                  />
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section
              title="Pattern"
              buttons={
                <Box color={direct ? 'good' : 'average'} fontSize="11px">
                  {direct ? 'builds directly' : 'places blueprints'}
                  {auto_rebuild && !demolish_mode ? ' | auto-rebuild' : ''}
                </Box>
              }
            >
              <Flex wrap style={{ gap: '4px' }}>
                {patterns.map((p) => (
                  <Flex.Item key={p.id}>
                    <Button
                      selected={pattern === p.id}
                      tooltip={p.name}
                      onClick={() => act('select_pattern', { id: p.id })}
                      style={{
                        width: '44px',
                        height: '44px',
                        padding: 0,
                        margin: 0,
                        boxSizing: 'border-box',
                        overflow: 'hidden',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      <PatternGrid grid={p.grid} />
                    </Button>
                  </Flex.Item>
                ))}
              </Flex>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable>
              <Tabs>
                {tabs.map((name) => (
                  <Tabs.Tab
                    key={name}
                    selected={activeTab === name}
                    icon={name === FAVORITES ? 'star' : undefined}
                    onClick={() => setTab(name)}
                  >
                    {name === FAVORITES ? '' : name}
                  </Tabs.Tab>
                ))}
              </Tabs>
              <Flex wrap mt={1}>
                {shown.length ? (
                  shown.map((entry) => (
                    <Flex.Item key={entry.key} mr={1} mb={1}>
                      <EntryButton entry={entry} />
                    </Flex.Item>
                  ))
                ) : (
                  <Box color="label" italic>
                    {activeTab === FAVORITES
                      ? 'Click the star on a structure to pin it here.'
                      : 'Nothing available.'}
                  </Box>
                )}
              </Flex>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
