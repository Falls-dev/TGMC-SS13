import { Color } from 'tgui-core/color';
import {
  Box,
  Button,
  NoticeBox,
  Section,
  Stack,
  StyleableSection,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Job = {
  ref: string;
  unavailable_reason: string | null;
  command: BooleanLike;
  position_label: string;
  description: string;
  duty: string;
};

type Department = {
  color: string;
  jobs: Record<string, Job>;
};

type Data = {
  departments_static: Record<string, Department>;
  departments: Record<string, Department>;
  shuttle_status: string | null;
  round_duration: string;
  security_level: number;
  security_level_text: string;
  evacuation_status: number;
  self_destruct_status: number;
};

const SEC_LEVEL_GREEN = 1;
const SEC_LEVEL_BLUE = 2;
const SEC_LEVEL_RED = 3;
const SEC_LEVEL_DELTA = 4;

const EVACUATION_STATUS_STANDING_BY = 0;
const EVACUATION_STATUS_COMPLETE = 3;

const NUKE_EXPLOSION_INACTIVE = 0;

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

/**
 * Builds the plain-text tooltip for a job: duty (aka description) if present, otherwise falls back to
 * the unavailable reason. Never falls back to the raw (huge, HTML-tagged) job.description.
 */
function jobTooltip(job: Job): string {
  if (job.unavailable_reason) {
    return job.unavailable_reason;
  }
  const lines: string[] = [];
  if (job.duty) {
    lines.push(`${job.duty}`);
  }
  return lines.join('\n');
}

/** Combines the (mostly static) job flavor text/colors with the (frequently changing) slot data. */
function mergeDepartments(
  staticDepartments: Record<string, Department>,
  liveDepartments: Record<string, Department>,
): Record<string, Department> {
  const merged: Record<string, Department> = {};

  for (const [name, department] of Object.entries(staticDepartments)) {
    const liveDepartment = liveDepartments[name];
    const jobs: Record<string, Job> = {};

    for (const [jobName, job] of Object.entries(department.jobs)) {
      jobs[jobName] = { ...job, ...liveDepartment?.jobs?.[jobName] };
    }

    merged[name] = { ...department, ...liveDepartment, jobs };
  }

  return merged;
}

type JobEntryProps = {
  jobName: string;
  job: Job;
  department: Department;
  onClick: () => void;
};

function JobEntry(props: JobEntryProps) {
  const { jobName, job, department, onClick } = props;

  return (
    <Button
      fluid
      style={{
        backgroundColor: job.unavailable_reason
          ? '#949494' // Grey background
          : Color.fromHex(department.color).darken(10).toString(),
        color: job.unavailable_reason
          ? '#616161' // Dark grey font
          : Color.fromHex(department.color).darken(90).toString(),
        fontSize: '1.1rem',
        cursor: job.unavailable_reason ? 'initial' : 'pointer',
      }}
      tooltip={jobTooltip(job)}
      tooltipPosition="top"
      onClick={() => {
        !job.unavailable_reason && onClick();
      }}
    >
      <Stack fill>
        <Stack.Item grow>{job.command ? <b>{jobName}</b> : jobName}</Stack.Item>
        <Stack.Item>
          <span style={{ whiteSpace: 'nowrap' }}>{job.position_label}</span>
        </Stack.Item>
      </Stack>
    </Button>
  );
}

type DepartmentEntryProps = {
  name: string;
  department: Department;
};

function DepartmentEntry(props: DepartmentEntryProps) {
  const { name, department } = props;
  const { act } = useBackend<Data>();

  return (
    <Box minWidth="30%">
      <StyleableSection
        title={name}
        style={{
          backgroundColor: department.color,
          marginBottom: '1em',
          breakInside: 'avoid-column',
        }}
        titleStyle={{
          borderBottomColor: Color.fromHex(department.color)
            .darken(50)
            .toString(),
        }}
        textStyle={{
          color: Color.fromHex(department.color).darken(80).toString(),
        }}
      >
        <Stack vertical>
          {Object.entries(department.jobs).map(([jobName, job]) => (
            <Stack.Item key={jobName}>
              <JobEntry
                jobName={jobName}
                job={job}
                department={department}
                onClick={() => act('select_job', { job: job.ref })}
              />
            </Stack.Item>
          ))}
        </Stack>
      </StyleableSection>
    </Box>
  );
}

export function JobSelection(props) {
  const { data } = useBackend<Data>();
  if (!data?.departments_static) {
    return null; // Stop TGUI whitescreens with TGUI-dev!
  }

  const departments = mergeDepartments(
    data.departments_static,
    data.departments || {},
  );
  const {
    shuttle_status,
    round_duration,
    security_level,
    security_level_text,
    evacuation_status,
    self_destruct_status,
  } = data;

  const evacuationInProgress =
    evacuation_status !== undefined &&
    evacuation_status !== EVACUATION_STATUS_STANDING_BY &&
    evacuation_status !== EVACUATION_STATUS_COMPLETE;
  const selfDestructActive =
    self_destruct_status !== undefined &&
    self_destruct_status !== NUKE_EXPLOSION_INACTIVE;
  const bannerCount = [
    shuttle_status,
    selfDestructActive,
    evacuationInProgress,
  ].filter(Boolean).length;

  return (
    <Window width={1012} height={666 + bannerCount * 32 /* Hahahahahaha */}>
      <Window.Content>
        <Section
          fill
          scrollable
          title={
            <>
              {shuttle_status && <NoticeBox danger>{shuttle_status}</NoticeBox>}
              {!!selfDestructActive && (
                <NoticeBox danger>
                  Ship self-destruct sequence has been activated!
                </NoticeBox>
              )}
              {!!evacuationInProgress && (
                <NoticeBox danger>
                  Ship evacuation is currently underway!
                </NoticeBox>
              )}
              {!!security_level_text && (
                <Box
                  as="span"
                  bold
                  color={alertColor(security_level)}
                  mr={1.5}
                >
                  Alert level: {security_level_text.toUpperCase()}
                </Box>
              )}
              <Box as="span" color="label">
                It is currently {round_duration} into the mission.
              </Box>
            </>
          }
        >
          <Box style={{ columns: '20em' }}>
            {Object.entries(departments).map(([name, department]) => (
              <DepartmentEntry key={name} name={name} department={department} />
            ))}
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
}
