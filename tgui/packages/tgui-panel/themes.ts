/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export const THEMES = ['light', 'dark'];

const COLOR_DARK_BG = '#202020';
const COLOR_DARK_BG_DARKER = '#171717';
const COLOR_DARK_BUTTON = '#494949';
const COLOR_DARK_TEXT = '#a4bad6';

let setClientThemeTimer: NodeJS.Timeout;
let lastThemeName: string | undefined;
let innerBgRetryBound = false;

const canUseInnerBackground = () =>
  Boolean((Byond as { supportsInnerBackground?: boolean }).supportsInnerBackground);

const withInnerBackground = (
  props: Record<string, string>,
  inner: Record<string, string>,
) => {
  if (canUseInnerBackground()) {
    return { ...props, ...inner };
  }
  return props;
};

const scheduleInnerBackgroundRetry = (inner: Record<string, string>) => {
  if (canUseInnerBackground() || !Byond.BLINK || innerBgRetryBound) {
    return;
  }
  innerBgRetryBound = true;
  const tryApply = () => {
    if (!canUseInnerBackground()) {
      return;
    }
    Byond.winset(inner);
    // Re-push CSS theme in case command raced with Topic
    if (lastThemeName) {
      Byond.command(`.output statbrowser:set_theme ${lastThemeName}`);
    }
  };
  window.addEventListener('byond-ready', tryApply);
  document.addEventListener('byond-ready', tryApply);
  setTimeout(tryApply, 100);
  setTimeout(tryApply, 500);
  setTimeout(tryApply, 1500);
};

/**
 * Darkmode preference, originally by Kmc2000.
 *
 * This lets you switch client themes by using winset.
 *
 * If you change ANYTHING in interface/skin.dmf you need to change it here.
 *
 * There's no way round it. We're essentially changing the skin by hand.
 * It's painful but it works, and is the way Lummox suggested.
 */
export const setClientTheme = (name) => {
  lastThemeName = name;
  // Transmit once for fast updates and again in a little while in case we won
  // the race against statbrowser init.
  clearInterval(setClientThemeTimer);
  Byond.command(`.output statbrowser:set_theme ${name}`);
  setClientThemeTimer = setTimeout(() => {
    Byond.command(`.output statbrowser:set_theme ${name}`);
  }, 1500);

  if (name === 'light') {
    const inner = {
      'browseroutput.inner-background-color': '#EEEEEE',
      'statbrowser.inner-background-color': '#EEEEEE',
    };
    Byond.winset(
      withInnerBackground(
        {
          // Main windows
          'infowindow.background-color': 'none',
          'infowindow.text-color': '#000000',
          'info.background-color': 'none',
          'info.text-color': '#000000',
          'browseroutput.background-color': 'none',
          'browseroutput.text-color': '#000000',
          'outputwindow.background-color': 'none',
          'outputwindow.text-color': '#000000',
          'mainwindow.background-color': 'none',
          'split.background-color': 'none',
          // Buttons
          'changelog.background-color': 'none',
          'changelog.text-color': '#000000',
          'discord.background-color': 'none',
          'discord.text-color': '#000000',
          'rules.background-color': 'none',
          'rules.text-color': '#000000',
          'wiki.background-color': 'none',
          'wiki.text-color': '#000000',
          'boosty.background-color': 'none',
          'boosty.text-color': '#000000',
          'github.background-color': 'none',
          'github.text-color': '#000000',
          'webmap.background-color': 'none',
          'webmap.text-color': '#000000',
          // Status and verb tabs
          'output.background-color': 'none',
          'output.text-color': '#000000',
          'statwindow.background-color': 'none',
          'statwindow.text-color': '#000000',
          'statbrowser.background-color': 'none',
          // Say, OOC, me Buttons etc.
          'saybutton.background-color': 'none',
          'saybutton.text-color': '#000000',
          'oocbutton.background-color': 'none',
          'oocbutton.text-color': '#000000',
          'mebutton.background-color': 'none',
          'mebutton.text-color': '#000000',
          'asset_cache_browser.background-color': 'none',
          'asset_cache_browser.text-color': '#000000',
          'tooltip.background-color': 'none',
          'tooltip.text-color': '#000000',
          'input.background-color': '#FFFFFF',
          'input.text-color': '#000000',
        },
        inner,
      ),
    );
    scheduleInnerBackgroundRetry(inner);
    return;
  }

  if (name === 'dark') {
    const inner = {
      'browseroutput.inner-background-color': COLOR_DARK_BG,
      'statbrowser.inner-background-color': COLOR_DARK_BG_DARKER,
    };
    Byond.winset(
      withInnerBackground(
        {
          // Main windows
          'infowindow.background-color': COLOR_DARK_BG,
          'infowindow.text-color': COLOR_DARK_TEXT,
          'info.background-color': COLOR_DARK_BG,
          'info.text-color': COLOR_DARK_TEXT,
          'browseroutput.background-color': COLOR_DARK_BG,
          'browseroutput.text-color': COLOR_DARK_TEXT,
          'outputwindow.background-color': COLOR_DARK_BG,
          'outputwindow.text-color': COLOR_DARK_TEXT,
          'mainwindow.background-color': COLOR_DARK_BG,
          'split.background-color': COLOR_DARK_BG,
          // Buttons
          'changelog.background-color': COLOR_DARK_BUTTON,
          'changelog.text-color': COLOR_DARK_TEXT,
          'discord.background-color': COLOR_DARK_BUTTON,
          'discord.text-color': COLOR_DARK_TEXT,
          'rules.background-color': COLOR_DARK_BUTTON,
          'rules.text-color': COLOR_DARK_TEXT,
          'wiki.background-color': COLOR_DARK_BUTTON,
          'wiki.text-color': COLOR_DARK_TEXT,
          'boosty.background-color': COLOR_DARK_BUTTON,
          'boosty.text-color': COLOR_DARK_TEXT,
          'github.background-color': COLOR_DARK_BUTTON,
          'github.text-color': COLOR_DARK_TEXT,
          'webmap.background-color': COLOR_DARK_BUTTON,
          'webmap.text-color': COLOR_DARK_TEXT,
          // Status and verb tabs
          'output.background-color': COLOR_DARK_BG_DARKER,
          'output.text-color': COLOR_DARK_TEXT,
          'statwindow.background-color': COLOR_DARK_BG_DARKER,
          'statwindow.text-color': COLOR_DARK_TEXT,
          'statbrowser.background-color': COLOR_DARK_BG_DARKER,
          // Say, OOC, me Buttons etc.
          'saybutton.background-color': COLOR_DARK_BG,
          'saybutton.text-color': COLOR_DARK_TEXT,
          'oocbutton.background-color': COLOR_DARK_BG,
          'oocbutton.text-color': COLOR_DARK_TEXT,
          'mebutton.background-color': COLOR_DARK_BG,
          'mebutton.text-color': COLOR_DARK_TEXT,
          'asset_cache_browser.background-color': COLOR_DARK_BG,
          'asset_cache_browser.text-color': COLOR_DARK_TEXT,
          'tooltip.background-color': COLOR_DARK_BG,
          'tooltip.text-color': COLOR_DARK_TEXT,
          'input.background-color': COLOR_DARK_BG_DARKER,
          'input.text-color': COLOR_DARK_TEXT,
        },
        inner,
      ),
    );
    scheduleInnerBackgroundRetry(inner);
  }
};
