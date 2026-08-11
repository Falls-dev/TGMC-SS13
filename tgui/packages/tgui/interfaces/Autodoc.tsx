import {
  Box,
  Button,
  Flex,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
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

type OccupantData = {
  name: string;
  stat: number;
  health: number;
  health_ratio: number;
  maxHealth: number;
  bruteLoss: number;
  oxyLoss: number;
  toxLoss: number;
  fireLoss: number;
  pulse: string | number;
  pulse_bad: BooleanLike;
};

type Data = {
  connected: BooleanLike;
  locked: BooleanLike;
  release_notice: BooleanLike;
  automaticmode: BooleanLike;
  surgery: BooleanLike;
  hasOccupant: BooleanLike;
  filtering: BooleanLike;
  blood_transfer: BooleanLike;
  heal_brute: BooleanLike;
  heal_burn: BooleanLike;
  heal_toxin: BooleanLike;
  occupant: OccupantData | null;
  surgeries: Record<string, BooleanLike>;
  queue: string[];
  auto_ready: BooleanLike;
};

type SurgeryButtonProps = {
  surgeryKey: string;
  label: string;
  activeExtra?: BooleanLike;
};

const SurgeryButton = (props: SurgeryButtonProps) => {
  const { act, data } = useBackend<Data>();
  const { surgeryKey, label, activeExtra } = props;
  const active = !!data.surgeries[surgeryKey] || !!activeExtra;
  return (
    <Button
      fluid
      selected={active}
      disabled={!!data.surgery || !!data.automaticmode}
      onClick={() => !active && act(surgeryKey)}
    >
      {label}
      {active && (
        <Icon
          name={data.surgery ? 'arrows-rotate' : 'plus'}
          position="absolute"
          right="0px"
          top="4px"
        />
      )}
    </Button>
  );
};

export const Autodoc = () => {
  const { data } = useBackend<Data>();
  const height = data.hasOccupant ? 780 : 280;

  return (
    <Window width={520} height={height} title="Autodoc Console">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <SettingsPanel />
          </Stack.Item>
          {!data.hasOccupant ? (
            <Stack.Item grow>
              <AutodocEmpty />
            </Stack.Item>
          ) : (
            <>
              <Stack.Item>
                <OccupantPanel />
              </Stack.Item>
              <Stack.Item>
                <DamagePanel />
              </Stack.Item>
              <Stack.Item>
                <QueuePanel />
              </Stack.Item>
              <Stack.Item>
                <ControlsPanel />
              </Stack.Item>
              <Stack.Item>
                <ManualSurgeriesPanel />
              </Stack.Item>
            </>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SettingsPanel = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Section title="Console Settings">
      <Flex>
        <Flex.Item grow>
          <Button
            fluid
            icon={data.locked ? 'lock' : 'lock-open'}
            color={data.locked ? 'bad' : undefined}
            onClick={() => act('locktoggle')}
          >
            {data.locked ? 'Unlock Console' : 'Lock Console'}
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            icon="bell"
            selected={!!data.release_notice}
            onClick={() => act('noticetoggle')}
          >
            {data.release_notice ? 'Notifications On' : 'Notifications Off'}
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            icon={data.automaticmode ? 'robot' : 'hand'}
            selected={!!data.automaticmode}
            onClick={() => act('automatictoggle')}
          >
            {data.automaticmode ? 'Automatic Mode' : 'Manual Mode'}
          </Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const AutodocEmpty = () => {
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

const OccupantPanel = () => {
  const { data } = useBackend<Data>();
  const occupant = data.occupant!;
  const status = STAT_LABELS[occupant.stat] || STAT_LABELS[0];

  return (
    <Section title="Occupant Statistics">
      <LabeledList>
        <LabeledList.Item label="Name">{occupant.name}</LabeledList.Item>
        <LabeledList.Item label="Health %">
          <ProgressBar
            value={occupant.health_ratio}
            ranges={{
              good: [0.5, Infinity],
              average: [0, 0.5],
              bad: [-Infinity, 0],
            }}
          >
            {round(occupant.health, 0)} ({status[1]})
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Pulse, bpm" color={occupant.pulse_bad ? 'bad' : 'good'}>
          {occupant.pulse}
        </LabeledList.Item>
        <LabeledList.Item label="Status" color={status[0]}>
          {status[1]}
        </LabeledList.Item>
        <LabeledList.Item label="Med-Pod Status" color={data.surgery ? 'bad' : 'good'}>
          {data.surgery
            ? 'SURGERY IN PROGRESS: MANUAL EJECTION ONLY BY TRAINED OPERATORS!'
            : 'Not in surgery'}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const DamagePanel = () => {
  const { data } = useBackend<Data>();
  const occupant = data.occupant!;
  const rows = [
    ['Brute Damage %', occupant.bruteLoss],
    ['Respiratory Damage %', occupant.oxyLoss],
    ['Toxin Content %', occupant.toxLoss],
    ['Burn Severity %', occupant.fireLoss],
  ] as const;

  return (
    <Section title="Damage Profile">
      <LabeledList>
        {rows.map(([label, value]) => (
          <LabeledList.Item key={label} label={label}>
            <ProgressBar
              value={value / 100}
              ranges={{
                good: [-Infinity, 0.25],
                average: [0.25, 0.6],
                bad: [0.6, Infinity],
              }}
            >
              {round(value, 0)}
            </ProgressBar>
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
};

const QueuePanel = () => {
  const { data } = useBackend<Data>();

  return (
    <Section title="Surgery Queue">
      {!!data.automaticmode &&
        (data.auto_ready ? (
          <NoticeBox success>Automatic Mode Ready.</NoticeBox>
        ) : (
          <NoticeBox danger>
            Automatic Mode Unavailable, Scan Patient First.
          </NoticeBox>
        ))}
      {!data.automaticmode &&
        (data.queue?.length ? (
          data.queue.map((entry, index) => (
            <Box key={`${entry}-${index}`}>{entry}</Box>
          ))
        ) : (
          <Box color="label">Queue empty.</Box>
        ))}
    </Section>
  );
};

const ControlsPanel = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Section>
      <Flex>
        <Flex.Item grow>
          <Button
            fluid
            color="good"
            icon="play"
            disabled={!!data.surgery}
            onClick={() => act('surgery')}
          >
            Begin Surgery Queue
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            icon="trash"
            disabled={!!data.surgery || !!data.automaticmode}
            onClick={() => act('clear')}
          >
            Clear Surgery Queue
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            icon={data.surgery ? 'triangle-exclamation' : 'user-slash'}
            color={data.surgery ? 'bad' : undefined}
            onClick={() => act('ejectify')}
          >
            Eject Patient
          </Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const ManualSurgeriesPanel = () => {
  const { data } = useBackend<Data>();

  if (data.surgery) {
    return null;
  }

  if (data.automaticmode) {
    return (
      <NoticeBox>
        Manual Surgery Interface Unavailable, Automatic Mode Engaged.
      </NoticeBox>
    );
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Trauma Surgeries">
          <Flex>
            <Flex.Item grow>
              <SurgeryButton
                surgeryKey="brute"
                label="Surgical Brute Damage Treatment"
                activeExtra={data.heal_brute}
              />
            </Flex.Item>
            <Flex.Item grow>
              <SurgeryButton
                surgeryKey="burn"
                label="Surgical Burn Damage Treatment"
                activeExtra={data.heal_burn}
              />
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Orthopedic Surgeries">
          <Flex wrap>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="broken"
                label="Broken Bone Surgery"
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="internal"
                label="Internal Bleeding Surgery"
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="shrapnel"
                label="Foreign Body Removal Surgery"
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="missing"
                label="Limb Replacement Surgery"
              />
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Organ Surgeries">
          <Flex wrap>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="organdamage"
                label="Surgical Organ Damage Treatment"
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="organgerms"
                label="Organ Infection Treatment"
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="eyes"
                label="Corrective Eye Surgery"
              />
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Hematology Treatments">
          <Flex wrap>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="blood"
                label="Blood Transfer"
                activeExtra={data.blood_transfer}
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="toxin"
                label="Toxin Damage Chelation"
                activeExtra={data.heal_toxin}
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="dialysis"
                label="Dialysis"
                activeExtra={data.filtering}
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="necro"
                label="Necrosis Removal Surgery"
              />
            </Flex.Item>
            <Flex.Item basis="50%" grow>
              <SurgeryButton
                surgeryKey="limbgerm"
                label="Limb Disinfection Procedure"
              />
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Special Surgeries">
          <Flex>
            <Flex.Item grow>
              <SurgeryButton
                surgeryKey="facial"
                label="Facial Reconstruction Surgery"
              />
            </Flex.Item>
            <Flex.Item grow>
              <SurgeryButton
                surgeryKey="open"
                label="Close Open Incision"
              />
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
