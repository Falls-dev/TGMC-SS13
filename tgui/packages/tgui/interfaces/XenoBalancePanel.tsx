import { Button, LabeledList, NoticeBox, NumberInput, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  current_buff: number;
  is_automatic_on: boolean;
  current_state: number;
  state_name: string;
  current_points: number;
  burrowed: number;
  alive_xenos: number;
  humans_on_ground: number;
  humans_on_ship: number;
};

export const XenoBalancePanel = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    current_buff,
    is_automatic_on,
    state_name,
    current_points,
    burrowed,
    alive_xenos,
    humans_on_ground,
    humans_on_ship,
  } = data;

  const buffPercent = Math.round(current_buff * 100);

  return (
    <Window title="Управление баффом ксен" width={480} height={335}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <NoticeBox info>
              Текущий множитель: <b>{buffPercent}%</b>
            </NoticeBox>
          </Stack.Item>

          <Stack.Item>
            <Section title="Состояние игры">
              <Stack>
                <Stack.Item basis="50%">
                  <LabeledList>
                    <LabeledList.Item label="Состояние">{state_name}</LabeledList.Item>
                    <LabeledList.Item label="Очки">{current_points?.toFixed(1)}</LabeledList.Item>
                    <LabeledList.Item label="Ксены + миньоны">{alive_xenos}</LabeledList.Item>
                    <LabeledList.Item label="Закопанные лярвы">{burrowed}</LabeledList.Item>
                  </LabeledList>
                </Stack.Item>

                <Stack.Item basis="50%">
                  <LabeledList>
                    <LabeledList.Item label="Марины на земле">{humans_on_ground}</LabeledList.Item>
                    <LabeledList.Item label="Марины на корабле">{humans_on_ship}</LabeledList.Item>
                  </LabeledList>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Управление балансом">
              <Stack align="center">
                <Stack.Item>
                  <NumberInput
                    width={8}
                    value={buffPercent}
                    minValue={10}
                    maxValue={500}
                    step={5}
                    unit="%"
                    onChange={(value) => act('set_buff', { value })}
                  />
                </Stack.Item>

                <Stack.Item grow>
                  <Button
                    fluid
                    icon={is_automatic_on ? 'toggle-on' : 'toggle-off'}
                    color={is_automatic_on ? 'good' : 'bad'}
                    onClick={() => act('toggle_auto')}
                  >
                    Автобаланс: {is_automatic_on ? 'Вкл' : 'Выкл'}
                  </Button>
                </Stack.Item>

                <Stack.Item>
                  <Button icon="undo" onClick={() => act('reset')}>
                    Сброс 100%
                  </Button>
                </Stack.Item>
              </Stack>

              <NoticeBox mt={1}>
                100% - базовые статы ксенов.
                <br />
                200% - здоровье, реген и урон в ближнем бою удваиваются.
              </NoticeBox>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
