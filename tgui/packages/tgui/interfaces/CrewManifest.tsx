import { useState } from 'react';
import { Icon, Input, Section, Table, Tooltip } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Crew = {
  paygrade_prefix: string;
  name: string;
  rank: string;
  squad?: string | null;
  is_active: string;
};

type ManifestData = {
  departments_with_jobs: {
    [department: string]: string[];
  };
} & {
  [department: string]: Crew[] | { [department: string]: string[] };
};

export const CrewManifest = () => {
  const { data } = useBackend<ManifestData>();
  const [searchTerm, setSearchTerm] = useState('');

  if (!data || Object.keys(data).length === 0) {
    return (
      <Window width={650} height={800}>
        <Window.Content>
          <Section>No crew manifest available.</Section>
        </Window.Content>
      </Window>
    );
  }

  const departmentOrder = [
    'Command',
    'Auxiliary',
    'Alpha',
    'Bravo',
    'Charlie',
    'Delta',
    'Echo',
    'Foxtrot',
    'Intel',
    'Marines',
    'Engineering',
    'Requisitions',
    'Medical',
    'Miscellaneous',
  ];

  const sortedDepartments = Object.entries(data)
    .filter(([key]) => key !== 'departments_with_jobs')
    .sort(([deptA], [deptB]) => {
      const indexA = departmentOrder.indexOf(deptA);
      const indexB = departmentOrder.indexOf(deptB);
      return (
        (indexA === -1 ? Infinity : indexA) -
        (indexB === -1 ? Infinity : indexB)
      );
    });

  return (
    <Window width={650} height={800}>
      <Window.Content className="CrewManifest" scrollable>
        <Section>
          <Input
            value={searchTerm}
            onChange={(value) => setSearchTerm(value.toLowerCase())}
            fluid
            placeholder="Search..."
          />
        </Section>

        {sortedDepartments.map(([department, crewList]) => {
          if (!Array.isArray(crewList) || crewList.length === 0) {
            return null;
          }

          const roleOrder = data.departments_with_jobs?.[department] || [];
          const supervisorRank = roleOrder[0];

          const filteredCrewList = [...crewList]
            .filter(
              (crew) =>
                crew.name?.toLowerCase().includes(searchTerm) ||
                crew.rank?.toLowerCase().includes(searchTerm) ||
                (crew.paygrade_prefix || '')
                  .toLowerCase()
                  .includes(searchTerm),
            )
            .sort((a, b) => {
              const rankA = roleOrder.indexOf(a.rank);
              const rankB = roleOrder.indexOf(b.rank);
              return (
                (rankA === -1 ? Infinity : rankA) -
                (rankB === -1 ? Infinity : rankB)
              );
            });

          if (filteredCrewList.length === 0) {
            return null;
          }

          return (
            <Section
              key={department}
              title={department}
              textAlign="center"
              className={
                'border-dept-' + department.toLowerCase().replace(/\s+/g, '-')
              }
              backgroundColor="rgba(10, 10, 10, 0.75)"
            >
              <Table>
                {filteredCrewList.map((crew, index) => (
                  <Table.Row
                    key={`${crew.name}-${index}`}
                    bold={crew.rank === supervisorRank}
                    className={index % 2 === 0 ? 'row-even' : 'row-odd'}
                  >
                    <Table.Cell
                      width="12%"
                      textAlign="right"
                      pr={1}
                      pt={1}
                      pb={1}
                      nowrap
                    >
                      {crew.paygrade_prefix}
                    </Table.Cell>
                    <Table.Cell
                      width="50%"
                      textAlign="left"
                      pt={1}
                      pb={1}
                      pl={1}
                      nowrap
                    >
                      {crew.name}
                    </Table.Cell>
                    <Table.Cell
                      width="33%"
                      textAlign="right"
                      pr="2%"
                      pt={1}
                      pb={1}
                      nowrap
                    >
                      {crew.rank}
                    </Table.Cell>
                    <Table.Cell
                      textAlign="right"
                      width="5%"
                      pr={1}
                      pt={1}
                      pb={1}
                      pl={2}
                    >
                      <Tooltip content={crew.is_active}>
                        <Icon
                          name="circle"
                          className={
                            'manifest-indicator-' +
                            (crew.is_active || 'unknown')
                              .toLowerCase()
                              .replace(/\*/g, '')
                              .replace(/\s/g, '-')
                              .replace(/:.*?$/, '')
                          }
                        />
                      </Tooltip>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          );
        })}
      </Window.Content>
    </Window>
  );
};
