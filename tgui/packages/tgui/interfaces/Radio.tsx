import { toFixed } from 'tgui-core/math';
import { Box, Button, LabeledList, NumberInput, Section } from 'tgui-core/components';
import { type BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type RadioChannel = {
  name: string;
  status: BooleanLike;
  hotkey: string;
};

type Data = {
  broadcasting: BooleanLike;
  listening: BooleanLike;
  frequency: number;
  minFrequency: number;
  maxFrequency: number;
  freqlock: BooleanLike;
  channels: RadioChannel[];
  command: BooleanLike;
  useCommand: BooleanLike;
  subspace: BooleanLike;
  subspaceSwitchable: BooleanLike;
  headset: BooleanLike;
  headsetHudOn?: BooleanLike;
  slDirection?: BooleanLike;
};

export const Radio = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    freqlock,
    frequency,
    minFrequency,
    maxFrequency,
    listening,
    broadcasting,
    command,
    useCommand,
    subspace,
    subspaceSwitchable,
    headset,
    headsetHudOn,
    slDirection,
  } = data;

  const radioChannels = data.channels;

  let height = 106;
  if (subspace) {
    height += radioChannels.length > 0 ? radioChannels.length * 21 + 6 : 24;
  }
  if (headset) {
    height += 27;
  }

  return (
    <Window width={360} height={height}>
      <Window.Content>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Frequency">
              {freqlock ? (
                <Box inline color="light-gray">
                  {toFixed(frequency / 10, 1)} kHz
                </Box>
              ) : (
                <NumberInput
                  animated
                  unit="kHz"
                  step={0.2}
                  stepPixelSize={10}
                  minValue={minFrequency / 10}
                  maxValue={maxFrequency / 10}
                  value={frequency / 10}
                  format={(value) => toFixed(value, 1)}
                  onDrag={(value) =>
                    act('frequency', {
                      adjust: value - frequency / 10,
                    })
                  }
                />
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Audio">
              <Button
                textAlign="center"
                width="37px"
                icon={listening ? 'volume-up' : 'volume-mute'}
                selected={!!listening}
                onClick={() => act('listen')}
              />
              <Button
                textAlign="center"
                width="37px"
                icon={broadcasting ? 'microphone' : 'microphone-slash'}
                selected={!!broadcasting}
                onClick={() => act('broadcast')}
              />
              {!!command && (
                <Button
                  ml={1}
                  icon="bullhorn"
                  selected={!!useCommand}
                  onClick={() => act('command')}
                >
                  {`High volume ${useCommand ? 'ON' : 'OFF'}`}
                </Button>
              )}
              {!!subspaceSwitchable && (
                <Button
                  ml={1}
                  icon="bullhorn"
                  selected={!!subspace}
                  onClick={() => act('subspace')}
                >
                  {`Subspace Tx ${subspace ? 'ON' : 'OFF'}`}
                </Button>
              )}
            </LabeledList.Item>
            {!!subspace && (
              <LabeledList.Item label="Channels">
                {radioChannels.length === 0 && (
                  <Box inline color="bad">
                    No encryption keys installed.
                  </Box>
                )}
                {radioChannels.map((channel) => (
                  <Box key={channel.name}>
                    <Button
                      icon={channel.status ? 'check-square-o' : 'square-o'}
                      selected={!!channel.status}
                      onClick={() =>
                        act('channel', {
                          channel: channel.name,
                        })
                      }
                    >
                      {channel.name + ' '}
                      {channel.hotkey
                        ? '[' + channel.hotkey.toUpperCase() + ']'
                        : '[N/A]'}
                    </Button>
                  </Box>
                ))}
              </LabeledList.Item>
            )}
            {!!headset && (
              <LabeledList.Item label="Squad HUD">
                <Button
                  selected={!!headsetHudOn}
                  onClick={() => act('headset_hud')}
                >
                  {`Squad HUD ${headsetHudOn ? 'ON' : 'OFF'}`}
                </Button>
                <Button
                  ml={1}
                  selected={!!slDirection}
                  onClick={() => act('sl_direction')}
                >
                  {`SL Finder ${slDirection ? 'ON' : 'OFF'}`}
                </Button>
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
