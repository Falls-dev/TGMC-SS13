import { useMemo, useState } from 'react';
import {
  Box,
  Button,
  Divider,
  Dropdown,
  Input,
  LabeledList,
  Modal,
  NoticeBox,
  Section,
  Stack,
  Table,
  TextArea,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CommentEntry = {
  index: number;
  text: string;
};

type RecordDetail = {
  has_general: BooleanLike;
  has_security: BooleanLike;
  id?: string;
  name?: string;
  rank?: string;
  sex?: string;
  age?: number | string;
  fingerprint?: string;
  p_stat?: string;
  m_stat?: string;
  photo_front?: string;
  photo_side?: string;
  criminal?: string;
  mi_crim?: string;
  mi_crim_d?: string;
  ma_crim?: string;
  ma_crim_d?: string;
  notes?: string;
  comments?: CommentEntry[];
};

type RecordListEntry = {
  id: string;
  name: string;
  rank: string;
  fingerprint: string;
  criminal: string;
};

type Data = {
  authenticated: string | null;
  rank: string | null;
  scan_name: string | null;
  printing: BooleanLike;
  records: RecordListEntry[];
  record: RecordDetail | null;
};

type EditField = {
  field: string;
  label: string;
  value: string;
  type: 'text' | 'number' | 'select' | 'textarea';
  options?: string[];
};

const CRIMINAL_STATUSES = [
  'None',
  '*Arrest*',
  'Incarcerated',
  'Released',
] as const;

const criminalColor = (status: string | undefined) => {
  switch (status) {
    case '*Arrest*':
      return 'bad';
    case 'Incarcerated':
      return 'average';
    case 'Released':
      return 'blue';
    default:
      return undefined;
  }
};

export const SecurityRecords = () => {
  const { act, data } = useBackend<Data>();
  const {
    authenticated,
    rank,
    scan_name,
    printing,
    records = [],
    record,
  } = data;

  const [filterText, setFilterText] = useState('');
  const [sortKey, setSortKey] = useState<keyof RecordListEntry>('name');
  const [sortAsc, setSortAsc] = useState(true);
  const [editField, setEditField] = useState<EditField | null>(null);
  const [editValue, setEditValue] = useState('');
  const [commentModal, setCommentModal] = useState(false);
  const [commentText, setCommentText] = useState('');
  const [searchModal, setSearchModal] = useState(false);
  const [searchValue, setSearchValue] = useState('');
  const [photoSide, setPhotoSide] = useState(false);

  const filteredRecords = useMemo(() => {
    const query = filterText.toLowerCase();
    const list = records.filter((entry) =>
      Object.values(entry).some((value) =>
        String(value).toLowerCase().includes(query),
      ),
    );
    list.sort((a, b) => {
      const left = String(a[sortKey] ?? '');
      const right = String(b[sortKey] ?? '');
      if (left < right) {
        return sortAsc ? -1 : 1;
      }
      if (left > right) {
        return sortAsc ? 1 : -1;
      }
      return 0;
    });
    return list;
  }, [records, filterText, sortKey, sortAsc]);

  const openEdit = (field: EditField) => {
    setEditField(field);
    setEditValue(field.value ?? '');
  };

  const saveEdit = (value = editValue) => {
    if (!editField) {
      return;
    }
    act('set_field', { field: editField.field, value });
    setEditField(null);
    setEditValue('');
  };

  const handleSort = (key: keyof RecordListEntry) => {
    if (sortKey === key) {
      setSortAsc(!sortAsc);
      return;
    }
    setSortKey(key);
    setSortAsc(true);
  };

  const sortMarker = (key: keyof RecordListEntry) => {
    if (sortKey !== key) {
      return '';
    }
    return sortAsc ? ' ▼' : ' ▲';
  };

  return (
    <Window width={700} height={720} title="Security Records">
      <Window.Content scrollable>
        {!authenticated ? (
          <LoginPanel
            scanName={scan_name}
            onScan={() => act('scan')}
            onLogin={() => act('login')}
          />
        ) : record ? (
          <RecordView
            record={record}
            printing={!!printing}
            authenticated={authenticated}
            rank={rank}
            photoSide={photoSide}
            onTogglePhoto={() => setPhotoSide(!photoSide)}
            onBack={() => act('clear_record')}
            onLogout={() => act('logout')}
            onPrint={() => act('print_record')}
            onNewRecord={() => act('new_record')}
            onDeleteRecord={() => act('delete_record')}
            onDeleteRecordAll={() => act('delete_record_all')}
            onAddComment={() => setCommentModal(true)}
            onDeleteComment={(index) => act('delete_comment', { index })}
            onEdit={openEdit}
          />
        ) : (
          <RecordsList
            records={filteredRecords}
            filterText={filterText}
            authenticated={authenticated}
            rank={rank}
            onFilter={setFilterText}
            onSort={handleSort}
            sortMarker={sortMarker}
            onSelect={(id) => act('select_record', { id })}
            onSearch={() => setSearchModal(true)}
            onNewGeneral={() => act('new_general_record')}
            onDeleteAll={() => act('delete_all_records')}
            onLogout={() => act('logout')}
            onScan={() => act('scan')}
            scanName={scan_name}
          />
        )}

        {editField && (
          <EditModal
            field={editField}
            value={editValue}
            onChange={setEditValue}
            onCancel={() => {
              setEditField(null);
              setEditValue('');
            }}
            onSave={saveEdit}
          />
        )}

        {commentModal && (
          <Modal width="400px">
            <Section title="Add Comment">
              <TextArea
                fluid
                height="100px"
                value={commentText}
                onChange={setCommentText}
                placeholder="Enter your comment..."
              />
              <Stack justify="space-between" mt={2}>
                <Button
                  onClick={() => {
                    setCommentModal(false);
                    setCommentText('');
                  }}
                >
                  Cancel
                </Button>
                <Button
                  color="good"
                  disabled={!commentText.trim()}
                  onClick={() => {
                    act('add_comment', { value: commentText });
                    setCommentModal(false);
                    setCommentText('');
                  }}
                >
                  Add Comment
                </Button>
              </Stack>
            </Section>
          </Modal>
        )}

        {searchModal && (
          <Modal width="400px">
            <Section title="Search Records">
              <Box mb={1}>
                Search by name, ID, fingerprints, or rank:
              </Box>
              <Input
                fluid
                autoFocus
                value={searchValue}
                onChange={setSearchValue}
                placeholder="Name, ID, fingerprints, or rank"
              />
              <Stack justify="space-between" mt={2}>
                <Button
                  onClick={() => {
                    setSearchModal(false);
                    setSearchValue('');
                  }}
                >
                  Cancel
                </Button>
                <Button
                  color="good"
                  disabled={!searchValue.trim()}
                  onClick={() => {
                    act('search', { value: searchValue });
                    setSearchModal(false);
                    setSearchValue('');
                  }}
                >
                  Search
                </Button>
              </Stack>
            </Section>
          </Modal>
        )}
      </Window.Content>
    </Window>
  );
};

const LoginPanel = (props: {
  scanName: string | null;
  onScan: () => void;
  onLogin: () => void;
}) => {
  const { scanName, onScan, onLogin } = props;
  return (
    <Section fill>
      <Stack vertical fill align="center" justify="center">
        <Stack.Item>
          <Box bold fontSize={2} textAlign="center">
            SECURITY RECORDS DATABASE
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box textAlign="center" color="label">
            Identity verification required
          </Box>
        </Stack.Item>
        <Stack.Item width="70%">
          <Divider />
        </Stack.Item>
        <Stack.Item width="60%">
          <Button fluid icon="id-card" onClick={onScan}>
            {scanName || '----------'}
          </Button>
        </Stack.Item>
        <Stack.Item width="60%">
          <Button fluid icon="sign-in-alt" color="good" onClick={onLogin}>
            Log In
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box color="bad" textAlign="center">
            Unauthorized use strictly prohibited
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const RecordsList = (props: {
  records: RecordListEntry[];
  filterText: string;
  authenticated: string;
  rank: string | null;
  scanName: string | null;
  onFilter: (value: string) => void;
  onSort: (key: keyof RecordListEntry) => void;
  sortMarker: (key: keyof RecordListEntry) => string;
  onSelect: (id: string) => void;
  onSearch: () => void;
  onNewGeneral: () => void;
  onDeleteAll: () => void;
  onLogout: () => void;
  onScan: () => void;
}) => {
  const {
    records,
    filterText,
    authenticated,
    rank,
    scanName,
    onFilter,
    onSort,
    sortMarker,
    onSelect,
    onSearch,
    onNewGeneral,
    onDeleteAll,
    onLogout,
    onScan,
  } = props;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section
          title="Security Records"
          buttons={
            <Stack>
              <Stack.Item>
                <Box mt={0.4} mr={1}>
                  {authenticated}
                  {rank ? ` (${rank})` : ''}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button icon="sign-out-alt" onClick={onLogout}>
                  Log Out
                </Button>
              </Stack.Item>
            </Stack>
          }
        >
          <Stack mb={1}>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Filter records..."
                value={filterText}
                onChange={onFilter}
              />
            </Stack.Item>
            <Stack.Item>
              <Button icon="search" onClick={onSearch}>
                Search
              </Button>
            </Stack.Item>
          </Stack>
          <Stack mb={1}>
            <Stack.Item grow>
              <Button fluid icon="id-card" onClick={onScan}>
                ID: {scanName || '----------'}
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button icon="plus" color="good" onClick={onNewGeneral}>
                New Record
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button.Confirm
                icon="trash"
                color="bad"
                confirmContent="Confirm delete all?"
                onClick={onDeleteAll}
              >
                Delete All Security Records
              </Button.Confirm>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable>
          <Table>
            <Table.Row header>
              <Table.Cell
                style={{ cursor: 'pointer' }}
                onClick={() => onSort('name')}
              >
                Name{sortMarker('name')}
              </Table.Cell>
              <Table.Cell
                style={{ cursor: 'pointer' }}
                onClick={() => onSort('id')}
              >
                ID{sortMarker('id')}
              </Table.Cell>
              <Table.Cell
                style={{ cursor: 'pointer' }}
                onClick={() => onSort('rank')}
              >
                Rank{sortMarker('rank')}
              </Table.Cell>
              <Table.Cell
                style={{ cursor: 'pointer' }}
                onClick={() => onSort('fingerprint')}
              >
                Fingerprints{sortMarker('fingerprint')}
              </Table.Cell>
              <Table.Cell
                style={{ cursor: 'pointer' }}
                onClick={() => onSort('criminal')}
              >
                Status{sortMarker('criminal')}
              </Table.Cell>
            </Table.Row>
            {records.map((entry) => (
              <Table.Row key={entry.id}>
                <Table.Cell>
                  <Button onClick={() => onSelect(entry.id)}>
                    {entry.name}
                  </Button>
                </Table.Cell>
                <Table.Cell>{entry.id}</Table.Cell>
                <Table.Cell>{entry.rank}</Table.Cell>
                <Table.Cell>{entry.fingerprint}</Table.Cell>
                <Table.Cell>
                  <Box color={criminalColor(entry.criminal)}>
                    {entry.criminal || '—'}
                  </Box>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
          {!records.length && (
            <NoticeBox mt={2}>No records match the current filter.</NoticeBox>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const EditableValue = (props: {
  value: string | number | undefined;
  onEdit: () => void;
  color?: string;
}) => {
  const { value, onEdit, color } = props;
  return (
    <Button compact color={color} onClick={onEdit}>
      {value ?? 'N/A'}
    </Button>
  );
};

const RecordView = (props: {
  record: RecordDetail;
  printing: boolean;
  authenticated: string;
  rank: string | null;
  photoSide: boolean;
  onTogglePhoto: () => void;
  onBack: () => void;
  onLogout: () => void;
  onPrint: () => void;
  onNewRecord: () => void;
  onDeleteRecord: () => void;
  onDeleteRecordAll: () => void;
  onAddComment: () => void;
  onDeleteComment: (index: number) => void;
  onEdit: (field: EditField) => void;
}) => {
  const {
    record,
    printing,
    authenticated,
    rank,
    photoSide,
    onTogglePhoto,
    onBack,
    onLogout,
    onPrint,
    onNewRecord,
    onDeleteRecord,
    onDeleteRecordAll,
    onAddComment,
    onDeleteComment,
    onEdit,
  } = props;

  const photo = photoSide ? record.photo_side : record.photo_front;

  return (
    <Stack vertical>
      <Stack.Item>
        <Section
          title={`Security Record — ${record.name ?? 'Unknown'}`}
          buttons={
            <Stack>
              <Stack.Item>
                <Box mt={0.4} mr={1}>
                  {authenticated}
                  {rank ? ` (${rank})` : ''}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button icon="sign-out-alt" onClick={onLogout}>
                  Log Out
                </Button>
              </Stack.Item>
            </Stack>
          }
        >
          <Stack>
            <Stack.Item grow>
              {!record.has_general ? (
                <NoticeBox danger>General Record Lost!</NoticeBox>
              ) : (
                <LabeledList>
                  <LabeledList.Item label="Name">
                    <EditableValue
                      value={record.name}
                      onEdit={() =>
                        onEdit({
                          field: 'name',
                          label: 'Name',
                          value: String(record.name ?? ''),
                          type: 'text',
                        })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="ID">
                    <EditableValue
                      value={record.id}
                      onEdit={() =>
                        onEdit({
                          field: 'id',
                          label: 'ID',
                          value: String(record.id ?? ''),
                          type: 'text',
                        })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Rank">{record.rank}</LabeledList.Item>
                  <LabeledList.Item label="Sex">
                    <EditableValue
                      value={record.sex}
                      onEdit={() =>
                        onEdit({
                          field: 'sex',
                          label: 'Sex',
                          value: String(record.sex ?? 'Male'),
                          type: 'select',
                          options: ['Male', 'Female'],
                        })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Age">
                    <EditableValue
                      value={record.age}
                      onEdit={() =>
                        onEdit({
                          field: 'age',
                          label: 'Age',
                          value: String(record.age ?? ''),
                          type: 'number',
                        })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Fingerprint">
                    <EditableValue
                      value={record.fingerprint}
                      onEdit={() =>
                        onEdit({
                          field: 'fingerprint',
                          label: 'Fingerprint',
                          value: String(record.fingerprint ?? ''),
                          type: 'text',
                        })
                      }
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Physical Status">
                    {record.p_stat}
                  </LabeledList.Item>
                  <LabeledList.Item label="Mental Status">
                    {record.m_stat}
                  </LabeledList.Item>
                </LabeledList>
              )}
            </Stack.Item>
            <Stack.Item>
              <Section>
                <Box textAlign="center">
                  {photo ? (
                    <img
                      src={photo}
                      alt="Record photo"
                      style={{
                        width: '96px',
                        height: '96px',
                        border: '1px solid #444',
                      }}
                    />
                  ) : (
                    <Box
                      width="96px"
                      height="96px"
                      backgroundColor="#222"
                      style={{
                        lineHeight: '96px',
                        textAlign: 'center',
                      }}
                    >
                      No Photo
                    </Box>
                  )}
                </Box>
                <Button fluid mt={1} onClick={onTogglePhoto}>
                  Show {photoSide ? 'Front' : 'Side'}
                </Button>
              </Section>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title="Security Data">
          {!record.has_security ? (
            <>
              <NoticeBox>Security Record Lost!</NoticeBox>
              {!!record.has_general && (
                <Button icon="plus" color="good" onClick={onNewRecord}>
                  New Security Record
                </Button>
              )}
            </>
          ) : (
            <LabeledList>
              <LabeledList.Item label="Criminal Status">
                <EditableValue
                  value={record.criminal}
                  color={criminalColor(record.criminal)}
                  onEdit={() =>
                    onEdit({
                      field: 'criminal',
                      label: 'Criminal Status',
                      value: String(record.criminal ?? 'None'),
                      type: 'select',
                      options: [...CRIMINAL_STATUSES],
                    })
                  }
                />
              </LabeledList.Item>
              <LabeledList.Item label="Minor Crimes">
                <EditableValue
                  value={record.mi_crim}
                  onEdit={() =>
                    onEdit({
                      field: 'mi_crim',
                      label: 'Minor Crimes',
                      value: String(record.mi_crim ?? ''),
                      type: 'text',
                    })
                  }
                />
              </LabeledList.Item>
              <LabeledList.Item label="Minor Details">
                <EditableValue
                  value={record.mi_crim_d}
                  onEdit={() =>
                    onEdit({
                      field: 'mi_crim_d',
                      label: 'Minor Crime Details',
                      value: String(record.mi_crim_d ?? ''),
                      type: 'text',
                    })
                  }
                />
              </LabeledList.Item>
              <LabeledList.Item label="Major Crimes">
                <EditableValue
                  value={record.ma_crim}
                  onEdit={() =>
                    onEdit({
                      field: 'ma_crim',
                      label: 'Major Crimes',
                      value: String(record.ma_crim ?? ''),
                      type: 'text',
                    })
                  }
                />
              </LabeledList.Item>
              <LabeledList.Item label="Major Details">
                <EditableValue
                  value={record.ma_crim_d}
                  onEdit={() =>
                    onEdit({
                      field: 'ma_crim_d',
                      label: 'Major Crime Details',
                      value: String(record.ma_crim_d ?? ''),
                      type: 'text',
                    })
                  }
                />
              </LabeledList.Item>
              <LabeledList.Item label="Important Notes">
                <EditableValue
                  value={record.notes}
                  onEdit={() =>
                    onEdit({
                      field: 'notes',
                      label: 'Important Notes',
                      value: String(record.notes ?? ''),
                      type: 'textarea',
                    })
                  }
                />
              </LabeledList.Item>
            </LabeledList>
          )}
        </Section>
      </Stack.Item>

      {!!record.has_security && (
        <Stack.Item>
          <Section
            title="Comments / Log"
            buttons={
              <Button icon="plus" onClick={onAddComment}>
                Add Entry
              </Button>
            }
          >
            {(record.comments ?? []).length === 0 && (
              <Box color="label">No comments available.</Box>
            )}
            {(record.comments ?? []).map((comment) => (
              <Box key={comment.index} mb={1}>
                <Box
                  dangerouslySetInnerHTML={{ __html: comment.text }}
                  mb={0.5}
                />
                <Button
                  compact
                  color="bad"
                  onClick={() => onDeleteComment(comment.index)}
                >
                  Delete Entry
                </Button>
                <Divider />
              </Box>
            ))}
          </Section>
        </Stack.Item>
      )}

      <Stack.Item>
        <Section>
          <Stack>
            <Stack.Item grow>
              <Button
                fluid
                icon="print"
                disabled={printing}
                onClick={onPrint}
              >
                {printing ? 'Printing...' : 'Print Record'}
              </Button>
            </Stack.Item>
            {!!record.has_security && (
              <Stack.Item grow>
                <Button.Confirm
                  fluid
                  icon="trash"
                  color="bad"
                  confirmContent="Confirm delete security?"
                  onClick={onDeleteRecord}
                >
                  Delete Record (Security Only)
                </Button.Confirm>
              </Stack.Item>
            )}
            {!!record.has_general && (
              <Stack.Item grow>
                <Button.Confirm
                  fluid
                  icon="trash"
                  color="bad"
                  confirmContent="Confirm delete ALL?"
                  onClick={onDeleteRecordAll}
                >
                  Delete Record (ALL)
                </Button.Confirm>
              </Stack.Item>
            )}
          </Stack>
          <Button fluid mt={1} icon="arrow-left" onClick={onBack}>
            Back
          </Button>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const EditModal = (props: {
  field: EditField;
  value: string;
  onChange: (value: string) => void;
  onCancel: () => void;
  onSave: (value?: string) => void;
}) => {
  const { field, value, onChange, onCancel, onSave } = props;

  return (
    <Modal width="320px">
      <Section title={`Edit ${field.label}`}>
        {field.type === 'select' ? (
          <Dropdown
            width="100%"
            options={field.options ?? []}
            selected={value}
            onSelected={(selected) => onSave(selected)}
          />
        ) : field.type === 'textarea' ? (
          <TextArea
            fluid
            autoFocus
            height="120px"
            value={value}
            onChange={onChange}
          />
        ) : (
          <Input
            fluid
            autoFocus
            autoSelect
            type={field.type === 'number' ? 'number' : 'text'}
            value={value}
            onChange={onChange}
            onEnter={() => onSave()}
          />
        )}
        {field.type !== 'select' && (
          <Stack justify="space-between" mt={2}>
            <Button onClick={onCancel}>Cancel</Button>
            <Button color="good" onClick={() => onSave()}>
              Save
            </Button>
          </Stack>
        )}
      </Section>
    </Modal>
  );
};
