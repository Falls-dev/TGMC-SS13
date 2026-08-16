import { useState } from 'react';
import {
  Box,
  Button,
  ColorBox,
  Icon,
  LabeledList,
  ProgressBar,
  Section,
  Table,
} from 'tgui-core/components';
import { toFixed } from 'tgui-core/math';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type AreaData = {
  name: string;
  charge: number;
  load: string;
  charging: number;
  eqp: number;
  lgt: number;
  env: number;
};

type Data = {
  attached: BooleanLike;
  supply: number;
  demand: number;
  supply_text: string;
  demand_text: string;
  areas: AreaData[];
};

const powerRank = (str: string) => {
  const unit = String(str.split(' ')[1] || '').toLowerCase();
  return ['w', 'kw', 'mw', 'gw'].indexOf(unit);
};

export const PowerMonitor = () => {
  const { data } = useBackend<Data>();
  const { attached, supply, demand, supply_text, demand_text, areas = [] } =
    data;
  const [sortByField, setSortByField] = useState<string | null>(null);
  const maxValue = Math.max(500000, supply, demand, 1);

  const sortedAreas = [...areas];
  if (sortByField === 'name') {
    sortedAreas.sort((a, b) => a.name.localeCompare(b.name));
  } else if (sortByField === 'charge') {
    sortedAreas.sort((a, b) => b.charge - a.charge);
  } else if (sortByField === 'draw') {
    sortedAreas.sort((a, b) => {
      const rankDiff = powerRank(b.load) - powerRank(a.load);
      if (rankDiff !== 0) {
        return rankDiff;
      }
      return parseFloat(b.load) - parseFloat(a.load);
    });
  }

  return (
    <Window width={550} height={700} title="Power Monitoring">
      <Window.Content scrollable>
        {!attached ? (
          <Section>
            <Box color="bad">No connection</Box>
          </Section>
        ) : (
          <>
            <Section>
              <LabeledList>
                <LabeledList.Item label="Supply">
                  <ProgressBar
                    value={supply}
                    minValue={0}
                    maxValue={maxValue}
                    color="teal"
                  >
                    {supply_text}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Draw">
                  <ProgressBar
                    value={demand}
                    minValue={0}
                    maxValue={maxValue}
                    color="pink"
                  >
                    {demand_text}
                  </ProgressBar>
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Section>
              <Box mb={1}>
                <Box inline mr={2} color="label">
                  Sort by:
                </Box>
                <Button.Checkbox
                  checked={sortByField === 'name'}
                  onClick={() =>
                    setSortByField(sortByField !== 'name' ? 'name' : null)
                  }
                >
                  Name
                </Button.Checkbox>
                <Button.Checkbox
                  checked={sortByField === 'charge'}
                  onClick={() =>
                    setSortByField(sortByField !== 'charge' ? 'charge' : null)
                  }
                >
                  Charge
                </Button.Checkbox>
                <Button.Checkbox
                  checked={sortByField === 'draw'}
                  onClick={() =>
                    setSortByField(sortByField !== 'draw' ? 'draw' : null)
                  }
                >
                  Draw
                </Button.Checkbox>
              </Box>
              <Table>
                <Table.Row header>
                  <Table.Cell>Area</Table.Cell>
                  <Table.Cell collapsing>Charge</Table.Cell>
                  <Table.Cell textAlign="right">Draw</Table.Cell>
                  <Table.Cell collapsing title="Equipment">
                    Eqp
                  </Table.Cell>
                  <Table.Cell collapsing title="Lighting">
                    Lgt
                  </Table.Cell>
                  <Table.Cell collapsing title="Environment">
                    Env
                  </Table.Cell>
                </Table.Row>
                {sortedAreas.map((area, i) => (
                  <Table.Row key={`${area.name}-${i}`} className="candystripe">
                    <Table.Cell>{area.name}</Table.Cell>
                    <Table.Cell textAlign="right" nowrap>
                      <AreaCharge
                        charging={area.charging}
                        charge={area.charge}
                      />
                    </Table.Cell>
                    <Table.Cell textAlign="right" nowrap>
                      {area.load}
                    </Table.Cell>
                    <Table.Cell textAlign="center" nowrap>
                      <AreaStatusColorBox status={area.eqp} />
                    </Table.Cell>
                    <Table.Cell textAlign="center" nowrap>
                      <AreaStatusColorBox status={area.lgt} />
                    </Table.Cell>
                    <Table.Cell textAlign="center" nowrap>
                      <AreaStatusColorBox status={area.env} />
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
};

const AreaCharge = (props: { charging: number; charge: number }) => {
  const { charging, charge } = props;
  return (
    <>
      <Icon
        width="18px"
        textAlign="center"
        name={
          (charging === 0 &&
            (charge > 50 ? 'battery-half' : 'battery-quarter')) ||
          (charging === 1 && 'bolt') ||
          (charging === 2 && 'battery-full') ||
          'battery-empty'
        }
        color={
          (charging === 0 && (charge > 50 ? 'yellow' : 'red')) ||
          (charging === 1 && 'yellow') ||
          (charging === 2 && 'green') ||
          undefined
        }
      />
      <Box inline width="36px" textAlign="right">
        {toFixed(charge) + '%'}
      </Box>
    </>
  );
};

const AreaStatusColorBox = (props: { status: number }) => {
  const { status } = props;
  const power = Boolean(status & 2);
  const mode = Boolean(status & 1);
  return (
    <ColorBox
      color={power ? 'good' : 'bad'}
      content={mode ? undefined : 'M'}
      title={`${power ? 'On' : 'Off'} [${mode ? 'auto' : 'manual'}]`}
    />
  );
};
