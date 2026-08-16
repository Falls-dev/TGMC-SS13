import { useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type PollOption = {
  ref: string;
  text: string;
  min_val: number;
  max_val: number;
  desc_min: string;
  desc_mid: string;
  desc_max: string;
};

type PollSummary = {
  ref: string;
  question: string;
  subtitle: string;
  poll_type: string;
  start_datetime: string;
  end_datetime: string;
  allow_revoting: BooleanLike;
  admin_only: BooleanLike;
  votes: number;
};

type PollDetail = {
  ref: string;
  question: string;
  subtitle: string;
  poll_type: string;
  start_datetime: string;
  end_datetime: string;
  allow_revoting: BooleanLike;
  options_allowed: number;
  options: PollOption[];
  voted_option_ref?: string | null;
  voted_option_refs?: string[];
  voted_ratings?: Record<string, number>;
  reply_text?: string;
};

type PollsData = {
  is_admin: BooleanLike;
  polls: PollSummary[];
  viewing: PollDetail | null;
};

const POLL_TYPE_LABELS: Record<string, string> = {
  OPTION: 'Single Choice',
  TEXT: 'Text Feedback',
  NUMVAL: 'Rating',
  MULTICHOICE: 'Multiple Choice',
  IRV: 'Ranked Choice',
};

export const Polls = () => {
  const { data } = useBackend<PollsData>();
  const { viewing } = data;

  return (
    <Window width={480} height={560} title="Player Polls">
      <Window.Content scrollable>
        {viewing ? (
          <PollDetailView key={viewing.ref} poll={viewing} />
        ) : (
          <PollListView />
        )}
      </Window.Content>
    </Window>
  );
};

const PollListView = () => {
  const { act, data } = useBackend<PollsData>();
  const { polls = [], is_admin } = data;

  return (
    <Section title="Active Polls">
      {polls.length === 0 && (
        <Box color="label">No polls are currently available.</Box>
      )}
      <Stack vertical>
        {polls.map((poll) => (
          <Stack.Item key={poll.ref}>
            <Button
              fluid
              textAlign="left"
              lineHeight={1.4}
              onClick={() => act('view_poll', { poll_ref: poll.ref })}
            >
              <Box bold>{poll.question}</Box>
              <Box fontSize="0.85em" color="label">
                {POLL_TYPE_LABELS[poll.poll_type] || poll.poll_type}
                {!!poll.admin_only && ' • Admin Only'}
                {poll.poll_type === 'IRV' && ' • Opens in a separate window'}
              </Box>
              <Box fontSize="0.8em" color="label">
                Runs {poll.start_datetime} — {poll.end_datetime}
              </Box>
            </Button>
          </Stack.Item>
        ))}
      </Stack>
      {!!is_admin && (
        <Box mt={2} fontSize="0.8em" color="label">
          Poll creation/editing is still managed from the admin panel.
        </Box>
      )}
    </Section>
  );
};

const PollDetailView = (props: { readonly poll: PollDetail }) => {
  const { poll } = props;
  const { act } = useBackend<PollsData>();

  return (
    <Section
      title={poll.question}
      buttons={
        <Button icon="arrow-left" onClick={() => act('back')}>
          Back
        </Button>
      }
    >
      {!!poll.subtitle && <Box mb={1}>{poll.subtitle}</Box>}
      <Box fontSize="0.85em" color="label" mb={2}>
        Runs from <b>{poll.start_datetime}</b> until <b>{poll.end_datetime}</b>
        {!!poll.allow_revoting && ' • Revoting is enabled'}
      </Box>
      {poll.poll_type === 'OPTION' && <OptionPoll poll={poll} />}
      {poll.poll_type === 'MULTICHOICE' && <MultiPoll poll={poll} />}
      {poll.poll_type === 'NUMVAL' && <RatingPoll poll={poll} />}
      {poll.poll_type === 'TEXT' && <TextPoll poll={poll} />}
    </Section>
  );
};

const OptionPoll = (props: { readonly poll: PollDetail }) => {
  const { poll } = props;
  const { act } = useBackend<PollsData>();
  const votedRef = poll.voted_option_ref;
  const locked = !!votedRef && !poll.allow_revoting;

  return (
    <Stack vertical>
      {poll.options.map((option) => (
        <Stack.Item key={option.ref}>
          <Button
            fluid
            color={votedRef === option.ref ? 'good' : undefined}
            icon={votedRef === option.ref ? 'check' : undefined}
            disabled={locked}
            onClick={() =>
              act('vote_option', {
                poll_ref: poll.ref,
                option_ref: option.ref,
              })
            }
          >
            {option.text}
          </Button>
        </Stack.Item>
      ))}
      {!!votedRef && (
        <Stack.Item>
          <Box color="good" fontSize="0.85em">
            You voted for this poll
            {poll.allow_revoting
              ? ' — click another option to change it.'
              : '.'}
          </Box>
        </Stack.Item>
      )}
    </Stack>
  );
};

const MultiPoll = (props: { readonly poll: PollDetail }) => {
  const { poll } = props;
  const { act } = useBackend<PollsData>();
  const votedRefs = poll.voted_option_refs ?? [];
  const hasVoted = votedRefs.length > 0;
  const locked = hasVoted && !poll.allow_revoting;
  const limit = poll.options_allowed || 1;
  const [selected, setSelected] = useState<string[]>(votedRefs);

  const toggle = (ref: string) => {
    if (locked) {
      return;
    }
    setSelected((prev) => {
      if (prev.includes(ref)) {
        return prev.filter((entry) => entry !== ref);
      }
      if (prev.length >= limit) {
        return [...prev.slice(1), ref];
      }
      return [...prev, ref];
    });
  };

  return (
    <Stack vertical>
      <Stack.Item fontSize="0.85em" color="label">
        Select up to {limit} option{limit === 1 ? '' : 's'}.
      </Stack.Item>
      {poll.options.map((option) => (
        <Stack.Item key={option.ref}>
          <Button.Checkbox
            checked={selected.includes(option.ref)}
            disabled={locked}
            onClick={() => toggle(option.ref)}
          >
            {option.text}
          </Button.Checkbox>
        </Stack.Item>
      ))}
      {!locked && (
        <Stack.Item>
          <Button
            fluid
            color="good"
            disabled={selected.length === 0}
            onClick={() =>
              act('vote_multi', { poll_ref: poll.ref, option_refs: selected })
            }
          >
            {hasVoted ? 'Update Vote' : 'Submit Vote'}
          </Button>
        </Stack.Item>
      )}
      {locked && (
        <Stack.Item>
          <Box color="good" fontSize="0.85em">
            You already voted on this poll.
          </Box>
        </Stack.Item>
      )}
    </Stack>
  );
};

const RatingPoll = (props: { readonly poll: PollDetail }) => {
  const { poll } = props;
  const { act } = useBackend<PollsData>();
  const votedRatings = poll.voted_ratings ?? {};
  const hasVoted = Object.keys(votedRatings).length > 0;
  const locked = hasVoted && !poll.allow_revoting;

  const [ratings, setRatings] = useState<Record<string, number>>(() => {
    const initial: Record<string, number> = {};
    poll.options.forEach((option) => {
      const mid = Math.round((option.min_val + option.max_val) / 2);
      initial[option.ref] = votedRatings[option.ref] ?? mid;
    });
    return initial;
  });

  return (
    <Stack vertical>
      {poll.options.map((option) => (
        <Stack.Item key={option.ref}>
          <LabeledList>
            <LabeledList.Item label={option.text}>
              <NumberInput
                width="60px"
                step={1}
                minValue={option.min_val}
                maxValue={option.max_val}
                value={ratings[option.ref]}
                disabled={locked}
                onChange={(value) =>
                  setRatings((prev) => ({ ...prev, [option.ref]: value }))
                }
              />
              {!!(option.desc_min || option.desc_mid || option.desc_max) && (
                <Box fontSize="0.8em" color="label" mt={0.5}>
                  {option.min_val}
                  {option.desc_min && ` (${option.desc_min})`} —{' '}
                  {option.max_val}
                  {option.desc_max && ` (${option.desc_max})`}
                </Box>
              )}
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      ))}
      {!locked && (
        <Stack.Item>
          <Button
            fluid
            color="good"
            onClick={() => act('vote_rating', { poll_ref: poll.ref, ratings })}
          >
            {hasVoted ? 'Update Ratings' : 'Submit Ratings'}
          </Button>
        </Stack.Item>
      )}
      {locked && (
        <Stack.Item>
          <Box color="good" fontSize="0.85em">
            You already submitted ratings for this poll.
          </Box>
        </Stack.Item>
      )}
    </Stack>
  );
};

const TextPoll = (props: { readonly poll: PollDetail }) => {
  const { poll } = props;
  const { act } = useBackend<PollsData>();
  const existing = poll.reply_text ?? '';
  const locked = !!existing && !poll.allow_revoting;
  const [text, setText] = useState(existing);

  return (
    <Stack vertical>
      <Stack.Item fontSize="0.85em" color="label">
        You can use letters, numbers and basic punctuation. Max 2048 characters.
      </Stack.Item>
      <Stack.Item>
        <TextArea
          fluid
          height="180px"
          value={text}
          disabled={locked}
          onChange={setText}
        />
      </Stack.Item>
      {!locked && (
        <Stack.Item>
          <Button
            fluid
            color="good"
            disabled={!text.trim()}
            onClick={() =>
              act('vote_text', { poll_ref: poll.ref, reply_text: text })
            }
          >
            {existing ? 'Update Response' : 'Submit'}
          </Button>
        </Stack.Item>
      )}
      {locked && (
        <Stack.Item>
          <Box color="good" fontSize="0.85em">
            You already responded to this poll.
          </Box>
        </Stack.Item>
      )}
    </Stack>
  );
};
