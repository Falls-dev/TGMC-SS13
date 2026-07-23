import {
  BlockQuote,
  Box,
  Icon,
  NoticeBox,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import {
  COLOR_DARKER_RED,
  COLOR_MID_GREY,
  COLOR_ZEBRA_BG,
  ROUNDED_BORDER,
  SPACING_PIXELS,
} from './constants';
import { MedScannerData } from './data';
import { MedCounter } from './MedCounter';

export function PatientStomachChemicals() {
  let row_transparency = 0;
  const { data } = useBackend<MedScannerData>();
  const { has_stomach_chemicals, stomach_chemicals_lists = {} } = data;

  if (!has_stomach_chemicals || Object.keys(stomach_chemicals_lists).length === 0) {
    return null;
  }

  return (
    <Section title="Stomach Contents">
      <Stack vertical>
        {Object.values(stomach_chemicals_lists)
          .sort((a, b) => {
            return a.ui_priority - b.ui_priority;
          })
          .map((chemical) => (
            <Stack.Item
              key={chemical.name}
              backgroundColor={
                row_transparency++ % 2 === 0 ? COLOR_ZEBRA_BG : ''
              }
              style={ROUNDED_BORDER}
            >
              <Box inline p="2.5px">
                <Tooltip
                  content={
                    <>
                      <NoticeBox
                        danger={!!(chemical.od || chemical.dangerous)}
                        textAlign="center"
                      >
                        <Icon name="flask" italic pr={SPACING_PIXELS} />
                        {chemical.name}
                      </NoticeBox>
                      <BlockQuote>{chemical.description}</BlockQuote>
                    </>
                  }
                >
                  <Box
                    inline
                    color={chemical.dangerous || chemical.od ? 'red' : 'white'}
                    bold={!!(chemical.dangerous || chemical.od)}
                  >
                    <MedCounter
                      current={chemical.amount}
                      max={chemical.dangerous ? 0 : chemical.od_threshold}
                      units="u"
                      icon="flask"
                      iconColor={
                        chemical.dangerous || chemical.od
                          ? 'red'
                          : chemical.color
                      }
                      currentColor={
                        chemical.dangerous || chemical.od ? 'red' : 'white'
                      }
                      maxColor={
                        chemical.dangerous || chemical.od
                          ? COLOR_DARKER_RED
                          : COLOR_MID_GREY
                      }
                      mr={SPACING_PIXELS}
                    />
                    <Box inline italic>
                      {chemical.name}
                    </Box>
                  </Box>
                </Tooltip>
              </Box>
            </Stack.Item>
          ))}
      </Stack>
    </Section>
  );
}
