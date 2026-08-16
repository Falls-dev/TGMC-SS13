import {
  Box,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import { SPACING_PIXELS, TEMP_LEVELS_TO_DATA } from './constants';
import { MedScannerData, TempLevels } from './data';
import { getBloodColor } from './helpers';
import { MedBoxedTag } from './MedBoxedTag';

export function PatientFooter() {
  const { data } = useBackend<MedScannerData>();
  const {
    blood_amount,
    regular_blood_amount,
    blood_type,
    body_temperature,
    internal_bleeding,
    pulse,
    total_unknown_implants,
    infection,
    total_flow_rate,
  } = data;
  const bloodColors = getBloodColor(
    blood_amount,
    regular_blood_amount,
    internal_bleeding,
  );
  const tempData = TEMP_LEVELS_TO_DATA[body_temperature.level];
  return (
    <Section>
      <LabeledList>
        <LabeledList.Item
          label="Blood Volume"
          tooltip="Bloodloss causes symptoms that start as suffocation and pain, but get significantly worse as more blood is lost. Blood can be restored by eating and taking Isotonic solution."
        >
          <Stack align="center">
            <Stack.Item>
              <MedBoxedTag
                textColor={bloodColors.foreground}
                backgroundColor={bloodColors.background}
              >
                {blood_type}
              </MedBoxedTag>
            </Stack.Item>
            <Stack.Item grow={1} ml={SPACING_PIXELS}>
              <Tooltip
                content={
                  <Box>
                    {Math.trunc(blood_amount)}/
                    {Math.trunc(regular_blood_amount)}cl
                    {total_flow_rate ? ` (${total_flow_rate}cl/2s)` : ''}
                  </Box>
                }
              >
                <ProgressBar
                  value={blood_amount / regular_blood_amount}
                  ranges={{
                    good: [0.8, Infinity],
                    red: [-Infinity, 0.8],
                  }}
                >
                  <Icon
                    name={total_flow_rate ? 'arrow-down' : 'arrow-up'}
                    mr="4px"
                  />
                  {Math.trunc((blood_amount / regular_blood_amount) * 100)}%
                </ProgressBar>
              </Tooltip>
            </Stack.Item>
          </Stack>
        </LabeledList.Item>
        <LabeledList.Item label="Body Temperature" color={tempData.background}>
          <Box inline bold={body_temperature.level !== TempLevels.OK}>
            {body_temperature.current}
          </Box>
          {!!(body_temperature.level !== TempLevels.OK) && (
            <MedBoxedTag
              ml={SPACING_PIXELS}
              backgroundColor={tempData.background}
              textColor={tempData.foreground}
            >
              {tempData.tag}
            </MedBoxedTag>
          )}
        </LabeledList.Item>
        <LabeledList.Item label="Pulse">{pulse}</LabeledList.Item>
      </LabeledList>
      {!!internal_bleeding && (
        <NoticeBox color={'red'} mt={'8px'} mb={'0px'}>
          Internal Bleeding Detected!
        </NoticeBox>
      )}
      {!!infection && (
        <NoticeBox color="orange" mt="8px" mb="0px">
          {infection}
        </NoticeBox>
      )}
      {!!total_unknown_implants && (
        <NoticeBox color="orange" mt="8px" mb="0px">
          There {total_unknown_implants !== 1 ? 'are' : 'is'}{' '}
          {total_unknown_implants} unknown implant
          {total_unknown_implants !== 1 ? 's' : ''} detected within the patient.
        </NoticeBox>
      )}
    </Section>
  );
}
