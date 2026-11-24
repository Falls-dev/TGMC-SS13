import DOMPurify from 'dompurify';

const CHAT_TAGS = [
  'a',
  'b',
  'big',
  'blockquote',
  'br',
  'center',
  'code',
  'dd',
  'del',
  'div',
  'dl',
  'dt',
  'em',
  'fieldset',
  'font',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'hr',
  'i',
  'img',
  'ins',
  'legend',
  'li',
  'ol',
  'p',
  'pre',
  's',
  'small',
  'span',
  'strike',
  'strong',
  'sub',
  'sup',
  'table',
  'tbody',
  'td',
  'th',
  'thead',
  'tfoot',
  'tr',
  'tt',
  'u',
  'ul',
];

const CHAT_ATTRIBUTES = [
  'align',
  'alt',
  'aria-label',
  'border',
  'cellpadding',
  'cellspacing',
  'class',
  'color',
  'colspan',
  'data-component',
  'data-content',
  'data-position',
  'face',
  'height',
  'href',
  'rowspan',
  'size',
  'src',
  'style',
  'title',
  'valign',
  'width',
];

// These properties support chat formatting without loading resources.
const CHAT_STYLES = [
  'background-color',
  'border-color',
  'color',
  'display',
  'font-family',
  'font-size',
  'font-style',
  'font-weight',
  'line-height',
  'text-align',
  'text-decoration',
  'vertical-align',
  'white-space',
];

const WEB_URL = /^https?:\/\/[^\s\\]+$/i;
const BYOND_TOPIC_URL = /^(?:byond:\/\/)?\?[^\s\\]+$/i;
const LOCAL_IMAGE =
  /^(?:[\w.-]+\/)*[\w.-]+\.(?:gif|jpe?g|png|webp)(?:[?#][^\s\\]*)?$/i;
const INLINE_IMAGE =
  /^data:image\/(?:gif|jpeg|png|webp);base64,[a-z0-9+/]+=*$/i;

/** Parse chat markup in an inert document and return nodes ready to mount. */
export function sanitizeChatHtml(html: string, fromHistory = false) {
  const fragment = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: CHAT_TAGS,
    ALLOWED_ATTR: CHAT_ATTRIBUTES,
    ALLOW_DATA_ATTR: false,
    ALLOW_ARIA_ATTR: false,
    ADD_URI_SAFE_ATTR: ['data-component', 'data-content', 'data-position'],
    ALLOWED_URI_REGEXP: /^(?:https?:\/\/|(?:byond:\/\/)?\?|[\w.-]+(?:\/|$))/i,
    RETURN_DOM_FRAGMENT: true,
    FORBID_TAGS: fromHistory ? ['a'] : [],
  });

  fragment.querySelectorAll('a[href]').forEach((link) => {
    const href = link.getAttribute('href')?.trim() || '';
    if (!WEB_URL.test(href) && !BYOND_TOPIC_URL.test(href)) {
      link.removeAttribute('href');
    }
  });

  fragment.querySelectorAll('img[src]').forEach((image) => {
    const src = image.getAttribute('src')?.trim() || '';
    if (
      !WEB_URL.test(src) &&
      !LOCAL_IMAGE.test(src) &&
      !INLINE_IMAGE.test(src)
    ) {
      image.removeAttribute('src');
    }
  });

  fragment.querySelectorAll<HTMLElement>('[style]').forEach((element) => {
    const styles = CHAT_STYLES.flatMap((property) => {
      const value = element.style.getPropertyValue(property);
      return value ? [[property, value] as const] : [];
    });
    element.removeAttribute('style');
    for (const [property, value] of styles) {
      element.style.setProperty(property, value);
    }
  });

  return fragment;
}
