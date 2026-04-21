import { useState } from 'react';
import {
  Box,
  Collapsible,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';

import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';

type Modpack = {
  name: string;
  desc: string;
  author: string;
  icon_class: string;
  id: string;
};

type Data = {
  categories: string[];
  features: Modpack[];
  translations: Modpack[];
  reverts: Modpack[];
};

type CategoryKey = 'Features' | 'Translations' | 'Reverts';

type ModpackListProps = {
  emptyText: string;
  items: Modpack[];
  searchPlaceholder: string;
};

export const Modpacks = () => {
  const { data } = useBackend<Data>();
  const [selectedCategory, setSelectedCategory] = useState<CategoryKey>(
    (data.categories[0] as CategoryKey) || 'Features',
  );

  return (
    <Window title="Modpacks" width={480} height={580}>
      <Window.Content>
        <NoticeBox>
          This menu lists modular content currently registered on the server.
        </NoticeBox>
        <Tabs>
          <Tabs.Tab
            selected={selectedCategory === 'Features'}
            onClick={() => setSelectedCategory('Features')}
          >
            Features
          </Tabs.Tab>
          <Tabs.Tab
            selected={selectedCategory === 'Translations'}
            onClick={() => setSelectedCategory('Translations')}
          >
            Translations
          </Tabs.Tab>
          <Tabs.Tab
            selected={selectedCategory === 'Reverts'}
            onClick={() => setSelectedCategory('Reverts')}
          >
            Reverts
          </Tabs.Tab>
        </Tabs>
        {selectedCategory === 'Features' && (
          <ModpackList
            emptyText="This server does not have visible feature modpacks."
            items={data.features}
            searchPlaceholder="Search feature modpacks..."
          />
        )}
        {selectedCategory === 'Translations' && (
          <ModpackList
            emptyText="This server does not have visible translation modpacks."
            items={data.translations}
            searchPlaceholder="Search translation modpacks..."
          />
        )}
        {selectedCategory === 'Reverts' && (
          <ModpackList
            emptyText="This server does not have visible revert modpacks."
            items={data.reverts}
            searchPlaceholder="Search revert modpacks..."
          />
        )}
      </Window.Content>
    </Window>
  );
};

const ModpackList = (props: ModpackListProps) => {
  const { emptyText, items, searchPlaceholder } = props;
  const [searchText, setSearchText] = useLocalState('modpackSearchText', '');
  const normalizedSearch = searchText.toLowerCase();

  const filteredItems = items.filter(
    (item) =>
      item.name &&
      (!normalizedSearch ||
        item.name.toLowerCase().includes(normalizedSearch) ||
        item.desc.toLowerCase().includes(normalizedSearch) ||
        item.author.toLowerCase().includes(normalizedSearch)),
  );

  if (items.length === 0) {
    return <NoticeBox>{emptyText}</NoticeBox>;
  }

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section fill>
          <Input
            fluid
            placeholder={searchPlaceholder}
            onChange={(value) => setSearchText(value)}
          />
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          fill
          scrollable
          title={
            normalizedSearch
              ? `Search results: ${filteredItems.length}`
              : `Total modpacks: ${items.length}`
          }
        >
          {filteredItems.map((item) => (
            <Collapsible
              color="transparent"
              key={item.id}
              title={<span className="color-white">{item.name}</span>}
            >
              <Table.Row>
                <Table.Cell collapsing>
                  <Box className={item.icon_class} m={1} />
                </Table.Cell>
                <Table.Cell verticalAlign="top">
                  <Box
                    style={{
                      borderBottom: '1px solid #888',
                      fontSize: '14px',
                      paddingBottom: '10px',
                      textAlign: 'center',
                    }}
                  >
                    <LabeledList.Item label="Description">
                      {item.desc}
                    </LabeledList.Item>
                    <LabeledList.Item label="Author">
                      {item.author}
                    </LabeledList.Item>
                  </Box>
                </Table.Cell>
              </Table.Row>
            </Collapsible>
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};
