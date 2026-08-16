import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Slider,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const PAGES = [
  {
    title: 'General',
    component: () => GeneralActions,
    color: 'green',
    icon: 'tools',
  },
  {
    title: 'Punish',
    component: () => PunishmentActions,
    color: 'red',
    icon: 'gavel',
  },
  {
    title: 'Physical',
    component: () => PhysicalActions,
    color: 'red',
    icon: 'bolt',
    canAccess: (data: Data) => {
      return !!data.is_human || !!data.is_xeno;
    },
  },
  {
    title: 'Transform',
    component: () => TransformActions,
    color: 'orange',
    icon: 'exchange-alt',
    canAccess: (data: Data) => {
      return hasPermission(data, 'mob_transform');
    },
  },
  {
    title: 'Fun',
    component: () => FunActions,
    color: 'blue',
    icon: 'laugh',
    canAccess: (data: Data) => {
      return hasPermission(data, 'mob_narrate') || hasPermission(data, 'mob_explode');
    },
  },
  {
    title: 'Antag',
    component: () => AntagActions,
    color: 'blue',
    icon: 'crosshairs',
    canAccess: (data: Data) => {
      return !!data.is_xeno && hasPermission(data, 'xeno_change_hivenumber');
    },
  },
];

const hasPermission = (data: Data, action: string) => {
  if (!(action in data.glob_pp_actions)) return false;

  const actionData = data.glob_pp_actions[action];
  return !!(actionData.permissions_required & data.current_permissions);
};

type PlayerAction = {
  name: string;
  action_tag: string;
  permissions_required: number;
};

type TransformEntry = { name: string; key: string; color: string };

type MuteBit = { name: string; bitflag: number };

type Data = {
  mob_type: string;
  is_human: BooleanLike;
  is_xeno: BooleanLike;
  has_client: BooleanLike;
  centcom_ban_db_enabled: BooleanLike;
  current_permissions: number;

  glob_status_flags: Record<string, number>;
  glob_limbs: Record<string, string>;
  glob_mute_bits: MuteBit[];
  glob_hives: Record<string, number>;
  glob_pp_actions: Record<string, PlayerAction>;
  glob_pp_transformables: Record<string, TransformEntry[]>;

  mob_name: string;
  mob_sleeping: BooleanLike;
  mob_status_flags: number;

  client_key?: string;
  client_ckey?: string;
  client_muted?: number;
  client_join_date?: string;
  account_join_date?: string;
  client_rank?: string;
  client_related_cid?: string;
  client_related_ip?: string;
};

