import { useMemo } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type SquadInfo = {
  id: string | number;
  name: string;
  color?: string;
  leader?: string;
  leader_ref?: string;
  overwatch_officer?: string;
  primary_objective?: string;
  secondary_objective?: string;
};

type MarineRow = {
  ref: string;
  name: string;
  role: string;
  acting_sl: BooleanLike;
  fireteam?: string;
  state: string;
  area: string;
  distance: string;
  is_dead: BooleanLike;
  is_leader: BooleanLike;
  sort_health: number;
  sort_rank: number;
};

type MonitorData = {
  marines: MarineRow[];
  leader_count: number;
  medic_count: number;
  engi_count: number;
  smart_count: number;
  spec_count: number;
  marine_count: number;
  living_count: number;
  total_deployed: number;
  smart_label: string;
  primary_objective?: string;
  secondary_objective?: string;
  overwatch_officer?: string;
};

type FireTarget = {
  name: string;
  ref: string;
};

type FireSupportData = {
  ob_ready: BooleanLike;
  ob_status: string;
  selected_target?: string;
  selected_target_ref?: string;
  ob_lasers: FireTarget[];
  beacons: FireTarget[];
  rail_ready: BooleanLike;
  rail_status: string;
  rail_lasers: FireTarget[];
};

type Data = {
  console_type: 'basic' | 'military' | 'main';
  operator?: string;
  can_interact: BooleanLike;
  on_monitor: BooleanLike;
  sort_by_health: BooleanLike;
  hide_dead: BooleanLike;
  z_hidden: number;
  ship_map_name: string;
  squads: SquadInfo[];
  current_squad: SquadInfo | null;
  monitor: MonitorData | null;
  firesupport?: FireSupportData;
};

const HIDE_NONE = 0;
const HIDE_ON_GROUND = 1;
const HIDE_ON_SHIP = 2;

const zFilterLabel = (zHidden: number, shipName: string) => {
  switch (zHidden) {
    case HIDE_ON_SHIP:
      return `Hiding: ${shipName}`;
    case HIDE_ON_GROUND:
      return 'Hiding: Ground';
    default:
      return 'Showing: All locations';
  }
};

export const OverwatchConsole = () => {
  const { data } = useBackend<Data>();
  const { operator, on_monitor, console_type } = data;

  return (
    <Window width={640} height={780} title="Overwatch Console">
      <Window.Content scrollable>
        {!operator && <LoginPanel />}
        {!!operator && on_monitor && <MonitorPanel />}
        {!!operator && !on_monitor && console_type === 'main' && (
          <MainPanel />
        )}
        {!!operator &&
          !on_monitor &&
          console_type !== 'main' &&
          !data.current_squad && <PickSquadPanel />}
        {!!operator &&
          !on_monitor &&
          console_type !== 'main' &&
          !!data.current_squad && <SquadPanel />}
      </Window.Content>
    </Window>
  );
};

const LoginPanel = () => {
  const { act } = useBackend<Data>();
  return (
    <Section title="Operator">
      <Button fluid icon="sign-in-alt" onClick={() => act('claim')}>
        Claim Overwatch
      </Button>
    </Section>
  );
};

const OperatorHeader = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Section
      title={`Operator: ${data.operator}`}
      buttons={
        <Button icon="sign-out-alt" color="bad" onClick={() => act('logout')}>
          Stop Overwatch
        </Button>
      }
    />
  );
};

