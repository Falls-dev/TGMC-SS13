import { Button, LabeledList, ProgressBar, Section } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  flush: BooleanLike;
  full_pressure: BooleanLike;
  pressure_charging: BooleanLike;
  panel_open: BooleanLike;
  per: number;
  isai: BooleanLike;
};

export const DisposalUnit = (props) => {
  const { act, data } = useBackend<Data>();
  const { flush, full_pressure, pressure_charging, panel_open, per, isai } =
    data;

  let stateColor: string;
  let stateText: string;
  if (full_pressure) {
    stateColor = 'good';
    stateText = 'Ready';
  } else if (panel_open) {
    stateColor = 'bad';
    stateText = 'Power Disabled';
  } else if (pressure_charging) {
    stateColor = 'average';
    stateText = 'Pressurizing';
  } else {
    stateColor = 'bad';
    stateText = 'Off';
  }

  return (
    <Window width={300} height={180}>
      <Window.Content>
        <Section>
          <LabeledList>
            <LabeledList.Item label="State" color={stateColor}>
              {stateText}
            </LabeledList.Item>
            <LabeledList.Item label="Pressure">
              <ProgressBar value={per} color="good" />
            </LabeledList.Item>
            <LabeledList.Item label="Handle">
              <Button
                icon={flush ? 'toggle-on' : 'toggle-off'}
                disabled={!!isai || !!panel_open}
                content={flush ? 'Disengage' : 'Engage'}
                onClick={() => act(flush ? 'handle-0' : 'handle-1')}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Eject">
              <Button
                icon="sign-out-alt"
                disabled={!!isai}
                content="Eject Contents"
                onClick={() => act('eject')}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Power">
              <Button
                icon="power-off"
                disabled={!!panel_open}
                selected={!!pressure_charging}
                onClick={() =>
                  act(pressure_charging ? 'pump-0' : 'pump-1')
                }
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
