import { Fragment } from 'react';
import {
  Box,
  Button,
  Collapsible,
  Divider,
  Flex,
  Icon,
  Input,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';

const category_icon = {
  Operations: 'parachute-box',
  Weapons: 'fighter-jet',
  Explosives: 'bomb',
  Armor: 'hard-hat',
  Clothing: 'tshirt',
  Medical: 'medkit',
  Engineering: 'tools',
  Supplies: 'hamburger',
  Imports: 'boxes',
  Vehicles: 'road',
  Factory: 'industry',
  'Pending Order': 'shopping-cart',
};

const SafeContents = ({ data, title }) => {
  if (!data || typeof data !== 'object') return null;

  return (
    <>
      <Table.Row>
        <Table.Cell bold>{title}</Table.Cell>
        <Table.Cell bold>Quantity</Table.Cell>
      </Table.Row>
      {Object.entries(data).map(([key, item]: [string, any]) => {
        const name = typeof item === 'object' && item !== null ? (item.name || key) : key;
        const count = typeof item === 'object' && item !== null ? (item.count || 1) : item;

        return (
          <Table.Row key={key}>
            <Table.Cell width="70%">{name}</Table.Cell>
            <Table.Cell>{count}</Table.Cell>
          </Table.Row>
        );
      })}
    </>
  );
};

const InputContents = (props) => <SafeContents data={props.input} title="Input" />;
const OutputContents = (props) => <SafeContents data={props.output} title="Output" />;

export const Assembler = (props) => {
  const { act, data } = useBackend();
  const [selectedMenu, setSelectedMenu] = useLocalState('selectedMenu', null);
  const { supplypacks, categories = [] } = data;

  const selectedPackCat = supplypacks ? supplypacks[selectedMenu] : null;

  return (
    <Window title="Assembler" width={900} height={700}>
      <Flex height="650px" align="stretch">
        <Flex.Item width="280px">
          <Menu />
        </Flex.Item>
        <Flex.Item position="relative" grow={1} height="100%">
          <Window.Content scrollable>
            {!!selectedPackCat && (
              <Category selectedPackCat={selectedPackCat} should_filter />
            )}
          </Window.Content>
        </Flex.Item>
      </Flex>
    </Window>
  );
};

const MenuButton = (props) => {
  const { condition, menuname, icon, width } = props;
  const [selectedMenu, setSelectedMenu] = useLocalState('selectedMenu', null);

  return (
    <Button
      icon={icon}
      selected={selectedMenu === menuname}
      onClick={() => setSelectedMenu(menuname)}
      disabled={condition}
      width={width}
      content={menuname}
    />
  );
};

const Menu = (props) => {
  const { data } = useBackend();
  const { categories } = data;

  return (
    <Section height="100%" p="5px">
      <Divider />
      {categories.map((category) => (
        <Fragment key={category}>
          <MenuButton
            icon={category_icon[category]}
            menuname={category}
            condition={0}
            width="100%"
          />
          <br />
        </Fragment>
      ))}
    </Section>
  );
};

const Pack = (props) => {
  const { data } = useBackend();
  const { pack } = props;
  const { supplypackscontents } = data;
  const item = supplypackscontents[pack];
  if (!item) return null;

  const { name, inputs, outputs } = item;

  return !!inputs && typeof inputs === 'object' && !!outputs && typeof outputs === 'object' ? (
    <Collapsible color="gray" title={<PackName name={name} pl={0} />}>
      <Table>
        <InputContents input={inputs} />
      </Table>
      <Table>
        <OutputContents output={outputs} />
      </Table>
    </Collapsible>
  ) : (
    <PackName name={name} pl="22px" />
  );
};

const PackName = (props) => {
  const { name, pl } = props;
  return (
    <Box inline pl={pl}>
      <Box width="15px" inline />
      <Box inline>{name}</Box>
    </Box>
  );
};

const CategoryButton = (props) => {
  const { act } = useBackend();
  const { icon, disabled, id, mode } = props;

  return (
    <Button
      icon={icon}
      disabled={disabled}
      onClick={() => act('select', { id: id, mode: mode })}
    />
  );
};

const Category = (props) => {
  const { data } = useBackend();
  const { supplypackscontents, assemblercraft } = data;
  const { selectedPackCat, should_filter } = props;
  const [filter, setFilter] = useLocalState(`pack-name-filter`, null);
  const [selectedMenu] = useLocalState('selectedMenu', null);

  const filterSearch = (entry) =>
    should_filter && filter
      ? supplypackscontents[entry]?.name?.toLowerCase().includes(filter.toLowerCase())
      : true;

  return (
    <Section
      level={1}
      title={
        <>
          <Icon name={category_icon[selectedMenu]} mr="5px" />
          {selectedMenu}
        </>
      }
    >
      <Stack vertical>
        {should_filter && (
          <Stack.Item>
            <Flex>
              <Flex.Item width="60px">Search :</Flex.Item>
              <Flex.Item grow={1}>
                <Input fluid onInput={(_e, value) => setFilter(value)} />
              </Flex.Item>
            </Flex>
          </Stack.Item>
        )}
        <Stack.Item>
          <Table>
            {selectedPackCat.filter(filterSearch).map((entry) => (
              <Table.Row key={entry}>
                <Table.Cell width="30px">
                  <CategoryButton
                    icon="sync"
                    id={entry}
                    disabled={entry === assemblercraft}
                    mode="add"
                  />
                </Table.Cell>
                <Table.Cell>
                  <Pack pack={entry} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
