/* eslint-disable */

(function () {
  // Utility functions
  var hasOwn = Object.prototype.hasOwnProperty;

  var assign = function (target) {
    for (var i = 1; i < arguments.length; i++) {
      var source = arguments[i];
      for (var key in source) {
        if (hasOwn.call(source, key)) {
          target[key] = source[key];
        }
      }
    }
    return target;
  };

  var parseMetaTag = function (name) {
    var content = document.getElementById(name).getAttribute('content');
    if (content === '[' + name + ']') {
      return null;
    }
    return content;
  };

  // BYOND API object
  // ------------------------------------------------------

  // 516.1680+ may inject a host Byond with native Topic. Grab Topic first, then
  // always use a plain API object (RU/Official style). Mutating the host object
  // breaks older Chromium clients (e.g. 516.1661) → white TGUI / no ready.
  var hostByond = window.Byond;
  var nativeTopic =
    hostByond && typeof hostByond.Topic === 'function'
      ? hostByond.Topic.bind(hostByond)
      : null;
  var nativeCommand =
    hostByond && typeof hostByond.command === 'function'
      ? hostByond.command.bind(hostByond)
      : null;
  // Keep host ref so late Topic injection can still be bound after we wipe.
  var hostByondRef = hostByond && typeof hostByond === 'object' ? hostByond : null;
  var Byond = (window.Byond = {});

  // Expose inlined metadata
  Byond.windowId = parseMetaTag('tgui:windowId');

  // Backwards compatibility
  window.__windowId__ = Byond.windowId;

  // Trident engine version (pre-Chromium BYOND clients)
  Byond.TRIDENT = (function () {
    var groups = navigator.userAgent.match(/Trident\/(\d+).+?;/i);
    var majorVersion = groups && groups[1];
    return majorVersion ? parseInt(majorVersion, 10) : null;
  })();

  // Blink engine version
  Byond.BLINK = (function () {
    var groups = navigator.userAgent.match(/Chrome\/(\d+)\./);
    var majorVersion = groups && groups[1];
    return majorVersion ? parseInt(majorVersion, 10) : null;
  })();

  // 3D webclient serves browse() iframes from 127.0.0.2, not 127.0.0.1.
  var isByondHost =
    location.hostname === '127.0.0.1' ||
    location.hostname === '127.0.0.2' ||
    location.hostname === 'localhost';

  // Basic checks to detect whether this page runs in BYOND
  var isByond =
    !!window.byond ||
    ((Byond.TRIDENT !== null ||
      Byond.BLINK !== null ||
      window.cef_to_byond ||
      !!nativeTopic) &&
    isByondHost &&
    location.search !== '?external');
  //As of BYOND 515 the path doesn't seem to include tmp dir anymore if you're trying to open tgui in external browser and looking why it doesn't work
  //&& location.pathname.indexOf('/tmp') === 0

  // Version constants
  Byond.IS_BYOND = isByond;

  // Strict mode flag
  Byond.strictMode = Boolean(Number(parseMetaTag('tgui:strictMode')));

  // Callbacks for asynchronous calls
  Byond.__callbacks__ = [];

  // Reviver for BYOND JSON
  var byondJsonReviver = function (key, value) {
    if (typeof value === 'object' && value !== null && value.__number__) {
      return parseFloat(value.__number__);
    }
    return value;
  };

  // Makes a BYOND call.
  // See: https://secure.byond.com/docs/ref/skinparams.html
  Byond.call = function (path, params) {
    // Not running in BYOND, abort.
    if (!isByond) {
      return;
    }
    // 516.1680+: native Topic for message/topic payloads
    if ((!path || path === '') && nativeTopic) {
      nativeTopic(params || {});
      return;
    }
    // Build the URL
    var url = (path || '') + '?';
    var i = 0;
    if (params) {
      for (var key in params) {
        if (hasOwn.call(params, key)) {
          if (i++ > 0) {
            url += '&';
          }
          var value = params[key];
          if (value === null || value === undefined) {
            value = '';
          }
          url += encodeURIComponent(key) + '=' + encodeURIComponent(value);
        }
      }
    }

    // Webclient
    if (window.byond) {
      window.byond.go('byond://' + url);
      return;
    }
    // Blink/WebView (516+): always prefer location.href.
    // cef_to_byond is reliable on older Trident/early CEF, but is often a
    // stub on 516.1680+ even when present — using it first whitescreens TGUI.
    if (Byond.BLINK !== null) {
      if (url.length < 2048) {
        location.href = 'byond://' + url;
        return;
      }
      if (window.cef_to_byond) {
        cef_to_byond('byond://' + url);
        return;
      }
    } else if (window.cef_to_byond) {
      cef_to_byond('byond://' + url);
      return;
    } else if (url.length < 2048) {
      location.href = 'byond://' + url;
      return;
    }
    // Send an HTTP request to DreamSeeker's HTTP server.
    // Allows sending much bigger payloads.
    var xhr = new XMLHttpRequest();
    xhr.open('GET', url);
    xhr.send();
  };

  Byond.callAsync = function (path, params) {
    if (!window.Promise) {
      throw new Error('Async calls require API level of ES2015 or later.');
    }
    var index = Byond.__callbacks__.length;
    var promise = new window.Promise(function (resolve) {
      Byond.__callbacks__.push(resolve);
    });
    Byond.call(
      path,
      assign({}, params, {
        callback: 'Byond.__callbacks__[' + index + ']',
      })
    );
    return promise;
  };

  Byond.topic = function (params) {
    // Refresh Topic if host re-injected it after our wipe
    var host = window.Byond !== Byond ? window.Byond : null;
    if (
      !nativeTopic &&
      host &&
      typeof host.Topic === 'function' &&
      host.Topic !== Byond.topic
    ) {
      nativeTopic = host.Topic.bind(host);
    }
    if (nativeTopic) {
      nativeTopic(params || {});
      return;
    }
    return Byond.call('', params);
  };

  Byond.command = function (command) {
    return Byond.call('winset', {
      command: command,
    });
  };

  Byond.winget = function (id, propName) {
    if (id === null) {
      id = '';
    }
    var isArray = propName instanceof Array;
    var isSpecific = propName && propName !== '*' && !isArray;
    var promise = Byond.callAsync('winget', {
      id: id,
      property: (isArray && propName.join(',')) || propName || '*',
    });
    if (isSpecific) {
      promise = promise.then(function (props) {
        return props[propName];
      });
    }
    return promise;
  };

  Byond.winset = function (id, propName, propValue) {
    if (id === null) {
      id = '';
    } else if (typeof id === 'object') {
      return Byond.call('winset', id);
    }
    var props = {};
    if (typeof propName === 'string') {
      props[propName] = propValue;
    } else {
      assign(props, propName);
    }
    props.id = id;
    return Byond.call('winset', props);
  };

  Byond.parseJson = function (json) {
    try {
      return JSON.parse(json, byondJsonReviver);
    } catch (err) {
      throw new Error('JSON parsing error: ' + (err && err.message));
    }
  };

  Byond.sendMessage = function (type, payload) {
    var message =
      typeof type === 'string' ? { type: type, payload: payload } : type;
    // JSON-encode the payload
    if (message.payload !== null && message.payload !== undefined) {
      message.payload = JSON.stringify(message.payload);
    }
    // Append an identifying header
    assign(message, {
      tgui: 1,
      window_id: Byond.windowId,
    });
    Byond.topic(message);
  };

  // This function exists purely for debugging, do not use it in code!
  Byond.injectMessage = function (type, payload) {
    window.update(JSON.stringify({ type: type, payload: payload }));
  };

  Byond.subscribe = function (listener) {
    window.update.flushQueue(listener);
    window.update.listeners.push(listener);
  };

  Byond.subscribeTo = function (type, listener) {
    var _listener = function (_type, payload) {
      if (_type === type) {
        listener(payload);
      }
    };
    window.update.flushQueue(_listener);
    window.update.listeners.push(_listener);
  };

  // Asset loaders
  // ------------------------------------------------------

  var RETRY_ATTEMPTS = 5;
  var RETRY_WAIT_INITIAL = 500;
  var RETRY_WAIT_INCREMENT = 500;

  var loadedAssetByUrl = {};

  var isStyleSheetLoaded = function (node, url) {
    var styleSheet = node.sheet;
    if (styleSheet) {
      return styleSheet.rules.length > 0;
    }
    return false;
  };

  var injectNode = function (node) {
    if (!document.body) {
      setTimeout(function () {
        injectNode(node);
      });
      return;
    }
    var refs = document.body.childNodes;
    var ref = refs[refs.length - 1];
    ref.parentNode.insertBefore(node, ref.nextSibling);
  };

  var loadAsset = function (options) {
    var url = options.url;
    var type = options.type;
    var sync = options.sync;
    var attempt = options.attempt || 0;
    if (loadedAssetByUrl[url]) {
      return;
    }
    loadedAssetByUrl[url] = options;
    // Generic retry function
    var retry = function () {
      if (attempt >= RETRY_ATTEMPTS) {
        var errorMessage =
          'Error: Failed to load the asset ' +
          "'" +
          url +
          "' after several attempts.";
        if (type === 'css') {
          errorMessage +=
            +'\nStylesheet was either not found, ' +
            "or you're trying to load an empty stylesheet " +
            'that has no CSS rules in it.';
        }
        throw new Error(errorMessage);
      }
      setTimeout(
        function () {
          loadedAssetByUrl[url] = null;
          options.attempt += 1;
          loadAsset(options);
        },
        RETRY_WAIT_INITIAL + attempt * RETRY_WAIT_INCREMENT
      );
    };
    // JS specific code
    if (type === 'js') {
      var node = document.createElement('script');
      node.type = 'text/javascript';
      node.crossOrigin = 'anonymous';
      node.src = url;
      if (sync) {
        node.defer = true;
      } else {
        node.async = true;
      }
      node.onerror = function () {
        node.onerror = null;
        node.parentNode.removeChild(node);
        node = null;
        retry();
      };
      injectNode(node);
      return;
    }
    // CSS specific code
    if (type === 'css') {
      var node = document.createElement('link');
      node.type = 'text/css';
      node.rel = 'stylesheet';
      node.crossOrigin = 'anonymous';
      node.href = url;
      // Temporarily set media to something inapplicable
      // to ensure it'll fetch without blocking render
      if (!sync) {
        node.media = 'only x';
      }
      var removeNodeAndRetry = function () {
        node.parentNode.removeChild(node);
        node = null;
        retry();
      };
      // 516: Chromium won't call onload() if there is a 404 error
      // Legacy IE doesn't use onerror, so we retain that
      // https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link#stylesheet_load_events
      node.onerror = function () {
        node.onerror = null;
        removeNodeAndRetry();
      };
      node.onload = function () {
        node.onload = null;
        if (isStyleSheetLoaded(node, url)) {
          // Render the stylesheet
          node.media = 'all';
          return;
        }
        removeNodeAndRetry();
      };
      injectNode(node);
      return;
    }
  };

  Byond.loadJs = function (url, sync) {
    loadAsset({ url: url, sync: sync, type: 'js' });
  };

  Byond.loadCss = function (url, sync) {
    loadAsset({ url: url, sync: sync, type: 'css' });
  };

  Byond.saveBlob = function (blob, filename, ext) {
    if (window.navigator.msSaveBlob) {
      window.navigator.msSaveBlob(blob, filename);
    } else if (window.showSaveFilePicker) {
      var accept = {};
      accept[blob.type] = [ext];

      var opts = {
        suggestedName: filename,
        types: [
          {
            description: 'SS13 file',
            accept: accept,
          },
        ],
      };

      window
        .showSaveFilePicker(opts)
        .then(function (file) {
          return file.createWritable();
        })
        .then(function (file) {
          return file.write(blob).then(function () {
            return file.close();
          });
        })
        .catch(function () {});
    }
  };

  // Icon cache
  Byond.iconRefMap = {};

  // inner-background-color is 516.1680+ (native Topic era). Never probe via
  // winget('') — that yields "Element default. not found" on older clients.
  Byond.supportsInnerBackground = !!nativeTopic;

  // 516.1679+ may inject/replace window.Byond after our script runs.
  // Re-assert our plain API and refresh native Topic when ready.
  var ensureByondApi = function () {
    var current = window.Byond;
    if (
      current &&
      current !== Byond &&
      typeof current.Topic === 'function' &&
      current.Topic !== Byond.topic
    ) {
      hostByondRef = current;
      nativeTopic = current.Topic.bind(current);
      Byond.supportsInnerBackground = true;
    }
    if (
      !nativeTopic &&
      hostByondRef &&
      typeof hostByondRef.Topic === 'function'
    ) {
      nativeTopic = hostByondRef.Topic.bind(hostByondRef);
      Byond.supportsInnerBackground = true;
    }
    if (
      current &&
      current !== Byond &&
      typeof current.command === 'function' &&
      current.command !== Byond.command
    ) {
      nativeCommand = current.command.bind(current);
    }
    try {
      window.Byond = Byond;
    } catch (err) {
      if (current && typeof current === 'object') {
        for (var key in Byond) {
          if (hasOwn.call(Byond, key)) {
            try {
              current[key] = Byond[key];
            } catch (e) {}
          }
        }
      }
    }
    if (
      !!window.byond ||
      (isByondHost &&
        location.search !== '?external' &&
        (Byond.TRIDENT !== null ||
          Byond.BLINK !== null ||
          window.cef_to_byond ||
          nativeTopic))
    ) {
      isByond = true;
      Byond.IS_BYOND = true;
    }
  };
  ensureByondApi();
  window.addEventListener('byond-ready', ensureByondApi);
  document.addEventListener('byond-ready', ensureByondApi);
  // Topic can appear slightly after first paint on 1680+
  var topicPolls = 0;
  var topicPoll = setInterval(function () {
    ensureByondApi();
    topicPolls += 1;
    if (nativeTopic || topicPolls >= 20) {
      clearInterval(topicPoll);
    }
  }, 50);
})();

