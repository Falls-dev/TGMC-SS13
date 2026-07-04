import { useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  Modal,
  ProgressBar,
  Section,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

export const MarineSelector = (props) => {
  const { act, data } = useBackend();
  const [showEmpty, setShowEmpty] = useState(false);
  const [showDesc, setShowDesc] = useState(null);

  const categories = Object.keys(data.displayed_records)
    .map((key) => ({
      ...data.cats[key],
      name: key,
      entries: data.displayed_records[key],
    }))
    .filter(
      (category) =>
        category.entries.length > 0 &&
        (showEmpty || category.remaining > 0 || category.remaining_points > 0),
    );

  return (
    <Window width={650} height={700}>
      {!!showDesc && (
        <Modal width="400px">
          <Box>{showDesc}</Box>
          <Button content="Dismiss" onClick={() => setShowDesc(null)} />
        </Modal>
      )}
      <Window.Content scrollable>
        <Section
          title="Choose your equipment"
          buttons={
            <>
              <Box inline width="4px" />
              <Button
                icon="power-off"
                selected={showEmpty}
                onClick={() => setShowEmpty(!showEmpty)}
              >
                Show Empty Categories
              </Button>
            </>
          }
        >
          Make selections in each of the categories below to get equipped.
          Surplus of some of the equipment found in this machine may be found in
          surplus vendors nearby.
        </Section>
        {categories.map((category) => (
          <ItemCategory
            category={category}
            key={category.id}
            showDesc={showDesc}
            setShowDesc={setShowDesc}
          />
        ))}
      </Window.Content>
    </Window>
  );
};

const ItemCategory = (props) => {
  const {
    category: {
      entries,
      name,
      choice,
      remaining,
      total,
      remaining_points,
      total_points,
    },
    showDesc,
    setShowDesc,
  } = props;

  const cant_buy =
    (choice === 'choice' && !remaining) ||
    (choice === 'points' && !remaining_points);
  return (
    <Section
      title={name}
      buttons={
        (choice === 'choice' && (
          <ProgressBar
            value={remaining / total}
            ranges={{
              good: [1, Infinity],
              average: [0.1, 1],
              bad: [-Infinity, 0.1],
            }}
          >
            {remaining + '/' + total + ' Choices'}
          </ProgressBar>
        )) ||
        (choice === 'points' && (
          <ProgressBar
            value={remaining_points / total_points}
            ranges={{
              good: [0.67, Infinity],
              average: [0.33, 0.67],
              bad: [-Infinity, 0.33],
            }}
          >
            {remaining_points + '/' + total_points + ' Points'}
          </ProgressBar>
        ))
      }
    >
      <LabeledList>
        {entries.map((display_record) => {
          return (
            <ItemLine
              display_record={display_record}
              key={display_record.id}
              cant_buy={cant_buy}
              remaining_points={remaining_points}
              showDesc={showDesc}
              setShowDesc={setShowDesc}
            />
          );
        })}
      </LabeledList>
    </Section>
  );
};

const ItemLine = (props) => {
  const { act, data } = useBackend();

  const {
    display_record,
    cant_buy,
    remaining_points,
    showDesc,
    setShowDesc,
  } = props;
  const {
    id,
    prod_cost,
    prod_index,
    prod_color,
    prod_name,
    prod_desc,
    product_cost,
    product_index,
    product_color,
    product_name,
    product_desc,
  } = display_record;
  const cost = product_cost ?? prod_cost;
  const index = product_index ?? prod_index;
  const color = product_color ?? prod_color;
  const name = product_name ?? prod_name;
  const desc = product_desc ?? prod_desc;

  return (
    <LabeledList.Item
      key={id}
      buttons={
        <>
          {color === 'white' && (
            <Box inline mr="6px" ml="6px">
              Essential
            </Box>
          )}
          {color === 'orange' && (
            <Box inline mr="6px" ml="6px" color="green">
              Recommended
            </Box>
          )}
          {color === 'orange2' && (
            <Box inline mr="6px" ml="6px" color="orange">
              Munition
            </Box>
          )}
          {color === 'orange3' && (
            <Box inline mr="6px" ml="6px" color="orange">
              Explosive
            </Box>
          )}
          {color === 'yellow' && (
            <Box inline mr="6px" ml="6px" color="yellow">
              Tool
            </Box>
          )}
          {color === 'yellow2' && (
            <Box inline mr="6px" ml="6px" color="yellow">
              Money
            </Box>
          )}
          {color === 'blue' && (
            <Box inline mr="6px" ml="6px" color="blue">
              Specialist
            </Box>
          )}
          {color === 'cyan' && (
            <Box inline mr="6px" ml="6px" color="cyan">
              Medicine
            </Box>
          )}
          {color === 'cyan2' && (
            <Box inline mr="6px" ml="6px" color="cyan">
              Implant
            </Box>
          )}
          {color === 'red' && (
            <Box inline mr="6px" ml="6px" color="red">
              Weapon
            </Box>
          )}
          {color === 'synth-cosmetic' && (
            <Box inline mr="6px" ml="6px" color="blue">
              Cosmetic
            </Box>
          )}
          {color === 'synth-storage' && (
            <Box inline mr="6px" ml="6px" color="magenta">
              Storage
            </Box>
          )}
          {color === 'synth-armor' && (
            <Box inline mr="6px" ml="6px" color="red">
              Armor
            </Box>
          )}
          {color === 'synth-rcmarmor' && (
            <Box inline mr="6px" ml="6px" color="orange">
              Recommended - Armor
            </Box>
          )}
          {color === 'synth-rcmarmstorage' && (
            <Box inline mr="6px" ml="6px" color="green">
              Recommended - Armor and Suit Storage
            </Box>
          )}
          {color === 'synth-attachable' && (
            <Box inline mr="6px" ml="6px" color="green">
              Recommended - Attachable to Flak Jacket
            </Box>
          )}
          {cost > 0 && (
            <Box inline width="75px" mr="6px" ml="6px">
              {cost} points
            </Box>
          )}
          <Button
            disabled={cant_buy || cost > remaining_points}
            onClick={() => act('vend', { vend: index })}
            selected={color === 'white'}
          >
            Vend
          </Button>
        </>
      }
      label={name}
      labelColor="white"
    >
      {!!desc && <Button onClick={() => setShowDesc(desc)}>?</Button>}
    </LabeledList.Item>
  );
};
