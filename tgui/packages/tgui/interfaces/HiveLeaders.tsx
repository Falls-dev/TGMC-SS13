import { Icon, Section, Table } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type HiveEntry = { designation: string; caste_type: string };

type Data = { queens: HiveEntry[]; leaders: HiveEntry[] };

export const HiveLeaders = () => {
  const { data } = useBackend<Data>();
  const { queens = [], leaders = [] } = data;

  return (
    <Window title="Hive Leaders" theme="xeno" width={280} height={350}>
      <Window.Content>
        <Section>
          <Table className="xeno_list">
            <Table.Row header className="xenoListRow">
              <Table.Cell width="5%" className="noPadCell" />
              <Table.Cell textAlign="left">Designation</Table.Cell>
              <Table.Cell textAlign="left">Caste</Table.Cell>
            </Table.Row>

            <Table.Row
              className="xenoListRow"
              backgroundColor="purple"
              height="25px"
            >
              <Table.Cell colSpan={3} p={1}>
                Hive Ruler
              </Table.Cell>
            </Table.Row>

            {queens.map((entry, i) => (
              <Table.Row key={`queen-${i}`}>
                <Table.Cell className="noPadCell">
                  <Icon name="star" ml={0.2} />
                </Table.Cell>
                <Table.Cell>{entry.designation}</Table.Cell>
                <Table.Cell>{entry.caste_type}</Table.Cell>
              </Table.Row>
            ))}

            <Table.Row
              className="xenoListRow"
              backgroundColor="purple"
              height="25px"
            >
              <Table.Cell colSpan={3} p={1}>
                Leaders
              </Table.Cell>
            </Table.Row>

            {leaders.map((entry, i) => (
              <Table.Row key={`leader-${i}`}>
                <Table.Cell className="noPadCell">
                  <Icon name="star" ml={0.2} />
                </Table.Cell>
                <Table.Cell>{entry.designation}</Table.Cell>
                <Table.Cell>{entry.caste_type}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
