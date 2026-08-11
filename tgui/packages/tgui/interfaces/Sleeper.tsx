import {
  Button,
  Flex,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { round } from 'tgui-core/math';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const STAT_LABELS = [
  ['good', 'Conscious'],
  ['average', 'Unconscious'],
  ['bad', '*Dead*'],
] as const;

const DAMAGES = [
  ['Brute', 'bruteLoss'],
  ['Burn', 'fireLoss'],
  ['Toxin', 'toxLoss'],
  ['Oxygen', 'oxyLoss'],
] as const;

const DAMAGE_RANGES = {
  good: [-Infinity, 0.25],
  average: [0.25, 0.5],
  bad: [0.5, Infinity],
};

const TEMP_COLORS = [
  'bad',
  'average',
  'average',
  'good',
  'average',
  'average',
  'bad',
];

type OccupantData = {
  name: string;
  stat: number;
  health: number;
  maxHealth: number;
  bruteLoss: number;
  oxyLoss: number;
  toxLoss: number;
  fireLoss: number;
  bodyTemperature: number;
  btCelsius: number;
  btFaren: number;
  temperatureSuitability: number;
  hasBlood: BooleanLike;
  bloodLevel: number;
  bloodMax: number;
  bloodPercent: number;
  pulse: string | number;
  pulse_bad: BooleanLike;
  totalreagents: number;
};

type ChemicalData = {
  title: string;
  id: string;
  occ_amount: number;
  pretty_amount: number;
  injectable: BooleanLike;
  overdosing: BooleanLike;
  od_warning: BooleanLike;
};

type Data = {
  connected: BooleanLike;
  connected_operable: BooleanLike;
  hasOccupant: BooleanLike;
  occupant: OccupantData | null;
  amounts: number[];
  maxchem: number;
  dialysis: BooleanLike;
  stasis: BooleanLike;
  chemicals: ChemicalData[];
};

export const Sleeper = () => {
  const { data } = useBackend<Data>();
  const { connected, connected_operable, hasOccupant } = data;

  let height = 220;
  if (connected && connected_operable) {
    height = hasOccupant ? 640 : 220;
  } else {
    height = 200;
  }

  return (
    <Window width={480} height={height} title="Sleeper Console">
      <Window.Content scrollable>
        {!connected || !connected_operable ? (
          <NotConnected />
        ) : (
          <Stack vertical fill>
            <Stack.Item>
              <SleeperControls />
            </Stack.Item>
            {hasOccupant ? (
              <>
                <Stack.Item>
                  <SleeperOccupant />
                </Stack.Item>
                <Stack.Item>
                  <SleeperDamage />
                </Stack.Item>
                <Stack.Item>
                  <SleeperChemicals />
                </Stack.Item>
              </>
            ) : (
              <Stack.Item grow>
                <SleeperEmpty />
              </Stack.Item>
            )}
          </Stack>
        )}
      </Window.Content>
    </Window>
  );
};

const NotConnected = () => {
  const { data } = useBackend<Data>();
  const { connected } = data;
  return (
    <Section fill>
      <Flex height="100%">
        <Flex.Item grow align="center" textAlign="center" color="label">
          <Icon name="triangle-exclamation" mb="0.5rem" size={5} />
          <br />
          {connected
            ? 'The connected sleeper is non-functional.'
            : 'This console is not connected to a sleeper.'}
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const SleeperControls = () => {
  const { act, data } = useBackend<Data>();
  const { hasOccupant, dialysis, stasis, occupant } = data;
  const dialysisDisabled = !hasOccupant || !occupant?.totalreagents;
  return (
    <Section title="Console Controls">
      <Flex>
        <Flex.Item grow>
          <Button
            fluid
            disabled={dialysisDisabled}
            selected={!!dialysis}
            icon={dialysis ? 'toggle-on' : 'toggle-off'}
            onClick={() => act('togglefilter')}
          >
            {dialysis ? 'Dialysis Active' : 'Dialysis Inactive'}
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            disabled={!hasOccupant}
            selected={!!stasis}
            icon={stasis ? 'snowflake' : 'toggle-off'}
            onClick={() => act('togglestasis')}
          >
            {stasis ? 'Cryostasis Active' : 'Cryostasis Inactive'}
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            disabled={!hasOccupant}
            icon="user-slash"
            onClick={() => act('ejectify')}
          >
            Eject Patient
          </Button>
        </Flex.Item>
      </Flex>
      {!!hasOccupant && dialysisDisabled && (
        <NoticeBox info>Occupant has no chemicals to remove!</NoticeBox>
      )}
    </Section>
  );
};

const SleeperOccupant = () => {
  const { data } = useBackend<Data>();
  const occupant = data.occupant!;
  const status = STAT_LABELS[occupant.stat] || STAT_LABELS[0];
  return (
    <Section title="Occupant">
      <LabeledList>
        <LabeledList.Item label="Name">{occupant.name}</LabeledList.Item>
        <LabeledList.Item label="Health">
          <ProgressBar
            value={occupant.health / occupant.maxHealth}
            ranges={{
              good: [0.5, Infinity],
              average: [0, 0.5],
              bad: [-Infinity, 0],
            }}
          >
            {round(occupant.health, 0)}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Status" color={status[0]}>
          {status[1]}
        </LabeledList.Item>
        <LabeledList.Item label="Temperature">
          <ProgressBar
            value={occupant.bodyTemperature / 1000}
            color={TEMP_COLORS[occupant.temperatureSuitability + 3]}
          >
            {round(occupant.btCelsius, 0)}&deg;C, {round(occupant.btFaren, 0)}
            &deg;F
          </ProgressBar>
        </LabeledList.Item>
        {!!occupant.hasBlood && (
          <>
            <LabeledList.Item label="Blood Level">
              <ProgressBar
                value={occupant.bloodLevel / occupant.bloodMax}
                ranges={{
                  bad: [-Infinity, 0.6],
                  average: [0.6, 0.9],
                  good: [0.9, Infinity],
                }}
              >
                {occupant.bloodPercent}%, {occupant.bloodLevel}cl
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item
              label="Pulse"
              color={occupant.pulse_bad ? 'bad' : 'good'}
            >
              {occupant.pulse} BPM
            </LabeledList.Item>
          </>
        )}
      </LabeledList>
    </Section>
  );
};

const SleeperDamage = () => {
  const { data } = useBackend<Data>();
  const occupant = data.occupant!;
  return (
    <Section title="Occupant Damage">
      <LabeledList>
        {DAMAGES.map(([label, key]) => (
          <LabeledList.Item key={key} label={label}>
            <ProgressBar value={occupant[key] / 100} ranges={DAMAGE_RANGES}>
              {round(occupant[key], 0)}
            </ProgressBar>
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
};

const SleeperChemicals = () => {
  const { act, data } = useBackend<Data>();
  const { chemicals, maxchem, amounts } = data;
  return (
    <Section title="Occupant Chemicals">
      <LabeledList>
        {chemicals.map((chem) => {
          let barColor = '';
          let odWarning;
          if (chem.overdosing) {
            barColor = 'bad';
            odWarning = (
              <Tooltip content="Overdosing!">
                <Icon name="exclamation-circle" />
              </Tooltip>
            );
          } else if (chem.od_warning) {
            barColor = 'average';
            odWarning = (
              <Tooltip content="Close to overdosing">
                <Icon name="exclamation-triangle" />
              </Tooltip>
            );
          }
          return (
            <LabeledList.Item key={chem.id} label={chem.title}>
              <Flex align="flex-start">
                <ProgressBar
                  value={chem.occ_amount / maxchem}
                  color={barColor}
                  mr="0.5rem"
                >
                  {odWarning} {chem.pretty_amount}/{maxchem}u
                </ProgressBar>
                {amounts.map((a) => (
                  <Button
                    key={a}
                    disabled={!chem.injectable || chem.occ_amount + a > maxchem}
                    icon="syringe"
                    tooltip={`Inject ${a}u of ${chem.title} into the occupant`}
                    mb="0"
                    height="19px"
                    onClick={() =>
                      act('chemical', {
                        chemid: chem.id,
                        amount: a,
                      })
                    }
                  >
                    {`Inject ${a}u`}
                  </Button>
                ))}
              </Flex>
            </LabeledList.Item>
          );
        })}
      </LabeledList>
    </Section>
  );
};

const SleeperEmpty = () => {
  return (
    <Section fill>
      <Flex height="100%">
        <Flex.Item grow align="center" textAlign="center" color="label">
          <Icon name="user-slash" mb="0.5rem" size={5} />
          <br />
          No occupant detected.
        </Flex.Item>
      </Flex>
    </Section>
  );
};
