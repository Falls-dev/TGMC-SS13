import {
  Box,
  Button,
  Flex,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  authenticated: number | BooleanLike;
  current_orbit: number;
  power_amount: number;
  engines_ready: BooleanLike;
  can_change_orbit: BooleanLike;
  changing_orbit: BooleanLike;
  ship_map_name: string;
  required_power: number;
  high_orbit: number;
  standard_orbit: number;
  low_orbit: number;
};

export const NavigationConsole = () => {
  const { data } = useBackend<Data>();
  const { authenticated } = data;

  return (
    <Window width={420} height={360} title="Navigation">
      <Window.Content>
        {!authenticated ? <LoginPage /> : <MainPage />}
      </Window.Content>
    </Window>
  );
};

const LoginPage = () => {
  const { act } = useBackend<Data>();
  return (
    <Section title="Authentication">
      <Button fluid icon="sign-in-alt" onClick={() => act('login')}>
        LOG IN
      </Button>
    </Section>
  );
};

const MainPage = () => {
  const { act, data } = useBackend<Data>();
  const {
    ship_map_name,
    current_orbit,
    power_amount,
    engines_ready,
    can_change_orbit,
    changing_orbit,
    required_power,
    high_orbit,
    low_orbit,
  } = data;

  const atHighOrbit = current_orbit >= high_orbit;
  const atLowOrbit = current_orbit <= low_orbit;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section
          title={ship_map_name}
          buttons={
            <Button icon="sign-out-alt" onClick={() => act('logout')}>
              LOG OUT
            </Button>
          }
        >
          <Box textAlign="center" fontSize="28px" mb={1} bold>
            {current_orbit}
          </Box>
          <LabeledList>
            <LabeledList.Item label="Power Level">
              {Math.round(power_amount)}
            </LabeledList.Item>
            <LabeledList.Item label="Engines prepared">
              {engines_ready ? (
                <Box color="good">Ready</Box>
              ) : (
                <Box color="average">Recalculating</Box>
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Required Power">
              {required_power}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section title="Orbital Control" fill>
          {!!changing_orbit && (
            <NoticeBox>Orbit change in progress.</NoticeBox>
          )}
          {!can_change_orbit ? (
            <NoticeBox color="bad">
              Insufficient Power Reserves to change orbit
            </NoticeBox>
          ) : (
            <Flex>
              <Flex.Item grow>
                <Button
                  fluid
                  icon="arrow-up"
                  disabled={!engines_ready || atHighOrbit}
                  tooltip={
                    atHighOrbit
                      ? 'Already at the highest orbit.'
                      : !engines_ready
                        ? 'Engines are recalculating.'
                        : undefined
                  }
                  onClick={() => act('UP')}
                >
                  Increase orbital level
                </Button>
              </Flex.Item>
              <Flex.Item grow>
                <Button
                  fluid
                  icon="arrow-down"
                  disabled={!engines_ready || atLowOrbit}
                  tooltip={
                    atLowOrbit
                      ? 'Already at the lowest orbit.'
                      : !engines_ready
                        ? 'Engines are recalculating.'
                        : undefined
                  }
                  onClick={() => act('DOWN')}
                >
                  Decrease orbital level
                </Button>
              </Flex.Item>
            </Flex>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};
