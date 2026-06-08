import {
  Box,
  Button,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type NukeDiskProps = {
  message: string;
  progress: number;
  time_left: number;
  flavor_text: string;
  running: BooleanLike;
  segment_time: number;
  color: string;
};

export const NukeDiskGenerator = (props) => {
  const { act, data } = useBackend<NukeDiskProps>();
  const {
    message,
    progress,
    time_left,
    flavor_text,
    running,
    segment_time,
    color,
  } = data;
  return (
    <Window title="Nuke Disk Generator" width={450} height={250}>
      <Window.Content>
        <Section title="Запустить генерацию">
          <Stack fill vertical>
            <Stack.Item>
              <NoticeBox>{flavor_text}</NoticeBox>
            </Stack.Item>
            <Stack.Item>
              <Box width="100%" textAlign="center">
                Прогресс генерации:
                <ProgressBar value={progress} color={color} />
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Box width="100%" textAlign="center">
                {running ? (
                  <NoticeBox danger>
                    <Box>
                      Осталось: {time_left} сек.
                      <ProgressBar
                        minValue={0}
                        maxValue={segment_time}
                        value={time_left * 10}
                      />
                    </Box>
                    <Box>{message}</Box>
                  </NoticeBox>
                ) : (
                  <NoticeBox>{message}</NoticeBox>
                )}
                <Button disabled={running} onClick={() => act('run_program')}>
                  Запустить генерацию
                </Button>
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
