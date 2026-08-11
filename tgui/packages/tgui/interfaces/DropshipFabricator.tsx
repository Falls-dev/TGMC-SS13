import { useState } from 'react';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { type BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type FabricatorItem = {
  id: string;
  name: string;
  desc: string;
  cost: number;
};

type FabricatorCategory = {
  name: string;
  items: FabricatorItem[];
};

type QueueItem = {
  name: string;
};

type DropshipFabricatorData = {
  points: number;
  busy: BooleanLike;
  nopower: BooleanLike;
  printing: string | null;
  queue: QueueItem[];
  categories: FabricatorCategory[];
};

export const DropshipFabricator = (props) => {
  const { data } = useBackend<DropshipFabricatorData>();
  const { points, nopower } = data;
  const [searchText, setSearchText] = useState('');

  return (
    <Window title="Dropship Part Fabricator" width={520} height={620}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section
              title="Fabricator Status"
              buttons={
                <Box bold fontSize="16px" color={nopower ? 'bad' : 'good'}>
                  {points} Points Available
                </Box>
              }
            >
              {!!nopower && (
                <NoticeBox danger>Fabricator has no power!</NoticeBox>
              )}
              <Input
                fluid
                placeholder="Search parts..."
                value={searchText}
                onChange={(value) => setSearchText(value)}
              />
            </Section>
          </Stack.Item>
          <Stack.Item>
            <FabricatingStatus />
          </Stack.Item>
          <Stack.Item grow>
            <FabricatorCatalog searchText={searchText} />
          </Stack.Item>
          <Stack.Item>
            <FabricatorQueue />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const FabricatingStatus = (props) => {
  const { data } = useBackend<DropshipFabricatorData>();
  const { busy, printing } = data;
  return (
    <Section title="Fabricating">
      {busy ? (
        <Box color="average">
          <Box className="fa fa-cog fa-spin" mr={1} inline />
          {printing || 'Unknown part'}
        </Box>
      ) : (
        <Box color="label">Idle</Box>
      )}
    </Section>
  );
};

const FabricatorQueue = (props) => {
  const { act, data } = useBackend<DropshipFabricatorData>();
  const { queue } = data;
  return (
    <Section
      title="Production Queue"
      buttons={
        <Button
          icon="trash"
          disabled={!queue.length}
          onClick={() => act('clear')}
        >
          Clear Queue
        </Button>
      }
    >
      {queue.length ? (
        queue.map((item, index) => (
          <Box key={`${item.name}-${index}`}>- {item.name}</Box>
        ))
      ) : (
        <Box color="label">Queue is empty.</Box>
      )}
    </Section>
  );
};

const FabricatorCatalog = (props: { searchText: string }) => {
  const { searchText } = props;
  const { data } = useBackend<DropshipFabricatorData>();
  const { categories } = data;

  const normalizedSearch = searchText.trim().toLowerCase();

  const filteredCategories = categories
    .map((category) => ({
      ...category,
      items: category.items.filter((item) =>
        item.name.toLowerCase().includes(normalizedSearch),
      ),
    }))
    .filter((category) => category.items.length > 0);

  if (!filteredCategories.length) {
    return (
      <Section fill>
        <Box color="label" textAlign="center">
          No matching parts found.
        </Box>
      </Section>
    );
  }

  return (
    <Stack vertical fill>
      {filteredCategories.map((category) => (
        <Stack.Item key={category.name}>
          <Section title={category.name}>
            <Stack vertical>
              {category.items.map((item) => (
                <Stack.Item key={item.id}>
                  <FabricatorRecipe item={item} />
                </Stack.Item>
              ))}
            </Stack>
          </Section>
        </Stack.Item>
      ))}
    </Stack>
  );
};

const FabricatorRecipe = (props: { item: FabricatorItem }) => {
  const { item } = props;
  const { act, data } = useBackend<DropshipFabricatorData>();
  const { points } = data;

  const canAfford = points >= item.cost;

  return (
    <Tooltip content={item.desc} position="bottom-start">
      <Button
        fluid
        disabled={!canAfford}
        color={canAfford ? undefined : 'transparent'}
        onClick={() => act('build', { id: item.id })}
      >
        <Stack>
          <Stack.Item grow>{item.name}</Stack.Item>
          <Stack.Item color={canAfford ? 'good' : 'bad'}>
            {item.cost} pts
          </Stack.Item>
        </Stack>
      </Button>
    </Tooltip>
  );
};
