import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

/**
 * Показывается только игрокам в лобби (/mob/new_player), когда начинается
 * End Of Round Deathmatch. Действия вызывают те же do_eord_respawn()/do_xeno_eord_respawn(),
 * что и OOC-глаголы «EORD Respawn» / «EORD Xeno Respawn».
 */
export function EORDMenu(props) {
  const { act } = useBackend();

  return (
    <Window width={420} height={310} title="Конец раунда">
      <Window.Content>
        <Section fill>
          <Stack vertical fill>
            <Stack.Item>
              <Box bold fontSize="1.2em" mb={1}>
                Раунд завершён!
              </Box>
              <Box color="label">
                Вы можете спокойно дождаться начала следующего раунда или
                вернуться в бой в Deathmatch в конце раунда.
              </Box>
            </Stack.Item>
            <Stack.Item grow />
            <Stack.Item>
              <Stack vertical>
                <Stack.Item>
                  <Button fluid icon="clock" onClick={() => act('wait')}>
                    Ждать в лобби следующий раунд
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    fluid
                    color="good"
                    icon="user"
                    onClick={() => act('join_human')}
                  >
                    Присоединиться к EORD за человека
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    fluid
                    color="bad"
                    icon="biohazard"
                    onClick={() => act('join_xeno')}
                  >
                    Присоединиться к EORD за ксеноморфа
                  </Button>
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
}
