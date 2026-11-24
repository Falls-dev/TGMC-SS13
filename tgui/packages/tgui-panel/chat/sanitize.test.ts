import { describe, it } from 'vitest';

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
