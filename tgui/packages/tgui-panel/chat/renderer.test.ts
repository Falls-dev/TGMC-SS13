import { afterEach, beforeEach, describe, it, vi } from 'vitest';

import { CHAT_RENDER_BATCH_SIZE } from './constants';

vi.mock('tgui/logging', () => ({
  createLogger: () => ({ debug: vi.fn(), error: vi.fn(), log: vi.fn() }),
}));
vi.mock('./sanitize', () => ({
  sanitizeChatHtml: () => {
    throw new Error('The plain-text fixture should skip HTML sanitization');
  },
}));

describe('chat renderer startup', () => {
  let chatRenderer: typeof import('./renderer').chatRenderer;

  beforeEach(async () => {
    vi.resetModules();
    vi.useFakeTimers();
    ({ chatRenderer } = await import('./renderer'));
  }, 20_000);

  afterEach(() => {
    vi.useRealTimers();
    document.body.replaceChildren();
  });

  it('loads retained history in bounded turns before live messages', ({
    expect,
  }) => {
    const container = document.createElement('div');
    container.style.overflowY = 'scroll';
    const chat = document.createElement('div');
    container.append(chat);
    document.body.append(container);

    const history = Array.from(
      { length: CHAT_RENDER_BATCH_SIZE * 2 + 1 },
      (_, index) => ({ text: `Saved ${index}`, fromHistory: true }),
    );
    chatRenderer.processBatch([{ text: 'Live before history' }]);
    chatRenderer.processBatch(history, { prepend: true });
    chatRenderer.mount(chat);
    chatRenderer.changePage({ acceptedTypes: { unknown: true } });
    const processed = vi.fn();
    chatRenderer.events.on('batchProcessed', processed);
    chatRenderer.onStateLoaded();

    expect(chat.children).toHaveLength(0);
    vi.advanceTimersToNextTimer();
    expect(chat.children).toHaveLength(CHAT_RENDER_BATCH_SIZE);
    expect(processed).not.toHaveBeenCalled();

    chatRenderer.processBatch([{ text: 'Live during history' }]);
    expect(chatRenderer.getRecentMessages().at(-1)?.text).toBe(
      'Live during history',
    );
    vi.advanceTimersToNextTimer();
    vi.advanceTimersToNextTimer();
    expect(Array.from(chat.children, (element) => element.textContent)).toEqual(
      [
        ...history.map((message) => message.text),
        'Live before history',
        'Live during history',
      ],
    );
    expect(processed).toHaveBeenLastCalledWith({ unknown: 2 });
  });
});
