import { Section, Table } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  sections: {
    title: string;
    entries: { id: string; name: string; caste: string }[];
  }[];
};

export const XenoManifest = () => {
  const { data } = useBackend<Data>();
  const { sections = [] } = data;

  return (
    <Window title="Xeno Manifest" theme="xeno" width={400} height={420}>
      <Window.Content scrollable>
        {sections.length === 0 && <Section>No xenomorphs in the hive.</Section>}
        {sections.map(({ title, entries }) => (
          <Section key={title} title={title}>
            <Table>
              <Table.Row header>
                <Table.Cell>Caste</Table.Cell>
                <Table.Cell>Name</Table.Cell>
              </Table.Row>
              {entries.map(({ id, name, caste }) => (
                <Table.Row key={id}>
                  <Table.Cell>{caste}</Table.Cell>
                  <Table.Cell>{name}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};
