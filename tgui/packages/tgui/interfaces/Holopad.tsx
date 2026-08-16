import {
  Box,
  Button,
  Flex,
  Icon,
  LabeledList,
  Modal,
  Section,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type HoloCall = {
  ref: string;
  caller: string;
  connected: BooleanLike;
};

type Data = {
  on_network: BooleanLike;
  on_cooldown: BooleanLike;
  calling: BooleanLike;
  holo_calls: HoloCall[];
};

export const Holopad = (props) => {
  const { act, data } = useBackend<Data>();
  const { calling } = data;

  return (
    <Window width={420} height={220}>
      {!!calling && (
        <Modal fontSize="36px" fontFamily="monospace">
          <Flex align="center">
            <Flex.Item mr={2} mt={2}>
              <Icon name="phone-alt" rotation={25} />
            </Flex.Item>
            <Flex.Item mr={2}>Dialing...</Flex.Item>
          </Flex>
          <Box mt={2} textAlign="center" fontSize="24px">
            <Button
              lineHeight="40px"
              icon="times"
              content="Hang Up"
              color="bad"
              onClick={() => act('hang_up')}
            />
          </Box>
        </Modal>
      )}
      <Window.Content scrollable>
        <HolopadContent />
      </Window.Content>
    </Window>
  );
};

const HolopadContent = (props) => {
  const { act, data } = useBackend<Data>();
  const { on_network, on_cooldown, holo_calls = [] } = data;

  return (
    <Section
      title="Holopad"
      buttons={
        <Button
          icon="bell"
          content={
            on_cooldown ? "AI's Presence Requested" : "Request AI's Presence"
          }
          disabled={!on_network || !!on_cooldown}
          onClick={() => act('AIrequest')}
        />
      }
    >
      <LabeledList>
        <LabeledList.Item label="Communicator">
          <Button
            icon="phone-alt"
            content="Call Holopad"
            disabled={!on_network}
            onClick={() => act('holocall')}
          />
        </LabeledList.Item>
        {holo_calls.map((call) => (
          <LabeledList.Item
            label={call.connected ? 'Current Call' : 'Incoming Call'}
            key={call.ref}
          >
            <Button
              icon={call.connected ? 'phone-slash' : 'phone-alt'}
              content={
                call.connected
                  ? `Disconnect call from ${call.caller}`
                  : `Answer call from ${call.caller}`
              }
              color={call.connected ? 'bad' : 'good'}
              disabled={!on_network}
              onClick={() =>
                act(call.connected ? 'disconnectcall' : 'connectcall', {
                  call: call.ref,
                })
              }
            />
          </LabeledList.Item>
        ))}
        {holo_calls.filter((call) => !call.connected).length > 0 && (
          <LabeledList.Item key="reject">
            <Button
              icon="phone-slash"
              content="Reject incoming call(s)"
              color="bad"
              onClick={() => act('rejectall')}
            />
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};
