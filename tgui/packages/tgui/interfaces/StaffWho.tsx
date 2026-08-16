import { type ReactNode } from 'react';
import { Button, Collapsible, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type AdminPayload = {
  special_color?: string;
  special_text?: string;
  category: string;
  text?: string;
  color?: string;
};

type CategoryInfo = {
  category: string;
  category_color: string;
};

type Data = {
  base_data: {
    categories: CategoryInfo[];
    total_admins: Record<string, AdminPayload[]>[];
  };
  admin_additional?: { total_admins: Record<string, AdminPayload[]>[] };
  admin_stealthed_additional?: {
    total_admins: Record<string, AdminPayload[]>[];
  };
};

export const StaffWho = () => {
  const { data } = useBackend<Data>();
  const { base_data, admin_additional, admin_stealthed_additional } = data;

  const total_admins = mergeArrays(
    base_data?.total_admins,
    admin_additional?.total_admins,
    admin_stealthed_additional?.total_admins,
  );

  return (
    <Window width={600} height={600}>
      <Window.Content scrollable>
        {base_data ? (
          <Stack fill vertical>
            <Stack.Item mt={0.2} grow>
              <FilterCategories
                categories={base_data.categories}
                total_admins={total_admins}
              />
            </Stack.Item>
          </Stack>
        ) : null}
      </Window.Content>
    </Window>
  );
};

const FilterCategories = (props: {
  categories: CategoryInfo[];
  total_admins: Record<string, AdminPayload[]>[];
}) => {
  const { categories, total_admins } = props;

  return categories.map((category) => {
    const category_admins = total_admins.filter((adminObj) =>
      isMatch(adminObj, category.category),
    );
    return (
      <CategoryDropDown
        key={category.category}
        category={category}
        category_admins={category_admins}
      />
    );
  });
};

const StaffWhoCollapsible = (props: {
  title: string;
  color: string;
  children: ReactNode;
}) => {
  const { title, color, children } = props;
  return (
    <Collapsible title={title} color={color} open>
      {children}
    </Collapsible>
  );
};

const CategoryDropDown = (props: {
  category: CategoryInfo;
  category_admins: Record<string, AdminPayload[]>[];
}) => {
  const { category, category_admins } = props;
  return (
    <StaffWhoCollapsible
      title={`${category.category} - ${category_admins.length}`}
      color={category.category_color}
    >
      <FilterAdmins category_admins={category_admins} />
    </StaffWhoCollapsible>
  );
};

const FilterAdmins = (props: {
  category_admins: Record<string, AdminPayload[]>[];
}) => {
  const { category_admins } = props;

  return category_admins.map((adminObj) => {
    const ckey = Object.keys(adminObj)[0];
    return <GetAdminInfo key={ckey} ckey={ckey} {...adminObj[ckey][0]} />;
  });
};

const GetAdminInfo = (props: {
  ckey: string;
  special_color?: string;
  special_text?: string;
  text?: string;
  color?: string;
}) => {
  const { ckey, special_color, special_text, text, color } = props;
  return (
    <Button
      color="transparent"
      style={{
        borderColor: color || '#2185d0',
        borderStyle: 'solid',
        borderWidth: '1px',
        color: color || 'white',
      }}
      tooltip={text}
      tooltipPosition="bottom-start"
    >
      <b
        style={{
          color: special_color || color || 'white',
        }}
      >
        {ckey}
        {special_text}
      </b>
    </Button>
  );
};

const isMatch = (adminObj, search: string) => {
  if (!search) {
    return true;
  }

  let found = false;
  const adminKey = Object.keys(adminObj)[0];
  const params = adminObj[adminKey];
  params.forEach((param) => {
    if (found) {
      return;
    }
    Object.keys(param).forEach((key) => {
      if (param[key] === search) {
        found = true;
      }
    });
  });
  return found;
};

const mergeArrays = (...arrays) => {
  const mergedObject = {};

  arrays.forEach((array) => {
    if (!array) return;

    array.forEach((item) => {
      if (!item) return;

      const key = Object.keys(item)[0];
      const value = item[key];

      if (!mergedObject[key]) {
        mergedObject[key] = [];
      }

      value.forEach((subItem) => {
        if (typeof subItem !== 'object' || subItem === null) return;

        const existingItemIndex = mergedObject[key].findIndex(
          (existingSubItem) =>
            Object.keys(existingSubItem).some((subKey) =>
              Object.prototype.hasOwnProperty.call(subItem, subKey),
            ),
        );

        if (existingItemIndex !== -1) {
          mergedObject[key][existingItemIndex] = {
            ...mergedObject[key][existingItemIndex],
            ...subItem,
          };
        } else {
          mergedObject[key].push(subItem);
        }
      });
    });
  });

  return Object.keys(mergedObject).map((key) => ({ [key]: mergedObject[key] }));
};
