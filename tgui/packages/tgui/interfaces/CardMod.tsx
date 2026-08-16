import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { sanitizeText } from '../sanitize';

type AccessEntry = {
  desc: string;
  ref: number | string;
};

type Region = {
  name: string;
  regid: number;
  accesses: AccessEntry[];
};

type PaygradeOption = {
  paygrade: string;
  name: string;
};

type Data = {
  authenticated: BooleanLike;
  has_id: BooleanLike;
  id_name: string;
  id_rank: string;
  id_owner: string;
  access_on_card: (number | string)[];
  id_account: number;
  has_auth_card: BooleanLike;
  auth_name: string;
  paygrade: string | null;
  paygrade_name: string | null;
  can_modify_paygrade: BooleanLike;
  available_paygrades: PaygradeOption[];
  mode: number;
  printing: BooleanLike;
  manifest: string;
  jobs: string[];
  regions: Region[];
};

const MODE_CARD = 0;
const MODE_MANIFEST = 1;

const accessSelected = (
  selected: (number | string)[],
  ref: number | string,
) => {
  const asString = String(ref);
  return selected.some((entry) => String(entry) === asString);
};

export const CardMod = () => {
  const { act, data } = useBackend<Data>();
  const {
    authenticated,
    has_id,
    id_name,
    id_rank,
    id_owner,
    access_on_card = [],
    id_account,
    has_auth_card,
    auth_name,
    paygrade,
    paygrade_name,
    can_modify_paygrade,
    available_paygrades = [],
    mode,
    printing,
    manifest = '',
    jobs = [],
    regions = [],
  } = data;
  const [tab, setTab] = useState(1);

  const selectedPaygrade =
    available_paygrades.find((entry) => entry.paygrade === paygrade)?.name ||
    paygrade_name ||
    'Unknown';

  return (
    <Window width={520} height={640} title="Identification Card Modifier">
      <Window.Content scrollable>
        <Section
          title="ID Cards"
          buttons={
            <>
              <Button
                icon={authenticated ? 'sign-out-alt' : 'sign-in-alt'}
                color={authenticated ? 'bad' : 'good'}
                onClick={() =>
                  act(authenticated ? 'PRG_logout' : 'PRG_authenticate')
                }
              >
                {authenticated ? 'Log Out' : 'Log In'}
              </Button>
              <Button
                icon="users"
                selected={mode === MODE_MANIFEST}
                onClick={() =>
                  act('PRG_mode', {
                    mode: mode === MODE_MANIFEST ? MODE_CARD : MODE_MANIFEST,
                  })
                }
              >
                Manifest
              </Button>
            </>
          }
        >
          <Stack vertical>
            <Stack.Item>
              <Button fluid icon="eject" onClick={() => act('PRG_eject')}>
                Target: {id_name}
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button fluid icon="eject" onClick={() => act('PRG_eject_auth')}>
                Auth: {auth_name}
              </Button>
            </Stack.Item>
          </Stack>
          {!authenticated && (
            <NoticeBox mt={1}>
              Insert target and authorization IDs, then log in
              {!has_id && !has_auth_card
                ? '.'
                : !has_id
                  ? ' (target ID missing).'
                  : !has_auth_card
                    ? ' (auth ID missing).'
                    : '.'}
            </NoticeBox>
          )}
        </Section>

        {mode === MODE_MANIFEST && (
          <Section
            title="Crew Manifest"
            buttons={
              <Button
                icon="print"
                disabled={!!printing}
                onClick={() => act('PRG_print')}
              >
                {printing ? 'Printing...' : 'Print'}
              </Button>
            }
          >
            <Box mb={1} color="label">
              Entries cannot be modified from this terminal.
            </Box>
            <Box
              dangerouslySetInnerHTML={{
                __html: sanitizeText(manifest),
              }}
            />
          </Section>
        )}

        {mode === MODE_CARD && !!authenticated && !!has_id && (
          <>
            <Section title="Registered Identity">
              <LabeledList>
                <LabeledList.Item label="Name">
                  <Input
                    value={id_owner}
                    width="250px"
                    expensive
                    onChange={(value) =>
                      act('PRG_edit', {
                        name: value,
                      })
                    }
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Account">
                  <NumberInput
                    step={1}
                    value={id_account || 0}
                    minValue={0}
                    maxValue={999999}
                    width="100px"
                    onChange={(value) =>
                      act('PRG_account', {
                        account: value,
                      })
                    }
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Assignment">
                  {id_rank}
                </LabeledList.Item>
                <LabeledList.Item label="Paygrade">
                  {can_modify_paygrade ? (
                    <Dropdown
                      width="220px"
                      options={available_paygrades.map((entry) => entry.name)}
                      selected={selectedPaygrade}
                      onSelected={(value) => {
                        const match = available_paygrades.find(
                          (entry) => entry.name === value,
                        );
                        if (match) {
                          act('PRG_paygrade', {
                            paygrade: match.paygrade,
                          });
                        }
                      }}
                    />
                  ) : (
                    <Box>
                      {paygrade_name || paygrade || 'None'} — UNABLE TO MODIFY
                    </Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>

            <Tabs>
              <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)}>
                Access
              </Tabs.Tab>
              <Tabs.Tab selected={tab === 2} onClick={() => setTab(2)}>
                Assignment
              </Tabs.Tab>
            </Tabs>

            {tab === 1 && (
              <Section
                title="Access"
                buttons={
                  <>
                    <Button
                      icon="check-double"
                      color="good"
                      onClick={() => act('PRG_grantall')}
                    >
                      Grant All
                    </Button>
                    <Button
                      icon="times"
                      color="bad"
                      onClick={() => act('PRG_denyall')}
                    >
                      Deny All
                    </Button>
                  </>
                }
              >
                {regions.map((region) => (
                  <Section
                    key={region.regid}
                    level={2}
                    title={region.name}
                    buttons={
                      <>
                        <Button
                          icon="check"
                          color="good"
                          onClick={() =>
                            act('PRG_grantregion', {
                              region: region.regid,
                            })
                          }
                        >
                          Grant
                        </Button>
                        <Button
                          icon="times"
                          color="bad"
                          onClick={() =>
                            act('PRG_denyregion', {
                              region: region.regid,
                            })
                          }
                        >
                          Deny
                        </Button>
                      </>
                    }
                  >
                    {region.accesses.map((access) => (
                      <Button
                        key={String(access.ref)}
                        m={0.5}
                        selected={accessSelected(access_on_card, access.ref)}
                        onClick={() =>
                          act('PRG_access', {
                            access_target: access.ref,
                          })
                        }
                      >
                        {access.desc}
                      </Button>
                    ))}
                  </Section>
                ))}
              </Section>
            )}

            {tab === 2 && (
              <Section title={`Jobs — ${id_rank}`}>
                <Button.Input
                  fluid
                  buttonText="Custom..."
                  onCommit={(value) =>
                    act('PRG_assign', {
                      assign_target: 'Custom',
                      custom_name: value,
                    })
                  }
                />
                <Box mt={1}>
                  {jobs
                    .filter((job) => job !== 'Custom')
                    .map((job) => (
                      <Button
                        key={job}
                        m={0.5}
                        selected={job === id_rank}
                        onClick={() =>
                          act('PRG_assign', {
                            assign_target: job,
                          })
                        }
                      >
                        {job}
                      </Button>
                    ))}
                </Box>
              </Section>
            )}
          </>
        )}

        {mode === MODE_CARD && !!authenticated && !has_id && (
          <NoticeBox>
            Insert a target ID card to modify assignments and access.
          </NoticeBox>
        )}
      </Window.Content>
    </Window>
  );
};
