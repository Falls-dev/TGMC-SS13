import { Fragment, useEffect, useState } from 'react';
import {
  AnimatedNumber,
  Box,
  Button,
  Collapsible,
  Divider,
  Flex,
  Icon,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const CATEGORY_DATA = {
  Operations: { name: 'Тактическое снаряжение', icon: 'parachute-box' },
  Weapons: { name: 'Вооружение', icon: 'fighter-jet' },
  Smartguns: { name: 'Смартганы', icon: 'star' },
  Stationary: { name: 'Турели и Стационарное вооружение', icon: 'bolt' },
  Launchers: { name: 'Гранатометы', icon: 'rocket' },
  Explosives: { name: 'Взрывчатка', icon: 'bomb' },
  Armor: { name: 'Броня', icon: 'hard-hat' },
  Clothing: { name: 'Униформа', icon: 'tshirt' },
  Medical: { name: 'Медикаменты', icon: 'medkit' },
  Engineering: { name: 'Инженерия', icon: 'tools' },
  Supplies: { name: 'Провизия', icon: 'hamburger' },
  Imports: { name: 'Импорт', icon: 'boxes' },
  Vehicles: { name: 'Техника', icon: 'road' },
  Factory: { name: 'Производство', icon: 'industry' },
  'Pending Order': { name: 'Корзина', icon: 'shopping-cart' },
};

const getCategoryInfo = (cat) => CATEGORY_DATA[cat] || { name: cat, icon: 'box' };

export const Cargo = () => {
  const { data } = useBackend();
  const [selectedMenu, setSelectedMenu] = useState('Operations');
  const [filter, setFilter] = useState('');

  useEffect(() => setFilter(''), [selectedMenu]);

  const {
    supplypacks = {},
    approvedrequests = [],
    deniedrequests = [],
    shopping_history = [],
    awaiting_delivery = [],
  } = data;

  const selectedPackCat = supplypacks[selectedMenu] || null;

  return (
    <Window title="Терминал Логистики Карго" width={1120} height={720}>
      <Window.Content className="theme-cargo">
        <Flex height="100%" align="stretch" spacing={1.5}>
          <Flex.Item width="300px">
            <Menu selectedMenu={selectedMenu} setSelectedMenu={setSelectedMenu} />
          </Flex.Item>

          <Flex.Item position="relative" grow={1} height="100%">
            <Section fill scrollable>
              {!!supplypacks[selectedMenu] && (
                <Box mb={1.5}>
                  <Input
                    autoFocus
                    placeholder="Поиск..."
                    fluid
                    expensive
                    value={filter}
                    onChange={setFilter}
                  />
                </Box>
              )}

              <Box key={filter ? 'search-results' : selectedMenu} className="crt-effect">
                {selectedMenu === 'Previous Purchases' && (
                  <OrderList
                    type={shopping_history}
                    readOnly={1}
                    selectedMenu="История покупок"
                  />
                )}

                {selectedMenu === 'Export History' && <Exports />}

                {selectedMenu === 'Awaiting Delivery' && (
                  <OrderList
                    type={awaiting_delivery}
                    readOnly={1}
                    selectedMenu="Доставка"
                  />
                )}

                {selectedMenu === 'Pending Order' && (
                  <ShoppingCart
                    selectedMenu={selectedMenu}
                    setSelectedMenu={setSelectedMenu}
                  />
                )}

                {selectedMenu === 'Requests' && <Requests />}

                {selectedMenu === 'Approved Requests' && (
                  <OrderList
                    type={approvedrequests}
                    selectedMenu="Одобренные запросы"
                  />
                )}

                {selectedMenu === 'Denied Requests' && (
                  <OrderList
                    type={deniedrequests}
                    selectedMenu="Отклоненные запросы"
                  />
                )}

                {!!filter && (
                  <SearchResults
                    supplypacks={supplypacks}
                    filter={filter}
                    setSelectedMenu={setSelectedMenu}
                  />
                )}

                {!!selectedPackCat && !filter && (
                  <Category
                    selectedPackCat={selectedPackCat}
                    selectedMenu={selectedMenu}
                  />
                )}
              </Box>
            </Section>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

const Exports = () => {
  const { data } = useBackend();
  const { export_history = [] } = data;

  return (
    <Section title="История Экспорта" icon="file-export">
      {!export_history.length ? (
        <NoticeBox info>Нет данных по экспорту.</NoticeBox>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Наименование</Table.Cell>
            <Table.Cell collapsing>Количество</Table.Cell>
            <Table.Cell collapsing>Очки за ед.</Table.Cell>
            <Table.Cell collapsing>Всего очков</Table.Cell>
          </Table.Row>
          {export_history.map((exp) => (
            <Table.Row key={exp.id}>
              <Table.Cell bold>{exp.name}</Table.Cell>
              <Table.Cell textAlign="center">{exp.amount}</Table.Cell>
              <Table.Cell textAlign="right">{exp.points}</Table.Cell>
              <Table.Cell textAlign="right" bold>
                {exp.total}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const MenuButton = (props) => {
  const { condition, menuname, icon, label, selectedMenu, setSelectedMenu } = props;
  const isSelected = selectedMenu === menuname;

  return (
    <Button
      fluid
      icon={icon}
      selected={isSelected}
      onClick={() => setSelectedMenu(menuname)}
      disabled={condition}
      className="sci-fi-shit"
      style={{ marginBottom: '3px', textAlign: 'left' }}
    >
      {label || menuname}
    </Button>
  );
};

const Menu = (props) => {
  const { act, data } = useBackend();
  const { readOnly, selectedMenu, setSelectedMenu } = props;

  const {
    requests = [],
    currentpoints = 0,
    personalpoints = 0,
    categories = [],
    shopping_list_cost = 0,
    shopping_list_items = 0,
    elevator,
    elevator_dir,
    export_history = [],
    deniedrequests = [],
    approvedrequests = [],
    awaiting_delivery_orders = 0,
    shopping_history = [],
  } = data;

  const elev_status = elevator === 'Raised' || elevator === 'Lowered';

  return (
    <Section fill className="cargo-sidebar">
      <Stack vertical fill spacing={1}>
        <Stack.Item>
          <Box
            p={1}
            mb={1}
            style={{
              border: '1px solid rgba(224, 134, 46, 0.8)',
              borderRadius: '4px',
              backgroundColor: 'rgba(0, 0, 0, 0.2)',
            }}
          >
            <Flex justify="flex-start" align="center" mb={0.5}>
              <Box color="label" width="90px" mr={1}>Очки Карго:</Box>
              <Box fontSize="1.2em" bold color="primary">
                <AnimatedNumber value={currentpoints} />
              </Box>
            </Flex>
            <Flex justify="flex-start" align="center">
              <Box color="label" width="90px" mr={1}>Личные очки:</Box>
              <Box fontSize="1.1em" bold color="warning">
                <AnimatedNumber value={personalpoints} />
              </Box>
            </Flex>
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Flex align="center" justify="space-between">
            <Flex.Item grow={1}>
              <MenuButton
                icon="truck-loading"
                menuname="Awaiting Delivery"
                label="Доставка"
                condition={!awaiting_delivery_orders}
                selectedMenu={selectedMenu}
                setSelectedMenu={setSelectedMenu}
              />
            </Flex.Item>
            <Box ml={1} bold color={awaiting_delivery_orders ? 'warning' : 'label'}>
              <AnimatedNumber value={awaiting_delivery_orders} />
            </Box>
          </Flex>

          {!readOnly && (
            <Button
              fluid
              mt={0.5}
              icon={`angle-double-${elevator_dir || 'up'}`}
              disabled={!elev_status}
              tooltip="Управление грузовым подъемником"
              onClick={() => act('send')}
            >
              Подъёмник: {elevator === 'Raised' ? 'Поднят' : 'Опущен'}
            </Button>
          )}
        </Stack.Item>

        <Divider />

        <Stack.Item>
          <Flex align="center" justify="space-between">
            <Flex.Item grow={1}>
              <MenuButton
                icon="shopping-cart"
                menuname="Pending Order"
                label="Корзина"
                condition={!shopping_list_items}
                selectedMenu={selectedMenu}
                setSelectedMenu={setSelectedMenu}
              />
            </Flex.Item>
            <Box ml={1} bold color={shopping_list_items ? 'warning' : 'label'}>
              <AnimatedNumber value={shopping_list_items} />
            </Box>
          </Flex>

          {shopping_list_cost > 0 && (
            <Box textAlign="right" color="label" fontSize="0.9em" mt={0.2} mb={1}>
              Сумма: <AnimatedNumber value={shopping_list_cost} /> очков
            </Box>
          )}
        </Stack.Item>

        <Divider />

        <Stack.Item>
          <Flex align="center" justify="space-between">
            <Flex.Item grow={1}>
              <MenuButton
                icon="clipboard-list"
                menuname="Requests"
                label="Запросы"
                condition={!requests.length}
                selectedMenu={selectedMenu}
                setSelectedMenu={setSelectedMenu}
              />
            </Flex.Item>
            <Box ml={1} bold color={requests.length ? 'warning' : 'label'}>
              {requests.length}
            </Box>
          </Flex>

          <MenuButton
            icon="clipboard-check"
            menuname="Approved Requests"
            label="Одобренные запросы"
            condition={!approvedrequests.length}
            selectedMenu={selectedMenu}
            setSelectedMenu={setSelectedMenu}
          />
          <MenuButton
            icon="times-circle"
            menuname="Denied Requests"
            label="Отклоненные запросы"
            condition={!deniedrequests.length}
            selectedMenu={selectedMenu}
            setSelectedMenu={setSelectedMenu}
          />
        </Stack.Item>

        {!readOnly && (
          <>
            <Divider />
            <Stack.Item>
              <MenuButton
                icon="history"
                menuname="Previous Purchases"
                label="История покупок"
                condition={!shopping_history.length}
                selectedMenu={selectedMenu}
                setSelectedMenu={setSelectedMenu}
              />
              <MenuButton
                icon="shipping-fast"
                menuname="Export History"
                label="История экспорта"
                condition={!export_history.length}
                selectedMenu={selectedMenu}
                setSelectedMenu={setSelectedMenu}
              />
            </Stack.Item>
          </>
        )}

        <Divider />

        <Stack.Item grow={1} style={{ overflowY: 'auto' }}>
          {categories.map((category) => {
            const catInfo = getCategoryInfo(category);
            return (
              <MenuButton
                key={category}
                icon={catInfo.icon}
                menuname={category}
                label={catInfo.name}
                selectedMenu={selectedMenu}
                setSelectedMenu={setSelectedMenu}
              />
            );
          })}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const OrderList = (props) => {
  const { act, data } = useBackend();
  const { currentpoints = 0 } = data;
  const { type = [], buttons, readOnly, selectedMenu } = props;
  const [actedOrders, setActedOrders] = useState({});
  const handleOrderAction = (id, actionType) => {
    setActedOrders((prev) => ({ ...prev, [id]: actionType }));
    setTimeout(() => act(actionType, { id }), 2200);
  };
  const pendingSpentPoints = type.reduce((sum, request) => {
    return actedOrders[request.id] === 'approve' ? sum + (request.cost || 0) : sum;
  }, 0);
  const effectivePoints = currentpoints - pendingSpentPoints;

  return (
    <Section title={selectedMenu} buttons={buttons}>
      {!type.length ? (
        <NoticeBox color="primary" mx={1}>Список пуст.</NoticeBox>
      ) : (
        type.map((request) => {
          const {
            id,
            orderer_rank = '',
            orderer = 'Неизвестно',
            authed_by,
            reason = 'Причина не указана',
            cost = 0,
            packs = {},
            personal_purchase,
          } = request;

          const actionStatus = actedOrders[id];
          const isApproved = actionStatus === 'approve';
          const isDenied = actionStatus === 'deny';
          const isDelivery = actionStatus === 'delivery';

          return (
            <Box
              key={id}
              position="relative"
              style={{
                maxHeight: actionStatus ? '0px' : '400px',
                overflow: 'hidden',
                marginBottom: actionStatus ? '0px' : '8px',
                opacity: actionStatus ? 0 : 1,
                transition: 'max-height 0.6s ease-in-out 1.6s, margin-bottom 0.6s ease-in-out 1.6s, opacity 0.4s ease-out 1.6s',
              }}
            >
              <Box position="relative" style={{ overflow: 'hidden', borderRadius: '3px' }}>
                <Section
                  level={2}
                  title={personal_purchase ? `Личный заказ #${id}` : `Заказ #${id}`}
                  style={{
                    paddingTop: '3px',
                    opacity: actionStatus ? 0.4 : 1,
                    transition: 'opacity 1.6s ease-out',
                  }}
                  buttons={
                    <Box inline style={{ transform: 'translateY(-2px)' }}>
                      {!readOnly && !authed_by && (
                        <Button
                          compact
                          color="good"
                          icon="check"
                          disabled={cost > effectivePoints}
                          onClick={() => handleOrderAction(id, 'approve')}
                        >
                          Одобрить
                        </Button>
                      )}
                      {!readOnly && !authed_by && (
                        <Button
                          compact
                          color="bad"
                          icon="times"
                          onClick={() => handleOrderAction(id, 'deny')}
                        >
                          Отклонить
                        </Button>
                      )}
                      {selectedMenu === 'Доставка' && (
                        <Button
                          compact
                          color="warning"
                          icon="parachute-box"
                          content="Быстрый сброс"
                          tooltip={
                            personal_purchase
                              ? 'Сброс бесплатен!'
                              : 'Быстрая доставка спишет 150 очков карго.'
                          }
                          disabled={!data.beacon || (!personal_purchase && effectivePoints < 150)}
                          onClick={() => handleOrderAction(id, 'delivery')}
                        />
                      )}
                    </Box>
                  }
                >
                  <LabeledList>
                    <LabeledList.Item label="Запросил">
                      <b>{orderer_rank} {orderer}</b>
                    </LabeledList.Item>
                    <LabeledList.Item label="Причина">{reason}</LabeledList.Item>
                    <LabeledList.Item label="Стоимость">
                      <Box inline bold color="primary">{cost} очков</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Содержимое">
                      <Packs packs={packs} />
                    </LabeledList.Item>
                  </LabeledList>
                </Section>

                <Box
                  position="absolute"
                  top={0}
                  left={0}
                  bottom={0}
                  className={
                    isApproved ? 'overlay-approve' :
                    isDenied ? 'overlay-deny' :
                    isDelivery ? 'overlay-delivery' : ''
                  }
                  style={{
                    width: actionStatus ? '100%' : '0%',
                    transition: 'width 1.6s cubic-bezier(0.4, 0, 0.2, 1)',
                    zIndex: 10,
                    pointerEvents: 'none',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    overflow: 'hidden',
                  }}
                >
                  {!isDelivery && (
                    <Box
                      style={{
                        color: 'white',
                        fontSize: '2.2em',
                        fontWeight: 'bold',
                        textShadow: '0px 2px 4px rgba(0,0,0,0.7)',
                        whiteSpace: 'nowrap',
                        opacity: actionStatus ? 1 : 0,
                        transition: 'opacity 0.4s ease-in 0.4s',
                      }}
                      className={
                        isDenied ? 'glitch-text' :
                        isApproved ? 'approved-glow' : ''
                      }
                    >
                      {isApproved ? 'ОДОБРЕНО' : isDenied ? 'ОТКЛОНЕНО' : ''}
                    </Box>
                  )}
                </Box>

                {isDelivery && (
                  <Box
                    position="absolute"
                    top={0}
                    left={0}
                    bottom={0}
                    right={0}
                    style={{
                      zIndex: 11,
                      pointerEvents: 'none',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <Box
                      style={{
                        color: 'white',
                        fontSize: '2.2em',
                        fontWeight: 'bold',
                        whiteSpace: 'nowrap',
                      }}
                      className="delivery-text"
                    >
                      ЗАКАЗ ОТПРАВЛЕН
                    </Box>
                  </Box>
                )}
              </Box>
            </Box>
          );
        })
      )}
    </Section>
  );
};

const Packs = (props) => {
  const { packs = {} } = props;
  return Object.keys(packs).map((pack) => (
    <Pack pack={pack} key={pack} amount={packs[pack]} />
  ));
};

const Pack = (props) => {
  const { data } = useBackend();
  const { pack, amount } = props;
  const { supplypackscontents = {} } = data;
  const packData = supplypackscontents[pack] || {};
  const { name = pack, item_notes, cost = 0, contains } = packData;

  return contains && typeof contains === 'object' ? (
    <Collapsible
      color="transparent"
      title={<PackName cost={cost} name={name} amount={amount} />}
    >
      {item_notes && (
        <Box color="label" fontSize="0.9em" mb={0.5}>
          Примечание: {item_notes}
        </Box>
      )}
      <Table>
        <PackContents contains={contains} />
      </Table>
    </Collapsible>
  ) : (
    <PackName cost={cost} name={name} amount={amount} pl="20px" />
  );
};

const PackName = (props) => {
  const { cost, name, amount, pl = '0px' } = props;

  return (
    <Box inline pl={pl}>
      <Box inline textAlign="right" width="130px" color="warning" mr={1}>
        {amount ? `${amount}x ` : ''}
        {cost} очков {amount ? `(${amount * cost})` : ''}
      </Box>
      <Box inline bold>{name}</Box>
    </Box>
  );
};

const Requests = (props) => {
  const { act, data } = useBackend();
  const { readOnly } = props;
  const { requests = [], currentpoints = 0 } = data;
  const totalCost = requests.reduce((sum, req) => sum + (req.cost || 0), 0);

  return (
    <OrderList
      type={requests}
      readOnly={readOnly}
      selectedMenu="Запросы в ожидании"
      buttons={
        !readOnly && (
          <Box inline style={{ transform: 'translateY(-2px)' }}>
            <Button
              compact
              icon="check-double"
              color="good"
              disabled={currentpoints < totalCost}
              onClick={() => act('approveall')}
            >
              Одобрить все
            </Button>
            <Button
              compact
              icon="times-circle"
              color="bad"
              onClick={() => act('denyall')}
            >
              Отклонить все
            </Button>
          </Box>
        )
      }
    />
  );
};

const ShoppingCart = (props) => {
  const { act, data } = useBackend();
  const {
    shopping_list = {},
    shopping_list_items = 0,
    shopping_list_cost = 0,
    personalpoints = 0,
  } = data;
  const { readOnly, selectedMenu } = props;
  const shopping_list_array = Object.keys(shopping_list);
  const [reason, setReason] = useState('');

  const canAffordPersonal = shopping_list_items > 0 && personalpoints >= shopping_list_cost && shopping_list_cost > 0;

  return (
    <Section title="Текущая Корзина" icon="shopping-cart">
      <Stack vertical spacing={1.5}>
        <Stack.Item>
          <Flex spacing={1} justify="center">
            <Button
              icon="paper-plane"
              color="good"
              style={{ height: '26px' }}
              disabled={(readOnly && !reason.trim()) || !shopping_list_items}
              onClick={() =>
                act(readOnly ? 'submitrequest' : 'buycart', { reason })
              }
            >
              <b>{readOnly ? 'Отправить запрос' : 'Оплатить корзину'}</b>
            </Button>

            <Button
              icon="user-check"
              color="warning"
              style={{ height: '26px' }}
              className={canAffordPersonal ? 'can-afford-personal' : ''}
              disabled={!shopping_list_items}
              tooltip="Оплатить из личных очков"
              onClick={() => act('buypersonal')}
            >
              <b>Личная покупка</b>
            </Button>

            <Button
              icon="trash-alt"
              color="bad"
              style={{ height: '26px' }}
              disabled={!shopping_list_items}
              onClick={() => act('clearcart')}
            >
              <b>Очистить корзину</b>
            </Button>
          </Flex>
        </Stack.Item>

        {readOnly && (
          <Stack.Item>
            <Box color="label" mb={0.5} ml={0.5}>Причина запроса:</Box>
            <Input autoFocus placeholder="Укажите обоснование..." fluid value={reason} onChange={setReason} />
          </Stack.Item>
        )}

        <Stack.Item grow={1}>
          <Category
            selectedPackCat={shopping_list_array}
            level={0}
            selectedMenu={selectedMenu}
            hideTitle
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const CategoryButton = (props) => {
  const { act } = useBackend();
  const { icon, disabled, id, mode, tooltip } = props;

  return (
    <Button
      compact
      icon={icon}
      disabled={disabled}
      tooltip={tooltip}
      onClick={() => act('cart', { id, mode })}
    />
  );
};

const Category = (props) => {
  const { data } = useBackend();
  const {
    shopping_list = {},
    shopping_list_cost = 0,
    currentpoints = 0,
    supplypackscontents = {},
  } = data;

  const spare_points = currentpoints - shopping_list_cost;
  const { selectedPackCat = [], level = 1, selectedMenu, hideTitle } = props;
  const catInfo = getCategoryInfo(selectedMenu);

  return (
    <Section
      level={level}
      title={
        !hideTitle && (
          <>
            <Icon name={catInfo.icon} mr={1} />
            {catInfo.name}
          </>
        )
      }
    >
      <Table>
        {selectedPackCat.map((entry) => {
          const shop_list = shopping_list[entry] || 0;
          const count = shop_list ? shop_list.count : 0;
          const packData = supplypackscontents[entry] || {};
          const cost = packData.cost || 0;

          return (
            <Table.Row key={entry}>
              <Table.Cell width="140px" textAlign="center">
                <Stack spacing={0.25} align="center">
                  <CategoryButton
                    icon="fast-backward"
                    disabled={!count}
                    id={entry}
                    mode="removeall"
                    tooltip="Убрать всё"
                  />
                  <CategoryButton
                    icon="minus"
                    disabled={!count}
                    id={entry}
                    mode="removeone"
                    tooltip="Убрать 1 шт."
                  />
                  <Box width="28px" textAlign="center" bold>
                    {!!count && <AnimatedNumber value={count} />}
                  </Box>
                  <CategoryButton
                    icon="plus"
                    id={entry}
                    mode="addone"
                    tooltip="Добавить 1 шт."
                  />
                  <CategoryButton
                    icon="fast-forward"
                    disabled={cost > spare_points}
                    id={entry}
                    mode="addall"
                    tooltip="Добавить на все оставшиеся очки"
                  />
                </Stack>
              </Table.Cell>
              <Table.Cell>
                <Pack pack={entry} />
              </Table.Cell>
            </Table.Row>
          );
        })}
      </Table>
    </Section>
  );
};

const SearchResults = (props) => {
  const { data } = useBackend();
  const { supplypackscontents = {} } = data;
  const { supplypacks = {}, filter } = props;
  const normalizedFilter = filter.toLowerCase();

  return Object.entries(supplypacks).map(([category, packs]) => {
    const matchingPacks = packs.filter((entry) =>
      supplypackscontents[entry]?.name
        ?.toLowerCase()
        .includes(normalizedFilter),
    );
    if (!matchingPacks.length) return null;

    return (
      <Category
        key={category}
        selectedPackCat={matchingPacks}
        selectedMenu={category}
      />
    );
  });
};

const PackContents = (props) => {
  const { contains = {} } = props;

  return (
    <>
      <Table.Row header>
        <Table.Cell>Содержимое набора</Table.Cell>
        <Table.Cell collapsing textAlign="right">
          Количество
        </Table.Cell>
      </Table.Row>
      {Object.values(contains).map((value, index) => (
        <Table.Row key={index}>
          <Table.Cell color="label">{value.name}</Table.Cell>
          <Table.Cell textAlign="right" bold>
            x{value.count}
          </Table.Cell>
        </Table.Row>
      ))}
    </>
  );
};

export const CargoRequest = (props) => {
  const { data } = useBackend();

  const [selectedMenu, setSelectedMenu] = useState('Operations');
  const [filter, setFilter] = useState('');
  useEffect(() => setFilter(''), [selectedMenu]);

  const { supplypacks = {}, approvedrequests = [], deniedrequests = [], awaiting_delivery = [] } =
    data;

  const selectedPackCat = supplypacks[selectedMenu] || null;

  return (
    <Window title="Консоль Запросов Снабжения" width={1120} height={720}>
      <Window.Content className="theme-cargo">
        <Flex height="100%" align="stretch" spacing={1.5}>
          <Flex.Item width="300px">
            <Menu
              readOnly={1}
              selectedMenu={selectedMenu}
              setSelectedMenu={setSelectedMenu}
            />
          </Flex.Item>
          <Flex.Item position="relative" grow={1} height="100%">
            <Section fill scrollable>
              {!!supplypacks[selectedMenu] && (
                <Box mb={1.5}>
                  <Input
                    autoFocus
                    placeholder="Поиск..."
                    fluid
                    expensive
                    value={filter}
                    onChange={setFilter}
                  />
                </Box>
              )}

              <Box key={filter ? 'search-results' : selectedMenu} className="crt-effect">
                {selectedMenu === 'Awaiting Delivery' && (
                  <OrderList
                    type={awaiting_delivery}
                    readOnly={1}
                    selectedMenu="Доставка"
                  />
                )}
                {selectedMenu === 'Pending Order' && (
                  <ShoppingCart
                    readOnly={1}
                    selectedMenu={selectedMenu}
                    setSelectedMenu={setSelectedMenu}
                  />
                )}
                {selectedMenu === 'Requests' && (
                  <Requests
                    readOnly={1}
                    selectedMenu={selectedMenu}
                    setSelectedMenu={setSelectedMenu}
                  />
                )}
                {selectedMenu === 'Approved Requests' && (
                  <OrderList
                    type={approvedrequests}
                    selectedMenu="Одобренные запросы"
                  />
                )}
                {selectedMenu === 'Denied Requests' && (
                  <OrderList
                    type={deniedrequests}
                    selectedMenu="Отклоненные запросы"
                  />
                )}
                {!!filter && (
                  <SearchResults
                    supplypacks={supplypacks}
                    filter={filter}
                    setSelectedMenu={setSelectedMenu}
                  />
                )}
                {!!selectedPackCat && !filter && (
                  <Category
                    selectedPackCat={selectedPackCat}
                    selectedMenu={selectedMenu}
                  />
                )}
              </Box>
            </Section>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};