// Error handling
// ------------------------------------------------------

window.onerror = function (msg, url, line, col, error) {
  window.onerror.errorCount = (window.onerror.errorCount || 0) + 1;
  // Proper stacktrace
  var stack = error && error.stack;
  // Ghetto stacktrace
  if (!stack) {
    stack = msg + '\n   at ' + url + ':' + line;
    if (col) {
      stack += ':' + col;
    }
  }
  // Augment the stack
  stack = window.__augmentStack__(stack, error);
  // Print error to the page
  if (Byond.strictMode) {
    var errorRoot = document.getElementById('FatalError');
    var errorStack = document.getElementById('FatalError__stack');
    if (errorRoot) {
      errorRoot.className = 'FatalError FatalError--visible';
      if (window.onerror.__stack__) {
        window.onerror.__stack__ += '\n\n' + stack;
      } else {
        window.onerror.__stack__ = stack;
      }
      var textProp = 'textContent';
      errorStack[textProp] = window.onerror.__stack__;
    }
    // Set window geometry
    var setFatalErrorGeometry = function () {
      Byond.winset(Byond.windowId, {
        titlebar: true,
        'is-visible': true,
        'can-resize': true,
      });
    };
    setFatalErrorGeometry();
    setInterval(setFatalErrorGeometry, 1000);
  }
  // Send logs to the game server
  if (Byond.strictMode) {
    Byond.sendMessage({
      type: 'log',
      fatal: 1,
      message: stack,
    });
  } else if (window.onerror.errorCount <= 1) {
    stack += '\nWindow is in non-strict mode, future errors are suppressed.';
    Byond.sendMessage({
      type: 'log',
      message: stack,
    });
  }
  // Short-circuit further updates
  if (Byond.strictMode) {
    window.update = function () {};
    window.update.queue = [];
  }
  // Prevent default action
  return true;
};

