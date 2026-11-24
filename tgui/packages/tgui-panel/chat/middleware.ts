/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { Store } from 'common/redux';
import { storage, type StorageDiagnostic } from 'common/storage';

import {
  addHighlightSetting,
  loadSettings,
  removeHighlightSetting,
  updateHighlightSetting,
  updateSettings,
} from '../settings/actions';
import { selectSettings } from '../settings/selectors';
import {
  addChatPage,
  changeChatPage,
  changeScrollTracking,
  clearChat,
  loadChat,
  moveChatPageLeft,
  moveChatPageRight,
  rebuildChat,
  removeChatPage,
  saveChatToDisk,
  toggleAcceptedType,
  updateMessageCount,
} from './actions';
import { MAX_PERSISTED_MESSAGES, MESSAGE_SAVE_INTERVAL } from './constants';
import { createMessage, serializeMessage } from './model';
import { chatRenderer } from './renderer';
import { selectChat, selectCurrentChatPage } from './selectors';

const CHAT_BATCH_INTERVAL = 16;
const CHAT_BATCH_SIZE = 64;

const saveChatToStorage = async (store: Store) => {
  const state = selectChat(store.getState());
  const fromIndex = Math.max(
    0,
    chatRenderer.messages.length - MAX_PERSISTED_MESSAGES,
  );
  const messages = chatRenderer.messages
    .slice(fromIndex)
    .map((message) => serializeMessage(message));
  storage.set('chat-state', state);
  storage.set('chat-messages', messages);
};

const surfaceStorageDiagnostics = (diagnostics: StorageDiagnostic[]) => {
  const batch = diagnostics
    .filter((d) => d.level !== 'info')
    .map((d) =>
      createMessage({
        type: 'internal/storage',
        text: `[Storage] ${d.message}`,
      }),
    );

  if (batch.length) {
    chatRenderer.processBatch(batch, {
      prepend: true,
    });
  }
};

const loadChatFromStorage = async (store: Store) => {
  const [state, messages] = await Promise.all([
    storage.get('chat-state'),
    storage.get('chat-messages'),
  ]);

  surfaceStorageDiagnostics(storage.diagnostics);
  // Discard incompatible versions
  if (state && state.version <= 4) {
    store.dispatch(loadChat());
    return;
  }
  if (messages) {
    const batch = [
      ...messages.map((message) => ({ ...message, fromHistory: true })),
      createMessage({
        type: 'internal/reconnected',
      }),
    ];
    chatRenderer.processBatch(batch, {
      prepend: true,
    });
  }
  store.dispatch(loadChat(state));
};

export const chatMiddleware = (store: Store) => {
  let initialized = false;
  let loaded = false;
  const sequences = new Set<number>();
  const sequencesRequested = new Set<number>();
  let highestSequence: number | undefined;
  const pendingMessages: ReturnType<typeof createMessage>[] = [];
  let batchTimer: ReturnType<typeof setTimeout> | undefined;

  const scheduleBatch = () => {
    batchTimer ??= setTimeout(
      () => flushMessages(CHAT_BATCH_SIZE),
      CHAT_BATCH_INTERVAL,
    );
  };

  const flushMessages = (limit = pendingMessages.length) => {
    clearTimeout(batchTimer);
    batchTimer = undefined;
    if (pendingMessages.length) {
      chatRenderer.processBatch(pendingMessages.splice(0, limit));
    }
    if (pendingMessages.length) {
      scheduleBatch();
    }
  };

  chatRenderer.events.on('batchProcessed', (countByType) => {
    // Use this flag to workaround unread messages caused by
    // loading them from storage. Side effect of that, is that
    // message count can not be trusted, only unread count.
    if (loaded) {
      store.dispatch(updateMessageCount(countByType));
    }
  });
  chatRenderer.events.on('scrollTrackingChanged', (scrollTracking) => {
    store.dispatch(changeScrollTracking(scrollTracking));
  });
  setInterval(() => {
    saveChatToStorage(store);
  }, MESSAGE_SAVE_INTERVAL);
  return (next) => (action) => {
    const { type, payload } = action;
    if (!initialized) {
      initialized = true;
      loadChatFromStorage(store);
    }
    if (type === 'chat/message') {
      let payload_obj;
      try {
        payload_obj = JSON.parse(payload);
      } catch (err) {
        return;
      }

      const sequence: number = payload_obj?.sequence;
      if (
        !payload_obj?.content ||
        !Number.isSafeInteger(sequence) ||
        sequence < 0 ||
        sequences.has(sequence)
      ) {
        return;
      }

      const wasRequested = sequencesRequested.delete(sequence);
      if (!wasRequested && highestSequence !== undefined) {
        for (let missing = highestSequence + 1; missing < sequence; missing++) {
          sequencesRequested.add(missing);
          Byond.sendMessage('chat/resend', missing);
        }
      }
      highestSequence = Math.max(highestSequence ?? sequence, sequence);
      sequences.add(sequence);

      pendingMessages.push(createMessage(payload_obj.content));
      scheduleBatch();
      return;
    }
    if (type === loadChat.type) {
      next(action);
      const page = selectCurrentChatPage(store.getState());
      chatRenderer.changePage(page);
      chatRenderer.onStateLoaded();
      loaded = true;
      return;
    }
    if (
      type === changeChatPage.type ||
      type === addChatPage.type ||
      type === removeChatPage.type ||
      type === toggleAcceptedType.type ||
      type === moveChatPageLeft.type ||
      type === moveChatPageRight.type
    ) {
      next(action);
      const page = selectCurrentChatPage(store.getState());
      chatRenderer.changePage(page);
      return;
    }
    if (type === rebuildChat.type) {
      flushMessages();
      chatRenderer.rebuildChat();
      return next(action);
    }

    if (
      type === updateSettings.type ||
      type === loadSettings.type ||
      type === addHighlightSetting.type ||
      type === removeHighlightSetting.type ||
      type === updateHighlightSetting.type
    ) {
      next(action);
      const settings = selectSettings(store.getState());
      chatRenderer.setHighlight(
        settings.highlightSettings,
        settings.highlightSettingById,
      );

      return;
    }
    if (type === 'roundrestart') {
      // Save chat as soon as possible
      flushMessages();
      saveChatToStorage(store);
      return next(action);
    }
    if (type === saveChatToDisk.type) {
      flushMessages();
      chatRenderer.saveToDisk();
      return;
    }
    if (type === clearChat.type) {
      flushMessages();
      chatRenderer.clearChat();
      return;
    }
    return next(action);
  };
};
