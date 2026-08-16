import { Box, Button, NoticeBox, Section, Stack } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type SquadEntry = {
  name: string;
  color: string;
};

type Data = {
  id_name: string;
  has_id: BooleanLike;
  squads: SquadEntry[];
};

export const SquadMod = () => {
  const { act, data } = useBackend<Data>();
  const { squads = [], id_name, has_id } = data;

  return (
    <Window width={400} height={360} title="Squad Distribution">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section>
              <Button fluid icon="eject" onClick={() => act('PRG_eject')}>
                {id_name}
              </Button>
              {!has_id && (
                <NoticeBox mt={1}>
                  Insert the ID of the person you want to transfer.
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>
          {!!has_id && (
            <Stack.Item grow>
              <Section title="Squad Transfer" fill scrollable>
                {!squads.length && (
                  <Box color="label">No available squads.</Box>
                )}
                {squads.map((entry) => (
                  <Button
                    key={entry.name}
                    fluid
                    backgroundColor={entry.color}
                    onClick={() => act('PRG_squad', { name: entry.name })}
                  >
                    {entry.name}
                  </Button>
                ))}
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