// Catch unhandled promise rejections
window.onunhandledrejection = function (e) {
  var msg = 'UnhandledRejection';
  if (e.reason) {
    msg += ': ' + (e.reason.message || e.reason.description || e.reason);
    if (e.reason.stack) {
      e.reason.stack = 'UnhandledRejection: ' + e.reason.stack;
    }
  }
  window.onerror(msg, null, null, null, e.reason);
};

// Helper for augmenting stack traces on fatal errors
window.__augmentStack__ = function (stack, error) {
  return stack + '\nUser Agent: ' + navigator.userAgent;
};

// Incoming message handling
// ------------------------------------------------------

// Message handler
window.update = function (rawMessage) {
  // Push onto the queue (active during initialization)
  if (window.update.queueActive) {
    window.update.queue.push(rawMessage);
    return;
  }
  // Parse the message
  var message = Byond.parseJson(rawMessage);
  // Notify listeners
  var listeners = window.update.listeners;
  for (var i = 0; i < listeners.length; i++) {
    listeners[i](message.type, message.payload);
  }
};

// Properties and variables of this specific handler
window.update.listeners = [];
window.update.queue = [];
window.update.queueActive = true;
window.update.flushQueue = function (listener) {
  // Disable and clear the queue permanently on short delay
  if (window.update.queueActive) {
    window.update.queueActive = false;
    if (window.setTimeout) {
      window.setTimeout(function () {
        window.update.queue = [];
      }, 0);
    }
  }
  // Process queued messages on provided listener
  var queue = window.update.queue;
  for (var i = 0; i < queue.length; i++) {
    var message = Byond.parseJson(queue[i]);
    listener(message.type, message.payload);
  }
};

window.replaceHtml = function (inline_html) {
  var children = document.body.childNodes;

  for (var i = 0; i < children.length; i++) {
    if (children[i].nodeValue == ' tgui:inline-html-start ') {
      while (children[i].nodeValue != ' tgui:inline-html-end ') {
        children[i].remove();
      }
      children[i].remove();
    }
  }

  document.body.insertAdjacentHTML(
    'afterbegin',
    '<!-- tgui:inline-html-start -->' +
      inline_html +
      '<!-- tgui:inline-html-end -->'
  );
};