const PickSquadPanel = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Stack vertical>
      <Stack.Item>
        <OperatorHeader />
      </Stack.Item>
      <Stack.Item>
        <Section title="Select Squad">
          {!data.squads?.length && (
            <NoticeBox>No active squads available.</NoticeBox>
          )}
          {data.squads?.map((squad) => (
            <Button
              key={squad.id}
              fluid
              onClick={() => act('pick_squad', { squad_id: squad.id })}
            >
              {squad.name}
            </Button>
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const SquadPanel = () => {
  const { act, data } = useBackend<Data>();
  const squad = data.current_squad!;
  const isMilitary = data.console_type === 'military';

  return (
    <Stack vertical>
      <Stack.Item>
        <OperatorHeader />
      </Stack.Item>
      <Stack.Item>
        <Section
          title={`${squad.name} Squad`}
          buttons={
            isMilitary ? (
              <Button icon="bullhorn" onClick={() => act('message')}>
                Message Squad
              </Button>
            ) : undefined
          }
        >
          <LabeledList>
            <LabeledList.Item
              label="Squad Leader"
              buttons={
                <>
                  {!!squad.leader_ref && (
                    <Button
                      icon="video"
                      onClick={() =>
                        act('jump', { target: squad.leader_ref })
                      }
                    >
                      {squad.leader}
                    </Button>
                  )}
                  {!squad.leader && <Box color="bad">NONE</Box>}
                  {isMilitary && (
                    <>
                      {!!squad.leader && (
                        <Button onClick={() => act('sl_message')}>MSG</Button>
                      )}
                      <Button onClick={() => act('change_lead')}>
                        {squad.leader
                          ? 'CHANGE SQUAD LEADER'
                          : 'ASSIGN SQUAD LEADER'}
                      </Button>
                    </>
                  )}
                </>
              }
            >
              {squad.leader || 'NONE'}
            </LabeledList.Item>
            {isMilitary && (
              <>
                <LabeledList.Item
                  label="Primary Objective"
                  buttons={
                    <Button onClick={() => act('set_primary')}>Set</Button>
                  }
                >
                  {squad.primary_objective || (
                    <Box color="bad">NONE!</Box>
                  )}
                </LabeledList.Item>
                <LabeledList.Item
                  label="Secondary Objective"
                  buttons={
                    <Button onClick={() => act('set_secondary')}>Set</Button>
                  }
                >
                  {squad.secondary_objective || (
                    <Box color="bad">NONE!</Box>
                  )}
                </LabeledList.Item>
              </>
            )}
          </LabeledList>
          {isMilitary && (
            <Box mt={1}>
              <Button fluid onClick={() => act('squad_transfer')}>
                Transfer a marine to another squad
              </Button>
            </Box>
          )}
          <Box mt={1}>
            <Button fluid icon="desktop" onClick={() => act('monitor')}>
              Squad Monitor
            </Button>
          </Box>
        </Section>
      </Stack.Item>
      {isMilitary && data.firesupport && (
        <Stack.Item>
          <FireSupportPanel />
        </Stack.Item>
      )}
    </Stack>
  );
};

const MainPanel = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Stack vertical>
      <Stack.Item>
        <OperatorHeader />
      </Stack.Item>
      <Stack.Item>
        <Section title="Squads">
          {data.squads?.map((squad) => (
            <Section
              key={squad.id}
              title={`${squad.name} Squad`}
              buttons={
                <>
                  <Button
                    onClick={() =>
                      act('message', { squad_id: squad.id })
                    }
                  >
                    Message Squad
                  </Button>
                  <Button
                    onClick={() =>
                      act('monitor', { squad_id: squad.id })
                    }
                  >
                    Monitor
                  </Button>
                </>
              }
            >
              <LabeledList>
                <LabeledList.Item
                  label="Leader"
                  buttons={
                    !!squad.leader_ref && (
                      <>
                        <Button
                          icon="video"
                          onClick={() =>
                            act('jump', { target: squad.leader_ref })
                          }
                        >
                          Cam
                        </Button>
                        <Button
                          onClick={() =>
                            act('sl_message', { squad_id: squad.id })
                          }
                        >
                          MSG
                        </Button>
                      </>
                    )
                  }
                >
                  {squad.leader || <Box color="bad">NONE</Box>}
                </LabeledList.Item>
                <LabeledList.Item label="Squad Overwatch">
                  {squad.overwatch_officer || (
                    <Box color="bad">NONE</Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          ))}
        </Section>
      </Stack.Item>
      {data.firesupport && (
        <Stack.Item>
          <FireSupportPanel />
        </Stack.Item>
      )}
    </Stack>
  );
};

const MonitorPanel = () => {
  const { act, data } = useBackend<Data>();
  const monitor = data.monitor;

  const marines = useMemo(() => {
    const list = monitor?.marines ? [...monitor.marines] : [];
    if (data.sort_by_health) {
      list.sort((a, b) => a.sort_health - b.sort_health);
    } else {
      list.sort((a, b) => a.sort_rank - b.sort_rank);
    }
    return list;
  }, [monitor?.marines, data.sort_by_health]);

  if (!monitor) {
    return (
      <Stack vertical>
        <Stack.Item>
          <OperatorHeader />
        </Stack.Item>
        <Stack.Item>
          <NoticeBox>No squad selected.</NoticeBox>
          <Button fluid onClick={() => act('back')}>
            Back
          </Button>
        </Stack.Item>
      </Stack>
    );
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <OperatorHeader />
      </Stack.Item>
      <Stack.Item>
        <Section
          title={`${data.current_squad?.name || 'Squad'} Monitor`}
          buttons={
            <Button icon="arrow-left" onClick={() => act('back')}>
              Back
            </Button>
          }
        >
          <LabeledList>
            <LabeledList.Item label="Squad Overwatch">
              {monitor.overwatch_officer || <Box color="bad">NONE</Box>}
            </LabeledList.Item>
            <LabeledList.Item label="Squad Leader">
              {monitor.leader_count ? (
                'Deployed'
              ) : (
                <Box color="bad">No Squad Leader Deployed!</Box>
              )}
            </LabeledList.Item>
            <LabeledList.Item label={monitor.smart_label}>
              {monitor.smart_count} Deployed
            </LabeledList.Item>
            <LabeledList.Item label="Specialist">
              {monitor.spec_count} Deployed
            </LabeledList.Item>
            <LabeledList.Item label="Corpsmen / Engineers">
              {monitor.medic_count} / {monitor.engi_count} Deployed
            </LabeledList.Item>
            <LabeledList.Item label="Marines">
              {monitor.marine_count} Deployed
            </LabeledList.Item>
            <LabeledList.Item label="Total / Alive">
              {monitor.total_deployed} / {monitor.living_count}
            </LabeledList.Item>
            <LabeledList.Item label="Primary">
              {monitor.primary_objective || <Box color="bad">NONE!</Box>}
            </LabeledList.Item>
            <LabeledList.Item label="Secondary">
              {monitor.secondary_objective || <Box color="bad">NONE!</Box>}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section
          title="Marines"
          buttons={
            <>
              <Button onClick={() => act('toggle_sort')}>
                {data.sort_by_health ? 'Sort by rank' : 'Sort by health'}
              </Button>
              <Button onClick={() => act('toggle_dead')}>
                {data.hide_dead ? 'Show Dead' : 'Hide Dead'}
              </Button>
              <Button onClick={() => act('cycle_z')}>
                {zFilterLabel(data.z_hidden, data.ship_map_name)}
              </Button>
            </>
          }
        >
          <Table>
            <Table.Row header>
              <Table.Cell>Name</Table.Cell>
              <Table.Cell>Role</Table.Cell>
              <Table.Cell>State</Table.Cell>
              <Table.Cell>Location</Table.Cell>
              <Table.Cell>SL Dist</Table.Cell>
            </Table.Row>
            {marines.map((marine) => (
              <Table.Row key={marine.ref}>
                <Table.Cell>
                  <Button
                    onClick={() => act('jump', { target: marine.ref })}
                  >
                    {marine.name}
                  </Button>
                </Table.Cell>
                <Table.Cell>
                  {marine.role}
                  {marine.acting_sl ? ' (acting SL)' : ''}
                  {marine.fireteam ? ` [${marine.fireteam}]` : ''}
                </Table.Cell>
                <Table.Cell color={marine.is_dead ? 'bad' : undefined}>
                  {marine.state}
                </Table.Cell>
                <Table.Cell>{marine.area}</Table.Cell>
                <Table.Cell>{marine.distance}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const FireSupportPanel = () => {
  const { act, data } = useBackend<Data>();
  const fs = data.firesupport!;
  const squadPrefix = data.current_squad
    ? `${data.current_squad.name} `
    : '';

  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Orbital Bombardment Control">
          <LabeledList>
            <LabeledList.Item label="Current Cannon Status">
              <Box color={fs.ob_ready ? 'good' : 'bad'}>{fs.ob_status}</Box>
            </LabeledList.Item>
            <LabeledList.Item label="Selected Target">
              {fs.selected_target || <Box color="average">None</Box>}
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1} mb={0.5} bold>
            {squadPrefix}Laser Targets:
          </Box>
          {!fs.ob_lasers?.length && <Box color="average">None</Box>}
          {fs.ob_lasers?.map((target) => (
            <Button
              key={target.ref}
              fluid
              onClick={() => act('select_target', { target: target.ref })}
            >
              {target.name}
            </Button>
          ))}
          <Box mt={1} mb={0.5} bold>
            Beacon Targets:
          </Box>
          {!fs.beacons?.length && (
            <Box color="average">None transmitting</Box>
          )}
          {fs.beacons?.map((beacon) => (
            <Button
              key={beacon.ref}
              fluid
              onClick={() => act('select_target', { target: beacon.ref })}
            >
              {beacon.name}
            </Button>
          ))}
          <Box mt={1}>
            <Button.Confirm
              fluid
              color="bad"
              icon="bomb"
              confirmContent="FIRE OB?"
              onClick={() => act('dropbomb')}
            >
              FIRE!
            </Button.Confirm>
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Rail Gun Control">
          <LabeledList>
            <LabeledList.Item label="Current Rail Gun Status">
              <Box color={fs.rail_ready ? 'good' : 'average'}>
                {fs.rail_status}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Selected Target">
              {fs.selected_target || <Box color="average">None</Box>}
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1} mb={0.5} bold>
            {squadPrefix}Laser Targets:
          </Box>
          {!fs.rail_lasers?.length && <Box color="average">None</Box>}
          {fs.rail_lasers?.map((target) => (
            <Button
              key={target.ref}
              fluid
              onClick={() => act('select_target', { target: target.ref })}
            >
              {target.name}
            </Button>
          ))}
          <Box mt={1}>
            <Button.Confirm
              fluid
              color="bad"
              icon="crosshairs"
              confirmContent="FIRE RAILGUN?"
              disabled={!fs.rail_ready}
              onClick={() => act('shootrailgun')}
            >
              FIRE!
            </Button.Confirm>
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
