import {
  Box,
  Button,
  Divider,
  Icon,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

export const SupplyDropConsole = (_props) => {
  const { act, data } = useBackend();
  const timeLeft = data.next_fire || 0;
  const launchCooldown = data.launch_cooldown || 1;
  const timeLeftPct = Math.min(1, Math.max(0, timeLeft / launchCooldown));
  const beacon = data.current_beacon || {};
  const hasSupplies = (data.supplies_count || 0) > 0;
  const isReadyToFire = timeLeft === 0;
  const hasTarget = Boolean(beacon.name || data.map_target_selected);
  const canFire = hasTarget && hasSupplies && isReadyToFire;
  const secondsLeft = Math.ceil(timeLeft / 10);

  return (
    <Window title="Консоль Сброса Снабжения" width={420} height={405}>
      <Window.Content className="theme-cargo">
        <Stack vertical fill spacing={1.5}>
          <Stack.Item>
            {!hasSupplies ? (
              <NoticeBox danger icon="exclamation-triangle">
                Площадка пуста! Разместите груз на платформе сброса.
              </NoticeBox>
            ) : !hasTarget ? (
              <NoticeBox warning icon="crosshairs">
                Цель не выбрана. Укажите координаты или маяк.
              </NoticeBox>
            ) : !isReadyToFire ? (
              <NoticeBox info icon="sync">
                Система перезаряжается. Готовность через {secondsLeft} сек.
              </NoticeBox>
            ) : (
              <NoticeBox success icon="check-circle">
                Система готова к запуску!
              </NoticeBox>
            )}
          </Stack.Item>

          <Stack.Item>
            <Section title="Наведение" icon="satellite-dish">
              <LabeledList>
                <LabeledList.Item label="Целевой маяк">
                  <Button
                    fluid
                    className="cargo-beacon-btn"
                    icon="broadcast-tower"
                    selected={Boolean(beacon.name)}
                    tooltip={beacon.name ? `Выбран маяк: ${beacon.name}` : 'Выбрать активный радиомаяк в зоне операции'}
                    onClick={() => act('select_beacon')}
                    style={{ overflow: 'hidden' }}
                  >
                    <Box
                      style={{
                        display: 'inline-block',
                        maxWidth: '220px',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        verticalAlign: 'bottom',
                      }}
                    >
                      {beacon.name ? beacon.name : 'Маяк не выбран'}
                    </Box>
                  </Button>
                </LabeledList.Item>

                <Divider />

                <LabeledList.Item label="Координата X">
                  <NumberInput
                    expensive
                    minValue={1}
                    maxValue={255}
                    value={data.target_x || 1}
                    unit="X"
                    onChange={(value) => act('set_x', { set_x: `${value}` })}
                  />
                </LabeledList.Item>

                <LabeledList.Item label="Координата Y">
                  <NumberInput
                    expensive
                    minValue={1}
                    maxValue={255}
                    value={data.target_y || 1}
                    unit="Y"
                    onChange={(value) => act('set_y', { set_y: `${value}` })}
                  />
                </LabeledList.Item>

                <LabeledList.Item label="Ручная наводка">
                  <Stack>
                    <Stack.Item grow={1}>
                      <Button
                        fluid
                        icon="crosshairs"
                        tooltip="Установить наведение по введенным X/Y координатам"
                        onClick={() => act('target_coordinates')}
                      >
                        По координатам
                      </Button>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="map-marked-alt"
                        tooltip="Открыть миникарту для выбора точки сброса"
                        onClick={() => act('open_map')}
                      >
                        Карта
                      </Button>
                    </Stack.Item>
                  </Stack>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section
              title="Платформа снабжения"
              icon="boxes-packing"
              buttons={
                <Button
                  icon="sync"
                  compact
                  tooltip="Обновить данные о предметах на платформе"
                  onClick={() => act('refresh_pad')}
                >
                  Обновить
                </Button>
              }
            >
              <Stack vertical spacing={1}>
                <Stack.Item>
                  <Box className="cargo-stat-badge">
                    <Icon name="box" mr={1} color={hasSupplies ? 'good' : 'bad'} />
                    <b>{data.supplies_count || 0}</b> предмет(ов) обнаружено на платформе.
                  </Box>
                </Stack.Item>

                <Stack.Item>
                  <Box color="label" fontSize="0.9em" ellipsis>
                    <Icon name="map-marker-alt" mr={1} />
                    {data.map_target_selected
                      ? `Цель на карте: (${data.map_target_x}, ${data.map_target_y})`
                      : beacon.name
                        ? `Координаты маяка: (${beacon.x_coords}, ${beacon.y_coords})`
                        : 'Точка сброса не задана'}
                  </Box>
                </Stack.Item>

                <Stack.Item>
                  <ProgressBar
                    width="100%"
                    value={timeLeftPct}
                    ranges={{
                      good: [-Infinity, 0.1],
                      average: [0.1, 0.6],
                      bad: [0.6, Infinity],
                    }}
                  >
                    {isReadyToFire
                      ? 'Перезарядка завершена'
                      : `Осталось: ${secondsLeft} сек.`}
                  </ProgressBar>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Button
              fluid
              bold
              disabled={!canFire}
              color={canFire ? 'good' : 'bad'}
              icon="rocket"
              style={{ fontSize: '1.2em', padding: '6px' }}
              tooltip={
                !canFire
                  ? 'Запуск недоступен: проверьте груз, выбор цели и перезарядку'
                  : 'Запустить капсулу снабжения в указанную точку'
              }
              onClick={() => act('send_beacon')}
            >
              Сброс груза
            </Button>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
