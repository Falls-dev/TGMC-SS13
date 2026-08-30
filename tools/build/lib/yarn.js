import Juke from '../juke/index.js';

let yarnPath;
let webclientYarnPath;

export const yarn = (...args) => {
  if (!yarnPath) {
    yarnPath = Juke.glob('./tgui/.yarn/releases/*.cjs')[0]
      .replace('/tgui/', '/');
  }
  return Juke.exec('node', [
    yarnPath,
    ...args.filter((arg) => typeof arg === 'string'),
  ], {
    cwd: './tgui',
  });
};

export const yarnWebclient = (...args) => {
  if (!webclientYarnPath) {
    webclientYarnPath = Juke.glob('./webclient/.yarn/releases/*.cjs')[0]
      .replace('/webclient/', '/');
  }
  return Juke.exec('node', [
    webclientYarnPath,
    ...args.filter((arg) => typeof arg === 'string'),
  ], {
    cwd: './webclient',
  });
};
