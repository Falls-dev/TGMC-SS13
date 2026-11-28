import { afterEach, describe, it, vi } from 'vitest';

const storageOrigin = 'https://storage.example.test';
const otherOrigin = 'https://other.example.test';

describe('iframe storage', () => {
  afterEach(() => {
    document.body.replaceChildren();
    vi.unstubAllGlobals();
    vi.resetModules();
  });

  it('uses the configured origin for messages and checks the reply sender', async ({
    expect,
  }) => {
    vi.stubGlobal('Byond', { storageCdn: `${storageOrigin}/iframe.html` });
    const fetch = vi.fn().mockResolvedValue({ status: 200 });
    vi.stubGlobal('fetch', fetch);

    const { storage } = await import('./storage');
    const iframeWindow = document.querySelector('iframe')!.contentWindow!;
    const sendReply = (
      origin: string,
      data: unknown,
      source = iframeWindow,
    ) => {
      window.dispatchEvent(
        new MessageEvent('message', { origin, source, data }),
      );
    };
    const postMessage = vi.spyOn(iframeWindow, 'postMessage');
    const write = storage.set('sample', 'saved');

    sendReply(otherOrigin, 'ready');
    sendReply(storageOrigin, 'ready', window);
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(postMessage).not.toHaveBeenCalled();

    sendReply(storageOrigin, 'ready');
    await vi.waitFor(() =>
      expect(postMessage).toHaveBeenCalledWith(
        { type: 'get', key: 'byondstorage-migrated' },
        storageOrigin,
      ),
    );
    sendReply(storageOrigin, { key: 'byondstorage-migrated', value: true });
    await write;
    expect(fetch).toHaveBeenCalledWith(`${storageOrigin}/iframe.html`, {
      method: 'HEAD',
      redirect: 'error',
    });
    expect(postMessage).toHaveBeenCalledWith(
      { type: 'set', key: 'sample', value: 'saved' },
      storageOrigin,
    );

    const read = storage.get('sample');
    await Promise.resolve();
    sendReply(otherOrigin, { key: 'sample', value: 'different origin' });
    sendReply(
      storageOrigin,
      { key: 'sample', value: 'different window' },
      window,
    );
    sendReply(storageOrigin, null);
    sendReply(storageOrigin, { key: 'sample', value: 'saved' });
    await expect(read).resolves.toBe('saved');
  });

  it('falls back to local storage for an invalid iframe setting', async ({
    expect,
  }) => {
    vi.stubGlobal('Byond', { storageCdn: 'relative-path.html' });
    const setItem = vi.fn();
    vi.stubGlobal('hubStorage', { getItem: vi.fn(), setItem });
    vi.stubGlobal('fetch', vi.fn());

    const { storage } = await import('./storage');
    await storage.set('sample', 'saved');

    expect(document.querySelector('iframe')).toBeNull();
    expect(fetch).not.toHaveBeenCalled();
    expect(setItem).toHaveBeenCalledWith('sample', JSON.stringify('saved'));
  });
});
