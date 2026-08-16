import { Box, Button, LabeledList, ProgressBar, Section } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  enemy_name: string;
  temp: string;
  player_hp: number;
  player_mp: number;
  enemy_hp: number;
  enemy_mp: number;
  gameover: BooleanLike;
  blocked: BooleanLike;
};

export const Arcade = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    enemy_name,
    temp,
    player_hp,
    player_mp,
    enemy_hp,
    enemy_mp,
    gameover,
    blocked,
  } = data;

  return (
    <Window width={380} height={280} title="Black Donnovan II: Double Revenge">
      <Window.Content>
        <Section title={enemy_name} align="center">
          <Box color="label" mb={1}>
            {temp}
          </Box>
          <LabeledList>
            <LabeledList.Item label="Your Health">
              <ProgressBar
                value={player_hp / 30}
                ranges={{
                  good: [0.5, Infinity],
                  average: [0.25, 0.5],
                  bad: [-Infinity, 0.25],
                }}
              >
                {player_hp}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Your Magic">
              <ProgressBar value={player_mp / 10} color="blue">
                {player_mp}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label={`${enemy_name}'s Health`}>
              <ProgressBar
                value={enemy_hp / 45}
                ranges={{
                  good: [-Infinity, 0.25],
                  average: [0.25, 0.5],
                  bad: [0.5, Infinity],
                }}
              >
                {Math.max(enemy_hp, 0)}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label={`${enemy_name}'s Magic`}>
              <ProgressBar value={enemy_mp / 20} color="orange">
                {Math.max(enemy_mp, 0)}
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section align="center">
          {gameover ? (
            <Button icon="rotate-right" onClick={() => act('newgame')}>
              New Game
            </Button>
          ) : (
            <>
              <Button
                icon="sword"
                disabled={!!blocked}
                onClick={() => act('attack')}
              >
                Attack
              </Button>
              <Button
                icon="heart"
                disabled={!!blocked}
                onClick={() => act('heal')}
              >
                Heal
              </Button>
              <Button
                icon="bolt"
                disabled={!!blocked}
                onClick={() => act('charge')}
              >
                Recharge Power
              </Button>
            </>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
