import { storage } from 'common/storage';
import { afterEach, beforeEach, describe, it, vi } from 'vitest';

vi.mock('common/storage', () => ({ storage: { get: vi.fn() } }));
vi.mock('./logging', () => ({
  createLogger: () => ({ debug: vi.fn(), log: vi.fn() }),
}));

describe('window geometry recall', () => {
  beforeEach(() => {
    vi.resetModules();
    vi.useFakeTimers();
    vi.stubGlobal('Byond', {
      windowId: 'test-window',
      winget: vi.fn().mockResolvedValue({ x: 0, y: 0 }),
      winset: vi.fn(),
    });
    vi.spyOn(window.screen, 'availWidth', 'get').mockReturnValue(1280);
    vi.spyOn(window.screen, 'availHeight', 'get').mockReturnValue(960);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('uses a saved position when it is available promptly', async ({
    expect,
  }) => {
    vi.mocked(storage.get).mockResolvedValue({ pos: [40, 50] });
    const { recallWindowGeometry, setupDrag } = await import('./drag');
    setupDrag();
    await recallWindowGeometry({ size: [400, 300] });
    expect(Byond.winset).toHaveBeenCalledWith('test-window', {
      size: '400x300',
    });
    expect(Byond.winset).toHaveBeenCalledWith('test-window', { pos: '40,50' });
  });

  it('centers promptly and ignores a late storage reply', async ({
    expect,
  }) => {
    let reply: (geometry: { pos: [number, number] }) => void;
    vi.mocked(storage.get).mockImplementation(
      () =>
        new Promise((resolve) => {
          reply = resolve;
        }),
    );
    const { recallWindowGeometry, setupDrag } = await import('./drag');
    setupDrag();
    const applied = recallWindowGeometry({ size: [400, 300] });
    await vi.advanceTimersByTimeAsync(100);
    await applied;
    expect(Byond.winset).toHaveBeenCalledWith('test-window', {
      pos: '440,330',
    });
    reply!({ pos: [40, 50] });
    await Promise.resolve();
    expect(Byond.winset).toHaveBeenCalledTimes(2);
  });

  it('does not apply geometry for a closed or replaced window', async ({
    expect,
  }) => {
    vi.mocked(storage.get).mockResolvedValue({ pos: [40, 50] });
    const { recallWindowGeometry } = await import('./drag');
    await recallWindowGeometry({ size: [400, 300] }, () => false);
    expect(Byond.winset).not.toHaveBeenCalled();
  });
});