export const PlayerPanel = (props) => {
  const { act, data } = useBackend<Data>();
  const [pageIndex, setPageIndex] = useState(0);
  const PageComponent = PAGES[pageIndex].component();
  const { mob_name, mob_type, client_key, client_ckey, client_rank } = data;

  return (
    <Window title={`${mob_name} Player Panel`} width={620} height={560}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section>
              <Stack>
                <Stack.Item width="80px" color="label">
                  Name:
                </Stack.Item>
                <Stack.Item grow align="right">
                  {mob_name}
                </Stack.Item>
              </Stack>
              <Stack mt={1}>
                <Stack.Item width="80px" color="label">
                  Mob Type:
                </Stack.Item>
                <Stack.Item grow align="right">
                  {mob_type}
                </Stack.Item>
                <Stack.Item align="right">
                  <Button
                    icon="window-restore"
                    disabled={!hasPermission(data, 'access_variables')}
                    onClick={() => act('access_variables')}
                  >
                    VV
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="clock"
                    disabled={!data.has_client || !hasPermission(data, 'access_playtimes')}
                    onClick={() => act('access_playtimes')}
                  >
                    Playtime
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="list"
                    disabled={!hasPermission(data, 'individual_logs')}
                    onClick={() => act('individual_logs')}
                  >
                    Logs
                  </Button>
                </Stack.Item>
              </Stack>
              {!!data.has_client && (
                <Stack mt={1}>
                  <Stack.Item width="80px" color="label">
                    Client:
                  </Stack.Item>
                  <Stack.Item grow align="left">
                    <Box inline style={{ wordBreak: 'break-all' }}>
                      {client_ckey ? `${client_key} (${client_ckey})` : client_key}
                    </Box>
                  </Stack.Item>
                  <Stack.Item align="right">
                    <Button
                      icon="comment-dots"
                      disabled={!hasPermission(data, 'private_message')}
                      onClick={() => act('private_message')}
                    >
                      PM
                    </Button>
                    <Button
                      ml={1}
                      icon="phone-alt"
                      disabled={!hasPermission(data, 'subtle_message')}
                      onClick={() => act('subtle_message')}
                    >
                      Subtle
                    </Button>
                  </Stack.Item>
                </Stack>
              )}
              {!!client_rank && (
                <Stack mt={1}>
                  <Stack.Item width="80px" color="label">
                    Rank:
                  </Stack.Item>
                  <Stack.Item grow align="left">
                    {client_rank}
                  </Stack.Item>
                </Stack>
              )}
              {!!data.account_join_date && (
                <Stack mt={1}>
                  <Stack.Item width="80px" color="label">
                    Byond age:
                  </Stack.Item>
                  <Stack.Item grow align="right">
                    {data.account_join_date}
                  </Stack.Item>
                </Stack>
              )}
              {!!data.client_join_date && (
                <Stack mt={1}>
                  <Stack.Item width="80px" color="label">
                    First join:
                  </Stack.Item>
                  <Stack.Item grow align="right">
                    {data.client_join_date}
                  </Stack.Item>
                </Stack>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item>
                <Section fitted>
                  <Tabs vertical>
                    {PAGES.map((page, i) => {
                      if (page.canAccess && !page.canAccess(data)) {
                        return null;
                      }

                      return (
                        <Tabs.Tab
                          key={i}
                          color={page.color}
                          selected={i === pageIndex}
                          icon={page.icon}
                          onClick={() => setPageIndex(i)}
                        >
                          {page.title}
                        </Tabs.Tab>
                      );
                    })}
                  </Tabs>
                </Section>
              </Stack.Item>
              <Stack.Item position="relative" grow basis={0} ml={1}>
                <Section fill scrollable>
                  <PageComponent />
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const GeneralActions = (props) => {
  const { act, data } = useBackend<Data>();
  const { mob_sleeping } = data;

  return (
    <>
      <Section title="Damage">
        <Stack align="right" fill>
          <Button.Confirm
            width="100%"
            icon="first-aid"
            color="green"
            confirmColor="green"
            disabled={!hasPermission(data, 'mob_rejuvenate')}
            onClick={() => act('mob_rejuvenate')}
          >
            Rejuvenate
          </Button.Confirm>
          <Button.Confirm
            width="100%"
            icon="skull"
            color="average"
            confirmColor="average"
            disabled={!hasPermission(data, 'mob_kill')}
            onClick={() => act('mob_kill')}
          >
            Kill
          </Button.Confirm>
          <Button.Confirm
            width="100%"
            icon="skull-crossbones"
            color="bad"
            confirmColor="bad"
            disabled={!hasPermission(data, 'mob_gib')}
            onClick={() => act('mob_gib')}
          >
            Gib
          </Button.Confirm>
        </Stack>
      </Section>

      <Section title="Teleportation">
        <Stack align="right" fill>
          <Button.Confirm
            width="100%"
            icon="reply"
            disabled={!hasPermission(data, 'mob_bring')}
            onClick={() => act('mob_bring')}
          >
            Bring
          </Button.Confirm>
          <Button
            width="100%"
            icon="share"
            disabled={!hasPermission(data, 'jump_to')}
            onClick={() => act('jump_to')}
          >
            Jump To
          </Button>
          <Button
            width="100%"
            icon="hand-paper"
            disabled={!hasPermission(data, 'get_mob')}
            onClick={() => act('get_mob')}
          >
            Get Mob
          </Button>
        </Stack>
      </Section>

      <Section title="Miscellaneous">
        <Stack align="right" fill>
          <Button.Checkbox
            width="100%"
            checked={mob_sleeping}
            color={mob_sleeping ? 'good' : 'bad'}
            disabled={!hasPermission(data, 'mob_sleep')}
            onClick={() => act('mob_sleep')}
          >
            Toggle Sleeping
          </Button.Checkbox>
          <Button.Confirm
            width="100%"
            icon="history"
            disabled={!hasPermission(data, 'send_to_lobby')}
            onClick={() => act('send_to_lobby')}
          >
            Send Back to Lobby
          </Button.Confirm>
          <Button.Confirm
            width="100%"
            icon="undo"
            disabled={!hasPermission(data, 'cryo_mob')}
            onClick={() => act('cryo_mob')}
            tooltip="Deletes the mob and re-opens the slot, storing their items in cryo."
          >
            Cryo
          </Button.Confirm>
        </Stack>
        <Stack align="right" fill mt={1}>
          <Button.Confirm
            width="100%"
            icon="dice"
            disabled={!hasPermission(data, 'thunderdome')}
            onClick={() => act('thunderdome')}
          >
            Thunderdome
          </Button.Confirm>
        </Stack>
        {hasPermission(data, 'mob_force_say') && (
          <Stack align="right" fill mt={2}>
            <Stack.Item width="100px" align="left" color="label">
              Force Say:
            </Stack.Item>
            <Stack.Item align="right" grow>
              <Input
                width="100%"
                onEnter={(e, value) => act('mob_force_say', { to_say: value })}
              />
            </Stack.Item>
          </Stack>
        )}
        {hasPermission(data, 'mob_force_emote') && (
          <Stack align="right" fill mt={2}>
            <Stack.Item width="100px" align="left" color="label">
              Force Emote:
            </Stack.Item>
            <Stack.Item align="right" grow>
              <Input
                width="100%"
                onEnter={(e, value) =>
                  act('mob_force_emote', { to_emote: value })
                }
              />
            </Stack.Item>
          </Stack>
        )}
      </Section>
    </>
  );
};

const PunishmentActions = (props) => {
  const { act, data } = useBackend<Data>();
  const { glob_mute_bits, client_muted = 0, has_client } = data;

  return (
    <>
      <Section title="Banishment">
        <Stack align="right" fill>
          <Button.Confirm
            width="100%"
            icon="gavel"
            color="red"
            disabled={!hasPermission(data, 'mob_ban')}
            onClick={() => act('mob_ban')}
          >
            Ban
          </Button.Confirm>
          <Button.Confirm
            width="100%"
            icon="door-open"
            color="red"
            disabled={!has_client || !hasPermission(data, 'mob_kick')}
            onClick={() => act('mob_kick')}
          >
            Kick
          </Button.Confirm>
        </Stack>
      </Section>

      <Section title="Record-keeping">
        <Stack align="right" fill>
          <Button
            width="100%"
            icon="clipboard-list"
            color="average"
            disabled={!hasPermission(data, 'show_notes')}
            onClick={() => act('show_notes')}
          >
            Check Notes
          </Button>
          <Button
            width="100%"
            icon="pen"
            color="average"
            disabled={!hasPermission(data, 'add_note')}
            onClick={() => act('add_note')}
          >
            Add Note
          </Button>
        </Stack>
        <Stack align="right" fill mt={1}>
          <Button
            width="100%"
            color="average"
            disabled={!has_client || !hasPermission(data, 'related_accounts_cid')}
            onClick={() => act('related_accounts_cid')}
          >
            CID Related Accounts
          </Button>
          <Button
            width="100%"
            color="average"
            disabled={!has_client || !hasPermission(data, 'related_accounts_ip')}
            onClick={() => act('related_accounts_ip')}
          >
            IP Related Accounts
          </Button>
        </Stack>
        {!!data.centcom_ban_db_enabled && (
          <Stack align="right" fill mt={1}>
            <Button
              width="100%"
              icon="globe"
              color="average"
              disabled={!hasPermission(data, 'centcom_lookup')}
              onClick={() => act('centcom_lookup')}
            >
              CentCom Ban Lookup
            </Button>
          </Stack>
        )}
      </Section>

      {!!has_client && (
        <Section title="Mute">
          <Stack align="right" fill wrap>
            {glob_mute_bits.map((bit, i) => {
              const isMuted = !!(client_muted && client_muted & bit.bitflag);
              return (
                <Button.Checkbox
                  key={i}
                  checked={isMuted}
                  color={isMuted ? 'good' : 'bad'}
                  disabled={!hasPermission(data, 'mob_mute')}
                  onClick={() => act('mob_mute', { mute_type: bit.bitflag })}
                >
                  {bit.name}
                </Button.Checkbox>
              );
            })}
          </Stack>
        </Section>
      )}
    </>
  );
};

const TransformActions = (props) => {
  const { act, data } = useBackend<Data>();
  const { glob_pp_transformables } = data;

  return (
    <>
      {Object.keys(glob_pp_transformables).map((category, i) => (
        <Section title={category} key={i}>
          <Stack align="right" fill wrap>
            {glob_pp_transformables[category].map((option, optionIndex) => (
              <Button.Confirm
                width="120px"
                key={optionIndex}
                color={option.color}
                disabled={!hasPermission(data, 'mob_transform')}
                onClick={() => act('mob_transform', { key: option.key })}
              >
                {option.name}
              </Button.Confirm>
            ))}
          </Stack>
        </Section>
      ))}
    </>
  );
};

const FunActions = (props) => {
  const { act, data } = useBackend<Data>();

  const [lockExplode, setLockExplode] = useState(true);
  const [expPower, setExpPower] = useState(50);
  const [falloff, setFalloff] = useState(75);

  return (
    <>
      {hasPermission(data, 'mob_narrate') && (
        <Section title="Narrate">
          <Stack align="right" fill>
            <Stack.Item width="100px" align="left" color="label">
              Narrate:
            </Stack.Item>
            <Stack.Item align="right" grow>
              <Input
                width="100%"
                onEnter={(e, value) =>
                  act('mob_narrate', { to_narrate: value })
                }
              />
            </Stack.Item>
          </Stack>
        </Section>
      )}

      {hasPermission(data, 'mob_explode') && (
        <Section
          title="Explosion"
          buttons={
            <Button
              ml={1}
              icon={lockExplode ? 'lock' : 'lock-open'}
              onClick={() => setLockExplode(!lockExplode)}
              color={lockExplode ? 'good' : 'bad'}
            >
              {lockExplode ? 'Locked' : 'Unlocked'}
            </Button>
          }
        >
          <Stack align="right" fill mt={1}>
            <Stack.Item>
              <Button.Confirm
                width="100%"
                color="red"
                disabled={lockExplode}
                onClick={() =>
                  act('mob_explode', { power: expPower, falloff: falloff })
                }
              >
                <Box height="100%" pt={2} pb={2} textAlign="center">
                  Detonate
                </Box>
              </Button.Confirm>
            </Stack.Item>
            <Stack.Item ml={1} grow>
              <Slider
                unit="Power"
                value={expPower}
                onChange={(e, value) => setExpPower(value)}
                minValue={0}
                maxValue={500}
                step={5}
                stepPixelSize={2}
              />
              <Slider
                unit="Falloff"
                value={falloff}
                onChange={(e, value) => setFalloff(value)}
                minValue={1}
                maxValue={200}
                step={1}
                stepPixelSize={2}
                mt={1}
              />
            </Stack.Item>
          </Stack>
        </Section>
      )}
    </>
  );
};

const AntagActions = (props) => {
  const { act, data } = useBackend<Data>();
  const { glob_hives } = data;

  const [selectedHivenumber, setHivenumber] = useState(
    Object.keys(glob_hives)[0],
  );

  return (
    <Section title="Xenomorph">
      <Stack align="right" fill>
        <Stack.Item grow>
          <Dropdown
            width="100%"
            color="purple"
            selected={selectedHivenumber}
            options={Object.keys(glob_hives)}
            onSelected={(value) => setHivenumber(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="random"
            color="purple"
            disabled={!hasPermission(data, 'xeno_change_hivenumber')}
            onClick={() =>
              act('xeno_change_hivenumber', {
                hivenumber: glob_hives[selectedHivenumber],
              })
            }
          >
            Change Hive
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const PhysicalActions = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    is_human,
    glob_limbs,
    mob_status_flags,
    glob_status_flags,
    has_client,
  } = data;

  const limbNames = Object.keys(glob_limbs);
  const limbFlags = limbNames.map((_, i) => 1 << i);

  const [delimbOption, setDelimbOption] = useState(0);

  return (
    <>
      <Section title="Status Flags">
        <Stack align="right" fill wrap>
          {Object.keys(glob_status_flags).map((val, i) => (
            <Button.Checkbox
              key={i}
              disabled={!hasPermission(data, 'set_status_flags')}
              color={mob_status_flags & glob_status_flags[val] ? 'good' : 'bad'}
              checked={!!(mob_status_flags & glob_status_flags[val])}
              onClick={() =>
                act('set_status_flags', {
                  status_flags:
                    mob_status_flags & glob_status_flags[val]
                      ? mob_status_flags & ~glob_status_flags[val]
                      : mob_status_flags | glob_status_flags[val],
                })
              }
            >
              {val}
            </Button.Checkbox>
          ))}
        </Stack>
      </Section>

      {!!is_human && (
        <Section
          title="Limbs"
          buttons={
            <Stack align="right" fill>
              {limbNames.map((val, index) => (
                <Button.Checkbox
                  key={index}
                  textAlign="center"
                  checked={!!(delimbOption & limbFlags[index])}
                  onClick={() =>
                    setDelimbOption(
                      delimbOption & limbFlags[index]
                        ? delimbOption & ~limbFlags[index]
                        : delimbOption | limbFlags[index],
                    )
                  }
                >
                  {val}
                </Button.Checkbox>
              ))}
            </Stack>
          }
        >
          <Stack align="right" fill>
            <Button.Confirm
              width="100%"
              icon="unlink"
              color="red"
              disabled={!delimbOption || !hasPermission(data, 'mob_delimb')}
              onClick={() =>
                act('mob_delimb', {
                  limbs: limbFlags
                    .map((val, index) => !!(delimbOption & val) && glob_limbs[limbNames[index]])
                    .filter(Boolean),
                })
              }
            >
              Delimb
            </Button.Confirm>
          </Stack>
        </Section>
      )}

      <Section title="Equipment">
        <Stack align="right" fill>
          <Button
            width="100%"
            icon="user-tie"
            color="orange"
            disabled={!hasPermission(data, 'select_equipment')}
            onClick={() => act('select_equipment')}
          >
            Select Equipment
          </Button>
          <Button.Confirm
            width="100%"
            icon="trash-alt"
            color="red"
            disabled={!hasPermission(data, 'strip_equipment')}
            onClick={() => act('strip_equipment', { drop_items: true })}
          >
            Strip Equipment
          </Button.Confirm>
        </Stack>
      </Section>

      <Section title="Game">
        <Stack align="right" fill>
          <Button.Confirm
            width="100%"
            icon="magnifying-glass"
            disabled={!hasPermission(data, 'check_contents')}
            onClick={() => act('check_contents')}
          >
            Check Contents
          </Button.Confirm>
          <Button.Confirm
            width="100%"
            icon="hand-holding"
            disabled={!has_client || !hasPermission(data, 'offer_mob')}
            onClick={() => act('offer_mob')}
          >
            Offer Mob
          </Button.Confirm>
          <Button.Confirm
            width="100%"
            icon="user-plus"
            disabled={!hasPermission(data, 'give_mob_action')}
            onClick={() => act('give_mob_action')}
          >
            Give Mob
          </Button.Confirm>
        </Stack>
        {!!is_human && (
          <Stack align="right" fill mt={1}>
            <Button.Confirm
              width="100%"
              icon="users"
              disabled={!hasPermission(data, 'set_squad')}
              onClick={() => act('set_squad')}
            >
              Set Squad
            </Button.Confirm>
            <Button.Confirm
              width="100%"
              icon="flag"
              disabled={!hasPermission(data, 'set_faction')}
              onClick={() => act('set_faction')}
            >
              Set Faction
            </Button.Confirm>
          </Stack>
        )}
        {!!is_human && (
          <Stack align="right" fill mt={1}>
            <Button
              width="100%"
              icon="id-badge"
              color="orange"
              disabled={!hasPermission(data, 'rank_and_equipment')}
              onClick={() => act('rank_and_equipment')}
            >
              Rank and Equipment
            </Button>
            <Button
              width="100%"
              icon="user-edit"
              color="orange"
              disabled={!hasPermission(data, 'edit_appearance')}
              onClick={() => act('edit_appearance')}
            >
              Edit Appearance
            </Button>
            <Button.Confirm
              width="100%"
              icon="random"
              color="orange"
              disabled={!hasPermission(data, 'randomize_name')}
              onClick={() => act('randomize_name')}
            >
              Randomize Name
            </Button.Confirm>
          </Stack>
        )}
      </Section>
    </>
  );
};
