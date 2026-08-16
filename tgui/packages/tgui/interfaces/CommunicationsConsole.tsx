import {
  Box,
  Button,
  Collapsible,
  Divider,
  Flex,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Message = {
  title: string;
  text: string;
  number: number;
};

type AlertLevelOption = {
  name: string;
  ref: string;
};

type Data = {
  authenticated: number;
  page: string;
  worldtime: number;
  alert_level: number;
  alert_level_text: string;
  tmp_alertlevel: number;
  tmp_alertlevel_text: string;
  evac_status: number;
  dest_status: number;
  evac_eta?: string;
  time_message: number | BooleanLike;
  time_request: number | BooleanLike;
  time_central: number | BooleanLike;
  stat_msg1?: string;
  stat_msg2?: string;
  admins_online: BooleanLike;
  cannot_switch_alert: BooleanLike;
  state_of_emergency: BooleanLike;
  available_alert_levels: AlertLevelOption[];
  messages: Message[] | null;
  current_message: Message | null;
  cooldown_request: number;
  cooldown_central: number;
  cooldown_message: number;
  evacuation_time_lock: number;
  ert_allowed: BooleanLike;
  ship_map_name: string;
};

const SEC_LEVEL_GREEN = 1;
const SEC_LEVEL_BLUE = 2;
const SEC_LEVEL_RED = 3;
const SEC_LEVEL_DELTA = 4;

const EVAC_STANDING_BY = 0;
const EVAC_INITIATING = 1;
const EVAC_IN_PROGRESS = 2;
const EVAC_COMPLETE = 3;

const PAGE_MAIN = 'main';
const PAGE_MESSAGES = 'messages';
const PAGE_VIEW_MESSAGE = 'viewmessage';
const PAGE_STATUS = 'status';
const PAGE_ALERT = 'alert';
const PAGE_CONFIRM_ALERT = 'confirm_alert';

const alertColor = (level: number) => {
  switch (level) {
    case SEC_LEVEL_DELTA:
      return 'purple';
    case SEC_LEVEL_RED:
      return 'red';
    case SEC_LEVEL_BLUE:
      return 'blue';
    case SEC_LEVEL_GREEN:
      return 'green';
    default:
      return undefined;
  }
};

const cooldownRemaining = (
  lastUsed: number | BooleanLike,
  worldTime: number,
  length: number,
) => {
  if (!lastUsed || typeof lastUsed !== 'number') {
    return 0;
  }
  return Math.max(0, Math.ceil((lastUsed + length - worldTime) / 10));
};

export const CommunicationsConsole = () => {
  const { data } = useBackend<Data>();
  const { authenticated, page } = data;

  return (
    <Window width={450} height={700} title="Communications Console">
      <Window.Content scrollable>
        {!authenticated && <LoginPage />}
        {!!authenticated && page === PAGE_MAIN && <MainPage />}
        {!!authenticated && page === PAGE_ALERT && <AlertPage />}
        {!!authenticated && page === PAGE_CONFIRM_ALERT && <ConfirmAlertPage />}
        {!!authenticated && page === PAGE_STATUS && <StatusPage />}
        {!!authenticated && page === PAGE_MESSAGES && <MessagesPage />}
        {!!authenticated && page === PAGE_VIEW_MESSAGE && <ViewMessagePage />}
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

const MainMenuButton = () => {
  const { act } = useBackend<Data>();
  return (
    <Button fluid icon="arrow-left" onClick={() => act('main')}>
      Main Menu
    </Button>
  );
};

const MainPage = () => {
  const { act, data } = useBackend<Data>();
  const {
    authenticated,
    alert_level,
    alert_level_text,
    worldtime,
    time_message,
    time_central,
    time_request,
    cooldown_message,
    cooldown_central,
    cooldown_request,
    evacuation_time_lock,
    evac_status,
    evac_eta,
    ert_allowed,
    admins_online,
    messages,
    ship_map_name,
  } = data;

  const announceSecs = cooldownRemaining(
    time_message,
    worldtime,
    cooldown_message,
  );
  const centralSecs = cooldownRemaining(
    time_central,
    worldtime,
    cooldown_central,
  );
  const requestSecs = cooldownRemaining(
    time_request,
    worldtime,
    cooldown_request,
  );
  const evacLockSecs = Math.max(
    0,
    Math.ceil((evacuation_time_lock - worldtime) / 10),
  );

  const canAnnounce = announceSecs <= 0;
  const canCentral = centralSecs <= 0 && !!admins_online;
  const canEvac =
    evac_status === EVAC_STANDING_BY && alert_level >= SEC_LEVEL_RED;
  const canDistress =
    !!ert_allowed &&
    alert_level >= SEC_LEVEL_RED &&
    alert_level < SEC_LEVEL_DELTA &&
    requestSecs <= 0;

  let distressReason = '';
  if (!ert_allowed) {
    distressReason = 'Distress beacon is disabled.';
  } else if (alert_level >= SEC_LEVEL_DELTA) {
    distressReason = 'Self-destruct in progress. Beacon disabled.';
  } else if (alert_level < SEC_LEVEL_RED) {
    distressReason = 'Ship is not under an active emergency.';
  } else if (requestSecs > 0) {
    distressReason = `Beacon is currently recharging. Time remaining: ${requestSecs} secs.`;
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <Section
          title="Ship Control"
          buttons={
            <Button icon="sign-out-alt" onClick={() => act('logout')}>
              LOG OUT
            </Button>
          }
        >
          <Flex direction="column">
            <Flex.Item>
              <Button
                fluid
                color={alertColor(alert_level)}
                icon="triangle-exclamation"
                onClick={() => act('changeseclevel')}
              >
                Change alert level; current: {alert_level_text.toUpperCase()}
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button fluid icon="tv" onClick={() => act('status')}>
                Set status display
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button fluid icon="envelope" onClick={() => act('messagelist')}>
                Message list
              </Button>
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>

      {authenticated >= 2 && (
        <Stack.Item>
          <Section title="Command">
            <Flex direction="column">
              <Flex.Item>
                {!canAnnounce ? (
                  <Button color="bad" fluid icon="ban">
                    Announcement recharging: {announceSecs} secs
                  </Button>
                ) : (
                  <Button
                    fluid
                    icon="bullhorn"
                    onClick={() => act('announce')}
                  >
                    Make an announcement
                  </Button>
                )}
              </Flex.Item>
              <Flex.Item>
                {!admins_online ? (
                  <Button color="bad" fluid icon="ban">
                    TGMC communication offline
                  </Button>
                ) : !canCentral ? (
                  <Button color="bad" fluid icon="ban">
                    Quantum relay re-cycling: {centralSecs} secs
                  </Button>
                ) : (
                  <Button
                    fluid
                    icon="paper-plane"
                    onClick={() => act('messageTGMC')}
                  >
                    Send a message to TGMC
                  </Button>
                )}
              </Flex.Item>
              <Flex.Item>
                <Button fluid icon="medal" onClick={() => act('award')}>
                  Award a medal
                </Button>
              </Flex.Item>
            </Flex>
          </Section>
        </Stack.Item>
      )}

      {authenticated >= 2 && (
        <Stack.Item>
          <Section title="Emergency measures">
            {alert_level < SEC_LEVEL_RED && (
              <NoticeBox color="bad" textAlign="center">
                The ship must be under red alert in order to enact evacuation
                procedures.
              </NoticeBox>
            )}
            {evac_status === EVAC_STANDING_BY && (
              <Button.Confirm
                fluid
                color="orange"
                icon="door-open"
                confirmColor="bad"
                confirmContent={`Evacuate ${ship_map_name}?`}
                confirmIcon="question"
                disabled={!canEvac || evacLockSecs > 0}
                tooltip={
                  evacLockSecs > 0
                    ? `Evacuation locked for ${Math.ceil(evacLockSecs / 60)} more minutes.`
                    : undefined
                }
                onClick={() => act('evacuation_start')}
              >
                Initiate emergency evacuation
              </Button.Confirm>
            )}
            {evac_status === EVAC_INITIATING && (
              <>
                <NoticeBox color="good" textAlign="center">
                  Evacuation ongoing
                  {evac_eta ? `. ETA: ${evac_eta}` : '.'}
                </NoticeBox>
                <Button.Confirm
                  fluid
                  color="red"
                  icon="ban"
                  confirmColor="bad"
                  confirmContent="Cancel Delta Alert?"
                  confirmIcon="question"
                  onClick={() => act('delta_cancel')}
                >
                  Cancel Delta Alert
                </Button.Confirm>
              </>
            )}
            {evac_status === EVAC_IN_PROGRESS && (
              <NoticeBox color="good" textAlign="center">
                Escape pods launching.
              </NoticeBox>
            )}
            {evac_status === EVAC_COMPLETE && (
              <NoticeBox color="good" textAlign="center">
                Evacuation complete.
              </NoticeBox>
            )}
            {!!ert_allowed &&
              (!canDistress ? (
                <Button
                  disabled
                  tooltip={distressReason}
                  fluid
                  icon="ban"
                >
                  Distress Beacon disabled
                </Button>
              ) : (
                <Button.Confirm
                  fluid
                  color="orange"
                  icon="phone-volume"
                  confirmColor="bad"
                  confirmContent="Confirm distress signal?"
                  confirmIcon="question"
                  onClick={() => act('distress')}
                >
                  Send Distress Beacon
                </Button.Confirm>
              ))}
          </Section>
        </Stack.Item>
      )}

      {messages && (
        <Stack.Item>
          <Divider />
          <Collapsible title="Messages">
            <Flex direction="column">
              {messages.map((entry) => (
                <Flex.Item key={entry.number}>
                  <Section
                    title={entry.title}
                    buttons={
                      <Button
                        color="red"
                        icon="trash"
                        onClick={() =>
                          act('delmessage', { number: entry.number })
                        }
                      >
                        Delete
                      </Button>
                    }
                  >
                    <Box>{entry.text}</Box>
                  </Section>
                </Flex.Item>
              ))}
            </Flex>
          </Collapsible>
        </Stack.Item>
      )}
    </Stack>
  );
};

const AlertPage = () => {
  const { act, data } = useBackend<Data>();
  const {
    alert_level_text,
    available_alert_levels,
    cannot_switch_alert,
    state_of_emergency,
    dest_status,
    evac_status,
  } = data;

  return (
    <Section title="Change alert level" buttons={<MainMenuButton />}>
      <Box mb={1}>
        Current alert level: <b>{alert_level_text}</b>
      </Box>
      {!!state_of_emergency && (
        <>
          {dest_status >= 1 && (
            <NoticeBox color="bad">
              The self-destruct mechanism is active.
              {evac_status !== EVAC_INITIATING
                ? ' You have to manually deactivate the self-destruct mechanism.'
                : ''}
            </NoticeBox>
          )}
          {evac_status === EVAC_INITIATING && (
            <NoticeBox color="bad">
              Evacuation initiated. Evacuate or rescind evacuation orders.
            </NoticeBox>
          )}
          {evac_status === EVAC_IN_PROGRESS && (
            <NoticeBox color="bad">Evacuation in progress.</NoticeBox>
          )}
          {evac_status === EVAC_COMPLETE && (
            <NoticeBox color="bad">Evacuation complete.</NoticeBox>
          )}
        </>
      )}
      {!!cannot_switch_alert && (
        <NoticeBox>Alert level cannot be changed right now.</NoticeBox>
      )}
      {!cannot_switch_alert &&
        available_alert_levels.map((level) => (
          <Button
            key={level.ref}
            fluid
            onClick={() =>
              act('securitylevel', { newalertlevel: level.ref })
            }
          >
            {level.name}
          </Button>
        ))}
    </Section>
  );
};

const ConfirmAlertPage = () => {
  const { act, data } = useBackend<Data>();
  const { alert_level_text, tmp_alertlevel_text } = data;

  return (
    <Section title="Confirm alert change" buttons={<MainMenuButton />}>
      <LabeledList>
        <LabeledList.Item label="Current alert level">
          {alert_level_text}
        </LabeledList.Item>
        <LabeledList.Item label="Confirm the change to">
          {tmp_alertlevel_text}
        </LabeledList.Item>
      </LabeledList>
      <Box mt={1} mb={1}>
        Swipe ID to confirm change.
      </Box>
      <Button fluid icon="id-card" onClick={() => act('swipeidseclevel')}>
        Swipe ID
      </Button>
    </Section>
  );
};

const StatusPage = () => {
  const { act, data } = useBackend<Data>();
  const { stat_msg1, stat_msg2 } = data;

  return (
    <Section title="Set Status Displays" buttons={<MainMenuButton />}>
      <Flex direction="column">
        <Flex.Item>
          <Button
            fluid
            icon="ban"
            onClick={() => act('setstat', { statdisp: 'blank' })}
          >
            Clear
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            fluid
            icon="clock"
            onClick={() => act('setstat', { statdisp: 'time' })}
          >
            Station Time
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            fluid
            icon="shuttle-space"
            onClick={() => act('setstat', { statdisp: 'shuttle' })}
          >
            Shuttle ETA
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            fluid
            icon="comment"
            onClick={() => act('setstat', { statdisp: 'message' })}
          >
            Message
          </Button>
        </Flex.Item>
      </Flex>
      <LabeledList>
        <LabeledList.Item label="Line 1">
          <Button onClick={() => act('setmsg1')}>
            {stat_msg1 || '(none)'}
          </Button>
        </LabeledList.Item>
        <LabeledList.Item label="Line 2">
          <Button onClick={() => act('setmsg2')}>
            {stat_msg2 || '(none)'}
          </Button>
        </LabeledList.Item>
      </LabeledList>
      <Box mt={1} mb={1}>
        Alert:
      </Box>
      <Flex>
        <Flex.Item grow>
          <Button
            fluid
            onClick={() =>
              act('setstat', { statdisp: 'alert', alert: 'default' })
            }
          >
            None
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            color="red"
            onClick={() =>
              act('setstat', { statdisp: 'alert', alert: 'redalert' })
            }
          >
            Red Alert
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            onClick={() =>
              act('setstat', { statdisp: 'alert', alert: 'lockdown' })
            }
          >
            Lockdown
          </Button>
        </Flex.Item>
        <Flex.Item grow>
          <Button
            fluid
            color="orange"
            onClick={() =>
              act('setstat', { statdisp: 'alert', alert: 'biohazard' })
            }
          >
            Biohazard
          </Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const MessagesPage = () => {
  const { act, data } = useBackend<Data>();
  const { messages } = data;

  return (
    <Section title="Messages" buttons={<MainMenuButton />}>
      {!messages && <NoticeBox>No messages.</NoticeBox>}
      {messages?.map((entry) => (
        <Button
          key={entry.number}
          fluid
          onClick={() =>
            act('viewmessage', { 'message-num': entry.number })
          }
        >
          {entry.title}
        </Button>
      ))}
    </Section>
  );
};

const ViewMessagePage = () => {
  const { act, data } = useBackend<Data>();
  const { current_message } = data;

  if (!current_message) {
    return (
      <Section title="Message" buttons={<MainMenuButton />}>
        <NoticeBox>Message not found.</NoticeBox>
      </Section>
    );
  }

  return (
    <Section
      title={current_message.title}
      buttons={
        <>
          <Button.Confirm
            color="red"
            icon="trash"
            confirmContent="Delete?"
            onClick={() =>
              act('delmessage', { number: current_message.number })
            }
          >
            Delete
          </Button.Confirm>
          <MainMenuButton />
        </>
      }
    >
      <Box>{current_message.text}</Box>
      <Box mt={1}>
        <Button
          icon="list"
          onClick={() => act('messagelist')}
        >
          Back to list
        </Button>
      </Box>
    </Section>
  );
};
