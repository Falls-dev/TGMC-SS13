import { afterEach, beforeEach, describe, it, vi } from 'vitest';

import { clearChat } from './actions';
import { chatMiddleware } from './middleware';
import { chatRenderer } from './renderer';

vi.mock('common/storage', () => ({
  storage: { diagnostics: [], get: vi.fn(), set: vi.fn() },
}));

vi.mock('./renderer', () => ({
  chatRenderer: {
    clearChat: vi.fn(),
    events: { on: vi.fn() },
    processBatch: vi.fn(),
  },
}));

const incoming = (sequence: number) => ({
  type: 'chat/message',
  payload: JSON.stringify({
    sequence,
    content: { text: `Message ${sequence}` },
  }),
});

const createDispatch = () =>
  chatMiddleware({
    dispatch: vi.fn(),
    getState: vi.fn(),
    subscribe: vi.fn(),
  })(vi.fn());

describe('chat message batching', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.stubGlobal('Byond', { sendMessage: vi.fn() });
  });

  afterEach(async () => {
    await Promise.resolve();
    vi.clearAllTimers();
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.clearAllMocks();
  });

  it('renders bursts in bounded batches with each message in arrival order', ({
    expect,
  }) => {
    const dispatch = createDispatch();
    for (let sequence = 0; sequence < 100; sequence++) {
      dispatch(incoming(sequence));
    }
    expect(chatRenderer.processBatch).not.toHaveBeenCalled();
    vi.advanceTimersByTime(32);
    const batches = vi
      .mocked(chatRenderer.processBatch)
      .mock.calls.map(([batch]) => batch);
    expect(batches.map((batch) => batch.length)).toEqual([64, 36]);
    expect(batches.flat().map(({ text }) => text)).toEqual(
      Array.from({ length: 100 }, (_, sequence) => `Message ${sequence}`),
    );
  });

  it('requests a missing sequence once and ignores repeated delivery', ({
    expect,
  }) => {
    const dispatch = createDispatch();
    for (const sequence of [20, 22, 21, 22, 23]) {
      dispatch(incoming(sequence));
    }
    vi.advanceTimersByTime(16);
    expect(Byond.sendMessage).toHaveBeenCalledExactlyOnceWith(
      'chat/resend',
      21,
    );
    expect(chatRenderer.processBatch).toHaveBeenCalledWith(
      [20, 22, 21, 23].map((sequence) =>
        expect.objectContaining({ text: `Message ${sequence}` }),
      ),
    );
  });

  it('handles queued messages before clearing the chat', ({ expect }) => {
    const dispatch = createDispatch();
    dispatch(incoming(0));
    dispatch(clearChat());
    expect(chatRenderer.processBatch).toHaveBeenCalledBefore(
      vi.mocked(chatRenderer.clearChat),
    );
    vi.advanceTimersByTime(16);
    expect(chatRenderer.processBatch).toHaveBeenCalledTimes(1);
  });
});
