/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import {
  ComponentProps,
  PropsWithChildren,
  ReactNode,
  useLayoutEffect,
  useRef,
} from 'react';
import { Box } from 'tgui-core/components';
import { UI_DISABLED, UI_INTERACTIVE } from 'tgui-core/constants';
import { BooleanLike, classes } from 'tgui-core/react';
import { decodeHtmlEntities } from 'tgui-core/string';

import {
  backendSuspendStart,
  globalStore,
  selectBackend,
  useBackend,
} from '../backend';
import { useDebug } from '../debug';
import {
  dragStartHandler,
  recallWindowGeometry,
  resizeStartHandler,
  setWindowKey,
} from '../drag';
import { createLogger } from '../logging';
import { Layout } from './Layout';
import { TitleBar } from './TitleBar';

const logger = createLogger('Window');

const DEFAULT_SIZE: [number, number] = [400, 600];

type Props = Partial<{
  buttons: ReactNode;
  canClose: BooleanLike;
  height: number;
  theme: string;
  title: string;
  width: number;
}> &
  PropsWithChildren;

export const Window = (props: Props) => {
  const {
    canClose = true,
    theme,
    title,
    children,
    buttons,
    width,
    height,
  } = props;

  const { config, suspended, suspending } = useBackend();
  const { debugLayout = false } = useDebug();
  const shown = useRef(false);
  const { key, locked, scale } = config.window || {};

  useLayoutEffect(() => {
    if (suspended) {
      shown.current = false;
      return;
    }
    if (suspending) {
      return;
    }
    let current = true;
    let reveal: ReturnType<typeof setTimeout> | undefined;
    const isCurrent = () => {
      const backend = selectBackend(globalStore.getState());
      return (
        current &&
        !backend.suspended &&
        !backend.suspending &&
        backend.config.window?.key === key
      );
    };
    if (key) {
      setWindowKey(key);
    }
    Byond.winset(Byond.windowId, {
      'can-close': Boolean(canClose),
      ...(!shown.current && { 'is-visible': false }),
    });
    recallWindowGeometry(
      { locked, scale, size: width && height ? [width, height] : DEFAULT_SIZE },
      isCurrent,
    ).then(() => {
      if (isCurrent() && !shown.current) {
        // Let the native window apply geometry before making it visible.
        reveal = setTimeout(() => {
          if (!isCurrent()) {
            return;
          }
          Byond.winset(Byond.windowId, { 'is-visible': true });
          Byond.sendMessage('visible');
          shown.current = true;
        });
      }
    });
    return () => {
      current = false;
      clearTimeout(reveal);
    };
  }, [canClose, height, key, locked, scale, suspended, suspending, width]);

  const dispatch = globalStore.dispatch;

  // Determine when to show dimmer
  const showDimmer =
    config.user &&
    (config.user.observer
      ? config.status < UI_DISABLED
      : config.status < UI_INTERACTIVE);

  return suspended ? null : (
    <Layout className="Window" theme={theme}>
      <TitleBar
        title={title || decodeHtmlEntities(config.title)}
        status={config.status}
        onDragStart={dragStartHandler}
        onClose={() => {
          logger.log('pressed close');
          dispatch(backendSuspendStart());
        }}
        canClose={canClose}
      >
        {buttons}
      </TitleBar>
      <div className={classes(['Window__rest', debugLayout && 'debug-layout'])}>
        {!suspended && children}
        {showDimmer && <div className="Window__dimmer" />}
      </div>
      <div
        className="Window__resizeHandle__e"
        onMouseDown={resizeStartHandler(1, 0) as any}
      />
      <div
        className="Window__resizeHandle__s"
        onMouseDown={resizeStartHandler(0, 1) as any}
      />
      <div
        className="Window__resizeHandle__se"
        onMouseDown={resizeStartHandler(1, 1) as any}
      />
    </Layout>
  );
};

type ContentProps = Partial<{
  className: string;
  fitted: boolean;
  scrollable: boolean;
  vertical: boolean;
}> &
  ComponentProps<typeof Box> &
  PropsWithChildren;

const WindowContent = (props: ContentProps) => {
  const { className, fitted, children, ...rest } = props;

  return (
    <Layout.Content
      className={classes(['Window__content', className])}
      {...rest}
    >
      {(fitted && children) || (
        <div className="Window__contentPadding">{children}</div>
      )}
    </Layout.Content>
  );
};

Window.Content = WindowContent;
