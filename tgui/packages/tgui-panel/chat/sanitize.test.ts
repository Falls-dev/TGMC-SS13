import { describe, expect, it } from 'vitest';

import { sanitizeChatHtml } from './sanitize';

describe('sanitizeChatHtml', () => {
  it('keeps examine cards, tip headings, and explicit line breaks', ({
    expect,
  }) => {
    const fragment = sanitizeChatHtml(
      '<fieldset class="fieldset examine_block"><legend class="fieldset_legend">' +
        '<big>Console</big></legend><i>Description</i><br>Second line</fieldset>',
    );

    const card = fragment.querySelector('fieldset.examine_block');
    expect(
      card?.querySelector('legend.fieldset_legend > big')?.textContent,
    ).toBe('Console');
    expect(card?.querySelector('br')?.nextSibling?.textContent).toBe(
      'Second line',
    );
  });

  it('keeps chat formatting, BYOND links, and asset images', ({ expect }) => {
    const fragment = sanitizeChatHtml(
      '<span class="notice" style="color: red" data-component="Tooltip" data-content="More info">Внимание</span>' +
        '<a href="byond://?_src_=holder;admin_token=example">Ticket</a>' +
        '<img src="asset.123.png" alt="Icon">',
    );

    const notice = fragment.querySelector<HTMLElement>('.notice');
    expect(notice?.textContent).toBe('Внимание');
    expect(notice?.style.color).toBe('red');
    expect(notice?.dataset.content).toBe('More info');
    expect(fragment.querySelector('a')?.getAttribute('href')).toBe(
      'byond://?_src_=holder;admin_token=example',
    );
    expect(fragment.querySelector('img')?.getAttribute('src')).toBe(
      'asset.123.png',
    );
  });

  it('preserves legacy font colors with a single safe color token', ({
    expect,
  }) => {
    const fragment = sanitizeChatHtml(
      '<font color="#6D2A6D"><span class="ooc">XOOC: Hello</span></font>' +
        '<font color="#6D2">Short hex</font><font color="red">Named</font>' +
        '<font color="red blue">Invalid</font><span color="#6D2">Span</span>',
    );
    expect(
      Array.from(fragment.querySelectorAll('font')).map((font) =>
        font.getAttribute('color'),
      ),
    ).toEqual(['#6D2A6D', '#6D2', 'red', null]);
    expect(fragment.querySelector('span[color]')).toBeNull();
  });

  it.each([false, true])(
    'keeps the nickname formatting separate from the channel (history: %s)',
    (fromHistory) => {
      const fragment = sanitizeChatHtml(
        '<span class="ooc" style="color:#B75800">MOOC: ' +
          '<span class="ooc-nickname" style="color:#12ABF0">' +
          '<a href="byond://?priv_msg=example">Anne O\'Neil &amp; Co</a></span>: ' +
          '<span class="message linkify">Hello</span></span>' +
          '<span class="colorooc">OOC: ' +
          '<span class="ooc-nickname adminooc">Terry</span>: Hello</span>',
        fromHistory,
      );
      const channel = fragment.querySelector<HTMLElement>('.ooc');
      const nickname = channel?.querySelector<HTMLElement>('.ooc-nickname');
      expect(channel?.style.color).toBe('rgb(183, 88, 0)');
      expect(nickname?.style.color).toBe('rgb(18, 171, 240)');
      expect(nickname?.textContent).toBe("Anne O'Neil & Co");
      expect(channel?.querySelector('.message')?.textContent).toBe('Hello');
      expect(fragment.querySelector('.colorooc .adminooc')?.textContent).toBe(
        'Terry',
      );
      expect(nickname?.querySelector('a')?.getAttribute('href')).toBe(
        fromHistory ? undefined : 'byond://?priv_msg=example',
      );
    },
  );

  it('drops active elements, event attributes and non-chat styles', ({
    expect,
  }) => {
    const fragment = sanitizeChatHtml(
      '<iframe></iframe><object></object><svg></svg><form></form>' +
        '<img src="asset.123.png" onerror="" srcset="other.png 2x">' +
        '<span style="background-image: linear-gradient(red, blue); color: red">Text</span>' +
        '<a href="file:///document.txt">Document</a>',
    );

    expect(fragment.querySelector('iframe, object, svg, form')).toBeNull();
    expect(fragment.querySelector('[onerror], [srcset], a[href]')).toBeNull();
    const text = fragment.querySelector<HTMLElement>('span');
    expect(text?.style.backgroundImage).toBe('');
    expect(text?.style.color).toBe('red');
  });

  it('keeps link labels as text when loading chat history', ({ expect }) => {
    const fragment = sanitizeChatHtml(
      '<a href="byond://?_src_=holder">Ticket</a> <b>closed</b>',
      true,
    );

    expect(fragment.querySelector('a')).toBeNull();
    expect(fragment.textContent).toBe('Ticket closed');
  });
});
