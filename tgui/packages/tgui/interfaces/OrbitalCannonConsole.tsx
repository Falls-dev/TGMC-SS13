import { Box, Button, Collapsible, Dimmer, Icon, NoticeBox, Section } from 'tgui-core/components';
import { type BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type FuelRequirement = {
  name: string;
  amount: number;
};

type Data = {
  cannon_linked: BooleanLike;
  tray_linked: BooleanLike;
  busy: BooleanLike;
  loaded_tray: BooleanLike;
  chambered_tray: BooleanLike;
  warhead: string | null;
  fuel: number;
  fuel_requirements: FuelRequirement[];
};

export const OrbitalCannonConsole = (props) => {
  const { data } = useBackend<Data>();
  const { cannon_linked, tray_linked } = data;

  return (
    <Window title="Orbital Cannon System Control Console" width={480} height={430}>
      <Window.Content scrollable>
        {(!cannon_linked && (
          <NoticeBox danger>No Orbital Cannon System Detected!</NoticeBox>
        )) ||
          (!tray_linked && (
            <NoticeBox danger>Orbital Cannon System Tray is missing!</NoticeBox>
          )) || <OrbitalCannonControls />}
      </Window.Content>
    </Window>
  );
};

const OrbitalCannonControls = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    busy,
    loaded_tray,
    chambered_tray,
    warhead,
    fuel,
    fuel_requirements,
  } = data;

  let trayStatus = 'unloaded';
  let trayColor = 'label';
  if (chambered_tray) {
    trayStatus = 'chambered';
    trayColor = 'good';
  } else if (loaded_tray) {
    trayStatus = 'loaded';
    trayColor = 'average';
  }

  return (
    <>
      <Section title="Tray Status">
        <Box>
          Orbital Cannon Tray is <Box as="span" bold color={trayColor}>{trayStatus}</Box>
        </Box>
        <Box>
          {warhead ? `${warhead} Detected` : 'No Warhead Detected'}
        </Box>
        <Box>
          {fuel} Solid Fuel Block{fuel === 1 ? '' : 's'} Detected
        </Box>
      </Section>
      <Section title="Tray Controls">
        <Button
          fluid
          mb={1}
          icon="truck-loading"
          disabled={!!busy || !!loaded_tray}
          onClick={() => act('load_tray')}
        >
          Load Tray
        </Button>
        <Button
          fluid
          mb={1}
          icon="sign-out-alt"
          disabled={!!busy || !loaded_tray || !!chambered_tray}
          onClick={() => act('unload_tray')}
        >
          Unload Tray
        </Button>
        <Button.Confirm
          fluid
          icon="sign-in-alt"
          disabled={!!busy || !loaded_tray || !!chambered_tray}
          confirmContent="This cannot be undone until the cannon is fired. Confirm?"
          onClick={() => act('chamber_tray')}
        >
          Chamber Tray Payload
        </Button.Confirm>
      </Section>
      <Collapsible title="Check Fuel Requirements">
        <Section>
          {fuel_requirements.map((requirement) => (
            <Box key={requirement.name}>
              {requirement.name}: <b>{requirement.amount} Solid Fuel blocks.</b>
            </Box>
          ))}
        </Section>
      </Collapsible>
      {!!busy && (
        <Dimmer fontSize="24px">
          <Icon name="cog" spin mr={1} />
          Cannon busy...
        </Dimmer>
      )}
    </>
  );
};
