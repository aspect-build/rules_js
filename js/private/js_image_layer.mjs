import { createWriteStream, createReadStream } from 'node:fs';
import { readFile, stat, realpath, readdir } from 'node:fs/promises';
import * as path from 'node:path';
import { Readable as Readable$2 } from 'node:stream';
import { pathToFileURL } from 'node:url';
import { createGzip } from 'node:zlib';
import require$$0$1 from 'stream';
import require$$0 from 'buffer';
import require$$2 from 'events';
import require$$13 from 'string_decoder';
import require$$0$2 from 'fs';

var commonjsGlobal = typeof globalThis !== 'undefined' ? globalThis : typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};

function getAugmentedNamespace(n) {
  var f = n.default;
	if (typeof f == "function") {
		var a = function () {
			return f.apply(this, arguments);
		};
		a.prototype = f.prototype;
  } else a = {};
  Object.defineProperty(a, '__esModule', {value: true});
	Object.keys(n).forEach(function (k) {
		var d = Object.getOwnPropertyDescriptor(n, k);
		Object.defineProperty(a, k, d.get ? d : {
			enumerable: true,
			get: function () {
				return n[k];
			}
		});
	});
	return a;
}

var bl = {exports: {}};

var ours = {exports: {}};

var stream = {exports: {}};

var primordials;
var hasRequiredPrimordials;

function requirePrimordials () {
	if (hasRequiredPrimordials) return primordials;
	hasRequiredPrimordials = 1;

	/*
	  This file is a reduced and adapted version of the main lib/internal/per_context/primordials.js file defined at

	  https://github.com/nodejs/node/blob/master/lib/internal/per_context/primordials.js

	  Don't try to replace with the original file and keep it up to date with the upstream file.
	*/
	primordials = {
	  ArrayIsArray(self) {
	    return Array.isArray(self)
	  },
	  ArrayPrototypeIncludes(self, el) {
	    return self.includes(el)
	  },
	  ArrayPrototypeIndexOf(self, el) {
	    return self.indexOf(el)
	  },
	  ArrayPrototypeJoin(self, sep) {
	    return self.join(sep)
	  },
	  ArrayPrototypeMap(self, fn) {
	    return self.map(fn)
	  },
	  ArrayPrototypePop(self, el) {
	    return self.pop(el)
	  },
	  ArrayPrototypePush(self, el) {
	    return self.push(el)
	  },
	  ArrayPrototypeSlice(self, start, end) {
	    return self.slice(start, end)
	  },
	  Error,
	  FunctionPrototypeCall(fn, thisArgs, ...args) {
	    return fn.call(thisArgs, ...args)
	  },
	  FunctionPrototypeSymbolHasInstance(self, instance) {
	    return Function.prototype[Symbol.hasInstance].call(self, instance)
	  },
	  MathFloor: Math.floor,
	  Number,
	  NumberIsInteger: Number.isInteger,
	  NumberIsNaN: Number.isNaN,
	  NumberMAX_SAFE_INTEGER: Number.MAX_SAFE_INTEGER,
	  NumberMIN_SAFE_INTEGER: Number.MIN_SAFE_INTEGER,
	  NumberParseInt: Number.parseInt,
	  ObjectDefineProperties(self, props) {
	    return Object.defineProperties(self, props)
	  },
	  ObjectDefineProperty(self, name, prop) {
	    return Object.defineProperty(self, name, prop)
	  },
	  ObjectGetOwnPropertyDescriptor(self, name) {
	    return Object.getOwnPropertyDescriptor(self, name)
	  },
	  ObjectKeys(obj) {
	    return Object.keys(obj)
	  },
	  ObjectSetPrototypeOf(target, proto) {
	    return Object.setPrototypeOf(target, proto)
	  },
	  Promise,
	  PromisePrototypeCatch(self, fn) {
	    return self.catch(fn)
	  },
	  PromisePrototypeThen(self, thenFn, catchFn) {
	    return self.then(thenFn, catchFn)
	  },
	  PromiseReject(err) {
	    return Promise.reject(err)
	  },
	  ReflectApply: Reflect.apply,
	  RegExpPrototypeTest(self, value) {
	    return self.test(value)
	  },
	  SafeSet: Set,
	  String,
	  StringPrototypeSlice(self, start, end) {
	    return self.slice(start, end)
	  },
	  StringPrototypeToLowerCase(self) {
	    return self.toLowerCase()
	  },
	  StringPrototypeToUpperCase(self) {
	    return self.toUpperCase()
	  },
	  StringPrototypeTrim(self) {
	    return self.trim()
	  },
	  Symbol,
	  SymbolAsyncIterator: Symbol.asyncIterator,
	  SymbolHasInstance: Symbol.hasInstance,
	  SymbolIterator: Symbol.iterator,
	  TypedArrayPrototypeSet(self, buf, len) {
	    return self.set(buf, len)
	  },
	  Uint8Array
	};
	return primordials;
}

var util = {exports: {}};

var hasRequiredUtil;

function requireUtil () {
	if (hasRequiredUtil) return util.exports;
	hasRequiredUtil = 1;
	(function (module) {

		const bufferModule = require$$0;
		const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
		const Blob = globalThis.Blob || bufferModule.Blob;
		/* eslint-disable indent */
		const isBlob =
		  typeof Blob !== 'undefined'
		    ? function isBlob(b) {
		        // eslint-disable-next-line indent
		        return b instanceof Blob
		      }
		    : function isBlob(b) {
		        return false
		      };
		/* eslint-enable indent */

		// This is a simplified version of AggregateError
		class AggregateError extends Error {
		  constructor(errors) {
		    if (!Array.isArray(errors)) {
		      throw new TypeError(`Expected input to be an Array, got ${typeof errors}`)
		    }
		    let message = '';
		    for (let i = 0; i < errors.length; i++) {
		      message += `    ${errors[i].stack}\n`;
		    }
		    super(message);
		    this.name = 'AggregateError';
		    this.errors = errors;
		  }
		}
		module.exports = {
		  AggregateError,
		  kEmptyObject: Object.freeze({}),
		  once(callback) {
		    let called = false;
		    return function (...args) {
		      if (called) {
		        return
		      }
		      called = true;
		      callback.apply(this, args);
		    }
		  },
		  createDeferredPromise: function () {
		    let resolve;
		    let reject;

		    // eslint-disable-next-line promise/param-names
		    const promise = new Promise((res, rej) => {
		      resolve = res;
		      reject = rej;
		    });
		    return {
		      promise,
		      resolve,
		      reject
		    }
		  },
		  promisify(fn) {
		    return new Promise((resolve, reject) => {
		      fn((err, ...args) => {
		        if (err) {
		          return reject(err)
		        }
		        return resolve(...args)
		      });
		    })
		  },
		  debuglog() {
		    return function () {}
		  },
		  format(format, ...args) {
		    // Simplified version of https://nodejs.org/api/util.html#utilformatformat-args
		    return format.replace(/%([sdifj])/g, function (...[_unused, type]) {
		      const replacement = args.shift();
		      if (type === 'f') {
		        return replacement.toFixed(6)
		      } else if (type === 'j') {
		        return JSON.stringify(replacement)
		      } else if (type === 's' && typeof replacement === 'object') {
		        const ctor = replacement.constructor !== Object ? replacement.constructor.name : '';
		        return `${ctor} {}`.trim()
		      } else {
		        return replacement.toString()
		      }
		    })
		  },
		  inspect(value) {
		    // Vastly simplified version of https://nodejs.org/api/util.html#utilinspectobject-options
		    switch (typeof value) {
		      case 'string':
		        if (value.includes("'")) {
		          if (!value.includes('"')) {
		            return `"${value}"`
		          } else if (!value.includes('`') && !value.includes('${')) {
		            return `\`${value}\``
		          }
		        }
		        return `'${value}'`
		      case 'number':
		        if (isNaN(value)) {
		          return 'NaN'
		        } else if (Object.is(value, -0)) {
		          return String(value)
		        }
		        return value
		      case 'bigint':
		        return `${String(value)}n`
		      case 'boolean':
		      case 'undefined':
		        return String(value)
		      case 'object':
		        return '{}'
		    }
		  },
		  types: {
		    isAsyncFunction(fn) {
		      return fn instanceof AsyncFunction
		    },
		    isArrayBufferView(arr) {
		      return ArrayBuffer.isView(arr)
		    }
		  },
		  isBlob
		};
		module.exports.promisify.custom = Symbol.for('nodejs.util.promisify.custom');
} (util));
	return util.exports;
}

var operators = {};

/**
 * @author Toru Nagashima <https://github.com/mysticatea>
 * @copyright 2015 Toru Nagashima. All rights reserved.
 * See LICENSE file in root directory for full license.
 */
/**
 * @typedef {object} PrivateData
 * @property {EventTarget} eventTarget The event target.
 * @property {{type:string}} event The original event object.
 * @property {number} eventPhase The current event phase.
 * @property {EventTarget|null} currentTarget The current event target.
 * @property {boolean} canceled The flag to prevent default.
 * @property {boolean} stopped The flag to stop propagation.
 * @property {boolean} immediateStopped The flag to stop propagation immediately.
 * @property {Function|null} passiveListener The listener if the current listener is passive. Otherwise this is null.
 * @property {number} timeStamp The unix time.
 * @private
 */

/**
 * Private data for event wrappers.
 * @type {WeakMap<Event, PrivateData>}
 * @private
 */
const privateData = new WeakMap();

/**
 * Cache for wrapper classes.
 * @type {WeakMap<Object, Function>}
 * @private
 */
const wrappers = new WeakMap();

/**
 * Get private data.
 * @param {Event} event The event object to get private data.
 * @returns {PrivateData} The private data of the event.
 * @private
 */
function pd(event) {
    const retv = privateData.get(event);
    console.assert(
        retv != null,
        "'this' is expected an Event object, but got",
        event
    );
    return retv
}

/**
 * https://dom.spec.whatwg.org/#set-the-canceled-flag
 * @param data {PrivateData} private data.
 */
function setCancelFlag(data) {
    if (data.passiveListener != null) {
        if (
            typeof console !== "undefined" &&
            typeof console.error === "function"
        ) {
            console.error(
                "Unable to preventDefault inside passive event listener invocation.",
                data.passiveListener
            );
        }
        return
    }
    if (!data.event.cancelable) {
        return
    }

    data.canceled = true;
    if (typeof data.event.preventDefault === "function") {
        data.event.preventDefault();
    }
}

/**
 * @see https://dom.spec.whatwg.org/#interface-event
 * @private
 */
/**
 * The event wrapper.
 * @constructor
 * @param {EventTarget} eventTarget The event target of this dispatching.
 * @param {Event|{type:string}} event The original event to wrap.
 */
function Event(eventTarget, event) {
    privateData.set(this, {
        eventTarget,
        event,
        eventPhase: 2,
        currentTarget: eventTarget,
        canceled: false,
        stopped: false,
        immediateStopped: false,
        passiveListener: null,
        timeStamp: event.timeStamp || Date.now(),
    });

    // https://heycam.github.io/webidl/#Unforgeable
    Object.defineProperty(this, "isTrusted", { value: false, enumerable: true });

    // Define accessors
    const keys = Object.keys(event);
    for (let i = 0; i < keys.length; ++i) {
        const key = keys[i];
        if (!(key in this)) {
            Object.defineProperty(this, key, defineRedirectDescriptor(key));
        }
    }
}

// Should be enumerable, but class methods are not enumerable.
Event.prototype = {
    /**
     * The type of this event.
     * @type {string}
     */
    get type() {
        return pd(this).event.type
    },

    /**
     * The target of this event.
     * @type {EventTarget}
     */
    get target() {
        return pd(this).eventTarget
    },

    /**
     * The target of this event.
     * @type {EventTarget}
     */
    get currentTarget() {
        return pd(this).currentTarget
    },

    /**
     * @returns {EventTarget[]} The composed path of this event.
     */
    composedPath() {
        const currentTarget = pd(this).currentTarget;
        if (currentTarget == null) {
            return []
        }
        return [currentTarget]
    },

    /**
     * Constant of NONE.
     * @type {number}
     */
    get NONE() {
        return 0
    },

    /**
     * Constant of CAPTURING_PHASE.
     * @type {number}
     */
    get CAPTURING_PHASE() {
        return 1
    },

    /**
     * Constant of AT_TARGET.
     * @type {number}
     */
    get AT_TARGET() {
        return 2
    },

    /**
     * Constant of BUBBLING_PHASE.
     * @type {number}
     */
    get BUBBLING_PHASE() {
        return 3
    },

    /**
     * The target of this event.
     * @type {number}
     */
    get eventPhase() {
        return pd(this).eventPhase
    },

    /**
     * Stop event bubbling.
     * @returns {void}
     */
    stopPropagation() {
        const data = pd(this);

        data.stopped = true;
        if (typeof data.event.stopPropagation === "function") {
            data.event.stopPropagation();
        }
    },

    /**
     * Stop event bubbling.
     * @returns {void}
     */
    stopImmediatePropagation() {
        const data = pd(this);

        data.stopped = true;
        data.immediateStopped = true;
        if (typeof data.event.stopImmediatePropagation === "function") {
            data.event.stopImmediatePropagation();
        }
    },

    /**
     * The flag to be bubbling.
     * @type {boolean}
     */
    get bubbles() {
        return Boolean(pd(this).event.bubbles)
    },

    /**
     * The flag to be cancelable.
     * @type {boolean}
     */
    get cancelable() {
        return Boolean(pd(this).event.cancelable)
    },

    /**
     * Cancel this event.
     * @returns {void}
     */
    preventDefault() {
        setCancelFlag(pd(this));
    },

    /**
     * The flag to indicate cancellation state.
     * @type {boolean}
     */
    get defaultPrevented() {
        return pd(this).canceled
    },

    /**
     * The flag to be composed.
     * @type {boolean}
     */
    get composed() {
        return Boolean(pd(this).event.composed)
    },

    /**
     * The unix time of this event.
     * @type {number}
     */
    get timeStamp() {
        return pd(this).timeStamp
    },

    /**
     * The target of this event.
     * @type {EventTarget}
     * @deprecated
     */
    get srcElement() {
        return pd(this).eventTarget
    },

    /**
     * The flag to stop event bubbling.
     * @type {boolean}
     * @deprecated
     */
    get cancelBubble() {
        return pd(this).stopped
    },
    set cancelBubble(value) {
        if (!value) {
            return
        }
        const data = pd(this);

        data.stopped = true;
        if (typeof data.event.cancelBubble === "boolean") {
            data.event.cancelBubble = true;
        }
    },

    /**
     * The flag to indicate cancellation state.
     * @type {boolean}
     * @deprecated
     */
    get returnValue() {
        return !pd(this).canceled
    },
    set returnValue(value) {
        if (!value) {
            setCancelFlag(pd(this));
        }
    },

    /**
     * Initialize this event object. But do nothing under event dispatching.
     * @param {string} type The event type.
     * @param {boolean} [bubbles=false] The flag to be possible to bubble up.
     * @param {boolean} [cancelable=false] The flag to be possible to cancel.
     * @deprecated
     */
    initEvent() {
        // Do nothing.
    },
};

// `constructor` is not enumerable.
Object.defineProperty(Event.prototype, "constructor", {
    value: Event,
    configurable: true,
    writable: true,
});

// Ensure `event instanceof window.Event` is `true`.
if (typeof window !== "undefined" && typeof window.Event !== "undefined") {
    Object.setPrototypeOf(Event.prototype, window.Event.prototype);

    // Make association for wrappers.
    wrappers.set(window.Event.prototype, Event);
}

/**
 * Get the property descriptor to redirect a given property.
 * @param {string} key Property name to define property descriptor.
 * @returns {PropertyDescriptor} The property descriptor to redirect the property.
 * @private
 */
function defineRedirectDescriptor(key) {
    return {
        get() {
            return pd(this).event[key]
        },
        set(value) {
            pd(this).event[key] = value;
        },
        configurable: true,
        enumerable: true,
    }
}

/**
 * Get the property descriptor to call a given method property.
 * @param {string} key Property name to define property descriptor.
 * @returns {PropertyDescriptor} The property descriptor to call the method property.
 * @private
 */
function defineCallDescriptor(key) {
    return {
        value() {
            const event = pd(this).event;
            return event[key].apply(event, arguments)
        },
        configurable: true,
        enumerable: true,
    }
}

/**
 * Define new wrapper class.
 * @param {Function} BaseEvent The base wrapper class.
 * @param {Object} proto The prototype of the original event.
 * @returns {Function} The defined wrapper class.
 * @private
 */
function defineWrapper(BaseEvent, proto) {
    const keys = Object.keys(proto);
    if (keys.length === 0) {
        return BaseEvent
    }

    /** CustomEvent */
    function CustomEvent(eventTarget, event) {
        BaseEvent.call(this, eventTarget, event);
    }

    CustomEvent.prototype = Object.create(BaseEvent.prototype, {
        constructor: { value: CustomEvent, configurable: true, writable: true },
    });

    // Define accessors.
    for (let i = 0; i < keys.length; ++i) {
        const key = keys[i];
        if (!(key in BaseEvent.prototype)) {
            const descriptor = Object.getOwnPropertyDescriptor(proto, key);
            const isFunc = typeof descriptor.value === "function";
            Object.defineProperty(
                CustomEvent.prototype,
                key,
                isFunc
                    ? defineCallDescriptor(key)
                    : defineRedirectDescriptor(key)
            );
        }
    }

    return CustomEvent
}

/**
 * Get the wrapper class of a given prototype.
 * @param {Object} proto The prototype of the original event to get its wrapper.
 * @returns {Function} The wrapper class.
 * @private
 */
function getWrapper(proto) {
    if (proto == null || proto === Object.prototype) {
        return Event
    }

    let wrapper = wrappers.get(proto);
    if (wrapper == null) {
        wrapper = defineWrapper(getWrapper(Object.getPrototypeOf(proto)), proto);
        wrappers.set(proto, wrapper);
    }
    return wrapper
}

/**
 * Wrap a given event to management a dispatching.
 * @param {EventTarget} eventTarget The event target of this dispatching.
 * @param {Object} event The event to wrap.
 * @returns {Event} The wrapper instance.
 * @private
 */
function wrapEvent(eventTarget, event) {
    const Wrapper = getWrapper(Object.getPrototypeOf(event));
    return new Wrapper(eventTarget, event)
}

/**
 * Get the immediateStopped flag of a given event.
 * @param {Event} event The event to get.
 * @returns {boolean} The flag to stop propagation immediately.
 * @private
 */
function isStopped(event) {
    return pd(event).immediateStopped
}

/**
 * Set the current event phase of a given event.
 * @param {Event} event The event to set current target.
 * @param {number} eventPhase New event phase.
 * @returns {void}
 * @private
 */
function setEventPhase(event, eventPhase) {
    pd(event).eventPhase = eventPhase;
}

/**
 * Set the current target of a given event.
 * @param {Event} event The event to set current target.
 * @param {EventTarget|null} currentTarget New current target.
 * @returns {void}
 * @private
 */
function setCurrentTarget(event, currentTarget) {
    pd(event).currentTarget = currentTarget;
}

/**
 * Set a passive listener of a given event.
 * @param {Event} event The event to set current target.
 * @param {Function|null} passiveListener New passive listener.
 * @returns {void}
 * @private
 */
function setPassiveListener(event, passiveListener) {
    pd(event).passiveListener = passiveListener;
}

/**
 * @typedef {object} ListenerNode
 * @property {Function} listener
 * @property {1|2|3} listenerType
 * @property {boolean} passive
 * @property {boolean} once
 * @property {ListenerNode|null} next
 * @private
 */

/**
 * @type {WeakMap<object, Map<string, ListenerNode>>}
 * @private
 */
const listenersMap = new WeakMap();

// Listener types
const CAPTURE = 1;
const BUBBLE = 2;
const ATTRIBUTE = 3;

/**
 * Check whether a given value is an object or not.
 * @param {any} x The value to check.
 * @returns {boolean} `true` if the value is an object.
 */
function isObject(x) {
    return x !== null && typeof x === "object" //eslint-disable-line no-restricted-syntax
}

/**
 * Get listeners.
 * @param {EventTarget} eventTarget The event target to get.
 * @returns {Map<string, ListenerNode>} The listeners.
 * @private
 */
function getListeners(eventTarget) {
    const listeners = listenersMap.get(eventTarget);
    if (listeners == null) {
        throw new TypeError(
            "'this' is expected an EventTarget object, but got another value."
        )
    }
    return listeners
}

/**
 * Get the property descriptor for the event attribute of a given event.
 * @param {string} eventName The event name to get property descriptor.
 * @returns {PropertyDescriptor} The property descriptor.
 * @private
 */
function defineEventAttributeDescriptor(eventName) {
    return {
        get() {
            const listeners = getListeners(this);
            let node = listeners.get(eventName);
            while (node != null) {
                if (node.listenerType === ATTRIBUTE) {
                    return node.listener
                }
                node = node.next;
            }
            return null
        },

        set(listener) {
            if (typeof listener !== "function" && !isObject(listener)) {
                listener = null; // eslint-disable-line no-param-reassign
            }
            const listeners = getListeners(this);

            // Traverse to the tail while removing old value.
            let prev = null;
            let node = listeners.get(eventName);
            while (node != null) {
                if (node.listenerType === ATTRIBUTE) {
                    // Remove old value.
                    if (prev !== null) {
                        prev.next = node.next;
                    } else if (node.next !== null) {
                        listeners.set(eventName, node.next);
                    } else {
                        listeners.delete(eventName);
                    }
                } else {
                    prev = node;
                }

                node = node.next;
            }

            // Add new value.
            if (listener !== null) {
                const newNode = {
                    listener,
                    listenerType: ATTRIBUTE,
                    passive: false,
                    once: false,
                    next: null,
                };
                if (prev === null) {
                    listeners.set(eventName, newNode);
                } else {
                    prev.next = newNode;
                }
            }
        },
        configurable: true,
        enumerable: true,
    }
}

/**
 * Define an event attribute (e.g. `eventTarget.onclick`).
 * @param {Object} eventTargetPrototype The event target prototype to define an event attrbite.
 * @param {string} eventName The event name to define.
 * @returns {void}
 */
function defineEventAttribute(eventTargetPrototype, eventName) {
    Object.defineProperty(
        eventTargetPrototype,
        `on${eventName}`,
        defineEventAttributeDescriptor(eventName)
    );
}

/**
 * Define a custom EventTarget with event attributes.
 * @param {string[]} eventNames Event names for event attributes.
 * @returns {EventTarget} The custom EventTarget.
 * @private
 */
function defineCustomEventTarget(eventNames) {
    /** CustomEventTarget */
    function CustomEventTarget() {
        EventTarget.call(this);
    }

    CustomEventTarget.prototype = Object.create(EventTarget.prototype, {
        constructor: {
            value: CustomEventTarget,
            configurable: true,
            writable: true,
        },
    });

    for (let i = 0; i < eventNames.length; ++i) {
        defineEventAttribute(CustomEventTarget.prototype, eventNames[i]);
    }

    return CustomEventTarget
}

/**
 * EventTarget.
 *
 * - This is constructor if no arguments.
 * - This is a function which returns a CustomEventTarget constructor if there are arguments.
 *
 * For example:
 *
 *     class A extends EventTarget {}
 *     class B extends EventTarget("message") {}
 *     class C extends EventTarget("message", "error") {}
 *     class D extends EventTarget(["message", "error"]) {}
 */
function EventTarget() {
    /*eslint-disable consistent-return */
    if (this instanceof EventTarget) {
        listenersMap.set(this, new Map());
        return
    }
    if (arguments.length === 1 && Array.isArray(arguments[0])) {
        return defineCustomEventTarget(arguments[0])
    }
    if (arguments.length > 0) {
        const types = new Array(arguments.length);
        for (let i = 0; i < arguments.length; ++i) {
            types[i] = arguments[i];
        }
        return defineCustomEventTarget(types)
    }
    throw new TypeError("Cannot call a class as a function")
    /*eslint-enable consistent-return */
}

// Should be enumerable, but class methods are not enumerable.
EventTarget.prototype = {
    /**
     * Add a given listener to this event target.
     * @param {string} eventName The event name to add.
     * @param {Function} listener The listener to add.
     * @param {boolean|{capture?:boolean,passive?:boolean,once?:boolean}} [options] The options for this listener.
     * @returns {void}
     */
    addEventListener(eventName, listener, options) {
        if (listener == null) {
            return
        }
        if (typeof listener !== "function" && !isObject(listener)) {
            throw new TypeError("'listener' should be a function or an object.")
        }

        const listeners = getListeners(this);
        const optionsIsObj = isObject(options);
        const capture = optionsIsObj
            ? Boolean(options.capture)
            : Boolean(options);
        const listenerType = capture ? CAPTURE : BUBBLE;
        const newNode = {
            listener,
            listenerType,
            passive: optionsIsObj && Boolean(options.passive),
            once: optionsIsObj && Boolean(options.once),
            next: null,
        };

        // Set it as the first node if the first node is null.
        let node = listeners.get(eventName);
        if (node === undefined) {
            listeners.set(eventName, newNode);
            return
        }

        // Traverse to the tail while checking duplication..
        let prev = null;
        while (node != null) {
            if (
                node.listener === listener &&
                node.listenerType === listenerType
            ) {
                // Should ignore duplication.
                return
            }
            prev = node;
            node = node.next;
        }

        // Add it.
        prev.next = newNode;
    },

    /**
     * Remove a given listener from this event target.
     * @param {string} eventName The event name to remove.
     * @param {Function} listener The listener to remove.
     * @param {boolean|{capture?:boolean,passive?:boolean,once?:boolean}} [options] The options for this listener.
     * @returns {void}
     */
    removeEventListener(eventName, listener, options) {
        if (listener == null) {
            return
        }

        const listeners = getListeners(this);
        const capture = isObject(options)
            ? Boolean(options.capture)
            : Boolean(options);
        const listenerType = capture ? CAPTURE : BUBBLE;

        let prev = null;
        let node = listeners.get(eventName);
        while (node != null) {
            if (
                node.listener === listener &&
                node.listenerType === listenerType
            ) {
                if (prev !== null) {
                    prev.next = node.next;
                } else if (node.next !== null) {
                    listeners.set(eventName, node.next);
                } else {
                    listeners.delete(eventName);
                }
                return
            }

            prev = node;
            node = node.next;
        }
    },

    /**
     * Dispatch a given event.
     * @param {Event|{type:string}} event The event to dispatch.
     * @returns {boolean} `false` if canceled.
     */
    dispatchEvent(event) {
        if (event == null || typeof event.type !== "string") {
            throw new TypeError('"event.type" should be a string.')
        }

        // If listeners aren't registered, terminate.
        const listeners = getListeners(this);
        const eventName = event.type;
        let node = listeners.get(eventName);
        if (node == null) {
            return true
        }

        // Since we cannot rewrite several properties, so wrap object.
        const wrappedEvent = wrapEvent(this, event);

        // This doesn't process capturing phase and bubbling phase.
        // This isn't participating in a tree.
        let prev = null;
        while (node != null) {
            // Remove this listener if it's once
            if (node.once) {
                if (prev !== null) {
                    prev.next = node.next;
                } else if (node.next !== null) {
                    listeners.set(eventName, node.next);
                } else {
                    listeners.delete(eventName);
                }
            } else {
                prev = node;
            }

            // Call this listener
            setPassiveListener(
                wrappedEvent,
                node.passive ? node.listener : null
            );
            if (typeof node.listener === "function") {
                try {
                    node.listener.call(this, wrappedEvent);
                } catch (err) {
                    if (
                        typeof console !== "undefined" &&
                        typeof console.error === "function"
                    ) {
                        console.error(err);
                    }
                }
            } else if (
                node.listenerType !== ATTRIBUTE &&
                typeof node.listener.handleEvent === "function"
            ) {
                node.listener.handleEvent(wrappedEvent);
            }

            // Break if `event.stopImmediatePropagation` was called.
            if (isStopped(wrappedEvent)) {
                break
            }

            node = node.next;
        }
        setPassiveListener(wrappedEvent, null);
        setEventPhase(wrappedEvent, 0);
        setCurrentTarget(wrappedEvent, null);

        return !wrappedEvent.defaultPrevented
    },
};

// `constructor` is not enumerable.
Object.defineProperty(EventTarget.prototype, "constructor", {
    value: EventTarget,
    configurable: true,
    writable: true,
});

// Ensure `eventTarget instanceof window.EventTarget` is `true`.
if (
    typeof window !== "undefined" &&
    typeof window.EventTarget !== "undefined"
) {
    Object.setPrototypeOf(EventTarget.prototype, window.EventTarget.prototype);
}

/**
 * @author Toru Nagashima <https://github.com/mysticatea>
 * See LICENSE file in root directory for full license.
 */

/**
 * The signal class.
 * @see https://dom.spec.whatwg.org/#abortsignal
 */
class AbortSignal extends EventTarget {
    /**
     * AbortSignal cannot be constructed directly.
     */
    constructor() {
        super();
        throw new TypeError("AbortSignal cannot be constructed directly");
    }
    /**
     * Returns `true` if this `AbortSignal`'s `AbortController` has signaled to abort, and `false` otherwise.
     */
    get aborted() {
        const aborted = abortedFlags.get(this);
        if (typeof aborted !== "boolean") {
            throw new TypeError(`Expected 'this' to be an 'AbortSignal' object, but got ${this === null ? "null" : typeof this}`);
        }
        return aborted;
    }
}
defineEventAttribute(AbortSignal.prototype, "abort");
/**
 * Create an AbortSignal object.
 */
function createAbortSignal() {
    const signal = Object.create(AbortSignal.prototype);
    EventTarget.call(signal);
    abortedFlags.set(signal, false);
    return signal;
}
/**
 * Abort a given signal.
 */
function abortSignal(signal) {
    if (abortedFlags.get(signal) !== false) {
        return;
    }
    abortedFlags.set(signal, true);
    signal.dispatchEvent({ type: "abort" });
}
/**
 * Aborted flag for each instances.
 */
const abortedFlags = new WeakMap();
// Properties should be enumerable.
Object.defineProperties(AbortSignal.prototype, {
    aborted: { enumerable: true },
});
// `toString()` should return `"[object AbortSignal]"`
if (typeof Symbol === "function" && typeof Symbol.toStringTag === "symbol") {
    Object.defineProperty(AbortSignal.prototype, Symbol.toStringTag, {
        configurable: true,
        value: "AbortSignal",
    });
}

/**
 * The AbortController.
 * @see https://dom.spec.whatwg.org/#abortcontroller
 */
class AbortController {
    /**
     * Initialize this controller.
     */
    constructor() {
        signals.set(this, createAbortSignal());
    }
    /**
     * Returns the `AbortSignal` object associated with this object.
     */
    get signal() {
        return getSignal(this);
    }
    /**
     * Abort and signal to any observers that the associated activity is to be aborted.
     */
    abort() {
        abortSignal(getSignal(this));
    }
}
/**
 * Associated signals.
 */
const signals = new WeakMap();
/**
 * Get the associated signal of a given controller.
 */
function getSignal(controller) {
    const signal = signals.get(controller);
    if (signal == null) {
        throw new TypeError(`Expected 'this' to be an 'AbortController' object, but got ${controller === null ? "null" : typeof controller}`);
    }
    return signal;
}
// Properties should be enumerable.
Object.defineProperties(AbortController.prototype, {
    signal: { enumerable: true },
    abort: { enumerable: true },
});
if (typeof Symbol === "function" && typeof Symbol.toStringTag === "symbol") {
    Object.defineProperty(AbortController.prototype, Symbol.toStringTag, {
        configurable: true,
        value: "AbortController",
    });
}

var abortController = /*#__PURE__*/Object.freeze({
	__proto__: null,
	'default': AbortController,
	AbortController: AbortController,
	AbortSignal: AbortSignal
});

var require$$9 = /*@__PURE__*/getAugmentedNamespace(abortController);

var errors;
var hasRequiredErrors;

function requireErrors () {
	if (hasRequiredErrors) return errors;
	hasRequiredErrors = 1;

	const { format, inspect, AggregateError: CustomAggregateError } = requireUtil();

	/*
	  This file is a reduced and adapted version of the main lib/internal/errors.js file defined at

	  https://github.com/nodejs/node/blob/master/lib/internal/errors.js

	  Don't try to replace with the original file and keep it up to date (starting from E(...) definitions)
	  with the upstream file.
	*/

	const AggregateError = globalThis.AggregateError || CustomAggregateError;
	const kIsNodeError = Symbol('kIsNodeError');
	const kTypes = [
	  'string',
	  'function',
	  'number',
	  'object',
	  // Accept 'Function' and 'Object' as alternative to the lower cased version.
	  'Function',
	  'Object',
	  'boolean',
	  'bigint',
	  'symbol'
	];
	const classRegExp = /^([A-Z][a-z0-9]*)+$/;
	const nodeInternalPrefix = '__node_internal_';
	const codes = {};
	function assert(value, message) {
	  if (!value) {
	    throw new codes.ERR_INTERNAL_ASSERTION(message)
	  }
	}

	// Only use this for integers! Decimal numbers do not work with this function.
	function addNumericalSeparator(val) {
	  let res = '';
	  let i = val.length;
	  const start = val[0] === '-' ? 1 : 0;
	  for (; i >= start + 4; i -= 3) {
	    res = `_${val.slice(i - 3, i)}${res}`;
	  }
	  return `${val.slice(0, i)}${res}`
	}
	function getMessage(key, msg, args) {
	  if (typeof msg === 'function') {
	    assert(
	      msg.length <= args.length,
	      // Default options do not count.
	      `Code: ${key}; The provided arguments length (${args.length}) does not match the required ones (${msg.length}).`
	    );
	    return msg(...args)
	  }
	  const expectedLength = (msg.match(/%[dfijoOs]/g) || []).length;
	  assert(
	    expectedLength === args.length,
	    `Code: ${key}; The provided arguments length (${args.length}) does not match the required ones (${expectedLength}).`
	  );
	  if (args.length === 0) {
	    return msg
	  }
	  return format(msg, ...args)
	}
	function E(code, message, Base) {
	  if (!Base) {
	    Base = Error;
	  }
	  class NodeError extends Base {
	    constructor(...args) {
	      super(getMessage(code, message, args));
	    }
	    toString() {
	      return `${this.name} [${code}]: ${this.message}`
	    }
	  }
	  Object.defineProperties(NodeError.prototype, {
	    name: {
	      value: Base.name,
	      writable: true,
	      enumerable: false,
	      configurable: true
	    },
	    toString: {
	      value() {
	        return `${this.name} [${code}]: ${this.message}`
	      },
	      writable: true,
	      enumerable: false,
	      configurable: true
	    }
	  });
	  NodeError.prototype.code = code;
	  NodeError.prototype[kIsNodeError] = true;
	  codes[code] = NodeError;
	}
	function hideStackFrames(fn) {
	  // We rename the functions that will be hidden to cut off the stacktrace
	  // at the outermost one
	  const hidden = nodeInternalPrefix + fn.name;
	  Object.defineProperty(fn, 'name', {
	    value: hidden
	  });
	  return fn
	}
	function aggregateTwoErrors(innerError, outerError) {
	  if (innerError && outerError && innerError !== outerError) {
	    if (Array.isArray(outerError.errors)) {
	      // If `outerError` is already an `AggregateError`.
	      outerError.errors.push(innerError);
	      return outerError
	    }
	    const err = new AggregateError([outerError, innerError], outerError.message);
	    err.code = outerError.code;
	    return err
	  }
	  return innerError || outerError
	}
	class AbortError extends Error {
	  constructor(message = 'The operation was aborted', options = undefined) {
	    if (options !== undefined && typeof options !== 'object') {
	      throw new codes.ERR_INVALID_ARG_TYPE('options', 'Object', options)
	    }
	    super(message, options);
	    this.code = 'ABORT_ERR';
	    this.name = 'AbortError';
	  }
	}
	E('ERR_ASSERTION', '%s', Error);
	E(
	  'ERR_INVALID_ARG_TYPE',
	  (name, expected, actual) => {
	    assert(typeof name === 'string', "'name' must be a string");
	    if (!Array.isArray(expected)) {
	      expected = [expected];
	    }
	    let msg = 'The ';
	    if (name.endsWith(' argument')) {
	      // For cases like 'first argument'
	      msg += `${name} `;
	    } else {
	      msg += `"${name}" ${name.includes('.') ? 'property' : 'argument'} `;
	    }
	    msg += 'must be ';
	    const types = [];
	    const instances = [];
	    const other = [];
	    for (const value of expected) {
	      assert(typeof value === 'string', 'All expected entries have to be of type string');
	      if (kTypes.includes(value)) {
	        types.push(value.toLowerCase());
	      } else if (classRegExp.test(value)) {
	        instances.push(value);
	      } else {
	        assert(value !== 'object', 'The value "object" should be written as "Object"');
	        other.push(value);
	      }
	    }

	    // Special handle `object` in case other instances are allowed to outline
	    // the differences between each other.
	    if (instances.length > 0) {
	      const pos = types.indexOf('object');
	      if (pos !== -1) {
	        types.splice(types, pos, 1);
	        instances.push('Object');
	      }
	    }
	    if (types.length > 0) {
	      switch (types.length) {
	        case 1:
	          msg += `of type ${types[0]}`;
	          break
	        case 2:
	          msg += `one of type ${types[0]} or ${types[1]}`;
	          break
	        default: {
	          const last = types.pop();
	          msg += `one of type ${types.join(', ')}, or ${last}`;
	        }
	      }
	      if (instances.length > 0 || other.length > 0) {
	        msg += ' or ';
	      }
	    }
	    if (instances.length > 0) {
	      switch (instances.length) {
	        case 1:
	          msg += `an instance of ${instances[0]}`;
	          break
	        case 2:
	          msg += `an instance of ${instances[0]} or ${instances[1]}`;
	          break
	        default: {
	          const last = instances.pop();
	          msg += `an instance of ${instances.join(', ')}, or ${last}`;
	        }
	      }
	      if (other.length > 0) {
	        msg += ' or ';
	      }
	    }
	    switch (other.length) {
	      case 0:
	        break
	      case 1:
	        if (other[0].toLowerCase() !== other[0]) {
	          msg += 'an ';
	        }
	        msg += `${other[0]}`;
	        break
	      case 2:
	        msg += `one of ${other[0]} or ${other[1]}`;
	        break
	      default: {
	        const last = other.pop();
	        msg += `one of ${other.join(', ')}, or ${last}`;
	      }
	    }
	    if (actual == null) {
	      msg += `. Received ${actual}`;
	    } else if (typeof actual === 'function' && actual.name) {
	      msg += `. Received function ${actual.name}`;
	    } else if (typeof actual === 'object') {
	      var _actual$constructor;
	      if (
	        (_actual$constructor = actual.constructor) !== null &&
	        _actual$constructor !== undefined &&
	        _actual$constructor.name
	      ) {
	        msg += `. Received an instance of ${actual.constructor.name}`;
	      } else {
	        const inspected = inspect(actual, {
	          depth: -1
	        });
	        msg += `. Received ${inspected}`;
	      }
	    } else {
	      let inspected = inspect(actual, {
	        colors: false
	      });
	      if (inspected.length > 25) {
	        inspected = `${inspected.slice(0, 25)}...`;
	      }
	      msg += `. Received type ${typeof actual} (${inspected})`;
	    }
	    return msg
	  },
	  TypeError
	);
	E(
	  'ERR_INVALID_ARG_VALUE',
	  (name, value, reason = 'is invalid') => {
	    let inspected = inspect(value);
	    if (inspected.length > 128) {
	      inspected = inspected.slice(0, 128) + '...';
	    }
	    const type = name.includes('.') ? 'property' : 'argument';
	    return `The ${type} '${name}' ${reason}. Received ${inspected}`
	  },
	  TypeError
	);
	E(
	  'ERR_INVALID_RETURN_VALUE',
	  (input, name, value) => {
	    var _value$constructor;
	    const type =
	      value !== null &&
	      value !== undefined &&
	      (_value$constructor = value.constructor) !== null &&
	      _value$constructor !== undefined &&
	      _value$constructor.name
	        ? `instance of ${value.constructor.name}`
	        : `type ${typeof value}`;
	    return `Expected ${input} to be returned from the "${name}"` + ` function but got ${type}.`
	  },
	  TypeError
	);
	E(
	  'ERR_MISSING_ARGS',
	  (...args) => {
	    assert(args.length > 0, 'At least one arg needs to be specified');
	    let msg;
	    const len = args.length;
	    args = (Array.isArray(args) ? args : [args]).map((a) => `"${a}"`).join(' or ');
	    switch (len) {
	      case 1:
	        msg += `The ${args[0]} argument`;
	        break
	      case 2:
	        msg += `The ${args[0]} and ${args[1]} arguments`;
	        break
	      default:
	        {
	          const last = args.pop();
	          msg += `The ${args.join(', ')}, and ${last} arguments`;
	        }
	        break
	    }
	    return `${msg} must be specified`
	  },
	  TypeError
	);
	E(
	  'ERR_OUT_OF_RANGE',
	  (str, range, input) => {
	    assert(range, 'Missing "range" argument');
	    let received;
	    if (Number.isInteger(input) && Math.abs(input) > 2 ** 32) {
	      received = addNumericalSeparator(String(input));
	    } else if (typeof input === 'bigint') {
	      received = String(input);
	      if (input > 2n ** 32n || input < -(2n ** 32n)) {
	        received = addNumericalSeparator(received);
	      }
	      received += 'n';
	    } else {
	      received = inspect(input);
	    }
	    return `The value of "${str}" is out of range. It must be ${range}. Received ${received}`
	  },
	  RangeError
	);
	E('ERR_MULTIPLE_CALLBACK', 'Callback called multiple times', Error);
	E('ERR_METHOD_NOT_IMPLEMENTED', 'The %s method is not implemented', Error);
	E('ERR_STREAM_ALREADY_FINISHED', 'Cannot call %s after a stream was finished', Error);
	E('ERR_STREAM_CANNOT_PIPE', 'Cannot pipe, not readable', Error);
	E('ERR_STREAM_DESTROYED', 'Cannot call %s after a stream was destroyed', Error);
	E('ERR_STREAM_NULL_VALUES', 'May not write null values to stream', TypeError);
	E('ERR_STREAM_PREMATURE_CLOSE', 'Premature close', Error);
	E('ERR_STREAM_PUSH_AFTER_EOF', 'stream.push() after EOF', Error);
	E('ERR_STREAM_UNSHIFT_AFTER_END_EVENT', 'stream.unshift() after end event', Error);
	E('ERR_STREAM_WRITE_AFTER_END', 'write after end', Error);
	E('ERR_UNKNOWN_ENCODING', 'Unknown encoding: %s', TypeError);
	errors = {
	  AbortError,
	  aggregateTwoErrors: hideStackFrames(aggregateTwoErrors),
	  hideStackFrames,
	  codes
	};
	return errors;
}

var validators;
var hasRequiredValidators;

function requireValidators () {
	if (hasRequiredValidators) return validators;
	hasRequiredValidators = 1;

	const {
	  ArrayIsArray,
	  ArrayPrototypeIncludes,
	  ArrayPrototypeJoin,
	  ArrayPrototypeMap,
	  NumberIsInteger,
	  NumberIsNaN,
	  NumberMAX_SAFE_INTEGER,
	  NumberMIN_SAFE_INTEGER,
	  NumberParseInt,
	  ObjectPrototypeHasOwnProperty,
	  RegExpPrototypeExec,
	  String,
	  StringPrototypeToUpperCase,
	  StringPrototypeTrim
	} = requirePrimordials();
	const {
	  hideStackFrames,
	  codes: { ERR_SOCKET_BAD_PORT, ERR_INVALID_ARG_TYPE, ERR_INVALID_ARG_VALUE, ERR_OUT_OF_RANGE, ERR_UNKNOWN_SIGNAL }
	} = requireErrors();
	const { normalizeEncoding } = requireUtil();
	const { isAsyncFunction, isArrayBufferView } = requireUtil().types;
	const signals = {};

	/**
	 * @param {*} value
	 * @returns {boolean}
	 */
	function isInt32(value) {
	  return value === (value | 0)
	}

	/**
	 * @param {*} value
	 * @returns {boolean}
	 */
	function isUint32(value) {
	  return value === value >>> 0
	}
	const octalReg = /^[0-7]+$/;
	const modeDesc = 'must be a 32-bit unsigned integer or an octal string';

	/**
	 * Parse and validate values that will be converted into mode_t (the S_*
	 * constants). Only valid numbers and octal strings are allowed. They could be
	 * converted to 32-bit unsigned integers or non-negative signed integers in the
	 * C++ land, but any value higher than 0o777 will result in platform-specific
	 * behaviors.
	 *
	 * @param {*} value Values to be validated
	 * @param {string} name Name of the argument
	 * @param {number} [def] If specified, will be returned for invalid values
	 * @returns {number}
	 */
	function parseFileMode(value, name, def) {
	  if (typeof value === 'undefined') {
	    value = def;
	  }
	  if (typeof value === 'string') {
	    if (RegExpPrototypeExec(octalReg, value) === null) {
	      throw new ERR_INVALID_ARG_VALUE(name, value, modeDesc)
	    }
	    value = NumberParseInt(value, 8);
	  }
	  validateUint32(value, name);
	  return value
	}

	/**
	 * @callback validateInteger
	 * @param {*} value
	 * @param {string} name
	 * @param {number} [min]
	 * @param {number} [max]
	 * @returns {asserts value is number}
	 */

	/** @type {validateInteger} */
	const validateInteger = hideStackFrames((value, name, min = NumberMIN_SAFE_INTEGER, max = NumberMAX_SAFE_INTEGER) => {
	  if (typeof value !== 'number') throw new ERR_INVALID_ARG_TYPE(name, 'number', value)
	  if (!NumberIsInteger(value)) throw new ERR_OUT_OF_RANGE(name, 'an integer', value)
	  if (value < min || value > max) throw new ERR_OUT_OF_RANGE(name, `>= ${min} && <= ${max}`, value)
	});

	/**
	 * @callback validateInt32
	 * @param {*} value
	 * @param {string} name
	 * @param {number} [min]
	 * @param {number} [max]
	 * @returns {asserts value is number}
	 */

	/** @type {validateInt32} */
	const validateInt32 = hideStackFrames((value, name, min = -2147483648, max = 2147483647) => {
	  // The defaults for min and max correspond to the limits of 32-bit integers.
	  if (typeof value !== 'number') {
	    throw new ERR_INVALID_ARG_TYPE(name, 'number', value)
	  }
	  if (!NumberIsInteger(value)) {
	    throw new ERR_OUT_OF_RANGE(name, 'an integer', value)
	  }
	  if (value < min || value > max) {
	    throw new ERR_OUT_OF_RANGE(name, `>= ${min} && <= ${max}`, value)
	  }
	});

	/**
	 * @callback validateUint32
	 * @param {*} value
	 * @param {string} name
	 * @param {number|boolean} [positive=false]
	 * @returns {asserts value is number}
	 */

	/** @type {validateUint32} */
	const validateUint32 = hideStackFrames((value, name, positive = false) => {
	  if (typeof value !== 'number') {
	    throw new ERR_INVALID_ARG_TYPE(name, 'number', value)
	  }
	  if (!NumberIsInteger(value)) {
	    throw new ERR_OUT_OF_RANGE(name, 'an integer', value)
	  }
	  const min = positive ? 1 : 0;
	  // 2 ** 32 === 4294967296
	  const max = 4294967295;
	  if (value < min || value > max) {
	    throw new ERR_OUT_OF_RANGE(name, `>= ${min} && <= ${max}`, value)
	  }
	});

	/**
	 * @callback validateString
	 * @param {*} value
	 * @param {string} name
	 * @returns {asserts value is string}
	 */

	/** @type {validateString} */
	function validateString(value, name) {
	  if (typeof value !== 'string') throw new ERR_INVALID_ARG_TYPE(name, 'string', value)
	}

	/**
	 * @callback validateNumber
	 * @param {*} value
	 * @param {string} name
	 * @param {number} [min]
	 * @param {number} [max]
	 * @returns {asserts value is number}
	 */

	/** @type {validateNumber} */
	function validateNumber(value, name, min = undefined, max) {
	  if (typeof value !== 'number') throw new ERR_INVALID_ARG_TYPE(name, 'number', value)
	  if (
	    (min != null && value < min) ||
	    (max != null && value > max) ||
	    ((min != null || max != null) && NumberIsNaN(value))
	  ) {
	    throw new ERR_OUT_OF_RANGE(
	      name,
	      `${min != null ? `>= ${min}` : ''}${min != null && max != null ? ' && ' : ''}${max != null ? `<= ${max}` : ''}`,
	      value
	    )
	  }
	}

	/**
	 * @callback validateOneOf
	 * @template T
	 * @param {T} value
	 * @param {string} name
	 * @param {T[]} oneOf
	 */

	/** @type {validateOneOf} */
	const validateOneOf = hideStackFrames((value, name, oneOf) => {
	  if (!ArrayPrototypeIncludes(oneOf, value)) {
	    const allowed = ArrayPrototypeJoin(
	      ArrayPrototypeMap(oneOf, (v) => (typeof v === 'string' ? `'${v}'` : String(v))),
	      ', '
	    );
	    const reason = 'must be one of: ' + allowed;
	    throw new ERR_INVALID_ARG_VALUE(name, value, reason)
	  }
	});

	/**
	 * @callback validateBoolean
	 * @param {*} value
	 * @param {string} name
	 * @returns {asserts value is boolean}
	 */

	/** @type {validateBoolean} */
	function validateBoolean(value, name) {
	  if (typeof value !== 'boolean') throw new ERR_INVALID_ARG_TYPE(name, 'boolean', value)
	}
	function getOwnPropertyValueOrDefault(options, key, defaultValue) {
	  return options == null || !ObjectPrototypeHasOwnProperty(options, key) ? defaultValue : options[key]
	}

	/**
	 * @callback validateObject
	 * @param {*} value
	 * @param {string} name
	 * @param {{
	 *   allowArray?: boolean,
	 *   allowFunction?: boolean,
	 *   nullable?: boolean
	 * }} [options]
	 */

	/** @type {validateObject} */
	const validateObject = hideStackFrames((value, name, options = null) => {
	  const allowArray = getOwnPropertyValueOrDefault(options, 'allowArray', false);
	  const allowFunction = getOwnPropertyValueOrDefault(options, 'allowFunction', false);
	  const nullable = getOwnPropertyValueOrDefault(options, 'nullable', false);
	  if (
	    (!nullable && value === null) ||
	    (!allowArray && ArrayIsArray(value)) ||
	    (typeof value !== 'object' && (!allowFunction || typeof value !== 'function'))
	  ) {
	    throw new ERR_INVALID_ARG_TYPE(name, 'Object', value)
	  }
	});

	/**
	 * @callback validateArray
	 * @param {*} value
	 * @param {string} name
	 * @param {number} [minLength]
	 * @returns {asserts value is any[]}
	 */

	/** @type {validateArray} */
	const validateArray = hideStackFrames((value, name, minLength = 0) => {
	  if (!ArrayIsArray(value)) {
	    throw new ERR_INVALID_ARG_TYPE(name, 'Array', value)
	  }
	  if (value.length < minLength) {
	    const reason = `must be longer than ${minLength}`;
	    throw new ERR_INVALID_ARG_VALUE(name, value, reason)
	  }
	});

	// eslint-disable-next-line jsdoc/require-returns-check
	/**
	 * @param {*} signal
	 * @param {string} [name='signal']
	 * @returns {asserts signal is keyof signals}
	 */
	function validateSignalName(signal, name = 'signal') {
	  validateString(signal, name);
	  if (signals[signal] === undefined) {
	    if (signals[StringPrototypeToUpperCase(signal)] !== undefined) {
	      throw new ERR_UNKNOWN_SIGNAL(signal + ' (signals must use all capital letters)')
	    }
	    throw new ERR_UNKNOWN_SIGNAL(signal)
	  }
	}

	/**
	 * @callback validateBuffer
	 * @param {*} buffer
	 * @param {string} [name='buffer']
	 * @returns {asserts buffer is ArrayBufferView}
	 */

	/** @type {validateBuffer} */
	const validateBuffer = hideStackFrames((buffer, name = 'buffer') => {
	  if (!isArrayBufferView(buffer)) {
	    throw new ERR_INVALID_ARG_TYPE(name, ['Buffer', 'TypedArray', 'DataView'], buffer)
	  }
	});

	/**
	 * @param {string} data
	 * @param {string} encoding
	 */
	function validateEncoding(data, encoding) {
	  const normalizedEncoding = normalizeEncoding(encoding);
	  const length = data.length;
	  if (normalizedEncoding === 'hex' && length % 2 !== 0) {
	    throw new ERR_INVALID_ARG_VALUE('encoding', encoding, `is invalid for data of length ${length}`)
	  }
	}

	/**
	 * Check that the port number is not NaN when coerced to a number,
	 * is an integer and that it falls within the legal range of port numbers.
	 * @param {*} port
	 * @param {string} [name='Port']
	 * @param {boolean} [allowZero=true]
	 * @returns {number}
	 */
	function validatePort(port, name = 'Port', allowZero = true) {
	  if (
	    (typeof port !== 'number' && typeof port !== 'string') ||
	    (typeof port === 'string' && StringPrototypeTrim(port).length === 0) ||
	    +port !== +port >>> 0 ||
	    port > 0xffff ||
	    (port === 0 && !allowZero)
	  ) {
	    throw new ERR_SOCKET_BAD_PORT(name, port, allowZero)
	  }
	  return port | 0
	}

	/**
	 * @callback validateAbortSignal
	 * @param {*} signal
	 * @param {string} name
	 */

	/** @type {validateAbortSignal} */
	const validateAbortSignal = hideStackFrames((signal, name) => {
	  if (signal !== undefined && (signal === null || typeof signal !== 'object' || !('aborted' in signal))) {
	    throw new ERR_INVALID_ARG_TYPE(name, 'AbortSignal', signal)
	  }
	});

	/**
	 * @callback validateFunction
	 * @param {*} value
	 * @param {string} name
	 * @returns {asserts value is Function}
	 */

	/** @type {validateFunction} */
	const validateFunction = hideStackFrames((value, name) => {
	  if (typeof value !== 'function') throw new ERR_INVALID_ARG_TYPE(name, 'Function', value)
	});

	/**
	 * @callback validatePlainFunction
	 * @param {*} value
	 * @param {string} name
	 * @returns {asserts value is Function}
	 */

	/** @type {validatePlainFunction} */
	const validatePlainFunction = hideStackFrames((value, name) => {
	  if (typeof value !== 'function' || isAsyncFunction(value)) throw new ERR_INVALID_ARG_TYPE(name, 'Function', value)
	});

	/**
	 * @callback validateUndefined
	 * @param {*} value
	 * @param {string} name
	 * @returns {asserts value is undefined}
	 */

	/** @type {validateUndefined} */
	const validateUndefined = hideStackFrames((value, name) => {
	  if (value !== undefined) throw new ERR_INVALID_ARG_TYPE(name, 'undefined', value)
	});

	/**
	 * @template T
	 * @param {T} value
	 * @param {string} name
	 * @param {T[]} union
	 */
	function validateUnion(value, name, union) {
	  if (!ArrayPrototypeIncludes(union, value)) {
	    throw new ERR_INVALID_ARG_TYPE(name, `('${ArrayPrototypeJoin(union, '|')}')`, value)
	  }
	}
	validators = {
	  isInt32,
	  isUint32,
	  parseFileMode,
	  validateArray,
	  validateBoolean,
	  validateBuffer,
	  validateEncoding,
	  validateFunction,
	  validateInt32,
	  validateInteger,
	  validateNumber,
	  validateObject,
	  validateOneOf,
	  validatePlainFunction,
	  validatePort,
	  validateSignalName,
	  validateString,
	  validateUint32,
	  validateUndefined,
	  validateUnion,
	  validateAbortSignal
	};
	return validators;
}

var endOfStream = {exports: {}};

var process$1;
var hasRequiredProcess;

function requireProcess () {
	if (hasRequiredProcess) return process$1;
	hasRequiredProcess = 1;
	// for now just expose the builtin process global from node.js
	process$1 = commonjsGlobal.process;
	return process$1;
}

var utils;
var hasRequiredUtils;

function requireUtils () {
	if (hasRequiredUtils) return utils;
	hasRequiredUtils = 1;

	const { Symbol, SymbolAsyncIterator, SymbolIterator } = requirePrimordials();
	const kDestroyed = Symbol('kDestroyed');
	const kIsErrored = Symbol('kIsErrored');
	const kIsReadable = Symbol('kIsReadable');
	const kIsDisturbed = Symbol('kIsDisturbed');
	function isReadableNodeStream(obj, strict = false) {
	  var _obj$_readableState;
	  return !!(
	    (
	      obj &&
	      typeof obj.pipe === 'function' &&
	      typeof obj.on === 'function' &&
	      (!strict || (typeof obj.pause === 'function' && typeof obj.resume === 'function')) &&
	      (!obj._writableState ||
	        ((_obj$_readableState = obj._readableState) === null || _obj$_readableState === undefined
	          ? undefined
	          : _obj$_readableState.readable) !== false) &&
	      // Duplex
	      (!obj._writableState || obj._readableState)
	    ) // Writable has .pipe.
	  )
	}

	function isWritableNodeStream(obj) {
	  var _obj$_writableState;
	  return !!(
	    (
	      obj &&
	      typeof obj.write === 'function' &&
	      typeof obj.on === 'function' &&
	      (!obj._readableState ||
	        ((_obj$_writableState = obj._writableState) === null || _obj$_writableState === undefined
	          ? undefined
	          : _obj$_writableState.writable) !== false)
	    ) // Duplex
	  )
	}

	function isDuplexNodeStream(obj) {
	  return !!(
	    obj &&
	    typeof obj.pipe === 'function' &&
	    obj._readableState &&
	    typeof obj.on === 'function' &&
	    typeof obj.write === 'function'
	  )
	}
	function isNodeStream(obj) {
	  return (
	    obj &&
	    (obj._readableState ||
	      obj._writableState ||
	      (typeof obj.write === 'function' && typeof obj.on === 'function') ||
	      (typeof obj.pipe === 'function' && typeof obj.on === 'function'))
	  )
	}
	function isIterable(obj, isAsync) {
	  if (obj == null) return false
	  if (isAsync === true) return typeof obj[SymbolAsyncIterator] === 'function'
	  if (isAsync === false) return typeof obj[SymbolIterator] === 'function'
	  return typeof obj[SymbolAsyncIterator] === 'function' || typeof obj[SymbolIterator] === 'function'
	}
	function isDestroyed(stream) {
	  if (!isNodeStream(stream)) return null
	  const wState = stream._writableState;
	  const rState = stream._readableState;
	  const state = wState || rState;
	  return !!(stream.destroyed || stream[kDestroyed] || (state !== null && state !== undefined && state.destroyed))
	}

	// Have been end():d.
	function isWritableEnded(stream) {
	  if (!isWritableNodeStream(stream)) return null
	  if (stream.writableEnded === true) return true
	  const wState = stream._writableState;
	  if (wState !== null && wState !== undefined && wState.errored) return false
	  if (typeof (wState === null || wState === undefined ? undefined : wState.ended) !== 'boolean') return null
	  return wState.ended
	}

	// Have emitted 'finish'.
	function isWritableFinished(stream, strict) {
	  if (!isWritableNodeStream(stream)) return null
	  if (stream.writableFinished === true) return true
	  const wState = stream._writableState;
	  if (wState !== null && wState !== undefined && wState.errored) return false
	  if (typeof (wState === null || wState === undefined ? undefined : wState.finished) !== 'boolean') return null
	  return !!(wState.finished || (strict === false && wState.ended === true && wState.length === 0))
	}

	// Have been push(null):d.
	function isReadableEnded(stream) {
	  if (!isReadableNodeStream(stream)) return null
	  if (stream.readableEnded === true) return true
	  const rState = stream._readableState;
	  if (!rState || rState.errored) return false
	  if (typeof (rState === null || rState === undefined ? undefined : rState.ended) !== 'boolean') return null
	  return rState.ended
	}

	// Have emitted 'end'.
	function isReadableFinished(stream, strict) {
	  if (!isReadableNodeStream(stream)) return null
	  const rState = stream._readableState;
	  if (rState !== null && rState !== undefined && rState.errored) return false
	  if (typeof (rState === null || rState === undefined ? undefined : rState.endEmitted) !== 'boolean') return null
	  return !!(rState.endEmitted || (strict === false && rState.ended === true && rState.length === 0))
	}
	function isReadable(stream) {
	  if (stream && stream[kIsReadable] != null) return stream[kIsReadable]
	  if (typeof (stream === null || stream === undefined ? undefined : stream.readable) !== 'boolean') return null
	  if (isDestroyed(stream)) return false
	  return isReadableNodeStream(stream) && stream.readable && !isReadableFinished(stream)
	}
	function isWritable(stream) {
	  if (typeof (stream === null || stream === undefined ? undefined : stream.writable) !== 'boolean') return null
	  if (isDestroyed(stream)) return false
	  return isWritableNodeStream(stream) && stream.writable && !isWritableEnded(stream)
	}
	function isFinished(stream, opts) {
	  if (!isNodeStream(stream)) {
	    return null
	  }
	  if (isDestroyed(stream)) {
	    return true
	  }
	  if ((opts === null || opts === undefined ? undefined : opts.readable) !== false && isReadable(stream)) {
	    return false
	  }
	  if ((opts === null || opts === undefined ? undefined : opts.writable) !== false && isWritable(stream)) {
	    return false
	  }
	  return true
	}
	function isWritableErrored(stream) {
	  var _stream$_writableStat, _stream$_writableStat2;
	  if (!isNodeStream(stream)) {
	    return null
	  }
	  if (stream.writableErrored) {
	    return stream.writableErrored
	  }
	  return (_stream$_writableStat =
	    (_stream$_writableStat2 = stream._writableState) === null || _stream$_writableStat2 === undefined
	      ? undefined
	      : _stream$_writableStat2.errored) !== null && _stream$_writableStat !== undefined
	    ? _stream$_writableStat
	    : null
	}
	function isReadableErrored(stream) {
	  var _stream$_readableStat, _stream$_readableStat2;
	  if (!isNodeStream(stream)) {
	    return null
	  }
	  if (stream.readableErrored) {
	    return stream.readableErrored
	  }
	  return (_stream$_readableStat =
	    (_stream$_readableStat2 = stream._readableState) === null || _stream$_readableStat2 === undefined
	      ? undefined
	      : _stream$_readableStat2.errored) !== null && _stream$_readableStat !== undefined
	    ? _stream$_readableStat
	    : null
	}
	function isClosed(stream) {
	  if (!isNodeStream(stream)) {
	    return null
	  }
	  if (typeof stream.closed === 'boolean') {
	    return stream.closed
	  }
	  const wState = stream._writableState;
	  const rState = stream._readableState;
	  if (
	    typeof (wState === null || wState === undefined ? undefined : wState.closed) === 'boolean' ||
	    typeof (rState === null || rState === undefined ? undefined : rState.closed) === 'boolean'
	  ) {
	    return (
	      (wState === null || wState === undefined ? undefined : wState.closed) ||
	      (rState === null || rState === undefined ? undefined : rState.closed)
	    )
	  }
	  if (typeof stream._closed === 'boolean' && isOutgoingMessage(stream)) {
	    return stream._closed
	  }
	  return null
	}
	function isOutgoingMessage(stream) {
	  return (
	    typeof stream._closed === 'boolean' &&
	    typeof stream._defaultKeepAlive === 'boolean' &&
	    typeof stream._removedConnection === 'boolean' &&
	    typeof stream._removedContLen === 'boolean'
	  )
	}
	function isServerResponse(stream) {
	  return typeof stream._sent100 === 'boolean' && isOutgoingMessage(stream)
	}
	function isServerRequest(stream) {
	  var _stream$req;
	  return (
	    typeof stream._consuming === 'boolean' &&
	    typeof stream._dumped === 'boolean' &&
	    ((_stream$req = stream.req) === null || _stream$req === undefined ? undefined : _stream$req.upgradeOrConnect) ===
	      undefined
	  )
	}
	function willEmitClose(stream) {
	  if (!isNodeStream(stream)) return null
	  const wState = stream._writableState;
	  const rState = stream._readableState;
	  const state = wState || rState;
	  return (
	    (!state && isServerResponse(stream)) || !!(state && state.autoDestroy && state.emitClose && state.closed === false)
	  )
	}
	function isDisturbed(stream) {
	  var _stream$kIsDisturbed;
	  return !!(
	    stream &&
	    ((_stream$kIsDisturbed = stream[kIsDisturbed]) !== null && _stream$kIsDisturbed !== undefined
	      ? _stream$kIsDisturbed
	      : stream.readableDidRead || stream.readableAborted)
	  )
	}
	function isErrored(stream) {
	  var _ref,
	    _ref2,
	    _ref3,
	    _ref4,
	    _ref5,
	    _stream$kIsErrored,
	    _stream$_readableStat3,
	    _stream$_writableStat3,
	    _stream$_readableStat4,
	    _stream$_writableStat4;
	  return !!(
	    stream &&
	    ((_ref =
	      (_ref2 =
	        (_ref3 =
	          (_ref4 =
	            (_ref5 =
	              (_stream$kIsErrored = stream[kIsErrored]) !== null && _stream$kIsErrored !== undefined
	                ? _stream$kIsErrored
	                : stream.readableErrored) !== null && _ref5 !== undefined
	              ? _ref5
	              : stream.writableErrored) !== null && _ref4 !== undefined
	            ? _ref4
	            : (_stream$_readableStat3 = stream._readableState) === null || _stream$_readableStat3 === undefined
	            ? undefined
	            : _stream$_readableStat3.errorEmitted) !== null && _ref3 !== undefined
	          ? _ref3
	          : (_stream$_writableStat3 = stream._writableState) === null || _stream$_writableStat3 === undefined
	          ? undefined
	          : _stream$_writableStat3.errorEmitted) !== null && _ref2 !== undefined
	        ? _ref2
	        : (_stream$_readableStat4 = stream._readableState) === null || _stream$_readableStat4 === undefined
	        ? undefined
	        : _stream$_readableStat4.errored) !== null && _ref !== undefined
	      ? _ref
	      : (_stream$_writableStat4 = stream._writableState) === null || _stream$_writableStat4 === undefined
	      ? undefined
	      : _stream$_writableStat4.errored)
	  )
	}
	utils = {
	  kDestroyed,
	  isDisturbed,
	  kIsDisturbed,
	  isErrored,
	  kIsErrored,
	  isReadable,
	  kIsReadable,
	  isClosed,
	  isDestroyed,
	  isDuplexNodeStream,
	  isFinished,
	  isIterable,
	  isReadableNodeStream,
	  isReadableEnded,
	  isReadableFinished,
	  isReadableErrored,
	  isNodeStream,
	  isWritable,
	  isWritableNodeStream,
	  isWritableEnded,
	  isWritableFinished,
	  isWritableErrored,
	  isServerRequest,
	  isServerResponse,
	  willEmitClose
	};
	return utils;
}

/* replacement start */

var hasRequiredEndOfStream;

function requireEndOfStream () {
	if (hasRequiredEndOfStream) return endOfStream.exports;
	hasRequiredEndOfStream = 1;
	const process = requireProcess()

	/* replacement end */
	// Ported from https://github.com/mafintosh/end-of-stream with
	// permission from the author, Mathias Buus (@mafintosh).

	;	const { AbortError, codes } = requireErrors();
	const { ERR_INVALID_ARG_TYPE, ERR_STREAM_PREMATURE_CLOSE } = codes;
	const { kEmptyObject, once } = requireUtil();
	const { validateAbortSignal, validateFunction, validateObject } = requireValidators();
	const { Promise } = requirePrimordials();
	const {
	  isClosed,
	  isReadable,
	  isReadableNodeStream,
	  isReadableFinished,
	  isReadableErrored,
	  isWritable,
	  isWritableNodeStream,
	  isWritableFinished,
	  isWritableErrored,
	  isNodeStream,
	  willEmitClose: _willEmitClose
	} = requireUtils();
	function isRequest(stream) {
	  return stream.setHeader && typeof stream.abort === 'function'
	}
	const nop = () => {};
	function eos(stream, options, callback) {
	  var _options$readable, _options$writable;
	  if (arguments.length === 2) {
	    callback = options;
	    options = kEmptyObject;
	  } else if (options == null) {
	    options = kEmptyObject;
	  } else {
	    validateObject(options, 'options');
	  }
	  validateFunction(callback, 'callback');
	  validateAbortSignal(options.signal, 'options.signal');
	  callback = once(callback);
	  const readable =
	    (_options$readable = options.readable) !== null && _options$readable !== undefined
	      ? _options$readable
	      : isReadableNodeStream(stream);
	  const writable =
	    (_options$writable = options.writable) !== null && _options$writable !== undefined
	      ? _options$writable
	      : isWritableNodeStream(stream);
	  if (!isNodeStream(stream)) {
	    // TODO: Webstreams.
	    throw new ERR_INVALID_ARG_TYPE('stream', 'Stream', stream)
	  }
	  const wState = stream._writableState;
	  const rState = stream._readableState;
	  const onlegacyfinish = () => {
	    if (!stream.writable) {
	      onfinish();
	    }
	  };

	  // TODO (ronag): Improve soft detection to include core modules and
	  // common ecosystem modules that do properly emit 'close' but fail
	  // this generic check.
	  let willEmitClose =
	    _willEmitClose(stream) && isReadableNodeStream(stream) === readable && isWritableNodeStream(stream) === writable;
	  let writableFinished = isWritableFinished(stream, false);
	  const onfinish = () => {
	    writableFinished = true;
	    // Stream should not be destroyed here. If it is that
	    // means that user space is doing something differently and
	    // we cannot trust willEmitClose.
	    if (stream.destroyed) {
	      willEmitClose = false;
	    }
	    if (willEmitClose && (!stream.readable || readable)) {
	      return
	    }
	    if (!readable || readableFinished) {
	      callback.call(stream);
	    }
	  };
	  let readableFinished = isReadableFinished(stream, false);
	  const onend = () => {
	    readableFinished = true;
	    // Stream should not be destroyed here. If it is that
	    // means that user space is doing something differently and
	    // we cannot trust willEmitClose.
	    if (stream.destroyed) {
	      willEmitClose = false;
	    }
	    if (willEmitClose && (!stream.writable || writable)) {
	      return
	    }
	    if (!writable || writableFinished) {
	      callback.call(stream);
	    }
	  };
	  const onerror = (err) => {
	    callback.call(stream, err);
	  };
	  let closed = isClosed(stream);
	  const onclose = () => {
	    closed = true;
	    const errored = isWritableErrored(stream) || isReadableErrored(stream);
	    if (errored && typeof errored !== 'boolean') {
	      return callback.call(stream, errored)
	    }
	    if (readable && !readableFinished && isReadableNodeStream(stream, true)) {
	      if (!isReadableFinished(stream, false)) return callback.call(stream, new ERR_STREAM_PREMATURE_CLOSE())
	    }
	    if (writable && !writableFinished) {
	      if (!isWritableFinished(stream, false)) return callback.call(stream, new ERR_STREAM_PREMATURE_CLOSE())
	    }
	    callback.call(stream);
	  };
	  const onrequest = () => {
	    stream.req.on('finish', onfinish);
	  };
	  if (isRequest(stream)) {
	    stream.on('complete', onfinish);
	    if (!willEmitClose) {
	      stream.on('abort', onclose);
	    }
	    if (stream.req) {
	      onrequest();
	    } else {
	      stream.on('request', onrequest);
	    }
	  } else if (writable && !wState) {
	    // legacy streams
	    stream.on('end', onlegacyfinish);
	    stream.on('close', onlegacyfinish);
	  }

	  // Not all streams will emit 'close' after 'aborted'.
	  if (!willEmitClose && typeof stream.aborted === 'boolean') {
	    stream.on('aborted', onclose);
	  }
	  stream.on('end', onend);
	  stream.on('finish', onfinish);
	  if (options.error !== false) {
	    stream.on('error', onerror);
	  }
	  stream.on('close', onclose);
	  if (closed) {
	    process.nextTick(onclose);
	  } else if (
	    (wState !== null && wState !== undefined && wState.errorEmitted) ||
	    (rState !== null && rState !== undefined && rState.errorEmitted)
	  ) {
	    if (!willEmitClose) {
	      process.nextTick(onclose);
	    }
	  } else if (
	    !readable &&
	    (!willEmitClose || isReadable(stream)) &&
	    (writableFinished || isWritable(stream) === false)
	  ) {
	    process.nextTick(onclose);
	  } else if (
	    !writable &&
	    (!willEmitClose || isWritable(stream)) &&
	    (readableFinished || isReadable(stream) === false)
	  ) {
	    process.nextTick(onclose);
	  } else if (rState && stream.req && stream.aborted) {
	    process.nextTick(onclose);
	  }
	  const cleanup = () => {
	    callback = nop;
	    stream.removeListener('aborted', onclose);
	    stream.removeListener('complete', onfinish);
	    stream.removeListener('abort', onclose);
	    stream.removeListener('request', onrequest);
	    if (stream.req) stream.req.removeListener('finish', onfinish);
	    stream.removeListener('end', onlegacyfinish);
	    stream.removeListener('close', onlegacyfinish);
	    stream.removeListener('finish', onfinish);
	    stream.removeListener('end', onend);
	    stream.removeListener('error', onerror);
	    stream.removeListener('close', onclose);
	  };
	  if (options.signal && !closed) {
	    const abort = () => {
	      // Keep it because cleanup removes it.
	      const endCallback = callback;
	      cleanup();
	      endCallback.call(
	        stream,
	        new AbortError(undefined, {
	          cause: options.signal.reason
	        })
	      );
	    };
	    if (options.signal.aborted) {
	      process.nextTick(abort);
	    } else {
	      const originalCallback = callback;
	      callback = once((...args) => {
	        options.signal.removeEventListener('abort', abort);
	        originalCallback.apply(stream, args);
	      });
	      options.signal.addEventListener('abort', abort);
	    }
	  }
	  return cleanup
	}
	function finished(stream, opts) {
	  return new Promise((resolve, reject) => {
	    eos(stream, opts, (err) => {
	      if (err) {
	        reject(err);
	      } else {
	        resolve();
	      }
	    });
	  })
	}
	endOfStream.exports = eos;
	endOfStream.exports.finished = finished;
	return endOfStream.exports;
}

var hasRequiredOperators;

function requireOperators () {
	if (hasRequiredOperators) return operators;
	hasRequiredOperators = 1;

	const AbortController = globalThis.AbortController || require$$9.AbortController;
	const {
	  codes: { ERR_INVALID_ARG_TYPE, ERR_MISSING_ARGS, ERR_OUT_OF_RANGE },
	  AbortError
	} = requireErrors();
	const { validateAbortSignal, validateInteger, validateObject } = requireValidators();
	const kWeakHandler = requirePrimordials().Symbol('kWeak');
	const { finished } = requireEndOfStream();
	const {
	  ArrayPrototypePush,
	  MathFloor,
	  Number,
	  NumberIsNaN,
	  Promise,
	  PromiseReject,
	  PromisePrototypeThen,
	  Symbol
	} = requirePrimordials();
	const kEmpty = Symbol('kEmpty');
	const kEof = Symbol('kEof');
	function map(fn, options) {
	  if (typeof fn !== 'function') {
	    throw new ERR_INVALID_ARG_TYPE('fn', ['Function', 'AsyncFunction'], fn)
	  }
	  if (options != null) {
	    validateObject(options, 'options');
	  }
	  if ((options === null || options === undefined ? undefined : options.signal) != null) {
	    validateAbortSignal(options.signal, 'options.signal');
	  }
	  let concurrency = 1;
	  if ((options === null || options === undefined ? undefined : options.concurrency) != null) {
	    concurrency = MathFloor(options.concurrency);
	  }
	  validateInteger(concurrency, 'concurrency', 1);
	  return async function* map() {
	    var _options$signal, _options$signal2;
	    const ac = new AbortController();
	    const stream = this;
	    const queue = [];
	    const signal = ac.signal;
	    const signalOpt = {
	      signal
	    };
	    const abort = () => ac.abort();
	    if (
	      options !== null &&
	      options !== undefined &&
	      (_options$signal = options.signal) !== null &&
	      _options$signal !== undefined &&
	      _options$signal.aborted
	    ) {
	      abort();
	    }
	    options === null || options === undefined
	      ? undefined
	      : (_options$signal2 = options.signal) === null || _options$signal2 === undefined
	      ? undefined
	      : _options$signal2.addEventListener('abort', abort);
	    let next;
	    let resume;
	    let done = false;
	    function onDone() {
	      done = true;
	    }
	    async function pump() {
	      try {
	        for await (let val of stream) {
	          var _val;
	          if (done) {
	            return
	          }
	          if (signal.aborted) {
	            throw new AbortError()
	          }
	          try {
	            val = fn(val, signalOpt);
	          } catch (err) {
	            val = PromiseReject(err);
	          }
	          if (val === kEmpty) {
	            continue
	          }
	          if (typeof ((_val = val) === null || _val === undefined ? undefined : _val.catch) === 'function') {
	            val.catch(onDone);
	          }
	          queue.push(val);
	          if (next) {
	            next();
	            next = null;
	          }
	          if (!done && queue.length && queue.length >= concurrency) {
	            await new Promise((resolve) => {
	              resume = resolve;
	            });
	          }
	        }
	        queue.push(kEof);
	      } catch (err) {
	        const val = PromiseReject(err);
	        PromisePrototypeThen(val, undefined, onDone);
	        queue.push(val);
	      } finally {
	        var _options$signal3;
	        done = true;
	        if (next) {
	          next();
	          next = null;
	        }
	        options === null || options === undefined
	          ? undefined
	          : (_options$signal3 = options.signal) === null || _options$signal3 === undefined
	          ? undefined
	          : _options$signal3.removeEventListener('abort', abort);
	      }
	    }
	    pump();
	    try {
	      while (true) {
	        while (queue.length > 0) {
	          const val = await queue[0];
	          if (val === kEof) {
	            return
	          }
	          if (signal.aborted) {
	            throw new AbortError()
	          }
	          if (val !== kEmpty) {
	            yield val;
	          }
	          queue.shift();
	          if (resume) {
	            resume();
	            resume = null;
	          }
	        }
	        await new Promise((resolve) => {
	          next = resolve;
	        });
	      }
	    } finally {
	      ac.abort();
	      done = true;
	      if (resume) {
	        resume();
	        resume = null;
	      }
	    }
	  }.call(this)
	}
	function asIndexedPairs(options = undefined) {
	  if (options != null) {
	    validateObject(options, 'options');
	  }
	  if ((options === null || options === undefined ? undefined : options.signal) != null) {
	    validateAbortSignal(options.signal, 'options.signal');
	  }
	  return async function* asIndexedPairs() {
	    let index = 0;
	    for await (const val of this) {
	      var _options$signal4;
	      if (
	        options !== null &&
	        options !== undefined &&
	        (_options$signal4 = options.signal) !== null &&
	        _options$signal4 !== undefined &&
	        _options$signal4.aborted
	      ) {
	        throw new AbortError({
	          cause: options.signal.reason
	        })
	      }
	      yield [index++, val];
	    }
	  }.call(this)
	}
	async function some(fn, options = undefined) {
	  for await (const unused of filter.call(this, fn, options)) {
	    return true
	  }
	  return false
	}
	async function every(fn, options = undefined) {
	  if (typeof fn !== 'function') {
	    throw new ERR_INVALID_ARG_TYPE('fn', ['Function', 'AsyncFunction'], fn)
	  }
	  // https://en.wikipedia.org/wiki/De_Morgan%27s_laws
	  return !(await some.call(
	    this,
	    async (...args) => {
	      return !(await fn(...args))
	    },
	    options
	  ))
	}
	async function find(fn, options) {
	  for await (const result of filter.call(this, fn, options)) {
	    return result
	  }
	  return undefined
	}
	async function forEach(fn, options) {
	  if (typeof fn !== 'function') {
	    throw new ERR_INVALID_ARG_TYPE('fn', ['Function', 'AsyncFunction'], fn)
	  }
	  async function forEachFn(value, options) {
	    await fn(value, options);
	    return kEmpty
	  }
	  // eslint-disable-next-line no-unused-vars
	  for await (const unused of map.call(this, forEachFn, options));
	}
	function filter(fn, options) {
	  if (typeof fn !== 'function') {
	    throw new ERR_INVALID_ARG_TYPE('fn', ['Function', 'AsyncFunction'], fn)
	  }
	  async function filterFn(value, options) {
	    if (await fn(value, options)) {
	      return value
	    }
	    return kEmpty
	  }
	  return map.call(this, filterFn, options)
	}

	// Specific to provide better error to reduce since the argument is only
	// missing if the stream has no items in it - but the code is still appropriate
	class ReduceAwareErrMissingArgs extends ERR_MISSING_ARGS {
	  constructor() {
	    super('reduce');
	    this.message = 'Reduce of an empty stream requires an initial value';
	  }
	}
	async function reduce(reducer, initialValue, options) {
	  var _options$signal5;
	  if (typeof reducer !== 'function') {
	    throw new ERR_INVALID_ARG_TYPE('reducer', ['Function', 'AsyncFunction'], reducer)
	  }
	  if (options != null) {
	    validateObject(options, 'options');
	  }
	  if ((options === null || options === undefined ? undefined : options.signal) != null) {
	    validateAbortSignal(options.signal, 'options.signal');
	  }
	  let hasInitialValue = arguments.length > 1;
	  if (
	    options !== null &&
	    options !== undefined &&
	    (_options$signal5 = options.signal) !== null &&
	    _options$signal5 !== undefined &&
	    _options$signal5.aborted
	  ) {
	    const err = new AbortError(undefined, {
	      cause: options.signal.reason
	    });
	    this.once('error', () => {}); // The error is already propagated
	    await finished(this.destroy(err));
	    throw err
	  }
	  const ac = new AbortController();
	  const signal = ac.signal;
	  if (options !== null && options !== undefined && options.signal) {
	    const opts = {
	      once: true,
	      [kWeakHandler]: this
	    };
	    options.signal.addEventListener('abort', () => ac.abort(), opts);
	  }
	  let gotAnyItemFromStream = false;
	  try {
	    for await (const value of this) {
	      var _options$signal6;
	      gotAnyItemFromStream = true;
	      if (
	        options !== null &&
	        options !== undefined &&
	        (_options$signal6 = options.signal) !== null &&
	        _options$signal6 !== undefined &&
	        _options$signal6.aborted
	      ) {
	        throw new AbortError()
	      }
	      if (!hasInitialValue) {
	        initialValue = value;
	        hasInitialValue = true;
	      } else {
	        initialValue = await reducer(initialValue, value, {
	          signal
	        });
	      }
	    }
	    if (!gotAnyItemFromStream && !hasInitialValue) {
	      throw new ReduceAwareErrMissingArgs()
	    }
	  } finally {
	    ac.abort();
	  }
	  return initialValue
	}
	async function toArray(options) {
	  if (options != null) {
	    validateObject(options, 'options');
	  }
	  if ((options === null || options === undefined ? undefined : options.signal) != null) {
	    validateAbortSignal(options.signal, 'options.signal');
	  }
	  const result = [];
	  for await (const val of this) {
	    var _options$signal7;
	    if (
	      options !== null &&
	      options !== undefined &&
	      (_options$signal7 = options.signal) !== null &&
	      _options$signal7 !== undefined &&
	      _options$signal7.aborted
	    ) {
	      throw new AbortError(undefined, {
	        cause: options.signal.reason
	      })
	    }
	    ArrayPrototypePush(result, val);
	  }
	  return result
	}
	function flatMap(fn, options) {
	  const values = map.call(this, fn, options);
	  return async function* flatMap() {
	    for await (const val of values) {
	      yield* val;
	    }
	  }.call(this)
	}
	function toIntegerOrInfinity(number) {
	  // We coerce here to align with the spec
	  // https://github.com/tc39/proposal-iterator-helpers/issues/169
	  number = Number(number);
	  if (NumberIsNaN(number)) {
	    return 0
	  }
	  if (number < 0) {
	    throw new ERR_OUT_OF_RANGE('number', '>= 0', number)
	  }
	  return number
	}
	function drop(number, options = undefined) {
	  if (options != null) {
	    validateObject(options, 'options');
	  }
	  if ((options === null || options === undefined ? undefined : options.signal) != null) {
	    validateAbortSignal(options.signal, 'options.signal');
	  }
	  number = toIntegerOrInfinity(number);
	  return async function* drop() {
	    var _options$signal8;
	    if (
	      options !== null &&
	      options !== undefined &&
	      (_options$signal8 = options.signal) !== null &&
	      _options$signal8 !== undefined &&
	      _options$signal8.aborted
	    ) {
	      throw new AbortError()
	    }
	    for await (const val of this) {
	      var _options$signal9;
	      if (
	        options !== null &&
	        options !== undefined &&
	        (_options$signal9 = options.signal) !== null &&
	        _options$signal9 !== undefined &&
	        _options$signal9.aborted
	      ) {
	        throw new AbortError()
	      }
	      if (number-- <= 0) {
	        yield val;
	      }
	    }
	  }.call(this)
	}
	function take(number, options = undefined) {
	  if (options != null) {
	    validateObject(options, 'options');
	  }
	  if ((options === null || options === undefined ? undefined : options.signal) != null) {
	    validateAbortSignal(options.signal, 'options.signal');
	  }
	  number = toIntegerOrInfinity(number);
	  return async function* take() {
	    var _options$signal10;
	    if (
	      options !== null &&
	      options !== undefined &&
	      (_options$signal10 = options.signal) !== null &&
	      _options$signal10 !== undefined &&
	      _options$signal10.aborted
	    ) {
	      throw new AbortError()
	    }
	    for await (const val of this) {
	      var _options$signal11;
	      if (
	        options !== null &&
	        options !== undefined &&
	        (_options$signal11 = options.signal) !== null &&
	        _options$signal11 !== undefined &&
	        _options$signal11.aborted
	      ) {
	        throw new AbortError()
	      }
	      if (number-- > 0) {
	        yield val;
	      } else {
	        return
	      }
	    }
	  }.call(this)
	}
	operators.streamReturningOperators = {
	  asIndexedPairs,
	  drop,
	  filter,
	  flatMap,
	  map,
	  take
	};
	operators.promiseReturningOperators = {
	  every,
	  forEach,
	  reduce,
	  toArray,
	  some,
	  find
	};
	return operators;
}

var destroy_1;
var hasRequiredDestroy;

function requireDestroy () {
	if (hasRequiredDestroy) return destroy_1;
	hasRequiredDestroy = 1;

	/* replacement start */

	const process = requireProcess();

	/* replacement end */

	const {
	  aggregateTwoErrors,
	  codes: { ERR_MULTIPLE_CALLBACK },
	  AbortError
	} = requireErrors();
	const { Symbol } = requirePrimordials();
	const { kDestroyed, isDestroyed, isFinished, isServerRequest } = requireUtils();
	const kDestroy = Symbol('kDestroy');
	const kConstruct = Symbol('kConstruct');
	function checkError(err, w, r) {
	  if (err) {
	    // Avoid V8 leak, https://github.com/nodejs/node/pull/34103#issuecomment-652002364
	    err.stack; // eslint-disable-line no-unused-expressions

	    if (w && !w.errored) {
	      w.errored = err;
	    }
	    if (r && !r.errored) {
	      r.errored = err;
	    }
	  }
	}

	// Backwards compat. cb() is undocumented and unused in core but
	// unfortunately might be used by modules.
	function destroy(err, cb) {
	  const r = this._readableState;
	  const w = this._writableState;
	  // With duplex streams we use the writable side for state.
	  const s = w || r;
	  if ((w && w.destroyed) || (r && r.destroyed)) {
	    if (typeof cb === 'function') {
	      cb();
	    }
	    return this
	  }

	  // We set destroyed to true before firing error callbacks in order
	  // to make it re-entrance safe in case destroy() is called within callbacks
	  checkError(err, w, r);
	  if (w) {
	    w.destroyed = true;
	  }
	  if (r) {
	    r.destroyed = true;
	  }

	  // If still constructing then defer calling _destroy.
	  if (!s.constructed) {
	    this.once(kDestroy, function (er) {
	      _destroy(this, aggregateTwoErrors(er, err), cb);
	    });
	  } else {
	    _destroy(this, err, cb);
	  }
	  return this
	}
	function _destroy(self, err, cb) {
	  let called = false;
	  function onDestroy(err) {
	    if (called) {
	      return
	    }
	    called = true;
	    const r = self._readableState;
	    const w = self._writableState;
	    checkError(err, w, r);
	    if (w) {
	      w.closed = true;
	    }
	    if (r) {
	      r.closed = true;
	    }
	    if (typeof cb === 'function') {
	      cb(err);
	    }
	    if (err) {
	      process.nextTick(emitErrorCloseNT, self, err);
	    } else {
	      process.nextTick(emitCloseNT, self);
	    }
	  }
	  try {
	    self._destroy(err || null, onDestroy);
	  } catch (err) {
	    onDestroy(err);
	  }
	}
	function emitErrorCloseNT(self, err) {
	  emitErrorNT(self, err);
	  emitCloseNT(self);
	}
	function emitCloseNT(self) {
	  const r = self._readableState;
	  const w = self._writableState;
	  if (w) {
	    w.closeEmitted = true;
	  }
	  if (r) {
	    r.closeEmitted = true;
	  }
	  if ((w && w.emitClose) || (r && r.emitClose)) {
	    self.emit('close');
	  }
	}
	function emitErrorNT(self, err) {
	  const r = self._readableState;
	  const w = self._writableState;
	  if ((w && w.errorEmitted) || (r && r.errorEmitted)) {
	    return
	  }
	  if (w) {
	    w.errorEmitted = true;
	  }
	  if (r) {
	    r.errorEmitted = true;
	  }
	  self.emit('error', err);
	}
	function undestroy() {
	  const r = this._readableState;
	  const w = this._writableState;
	  if (r) {
	    r.constructed = true;
	    r.closed = false;
	    r.closeEmitted = false;
	    r.destroyed = false;
	    r.errored = null;
	    r.errorEmitted = false;
	    r.reading = false;
	    r.ended = r.readable === false;
	    r.endEmitted = r.readable === false;
	  }
	  if (w) {
	    w.constructed = true;
	    w.destroyed = false;
	    w.closed = false;
	    w.closeEmitted = false;
	    w.errored = null;
	    w.errorEmitted = false;
	    w.finalCalled = false;
	    w.prefinished = false;
	    w.ended = w.writable === false;
	    w.ending = w.writable === false;
	    w.finished = w.writable === false;
	  }
	}
	function errorOrDestroy(stream, err, sync) {
	  // We have tests that rely on errors being emitted
	  // in the same tick, so changing this is semver major.
	  // For now when you opt-in to autoDestroy we allow
	  // the error to be emitted nextTick. In a future
	  // semver major update we should change the default to this.

	  const r = stream._readableState;
	  const w = stream._writableState;
	  if ((w && w.destroyed) || (r && r.destroyed)) {
	    return this
	  }
	  if ((r && r.autoDestroy) || (w && w.autoDestroy)) stream.destroy(err);
	  else if (err) {
	    // Avoid V8 leak, https://github.com/nodejs/node/pull/34103#issuecomment-652002364
	    err.stack; // eslint-disable-line no-unused-expressions

	    if (w && !w.errored) {
	      w.errored = err;
	    }
	    if (r && !r.errored) {
	      r.errored = err;
	    }
	    if (sync) {
	      process.nextTick(emitErrorNT, stream, err);
	    } else {
	      emitErrorNT(stream, err);
	    }
	  }
	}
	function construct(stream, cb) {
	  if (typeof stream._construct !== 'function') {
	    return
	  }
	  const r = stream._readableState;
	  const w = stream._writableState;
	  if (r) {
	    r.constructed = false;
	  }
	  if (w) {
	    w.constructed = false;
	  }
	  stream.once(kConstruct, cb);
	  if (stream.listenerCount(kConstruct) > 1) {
	    // Duplex
	    return
	  }
	  process.nextTick(constructNT, stream);
	}
	function constructNT(stream) {
	  let called = false;
	  function onConstruct(err) {
	    if (called) {
	      errorOrDestroy(stream, err !== null && err !== undefined ? err : new ERR_MULTIPLE_CALLBACK());
	      return
	    }
	    called = true;
	    const r = stream._readableState;
	    const w = stream._writableState;
	    const s = w || r;
	    if (r) {
	      r.constructed = true;
	    }
	    if (w) {
	      w.constructed = true;
	    }
	    if (s.destroyed) {
	      stream.emit(kDestroy, err);
	    } else if (err) {
	      errorOrDestroy(stream, err, true);
	    } else {
	      process.nextTick(emitConstructNT, stream);
	    }
	  }
	  try {
	    stream._construct(onConstruct);
	  } catch (err) {
	    onConstruct(err);
	  }
	}
	function emitConstructNT(stream) {
	  stream.emit(kConstruct);
	}
	function isRequest(stream) {
	  return stream && stream.setHeader && typeof stream.abort === 'function'
	}
	function emitCloseLegacy(stream) {
	  stream.emit('close');
	}
	function emitErrorCloseLegacy(stream, err) {
	  stream.emit('error', err);
	  process.nextTick(emitCloseLegacy, stream);
	}

	// Normalize destroy for legacy.
	function destroyer(stream, err) {
	  if (!stream || isDestroyed(stream)) {
	    return
	  }
	  if (!err && !isFinished(stream)) {
	    err = new AbortError();
	  }

	  // TODO: Remove isRequest branches.
	  if (isServerRequest(stream)) {
	    stream.socket = null;
	    stream.destroy(err);
	  } else if (isRequest(stream)) {
	    stream.abort();
	  } else if (isRequest(stream.req)) {
	    stream.req.abort();
	  } else if (typeof stream.destroy === 'function') {
	    stream.destroy(err);
	  } else if (typeof stream.close === 'function') {
	    // TODO: Don't lose err?
	    stream.close();
	  } else if (err) {
	    process.nextTick(emitErrorCloseLegacy, stream, err);
	  } else {
	    process.nextTick(emitCloseLegacy, stream);
	  }
	  if (!stream.destroyed) {
	    stream[kDestroyed] = true;
	  }
	}
	destroy_1 = {
	  construct,
	  destroyer,
	  destroy,
	  undestroy,
	  errorOrDestroy
	};
	return destroy_1;
}

var legacy;
var hasRequiredLegacy;

function requireLegacy () {
	if (hasRequiredLegacy) return legacy;
	hasRequiredLegacy = 1;

	const { ArrayIsArray, ObjectSetPrototypeOf } = requirePrimordials();
	const { EventEmitter: EE } = require$$2;
	function Stream(opts) {
	  EE.call(this, opts);
	}
	ObjectSetPrototypeOf(Stream.prototype, EE.prototype);
	ObjectSetPrototypeOf(Stream, EE);
	Stream.prototype.pipe = function (dest, options) {
	  const source = this;
	  function ondata(chunk) {
	    if (dest.writable && dest.write(chunk) === false && source.pause) {
	      source.pause();
	    }
	  }
	  source.on('data', ondata);
	  function ondrain() {
	    if (source.readable && source.resume) {
	      source.resume();
	    }
	  }
	  dest.on('drain', ondrain);

	  // If the 'end' option is not supplied, dest.end() will be called when
	  // source gets the 'end' or 'close' events.  Only dest.end() once.
	  if (!dest._isStdio && (!options || options.end !== false)) {
	    source.on('end', onend);
	    source.on('close', onclose);
	  }
	  let didOnEnd = false;
	  function onend() {
	    if (didOnEnd) return
	    didOnEnd = true;
	    dest.end();
	  }
	  function onclose() {
	    if (didOnEnd) return
	    didOnEnd = true;
	    if (typeof dest.destroy === 'function') dest.destroy();
	  }

	  // Don't leave dangling pipes when there are errors.
	  function onerror(er) {
	    cleanup();
	    if (EE.listenerCount(this, 'error') === 0) {
	      this.emit('error', er);
	    }
	  }
	  prependListener(source, 'error', onerror);
	  prependListener(dest, 'error', onerror);

	  // Remove all the event listeners that were added.
	  function cleanup() {
	    source.removeListener('data', ondata);
	    dest.removeListener('drain', ondrain);
	    source.removeListener('end', onend);
	    source.removeListener('close', onclose);
	    source.removeListener('error', onerror);
	    dest.removeListener('error', onerror);
	    source.removeListener('end', cleanup);
	    source.removeListener('close', cleanup);
	    dest.removeListener('close', cleanup);
	  }
	  source.on('end', cleanup);
	  source.on('close', cleanup);
	  dest.on('close', cleanup);
	  dest.emit('pipe', source);

	  // Allow for unix-like usage: A.pipe(B).pipe(C)
	  return dest
	};
	function prependListener(emitter, event, fn) {
	  // Sadly this is not cacheable as some libraries bundle their own
	  // event emitter implementation with them.
	  if (typeof emitter.prependListener === 'function') return emitter.prependListener(event, fn)

	  // This is a hack to make sure that our error handler is attached before any
	  // userland ones.  NEVER DO THIS. This is here only because this code needs
	  // to continue to work with older versions of Node.js that do not include
	  // the prependListener() method. The goal is to eventually remove this hack.
	  if (!emitter._events || !emitter._events[event]) emitter.on(event, fn);
	  else if (ArrayIsArray(emitter._events[event])) emitter._events[event].unshift(fn);
	  else emitter._events[event] = [fn, emitter._events[event]];
	}
	legacy = {
	  Stream,
	  prependListener
	};
	return legacy;
}

var addAbortSignal = {exports: {}};

var hasRequiredAddAbortSignal;

function requireAddAbortSignal () {
	if (hasRequiredAddAbortSignal) return addAbortSignal.exports;
	hasRequiredAddAbortSignal = 1;
	(function (module) {

		const { AbortError, codes } = requireErrors();
		const eos = requireEndOfStream();
		const { ERR_INVALID_ARG_TYPE } = codes;

		// This method is inlined here for readable-stream
		// It also does not allow for signal to not exist on the stream
		// https://github.com/nodejs/node/pull/36061#discussion_r533718029
		const validateAbortSignal = (signal, name) => {
		  if (typeof signal !== 'object' || !('aborted' in signal)) {
		    throw new ERR_INVALID_ARG_TYPE(name, 'AbortSignal', signal)
		  }
		};
		function isNodeStream(obj) {
		  return !!(obj && typeof obj.pipe === 'function')
		}
		module.exports.addAbortSignal = function addAbortSignal(signal, stream) {
		  validateAbortSignal(signal, 'signal');
		  if (!isNodeStream(stream)) {
		    throw new ERR_INVALID_ARG_TYPE('stream', 'stream.Stream', stream)
		  }
		  return module.exports.addAbortSignalNoValidate(signal, stream)
		};
		module.exports.addAbortSignalNoValidate = function (signal, stream) {
		  if (typeof signal !== 'object' || !('aborted' in signal)) {
		    return stream
		  }
		  const onAbort = () => {
		    stream.destroy(
		      new AbortError(undefined, {
		        cause: signal.reason
		      })
		    );
		  };
		  if (signal.aborted) {
		    onAbort();
		  } else {
		    signal.addEventListener('abort', onAbort);
		    eos(stream, () => signal.removeEventListener('abort', onAbort));
		  }
		  return stream
		};
} (addAbortSignal));
	return addAbortSignal.exports;
}

var buffer_list;
var hasRequiredBuffer_list;

function requireBuffer_list () {
	if (hasRequiredBuffer_list) return buffer_list;
	hasRequiredBuffer_list = 1;

	const { StringPrototypeSlice, SymbolIterator, TypedArrayPrototypeSet, Uint8Array } = requirePrimordials();
	const { Buffer } = require$$0;
	const { inspect } = requireUtil();
	buffer_list = class BufferList {
	  constructor() {
	    this.head = null;
	    this.tail = null;
	    this.length = 0;
	  }
	  push(v) {
	    const entry = {
	      data: v,
	      next: null
	    };
	    if (this.length > 0) this.tail.next = entry;
	    else this.head = entry;
	    this.tail = entry;
	    ++this.length;
	  }
	  unshift(v) {
	    const entry = {
	      data: v,
	      next: this.head
	    };
	    if (this.length === 0) this.tail = entry;
	    this.head = entry;
	    ++this.length;
	  }
	  shift() {
	    if (this.length === 0) return
	    const ret = this.head.data;
	    if (this.length === 1) this.head = this.tail = null;
	    else this.head = this.head.next;
	    --this.length;
	    return ret
	  }
	  clear() {
	    this.head = this.tail = null;
	    this.length = 0;
	  }
	  join(s) {
	    if (this.length === 0) return ''
	    let p = this.head;
	    let ret = '' + p.data;
	    while ((p = p.next) !== null) ret += s + p.data;
	    return ret
	  }
	  concat(n) {
	    if (this.length === 0) return Buffer.alloc(0)
	    const ret = Buffer.allocUnsafe(n >>> 0);
	    let p = this.head;
	    let i = 0;
	    while (p) {
	      TypedArrayPrototypeSet(ret, p.data, i);
	      i += p.data.length;
	      p = p.next;
	    }
	    return ret
	  }

	  // Consumes a specified amount of bytes or characters from the buffered data.
	  consume(n, hasStrings) {
	    const data = this.head.data;
	    if (n < data.length) {
	      // `slice` is the same for buffers and strings.
	      const slice = data.slice(0, n);
	      this.head.data = data.slice(n);
	      return slice
	    }
	    if (n === data.length) {
	      // First chunk is a perfect match.
	      return this.shift()
	    }
	    // Result spans more than one buffer.
	    return hasStrings ? this._getString(n) : this._getBuffer(n)
	  }
	  first() {
	    return this.head.data
	  }
	  *[SymbolIterator]() {
	    for (let p = this.head; p; p = p.next) {
	      yield p.data;
	    }
	  }

	  // Consumes a specified amount of characters from the buffered data.
	  _getString(n) {
	    let ret = '';
	    let p = this.head;
	    let c = 0;
	    do {
	      const str = p.data;
	      if (n > str.length) {
	        ret += str;
	        n -= str.length;
	      } else {
	        if (n === str.length) {
	          ret += str;
	          ++c;
	          if (p.next) this.head = p.next;
	          else this.head = this.tail = null;
	        } else {
	          ret += StringPrototypeSlice(str, 0, n);
	          this.head = p;
	          p.data = StringPrototypeSlice(str, n);
	        }
	        break
	      }
	      ++c;
	    } while ((p = p.next) !== null)
	    this.length -= c;
	    return ret
	  }

	  // Consumes a specified amount of bytes from the buffered data.
	  _getBuffer(n) {
	    const ret = Buffer.allocUnsafe(n);
	    const retLen = n;
	    let p = this.head;
	    let c = 0;
	    do {
	      const buf = p.data;
	      if (n > buf.length) {
	        TypedArrayPrototypeSet(ret, buf, retLen - n);
	        n -= buf.length;
	      } else {
	        if (n === buf.length) {
	          TypedArrayPrototypeSet(ret, buf, retLen - n);
	          ++c;
	          if (p.next) this.head = p.next;
	          else this.head = this.tail = null;
	        } else {
	          TypedArrayPrototypeSet(ret, new Uint8Array(buf.buffer, buf.byteOffset, n), retLen - n);
	          this.head = p;
	          p.data = buf.slice(n);
	        }
	        break
	      }
	      ++c;
	    } while ((p = p.next) !== null)
	    this.length -= c;
	    return ret
	  }

	  // Make sure the linked list only shows the minimal necessary information.
	  [Symbol.for('nodejs.util.inspect.custom')](_, options) {
	    return inspect(this, {
	      ...options,
	      // Only inspect one level.
	      depth: 0,
	      // It should not recurse.
	      customInspect: false
	    })
	  }
	};
	return buffer_list;
}

var state;
var hasRequiredState;

function requireState () {
	if (hasRequiredState) return state;
	hasRequiredState = 1;

	const { MathFloor, NumberIsInteger } = requirePrimordials();
	const { ERR_INVALID_ARG_VALUE } = requireErrors().codes;
	function highWaterMarkFrom(options, isDuplex, duplexKey) {
	  return options.highWaterMark != null ? options.highWaterMark : isDuplex ? options[duplexKey] : null
	}
	function getDefaultHighWaterMark(objectMode) {
	  return objectMode ? 16 : 16 * 1024
	}
	function getHighWaterMark(state, options, duplexKey, isDuplex) {
	  const hwm = highWaterMarkFrom(options, isDuplex, duplexKey);
	  if (hwm != null) {
	    if (!NumberIsInteger(hwm) || hwm < 0) {
	      const name = isDuplex ? `options.${duplexKey}` : 'options.highWaterMark';
	      throw new ERR_INVALID_ARG_VALUE(name, hwm)
	    }
	    return MathFloor(hwm)
	  }

	  // Default value
	  return getDefaultHighWaterMark(state.objectMode)
	}
	state = {
	  getHighWaterMark,
	  getDefaultHighWaterMark
	};
	return state;
}

var from_1;
var hasRequiredFrom;

function requireFrom () {
	if (hasRequiredFrom) return from_1;
	hasRequiredFrom = 1;

	/* replacement start */

	const process = requireProcess();

	/* replacement end */

	const { PromisePrototypeThen, SymbolAsyncIterator, SymbolIterator } = requirePrimordials();
	const { Buffer } = require$$0;
	const { ERR_INVALID_ARG_TYPE, ERR_STREAM_NULL_VALUES } = requireErrors().codes;
	function from(Readable, iterable, opts) {
	  let iterator;
	  if (typeof iterable === 'string' || iterable instanceof Buffer) {
	    return new Readable({
	      objectMode: true,
	      ...opts,
	      read() {
	        this.push(iterable);
	        this.push(null);
	      }
	    })
	  }
	  let isAsync;
	  if (iterable && iterable[SymbolAsyncIterator]) {
	    isAsync = true;
	    iterator = iterable[SymbolAsyncIterator]();
	  } else if (iterable && iterable[SymbolIterator]) {
	    isAsync = false;
	    iterator = iterable[SymbolIterator]();
	  } else {
	    throw new ERR_INVALID_ARG_TYPE('iterable', ['Iterable'], iterable)
	  }
	  const readable = new Readable({
	    objectMode: true,
	    highWaterMark: 1,
	    // TODO(ronag): What options should be allowed?
	    ...opts
	  });

	  // Flag to protect against _read
	  // being called before last iteration completion.
	  let reading = false;
	  readable._read = function () {
	    if (!reading) {
	      reading = true;
	      next();
	    }
	  };
	  readable._destroy = function (error, cb) {
	    PromisePrototypeThen(
	      close(error),
	      () => process.nextTick(cb, error),
	      // nextTick is here in case cb throws
	      (e) => process.nextTick(cb, e || error)
	    );
	  };
	  async function close(error) {
	    const hadError = error !== undefined && error !== null;
	    const hasThrow = typeof iterator.throw === 'function';
	    if (hadError && hasThrow) {
	      const { value, done } = await iterator.throw(error);
	      await value;
	      if (done) {
	        return
	      }
	    }
	    if (typeof iterator.return === 'function') {
	      const { value } = await iterator.return();
	      await value;
	    }
	  }
	  async function next() {
	    for (;;) {
	      try {
	        const { value, done } = isAsync ? await iterator.next() : iterator.next();
	        if (done) {
	          readable.push(null);
	        } else {
	          const res = value && typeof value.then === 'function' ? await value : value;
	          if (res === null) {
	            reading = false;
	            throw new ERR_STREAM_NULL_VALUES()
	          } else if (readable.push(res)) {
	            continue
	          } else {
	            reading = false;
	          }
	        }
	      } catch (err) {
	        readable.destroy(err);
	      }
	      break
	    }
	  }
	  return readable
	}
	from_1 = from;
	return from_1;
}

/* replacement start */

var readable;
var hasRequiredReadable;

function requireReadable () {
	if (hasRequiredReadable) return readable;
	hasRequiredReadable = 1;
	const process = requireProcess()

	/* replacement end */
	// Copyright Joyent, Inc. and other Node contributors.
	//
	// Permission is hereby granted, free of charge, to any person obtaining a
	// copy of this software and associated documentation files (the
	// "Software"), to deal in the Software without restriction, including
	// without limitation the rights to use, copy, modify, merge, publish,
	// distribute, sublicense, and/or sell copies of the Software, and to permit
	// persons to whom the Software is furnished to do so, subject to the
	// following conditions:
	//
	// The above copyright notice and this permission notice shall be included
	// in all copies or substantial portions of the Software.
	//
	// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
	// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
	// USE OR OTHER DEALINGS IN THE SOFTWARE.

	;	const {
	  ArrayPrototypeIndexOf,
	  NumberIsInteger,
	  NumberIsNaN,
	  NumberParseInt,
	  ObjectDefineProperties,
	  ObjectKeys,
	  ObjectSetPrototypeOf,
	  Promise,
	  SafeSet,
	  SymbolAsyncIterator,
	  Symbol
	} = requirePrimordials();
	readable = Readable;
	Readable.ReadableState = ReadableState;
	const { EventEmitter: EE } = require$$2;
	const { Stream, prependListener } = requireLegacy();
	const { Buffer } = require$$0;
	const { addAbortSignal } = requireAddAbortSignal();
	const eos = requireEndOfStream();
	let debug = requireUtil().debuglog('stream', (fn) => {
	  debug = fn;
	});
	const BufferList = requireBuffer_list();
	const destroyImpl = requireDestroy();
	const { getHighWaterMark, getDefaultHighWaterMark } = requireState();
	const {
	  aggregateTwoErrors,
	  codes: {
	    ERR_INVALID_ARG_TYPE,
	    ERR_METHOD_NOT_IMPLEMENTED,
	    ERR_OUT_OF_RANGE,
	    ERR_STREAM_PUSH_AFTER_EOF,
	    ERR_STREAM_UNSHIFT_AFTER_END_EVENT
	  }
	} = requireErrors();
	const { validateObject } = requireValidators();
	const kPaused = Symbol('kPaused');
	const { StringDecoder } = require$$13;
	const from = requireFrom();
	ObjectSetPrototypeOf(Readable.prototype, Stream.prototype);
	ObjectSetPrototypeOf(Readable, Stream);
	const nop = () => {};
	const { errorOrDestroy } = destroyImpl;
	function ReadableState(options, stream, isDuplex) {
	  // Duplex streams are both readable and writable, but share
	  // the same options object.
	  // However, some cases require setting options to different
	  // values for the readable and the writable sides of the duplex stream.
	  // These options can be provided separately as readableXXX and writableXXX.
	  if (typeof isDuplex !== 'boolean') isDuplex = stream instanceof requireDuplex();

	  // Object stream flag. Used to make read(n) ignore n and to
	  // make all the buffer merging and length checks go away.
	  this.objectMode = !!(options && options.objectMode);
	  if (isDuplex) this.objectMode = this.objectMode || !!(options && options.readableObjectMode);

	  // The point at which it stops calling _read() to fill the buffer
	  // Note: 0 is a valid value, means "don't call _read preemptively ever"
	  this.highWaterMark = options
	    ? getHighWaterMark(this, options, 'readableHighWaterMark', isDuplex)
	    : getDefaultHighWaterMark(false);

	  // A linked list is used to store data chunks instead of an array because the
	  // linked list can remove elements from the beginning faster than
	  // array.shift().
	  this.buffer = new BufferList();
	  this.length = 0;
	  this.pipes = [];
	  this.flowing = null;
	  this.ended = false;
	  this.endEmitted = false;
	  this.reading = false;

	  // Stream is still being constructed and cannot be
	  // destroyed until construction finished or failed.
	  // Async construction is opt in, therefore we start as
	  // constructed.
	  this.constructed = true;

	  // A flag to be able to tell if the event 'readable'/'data' is emitted
	  // immediately, or on a later tick.  We set this to true at first, because
	  // any actions that shouldn't happen until "later" should generally also
	  // not happen before the first read call.
	  this.sync = true;

	  // Whenever we return null, then we set a flag to say
	  // that we're awaiting a 'readable' event emission.
	  this.needReadable = false;
	  this.emittedReadable = false;
	  this.readableListening = false;
	  this.resumeScheduled = false;
	  this[kPaused] = null;

	  // True if the error was already emitted and should not be thrown again.
	  this.errorEmitted = false;

	  // Should close be emitted on destroy. Defaults to true.
	  this.emitClose = !options || options.emitClose !== false;

	  // Should .destroy() be called after 'end' (and potentially 'finish').
	  this.autoDestroy = !options || options.autoDestroy !== false;

	  // Has it been destroyed.
	  this.destroyed = false;

	  // Indicates whether the stream has errored. When true no further
	  // _read calls, 'data' or 'readable' events should occur. This is needed
	  // since when autoDestroy is disabled we need a way to tell whether the
	  // stream has failed.
	  this.errored = null;

	  // Indicates whether the stream has finished destroying.
	  this.closed = false;

	  // True if close has been emitted or would have been emitted
	  // depending on emitClose.
	  this.closeEmitted = false;

	  // Crypto is kind of old and crusty.  Historically, its default string
	  // encoding is 'binary' so we have to make this configurable.
	  // Everything else in the universe uses 'utf8', though.
	  this.defaultEncoding = (options && options.defaultEncoding) || 'utf8';

	  // Ref the piped dest which we need a drain event on it
	  // type: null | Writable | Set<Writable>.
	  this.awaitDrainWriters = null;
	  this.multiAwaitDrain = false;

	  // If true, a maybeReadMore has been scheduled.
	  this.readingMore = false;
	  this.dataEmitted = false;
	  this.decoder = null;
	  this.encoding = null;
	  if (options && options.encoding) {
	    this.decoder = new StringDecoder(options.encoding);
	    this.encoding = options.encoding;
	  }
	}
	function Readable(options) {
	  if (!(this instanceof Readable)) return new Readable(options)

	  // Checking for a Stream.Duplex instance is faster here instead of inside
	  // the ReadableState constructor, at least with V8 6.5.
	  const isDuplex = this instanceof requireDuplex();
	  this._readableState = new ReadableState(options, this, isDuplex);
	  if (options) {
	    if (typeof options.read === 'function') this._read = options.read;
	    if (typeof options.destroy === 'function') this._destroy = options.destroy;
	    if (typeof options.construct === 'function') this._construct = options.construct;
	    if (options.signal && !isDuplex) addAbortSignal(options.signal, this);
	  }
	  Stream.call(this, options);
	  destroyImpl.construct(this, () => {
	    if (this._readableState.needReadable) {
	      maybeReadMore(this, this._readableState);
	    }
	  });
	}
	Readable.prototype.destroy = destroyImpl.destroy;
	Readable.prototype._undestroy = destroyImpl.undestroy;
	Readable.prototype._destroy = function (err, cb) {
	  cb(err);
	};
	Readable.prototype[EE.captureRejectionSymbol] = function (err) {
	  this.destroy(err);
	};

	// Manually shove something into the read() buffer.
	// This returns true if the highWaterMark has not been hit yet,
	// similar to how Writable.write() returns true if you should
	// write() some more.
	Readable.prototype.push = function (chunk, encoding) {
	  return readableAddChunk(this, chunk, encoding, false)
	};

	// Unshift should *always* be something directly out of read().
	Readable.prototype.unshift = function (chunk, encoding) {
	  return readableAddChunk(this, chunk, encoding, true)
	};
	function readableAddChunk(stream, chunk, encoding, addToFront) {
	  debug('readableAddChunk', chunk);
	  const state = stream._readableState;
	  let err;
	  if (!state.objectMode) {
	    if (typeof chunk === 'string') {
	      encoding = encoding || state.defaultEncoding;
	      if (state.encoding !== encoding) {
	        if (addToFront && state.encoding) {
	          // When unshifting, if state.encoding is set, we have to save
	          // the string in the BufferList with the state encoding.
	          chunk = Buffer.from(chunk, encoding).toString(state.encoding);
	        } else {
	          chunk = Buffer.from(chunk, encoding);
	          encoding = '';
	        }
	      }
	    } else if (chunk instanceof Buffer) {
	      encoding = '';
	    } else if (Stream._isUint8Array(chunk)) {
	      chunk = Stream._uint8ArrayToBuffer(chunk);
	      encoding = '';
	    } else if (chunk != null) {
	      err = new ERR_INVALID_ARG_TYPE('chunk', ['string', 'Buffer', 'Uint8Array'], chunk);
	    }
	  }
	  if (err) {
	    errorOrDestroy(stream, err);
	  } else if (chunk === null) {
	    state.reading = false;
	    onEofChunk(stream, state);
	  } else if (state.objectMode || (chunk && chunk.length > 0)) {
	    if (addToFront) {
	      if (state.endEmitted) errorOrDestroy(stream, new ERR_STREAM_UNSHIFT_AFTER_END_EVENT());
	      else if (state.destroyed || state.errored) return false
	      else addChunk(stream, state, chunk, true);
	    } else if (state.ended) {
	      errorOrDestroy(stream, new ERR_STREAM_PUSH_AFTER_EOF());
	    } else if (state.destroyed || state.errored) {
	      return false
	    } else {
	      state.reading = false;
	      if (state.decoder && !encoding) {
	        chunk = state.decoder.write(chunk);
	        if (state.objectMode || chunk.length !== 0) addChunk(stream, state, chunk, false);
	        else maybeReadMore(stream, state);
	      } else {
	        addChunk(stream, state, chunk, false);
	      }
	    }
	  } else if (!addToFront) {
	    state.reading = false;
	    maybeReadMore(stream, state);
	  }

	  // We can push more data if we are below the highWaterMark.
	  // Also, if we have no data yet, we can stand some more bytes.
	  // This is to work around cases where hwm=0, such as the repl.
	  return !state.ended && (state.length < state.highWaterMark || state.length === 0)
	}
	function addChunk(stream, state, chunk, addToFront) {
	  if (state.flowing && state.length === 0 && !state.sync && stream.listenerCount('data') > 0) {
	    // Use the guard to avoid creating `Set()` repeatedly
	    // when we have multiple pipes.
	    if (state.multiAwaitDrain) {
	      state.awaitDrainWriters.clear();
	    } else {
	      state.awaitDrainWriters = null;
	    }
	    state.dataEmitted = true;
	    stream.emit('data', chunk);
	  } else {
	    // Update the buffer info.
	    state.length += state.objectMode ? 1 : chunk.length;
	    if (addToFront) state.buffer.unshift(chunk);
	    else state.buffer.push(chunk);
	    if (state.needReadable) emitReadable(stream);
	  }
	  maybeReadMore(stream, state);
	}
	Readable.prototype.isPaused = function () {
	  const state = this._readableState;
	  return state[kPaused] === true || state.flowing === false
	};

	// Backwards compatibility.
	Readable.prototype.setEncoding = function (enc) {
	  const decoder = new StringDecoder(enc);
	  this._readableState.decoder = decoder;
	  // If setEncoding(null), decoder.encoding equals utf8.
	  this._readableState.encoding = this._readableState.decoder.encoding;
	  const buffer = this._readableState.buffer;
	  // Iterate over current buffer to convert already stored Buffers:
	  let content = '';
	  for (const data of buffer) {
	    content += decoder.write(data);
	  }
	  buffer.clear();
	  if (content !== '') buffer.push(content);
	  this._readableState.length = content.length;
	  return this
	};

	// Don't raise the hwm > 1GB.
	const MAX_HWM = 0x40000000;
	function computeNewHighWaterMark(n) {
	  if (n > MAX_HWM) {
	    throw new ERR_OUT_OF_RANGE('size', '<= 1GiB', n)
	  } else {
	    // Get the next highest power of 2 to prevent increasing hwm excessively in
	    // tiny amounts.
	    n--;
	    n |= n >>> 1;
	    n |= n >>> 2;
	    n |= n >>> 4;
	    n |= n >>> 8;
	    n |= n >>> 16;
	    n++;
	  }
	  return n
	}

	// This function is designed to be inlinable, so please take care when making
	// changes to the function body.
	function howMuchToRead(n, state) {
	  if (n <= 0 || (state.length === 0 && state.ended)) return 0
	  if (state.objectMode) return 1
	  if (NumberIsNaN(n)) {
	    // Only flow one buffer at a time.
	    if (state.flowing && state.length) return state.buffer.first().length
	    return state.length
	  }
	  if (n <= state.length) return n
	  return state.ended ? state.length : 0
	}

	// You can override either this method, or the async _read(n) below.
	Readable.prototype.read = function (n) {
	  debug('read', n);
	  // Same as parseInt(undefined, 10), however V8 7.3 performance regressed
	  // in this scenario, so we are doing it manually.
	  if (n === undefined) {
	    n = NaN;
	  } else if (!NumberIsInteger(n)) {
	    n = NumberParseInt(n, 10);
	  }
	  const state = this._readableState;
	  const nOrig = n;

	  // If we're asking for more than the current hwm, then raise the hwm.
	  if (n > state.highWaterMark) state.highWaterMark = computeNewHighWaterMark(n);
	  if (n !== 0) state.emittedReadable = false;

	  // If we're doing read(0) to trigger a readable event, but we
	  // already have a bunch of data in the buffer, then just trigger
	  // the 'readable' event and move on.
	  if (
	    n === 0 &&
	    state.needReadable &&
	    ((state.highWaterMark !== 0 ? state.length >= state.highWaterMark : state.length > 0) || state.ended)
	  ) {
	    debug('read: emitReadable', state.length, state.ended);
	    if (state.length === 0 && state.ended) endReadable(this);
	    else emitReadable(this);
	    return null
	  }
	  n = howMuchToRead(n, state);

	  // If we've ended, and we're now clear, then finish it up.
	  if (n === 0 && state.ended) {
	    if (state.length === 0) endReadable(this);
	    return null
	  }

	  // All the actual chunk generation logic needs to be
	  // *below* the call to _read.  The reason is that in certain
	  // synthetic stream cases, such as passthrough streams, _read
	  // may be a completely synchronous operation which may change
	  // the state of the read buffer, providing enough data when
	  // before there was *not* enough.
	  //
	  // So, the steps are:
	  // 1. Figure out what the state of things will be after we do
	  // a read from the buffer.
	  //
	  // 2. If that resulting state will trigger a _read, then call _read.
	  // Note that this may be asynchronous, or synchronous.  Yes, it is
	  // deeply ugly to write APIs this way, but that still doesn't mean
	  // that the Readable class should behave improperly, as streams are
	  // designed to be sync/async agnostic.
	  // Take note if the _read call is sync or async (ie, if the read call
	  // has returned yet), so that we know whether or not it's safe to emit
	  // 'readable' etc.
	  //
	  // 3. Actually pull the requested chunks out of the buffer and return.

	  // if we need a readable event, then we need to do some reading.
	  let doRead = state.needReadable;
	  debug('need readable', doRead);

	  // If we currently have less than the highWaterMark, then also read some.
	  if (state.length === 0 || state.length - n < state.highWaterMark) {
	    doRead = true;
	    debug('length less than watermark', doRead);
	  }

	  // However, if we've ended, then there's no point, if we're already
	  // reading, then it's unnecessary, if we're constructing we have to wait,
	  // and if we're destroyed or errored, then it's not allowed,
	  if (state.ended || state.reading || state.destroyed || state.errored || !state.constructed) {
	    doRead = false;
	    debug('reading, ended or constructing', doRead);
	  } else if (doRead) {
	    debug('do read');
	    state.reading = true;
	    state.sync = true;
	    // If the length is currently zero, then we *need* a readable event.
	    if (state.length === 0) state.needReadable = true;

	    // Call internal read method
	    try {
	      this._read(state.highWaterMark);
	    } catch (err) {
	      errorOrDestroy(this, err);
	    }
	    state.sync = false;
	    // If _read pushed data synchronously, then `reading` will be false,
	    // and we need to re-evaluate how much data we can return to the user.
	    if (!state.reading) n = howMuchToRead(nOrig, state);
	  }
	  let ret;
	  if (n > 0) ret = fromList(n, state);
	  else ret = null;
	  if (ret === null) {
	    state.needReadable = state.length <= state.highWaterMark;
	    n = 0;
	  } else {
	    state.length -= n;
	    if (state.multiAwaitDrain) {
	      state.awaitDrainWriters.clear();
	    } else {
	      state.awaitDrainWriters = null;
	    }
	  }
	  if (state.length === 0) {
	    // If we have nothing in the buffer, then we want to know
	    // as soon as we *do* get something into the buffer.
	    if (!state.ended) state.needReadable = true;

	    // If we tried to read() past the EOF, then emit end on the next tick.
	    if (nOrig !== n && state.ended) endReadable(this);
	  }
	  if (ret !== null && !state.errorEmitted && !state.closeEmitted) {
	    state.dataEmitted = true;
	    this.emit('data', ret);
	  }
	  return ret
	};
	function onEofChunk(stream, state) {
	  debug('onEofChunk');
	  if (state.ended) return
	  if (state.decoder) {
	    const chunk = state.decoder.end();
	    if (chunk && chunk.length) {
	      state.buffer.push(chunk);
	      state.length += state.objectMode ? 1 : chunk.length;
	    }
	  }
	  state.ended = true;
	  if (state.sync) {
	    // If we are sync, wait until next tick to emit the data.
	    // Otherwise we risk emitting data in the flow()
	    // the readable code triggers during a read() call.
	    emitReadable(stream);
	  } else {
	    // Emit 'readable' now to make sure it gets picked up.
	    state.needReadable = false;
	    state.emittedReadable = true;
	    // We have to emit readable now that we are EOF. Modules
	    // in the ecosystem (e.g. dicer) rely on this event being sync.
	    emitReadable_(stream);
	  }
	}

	// Don't emit readable right away in sync mode, because this can trigger
	// another read() call => stack overflow.  This way, it might trigger
	// a nextTick recursion warning, but that's not so bad.
	function emitReadable(stream) {
	  const state = stream._readableState;
	  debug('emitReadable', state.needReadable, state.emittedReadable);
	  state.needReadable = false;
	  if (!state.emittedReadable) {
	    debug('emitReadable', state.flowing);
	    state.emittedReadable = true;
	    process.nextTick(emitReadable_, stream);
	  }
	}
	function emitReadable_(stream) {
	  const state = stream._readableState;
	  debug('emitReadable_', state.destroyed, state.length, state.ended);
	  if (!state.destroyed && !state.errored && (state.length || state.ended)) {
	    stream.emit('readable');
	    state.emittedReadable = false;
	  }

	  // The stream needs another readable event if:
	  // 1. It is not flowing, as the flow mechanism will take
	  //    care of it.
	  // 2. It is not ended.
	  // 3. It is below the highWaterMark, so we can schedule
	  //    another readable later.
	  state.needReadable = !state.flowing && !state.ended && state.length <= state.highWaterMark;
	  flow(stream);
	}

	// At this point, the user has presumably seen the 'readable' event,
	// and called read() to consume some data.  that may have triggered
	// in turn another _read(n) call, in which case reading = true if
	// it's in progress.
	// However, if we're not ended, or reading, and the length < hwm,
	// then go ahead and try to read some more preemptively.
	function maybeReadMore(stream, state) {
	  if (!state.readingMore && state.constructed) {
	    state.readingMore = true;
	    process.nextTick(maybeReadMore_, stream, state);
	  }
	}
	function maybeReadMore_(stream, state) {
	  // Attempt to read more data if we should.
	  //
	  // The conditions for reading more data are (one of):
	  // - Not enough data buffered (state.length < state.highWaterMark). The loop
	  //   is responsible for filling the buffer with enough data if such data
	  //   is available. If highWaterMark is 0 and we are not in the flowing mode
	  //   we should _not_ attempt to buffer any extra data. We'll get more data
	  //   when the stream consumer calls read() instead.
	  // - No data in the buffer, and the stream is in flowing mode. In this mode
	  //   the loop below is responsible for ensuring read() is called. Failing to
	  //   call read here would abort the flow and there's no other mechanism for
	  //   continuing the flow if the stream consumer has just subscribed to the
	  //   'data' event.
	  //
	  // In addition to the above conditions to keep reading data, the following
	  // conditions prevent the data from being read:
	  // - The stream has ended (state.ended).
	  // - There is already a pending 'read' operation (state.reading). This is a
	  //   case where the stream has called the implementation defined _read()
	  //   method, but they are processing the call asynchronously and have _not_
	  //   called push() with new data. In this case we skip performing more
	  //   read()s. The execution ends in this method again after the _read() ends
	  //   up calling push() with more data.
	  while (
	    !state.reading &&
	    !state.ended &&
	    (state.length < state.highWaterMark || (state.flowing && state.length === 0))
	  ) {
	    const len = state.length;
	    debug('maybeReadMore read 0');
	    stream.read(0);
	    if (len === state.length)
	      // Didn't get any data, stop spinning.
	      break
	  }
	  state.readingMore = false;
	}

	// Abstract method.  to be overridden in specific implementation classes.
	// call cb(er, data) where data is <= n in length.
	// for virtual (non-string, non-buffer) streams, "length" is somewhat
	// arbitrary, and perhaps not very meaningful.
	Readable.prototype._read = function (n) {
	  throw new ERR_METHOD_NOT_IMPLEMENTED('_read()')
	};
	Readable.prototype.pipe = function (dest, pipeOpts) {
	  const src = this;
	  const state = this._readableState;
	  if (state.pipes.length === 1) {
	    if (!state.multiAwaitDrain) {
	      state.multiAwaitDrain = true;
	      state.awaitDrainWriters = new SafeSet(state.awaitDrainWriters ? [state.awaitDrainWriters] : []);
	    }
	  }
	  state.pipes.push(dest);
	  debug('pipe count=%d opts=%j', state.pipes.length, pipeOpts);
	  const doEnd = (!pipeOpts || pipeOpts.end !== false) && dest !== process.stdout && dest !== process.stderr;
	  const endFn = doEnd ? onend : unpipe;
	  if (state.endEmitted) process.nextTick(endFn);
	  else src.once('end', endFn);
	  dest.on('unpipe', onunpipe);
	  function onunpipe(readable, unpipeInfo) {
	    debug('onunpipe');
	    if (readable === src) {
	      if (unpipeInfo && unpipeInfo.hasUnpiped === false) {
	        unpipeInfo.hasUnpiped = true;
	        cleanup();
	      }
	    }
	  }
	  function onend() {
	    debug('onend');
	    dest.end();
	  }
	  let ondrain;
	  let cleanedUp = false;
	  function cleanup() {
	    debug('cleanup');
	    // Cleanup event handlers once the pipe is broken.
	    dest.removeListener('close', onclose);
	    dest.removeListener('finish', onfinish);
	    if (ondrain) {
	      dest.removeListener('drain', ondrain);
	    }
	    dest.removeListener('error', onerror);
	    dest.removeListener('unpipe', onunpipe);
	    src.removeListener('end', onend);
	    src.removeListener('end', unpipe);
	    src.removeListener('data', ondata);
	    cleanedUp = true;

	    // If the reader is waiting for a drain event from this
	    // specific writer, then it would cause it to never start
	    // flowing again.
	    // So, if this is awaiting a drain, then we just call it now.
	    // If we don't know, then assume that we are waiting for one.
	    if (ondrain && state.awaitDrainWriters && (!dest._writableState || dest._writableState.needDrain)) ondrain();
	  }
	  function pause() {
	    // If the user unpiped during `dest.write()`, it is possible
	    // to get stuck in a permanently paused state if that write
	    // also returned false.
	    // => Check whether `dest` is still a piping destination.
	    if (!cleanedUp) {
	      if (state.pipes.length === 1 && state.pipes[0] === dest) {
	        debug('false write response, pause', 0);
	        state.awaitDrainWriters = dest;
	        state.multiAwaitDrain = false;
	      } else if (state.pipes.length > 1 && state.pipes.includes(dest)) {
	        debug('false write response, pause', state.awaitDrainWriters.size);
	        state.awaitDrainWriters.add(dest);
	      }
	      src.pause();
	    }
	    if (!ondrain) {
	      // When the dest drains, it reduces the awaitDrain counter
	      // on the source.  This would be more elegant with a .once()
	      // handler in flow(), but adding and removing repeatedly is
	      // too slow.
	      ondrain = pipeOnDrain(src, dest);
	      dest.on('drain', ondrain);
	    }
	  }
	  src.on('data', ondata);
	  function ondata(chunk) {
	    debug('ondata');
	    const ret = dest.write(chunk);
	    debug('dest.write', ret);
	    if (ret === false) {
	      pause();
	    }
	  }

	  // If the dest has an error, then stop piping into it.
	  // However, don't suppress the throwing behavior for this.
	  function onerror(er) {
	    debug('onerror', er);
	    unpipe();
	    dest.removeListener('error', onerror);
	    if (dest.listenerCount('error') === 0) {
	      const s = dest._writableState || dest._readableState;
	      if (s && !s.errorEmitted) {
	        // User incorrectly emitted 'error' directly on the stream.
	        errorOrDestroy(dest, er);
	      } else {
	        dest.emit('error', er);
	      }
	    }
	  }

	  // Make sure our error handler is attached before userland ones.
	  prependListener(dest, 'error', onerror);

	  // Both close and finish should trigger unpipe, but only once.
	  function onclose() {
	    dest.removeListener('finish', onfinish);
	    unpipe();
	  }
	  dest.once('close', onclose);
	  function onfinish() {
	    debug('onfinish');
	    dest.removeListener('close', onclose);
	    unpipe();
	  }
	  dest.once('finish', onfinish);
	  function unpipe() {
	    debug('unpipe');
	    src.unpipe(dest);
	  }

	  // Tell the dest that it's being piped to.
	  dest.emit('pipe', src);

	  // Start the flow if it hasn't been started already.

	  if (dest.writableNeedDrain === true) {
	    if (state.flowing) {
	      pause();
	    }
	  } else if (!state.flowing) {
	    debug('pipe resume');
	    src.resume();
	  }
	  return dest
	};
	function pipeOnDrain(src, dest) {
	  return function pipeOnDrainFunctionResult() {
	    const state = src._readableState;

	    // `ondrain` will call directly,
	    // `this` maybe not a reference to dest,
	    // so we use the real dest here.
	    if (state.awaitDrainWriters === dest) {
	      debug('pipeOnDrain', 1);
	      state.awaitDrainWriters = null;
	    } else if (state.multiAwaitDrain) {
	      debug('pipeOnDrain', state.awaitDrainWriters.size);
	      state.awaitDrainWriters.delete(dest);
	    }
	    if ((!state.awaitDrainWriters || state.awaitDrainWriters.size === 0) && src.listenerCount('data')) {
	      src.resume();
	    }
	  }
	}
	Readable.prototype.unpipe = function (dest) {
	  const state = this._readableState;
	  const unpipeInfo = {
	    hasUnpiped: false
	  };

	  // If we're not piping anywhere, then do nothing.
	  if (state.pipes.length === 0) return this
	  if (!dest) {
	    // remove all.
	    const dests = state.pipes;
	    state.pipes = [];
	    this.pause();
	    for (let i = 0; i < dests.length; i++)
	      dests[i].emit('unpipe', this, {
	        hasUnpiped: false
	      });
	    return this
	  }

	  // Try to find the right one.
	  const index = ArrayPrototypeIndexOf(state.pipes, dest);
	  if (index === -1) return this
	  state.pipes.splice(index, 1);
	  if (state.pipes.length === 0) this.pause();
	  dest.emit('unpipe', this, unpipeInfo);
	  return this
	};

	// Set up data events if they are asked for
	// Ensure readable listeners eventually get something.
	Readable.prototype.on = function (ev, fn) {
	  const res = Stream.prototype.on.call(this, ev, fn);
	  const state = this._readableState;
	  if (ev === 'data') {
	    // Update readableListening so that resume() may be a no-op
	    // a few lines down. This is needed to support once('readable').
	    state.readableListening = this.listenerCount('readable') > 0;

	    // Try start flowing on next tick if stream isn't explicitly paused.
	    if (state.flowing !== false) this.resume();
	  } else if (ev === 'readable') {
	    if (!state.endEmitted && !state.readableListening) {
	      state.readableListening = state.needReadable = true;
	      state.flowing = false;
	      state.emittedReadable = false;
	      debug('on readable', state.length, state.reading);
	      if (state.length) {
	        emitReadable(this);
	      } else if (!state.reading) {
	        process.nextTick(nReadingNextTick, this);
	      }
	    }
	  }
	  return res
	};
	Readable.prototype.addListener = Readable.prototype.on;
	Readable.prototype.removeListener = function (ev, fn) {
	  const res = Stream.prototype.removeListener.call(this, ev, fn);
	  if (ev === 'readable') {
	    // We need to check if there is someone still listening to
	    // readable and reset the state. However this needs to happen
	    // after readable has been emitted but before I/O (nextTick) to
	    // support once('readable', fn) cycles. This means that calling
	    // resume within the same tick will have no
	    // effect.
	    process.nextTick(updateReadableListening, this);
	  }
	  return res
	};
	Readable.prototype.off = Readable.prototype.removeListener;
	Readable.prototype.removeAllListeners = function (ev) {
	  const res = Stream.prototype.removeAllListeners.apply(this, arguments);
	  if (ev === 'readable' || ev === undefined) {
	    // We need to check if there is someone still listening to
	    // readable and reset the state. However this needs to happen
	    // after readable has been emitted but before I/O (nextTick) to
	    // support once('readable', fn) cycles. This means that calling
	    // resume within the same tick will have no
	    // effect.
	    process.nextTick(updateReadableListening, this);
	  }
	  return res
	};
	function updateReadableListening(self) {
	  const state = self._readableState;
	  state.readableListening = self.listenerCount('readable') > 0;
	  if (state.resumeScheduled && state[kPaused] === false) {
	    // Flowing needs to be set to true now, otherwise
	    // the upcoming resume will not flow.
	    state.flowing = true;

	    // Crude way to check if we should resume.
	  } else if (self.listenerCount('data') > 0) {
	    self.resume();
	  } else if (!state.readableListening) {
	    state.flowing = null;
	  }
	}
	function nReadingNextTick(self) {
	  debug('readable nexttick read 0');
	  self.read(0);
	}

	// pause() and resume() are remnants of the legacy readable stream API
	// If the user uses them, then switch into old mode.
	Readable.prototype.resume = function () {
	  const state = this._readableState;
	  if (!state.flowing) {
	    debug('resume');
	    // We flow only if there is no one listening
	    // for readable, but we still have to call
	    // resume().
	    state.flowing = !state.readableListening;
	    resume(this, state);
	  }
	  state[kPaused] = false;
	  return this
	};
	function resume(stream, state) {
	  if (!state.resumeScheduled) {
	    state.resumeScheduled = true;
	    process.nextTick(resume_, stream, state);
	  }
	}
	function resume_(stream, state) {
	  debug('resume', state.reading);
	  if (!state.reading) {
	    stream.read(0);
	  }
	  state.resumeScheduled = false;
	  stream.emit('resume');
	  flow(stream);
	  if (state.flowing && !state.reading) stream.read(0);
	}
	Readable.prototype.pause = function () {
	  debug('call pause flowing=%j', this._readableState.flowing);
	  if (this._readableState.flowing !== false) {
	    debug('pause');
	    this._readableState.flowing = false;
	    this.emit('pause');
	  }
	  this._readableState[kPaused] = true;
	  return this
	};
	function flow(stream) {
	  const state = stream._readableState;
	  debug('flow', state.flowing);
	  while (state.flowing && stream.read() !== null);
	}

	// Wrap an old-style stream as the async data source.
	// This is *not* part of the readable stream interface.
	// It is an ugly unfortunate mess of history.
	Readable.prototype.wrap = function (stream) {
	  let paused = false;

	  // TODO (ronag): Should this.destroy(err) emit
	  // 'error' on the wrapped stream? Would require
	  // a static factory method, e.g. Readable.wrap(stream).

	  stream.on('data', (chunk) => {
	    if (!this.push(chunk) && stream.pause) {
	      paused = true;
	      stream.pause();
	    }
	  });
	  stream.on('end', () => {
	    this.push(null);
	  });
	  stream.on('error', (err) => {
	    errorOrDestroy(this, err);
	  });
	  stream.on('close', () => {
	    this.destroy();
	  });
	  stream.on('destroy', () => {
	    this.destroy();
	  });
	  this._read = () => {
	    if (paused && stream.resume) {
	      paused = false;
	      stream.resume();
	    }
	  };

	  // Proxy all the other methods. Important when wrapping filters and duplexes.
	  const streamKeys = ObjectKeys(stream);
	  for (let j = 1; j < streamKeys.length; j++) {
	    const i = streamKeys[j];
	    if (this[i] === undefined && typeof stream[i] === 'function') {
	      this[i] = stream[i].bind(stream);
	    }
	  }
	  return this
	};
	Readable.prototype[SymbolAsyncIterator] = function () {
	  return streamToAsyncIterator(this)
	};
	Readable.prototype.iterator = function (options) {
	  if (options !== undefined) {
	    validateObject(options, 'options');
	  }
	  return streamToAsyncIterator(this, options)
	};
	function streamToAsyncIterator(stream, options) {
	  if (typeof stream.read !== 'function') {
	    stream = Readable.wrap(stream, {
	      objectMode: true
	    });
	  }
	  const iter = createAsyncIterator(stream, options);
	  iter.stream = stream;
	  return iter
	}
	async function* createAsyncIterator(stream, options) {
	  let callback = nop;
	  function next(resolve) {
	    if (this === stream) {
	      callback();
	      callback = nop;
	    } else {
	      callback = resolve;
	    }
	  }
	  stream.on('readable', next);
	  let error;
	  const cleanup = eos(
	    stream,
	    {
	      writable: false
	    },
	    (err) => {
	      error = err ? aggregateTwoErrors(error, err) : null;
	      callback();
	      callback = nop;
	    }
	  );
	  try {
	    while (true) {
	      const chunk = stream.destroyed ? null : stream.read();
	      if (chunk !== null) {
	        yield chunk;
	      } else if (error) {
	        throw error
	      } else if (error === null) {
	        return
	      } else {
	        await new Promise(next);
	      }
	    }
	  } catch (err) {
	    error = aggregateTwoErrors(error, err);
	    throw error
	  } finally {
	    if (
	      (error || (options === null || options === undefined ? undefined : options.destroyOnReturn) !== false) &&
	      (error === undefined || stream._readableState.autoDestroy)
	    ) {
	      destroyImpl.destroyer(stream, null);
	    } else {
	      stream.off('readable', next);
	      cleanup();
	    }
	  }
	}

	// Making it explicit these properties are not enumerable
	// because otherwise some prototype manipulation in
	// userland will fail.
	ObjectDefineProperties(Readable.prototype, {
	  readable: {
	    __proto__: null,
	    get() {
	      const r = this._readableState;
	      // r.readable === false means that this is part of a Duplex stream
	      // where the readable side was disabled upon construction.
	      // Compat. The user might manually disable readable side through
	      // deprecated setter.
	      return !!r && r.readable !== false && !r.destroyed && !r.errorEmitted && !r.endEmitted
	    },
	    set(val) {
	      // Backwards compat.
	      if (this._readableState) {
	        this._readableState.readable = !!val;
	      }
	    }
	  },
	  readableDidRead: {
	    __proto__: null,
	    enumerable: false,
	    get: function () {
	      return this._readableState.dataEmitted
	    }
	  },
	  readableAborted: {
	    __proto__: null,
	    enumerable: false,
	    get: function () {
	      return !!(
	        this._readableState.readable !== false &&
	        (this._readableState.destroyed || this._readableState.errored) &&
	        !this._readableState.endEmitted
	      )
	    }
	  },
	  readableHighWaterMark: {
	    __proto__: null,
	    enumerable: false,
	    get: function () {
	      return this._readableState.highWaterMark
	    }
	  },
	  readableBuffer: {
	    __proto__: null,
	    enumerable: false,
	    get: function () {
	      return this._readableState && this._readableState.buffer
	    }
	  },
	  readableFlowing: {
	    __proto__: null,
	    enumerable: false,
	    get: function () {
	      return this._readableState.flowing
	    },
	    set: function (state) {
	      if (this._readableState) {
	        this._readableState.flowing = state;
	      }
	    }
	  },
	  readableLength: {
	    __proto__: null,
	    enumerable: false,
	    get() {
	      return this._readableState.length
	    }
	  },
	  readableObjectMode: {
	    __proto__: null,
	    enumerable: false,
	    get() {
	      return this._readableState ? this._readableState.objectMode : false
	    }
	  },
	  readableEncoding: {
	    __proto__: null,
	    enumerable: false,
	    get() {
	      return this._readableState ? this._readableState.encoding : null
	    }
	  },
	  errored: {
	    __proto__: null,
	    enumerable: false,
	    get() {
	      return this._readableState ? this._readableState.errored : null
	    }
	  },
	  closed: {
	    __proto__: null,
	    get() {
	      return this._readableState ? this._readableState.closed : false
	    }
	  },
	  destroyed: {
	    __proto__: null,
	    enumerable: false,
	    get() {
	      return this._readableState ? this._readableState.destroyed : false
	    },
	    set(value) {
	      // We ignore the value if the stream
	      // has not been initialized yet.
	      if (!this._readableState) {
	        return
	      }

	      // Backward compatibility, the user is explicitly
	      // managing destroyed.
	      this._readableState.destroyed = value;
	    }
	  },
	  readableEnded: {
	    __proto__: null,
	    enumerable: false,
	    get() {
	      return this._readableState ? this._readableState.endEmitted : false
	    }
	  }
	});
	ObjectDefineProperties(ReadableState.prototype, {
	  // Legacy getter for `pipesCount`.
	  pipesCount: {
	    __proto__: null,
	    get() {
	      return this.pipes.length
	    }
	  },
	  // Legacy property for `paused`.
	  paused: {
	    __proto__: null,
	    get() {
	      return this[kPaused] !== false
	    },
	    set(value) {
	      this[kPaused] = !!value;
	    }
	  }
	});

	// Exposed for testing purposes only.
	Readable._fromList = fromList;

	// Pluck off n bytes from an array of buffers.
	// Length is the combined lengths of all the buffers in the list.
	// This function is designed to be inlinable, so please take care when making
	// changes to the function body.
	function fromList(n, state) {
	  // nothing buffered.
	  if (state.length === 0) return null
	  let ret;
	  if (state.objectMode) ret = state.buffer.shift();
	  else if (!n || n >= state.length) {
	    // Read it all, truncate the list.
	    if (state.decoder) ret = state.buffer.join('');
	    else if (state.buffer.length === 1) ret = state.buffer.first();
	    else ret = state.buffer.concat(state.length);
	    state.buffer.clear();
	  } else {
	    // read part of list.
	    ret = state.buffer.consume(n, state.decoder);
	  }
	  return ret
	}
	function endReadable(stream) {
	  const state = stream._readableState;
	  debug('endReadable', state.endEmitted);
	  if (!state.endEmitted) {
	    state.ended = true;
	    process.nextTick(endReadableNT, state, stream);
	  }
	}
	function endReadableNT(state, stream) {
	  debug('endReadableNT', state.endEmitted, state.length);

	  // Check that we didn't get one last unshift.
	  if (!state.errored && !state.closeEmitted && !state.endEmitted && state.length === 0) {
	    state.endEmitted = true;
	    stream.emit('end');
	    if (stream.writable && stream.allowHalfOpen === false) {
	      process.nextTick(endWritableNT, stream);
	    } else if (state.autoDestroy) {
	      // In case of duplex streams we need a way to detect
	      // if the writable side is ready for autoDestroy as well.
	      const wState = stream._writableState;
	      const autoDestroy =
	        !wState ||
	        (wState.autoDestroy &&
	          // We don't expect the writable to ever 'finish'
	          // if writable is explicitly set to false.
	          (wState.finished || wState.writable === false));
	      if (autoDestroy) {
	        stream.destroy();
	      }
	    }
	  }
	}
	function endWritableNT(stream) {
	  const writable = stream.writable && !stream.writableEnded && !stream.destroyed;
	  if (writable) {
	    stream.end();
	  }
	}
	Readable.from = function (iterable, opts) {
	  return from(Readable, iterable, opts)
	};
	let webStreamsAdapters;

	// Lazy to avoid circular references
	function lazyWebStreams() {
	  if (webStreamsAdapters === undefined) webStreamsAdapters = {};
	  return webStreamsAdapters
	}
	Readable.fromWeb = function (readableStream, options) {
	  return lazyWebStreams().newStreamReadableFromReadableStream(readableStream, options)
	};
	Readable.toWeb = function (streamReadable, options) {
	  return lazyWebStreams().newReadableStreamFromStreamReadable(streamReadable, options)
	};
	Readable.wrap = function (src, options) {
	  var _ref, _src$readableObjectMo;
	  return new Readable({
	    objectMode:
	      (_ref =
	        (_src$readableObjectMo = src.readableObjectMode) !== null && _src$readableObjectMo !== undefined
	          ? _src$readableObjectMo
	          : src.objectMode) !== null && _ref !== undefined
	        ? _ref
	        : true,
	    ...options,
	    destroy(err, callback) {
	      destroyImpl.destroyer(src, err);
	      callback(err);
	    }
	  }).wrap(src)
	};
	return readable;
}

/* replacement start */

var writable;
var hasRequiredWritable;

function requireWritable () {
	if (hasRequiredWritable) return writable;
	hasRequiredWritable = 1;
	const process = requireProcess()

	/* replacement end */
	// Copyright Joyent, Inc. and other Node contributors.
	//
	// Permission is hereby granted, free of charge, to any person obtaining a
	// copy of this software and associated documentation files (the
	// "Software"), to deal in the Software without restriction, including
	// without limitation the rights to use, copy, modify, merge, publish,
	// distribute, sublicense, and/or sell copies of the Software, and to permit
	// persons to whom the Software is furnished to do so, subject to the
	// following conditions:
	//
	// The above copyright notice and this permission notice shall be included
	// in all copies or substantial portions of the Software.
	//
	// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
	// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
	// USE OR OTHER DEALINGS IN THE SOFTWARE.

	// A bit simpler than readable streams.
	// Implement an async ._write(chunk, encoding, cb), and it'll handle all
	// the drain event emission and buffering.

	;	const {
	  ArrayPrototypeSlice,
	  Error,
	  FunctionPrototypeSymbolHasInstance,
	  ObjectDefineProperty,
	  ObjectDefineProperties,
	  ObjectSetPrototypeOf,
	  StringPrototypeToLowerCase,
	  Symbol,
	  SymbolHasInstance
	} = requirePrimordials();
	writable = Writable;
	Writable.WritableState = WritableState;
	const { EventEmitter: EE } = require$$2;
	const Stream = requireLegacy().Stream;
	const { Buffer } = require$$0;
	const destroyImpl = requireDestroy();
	const { addAbortSignal } = requireAddAbortSignal();
	const { getHighWaterMark, getDefaultHighWaterMark } = requireState();
	const {
	  ERR_INVALID_ARG_TYPE,
	  ERR_METHOD_NOT_IMPLEMENTED,
	  ERR_MULTIPLE_CALLBACK,
	  ERR_STREAM_CANNOT_PIPE,
	  ERR_STREAM_DESTROYED,
	  ERR_STREAM_ALREADY_FINISHED,
	  ERR_STREAM_NULL_VALUES,
	  ERR_STREAM_WRITE_AFTER_END,
	  ERR_UNKNOWN_ENCODING
	} = requireErrors().codes;
	const { errorOrDestroy } = destroyImpl;
	ObjectSetPrototypeOf(Writable.prototype, Stream.prototype);
	ObjectSetPrototypeOf(Writable, Stream);
	function nop() {}
	const kOnFinished = Symbol('kOnFinished');
	function WritableState(options, stream, isDuplex) {
	  // Duplex streams are both readable and writable, but share
	  // the same options object.
	  // However, some cases require setting options to different
	  // values for the readable and the writable sides of the duplex stream,
	  // e.g. options.readableObjectMode vs. options.writableObjectMode, etc.
	  if (typeof isDuplex !== 'boolean') isDuplex = stream instanceof requireDuplex();

	  // Object stream flag to indicate whether or not this stream
	  // contains buffers or objects.
	  this.objectMode = !!(options && options.objectMode);
	  if (isDuplex) this.objectMode = this.objectMode || !!(options && options.writableObjectMode);

	  // The point at which write() starts returning false
	  // Note: 0 is a valid value, means that we always return false if
	  // the entire buffer is not flushed immediately on write().
	  this.highWaterMark = options
	    ? getHighWaterMark(this, options, 'writableHighWaterMark', isDuplex)
	    : getDefaultHighWaterMark(false);

	  // if _final has been called.
	  this.finalCalled = false;

	  // drain event flag.
	  this.needDrain = false;
	  // At the start of calling end()
	  this.ending = false;
	  // When end() has been called, and returned.
	  this.ended = false;
	  // When 'finish' is emitted.
	  this.finished = false;

	  // Has it been destroyed
	  this.destroyed = false;

	  // Should we decode strings into buffers before passing to _write?
	  // this is here so that some node-core streams can optimize string
	  // handling at a lower level.
	  const noDecode = !!(options && options.decodeStrings === false);
	  this.decodeStrings = !noDecode;

	  // Crypto is kind of old and crusty.  Historically, its default string
	  // encoding is 'binary' so we have to make this configurable.
	  // Everything else in the universe uses 'utf8', though.
	  this.defaultEncoding = (options && options.defaultEncoding) || 'utf8';

	  // Not an actual buffer we keep track of, but a measurement
	  // of how much we're waiting to get pushed to some underlying
	  // socket or file.
	  this.length = 0;

	  // A flag to see when we're in the middle of a write.
	  this.writing = false;

	  // When true all writes will be buffered until .uncork() call.
	  this.corked = 0;

	  // A flag to be able to tell if the onwrite cb is called immediately,
	  // or on a later tick.  We set this to true at first, because any
	  // actions that shouldn't happen until "later" should generally also
	  // not happen before the first write call.
	  this.sync = true;

	  // A flag to know if we're processing previously buffered items, which
	  // may call the _write() callback in the same tick, so that we don't
	  // end up in an overlapped onwrite situation.
	  this.bufferProcessing = false;

	  // The callback that's passed to _write(chunk, cb).
	  this.onwrite = onwrite.bind(undefined, stream);

	  // The callback that the user supplies to write(chunk, encoding, cb).
	  this.writecb = null;

	  // The amount that is being written when _write is called.
	  this.writelen = 0;

	  // Storage for data passed to the afterWrite() callback in case of
	  // synchronous _write() completion.
	  this.afterWriteTickInfo = null;
	  resetBuffer(this);

	  // Number of pending user-supplied write callbacks
	  // this must be 0 before 'finish' can be emitted.
	  this.pendingcb = 0;

	  // Stream is still being constructed and cannot be
	  // destroyed until construction finished or failed.
	  // Async construction is opt in, therefore we start as
	  // constructed.
	  this.constructed = true;

	  // Emit prefinish if the only thing we're waiting for is _write cbs
	  // This is relevant for synchronous Transform streams.
	  this.prefinished = false;

	  // True if the error was already emitted and should not be thrown again.
	  this.errorEmitted = false;

	  // Should close be emitted on destroy. Defaults to true.
	  this.emitClose = !options || options.emitClose !== false;

	  // Should .destroy() be called after 'finish' (and potentially 'end').
	  this.autoDestroy = !options || options.autoDestroy !== false;

	  // Indicates whether the stream has errored. When true all write() calls
	  // should return false. This is needed since when autoDestroy
	  // is disabled we need a way to tell whether the stream has failed.
	  this.errored = null;

	  // Indicates whether the stream has finished destroying.
	  this.closed = false;

	  // True if close has been emitted or would have been emitted
	  // depending on emitClose.
	  this.closeEmitted = false;
	  this[kOnFinished] = [];
	}
	function resetBuffer(state) {
	  state.buffered = [];
	  state.bufferedIndex = 0;
	  state.allBuffers = true;
	  state.allNoop = true;
	}
	WritableState.prototype.getBuffer = function getBuffer() {
	  return ArrayPrototypeSlice(this.buffered, this.bufferedIndex)
	};
	ObjectDefineProperty(WritableState.prototype, 'bufferedRequestCount', {
	  __proto__: null,
	  get() {
	    return this.buffered.length - this.bufferedIndex
	  }
	});
	function Writable(options) {
	  // Writable ctor is applied to Duplexes, too.
	  // `realHasInstance` is necessary because using plain `instanceof`
	  // would return false, as no `_writableState` property is attached.

	  // Trying to use the custom `instanceof` for Writable here will also break the
	  // Node.js LazyTransform implementation, which has a non-trivial getter for
	  // `_writableState` that would lead to infinite recursion.

	  // Checking for a Stream.Duplex instance is faster here instead of inside
	  // the WritableState constructor, at least with V8 6.5.
	  const isDuplex = this instanceof requireDuplex();
	  if (!isDuplex && !FunctionPrototypeSymbolHasInstance(Writable, this)) return new Writable(options)
	  this._writableState = new WritableState(options, this, isDuplex);
	  if (options) {
	    if (typeof options.write === 'function') this._write = options.write;
	    if (typeof options.writev === 'function') this._writev = options.writev;
	    if (typeof options.destroy === 'function') this._destroy = options.destroy;
	    if (typeof options.final === 'function') this._final = options.final;
	    if (typeof options.construct === 'function') this._construct = options.construct;
	    if (options.signal) addAbortSignal(options.signal, this);
	  }
	  Stream.call(this, options);
	  destroyImpl.construct(this, () => {
	    const state = this._writableState;
	    if (!state.writing) {
	      clearBuffer(this, state);
	    }
	    finishMaybe(this, state);
	  });
	}
	ObjectDefineProperty(Writable, SymbolHasInstance, {
	  __proto__: null,
	  value: function (object) {
	    if (FunctionPrototypeSymbolHasInstance(this, object)) return true
	    if (this !== Writable) return false
	    return object && object._writableState instanceof WritableState
	  }
	});

	// Otherwise people can pipe Writable streams, which is just wrong.
	Writable.prototype.pipe = function () {
	  errorOrDestroy(this, new ERR_STREAM_CANNOT_PIPE());
	};
	function _write(stream, chunk, encoding, cb) {
	  const state = stream._writableState;
	  if (typeof encoding === 'function') {
	    cb = encoding;
	    encoding = state.defaultEncoding;
	  } else {
	    if (!encoding) encoding = state.defaultEncoding;
	    else if (encoding !== 'buffer' && !Buffer.isEncoding(encoding)) throw new ERR_UNKNOWN_ENCODING(encoding)
	    if (typeof cb !== 'function') cb = nop;
	  }
	  if (chunk === null) {
	    throw new ERR_STREAM_NULL_VALUES()
	  } else if (!state.objectMode) {
	    if (typeof chunk === 'string') {
	      if (state.decodeStrings !== false) {
	        chunk = Buffer.from(chunk, encoding);
	        encoding = 'buffer';
	      }
	    } else if (chunk instanceof Buffer) {
	      encoding = 'buffer';
	    } else if (Stream._isUint8Array(chunk)) {
	      chunk = Stream._uint8ArrayToBuffer(chunk);
	      encoding = 'buffer';
	    } else {
	      throw new ERR_INVALID_ARG_TYPE('chunk', ['string', 'Buffer', 'Uint8Array'], chunk)
	    }
	  }
	  let err;
	  if (state.ending) {
	    err = new ERR_STREAM_WRITE_AFTER_END();
	  } else if (state.destroyed) {
	    err = new ERR_STREAM_DESTROYED('write');
	  }
	  if (err) {
	    process.nextTick(cb, err);
	    errorOrDestroy(stream, err, true);
	    return err
	  }
	  state.pendingcb++;
	  return writeOrBuffer(stream, state, chunk, encoding, cb)
	}
	Writable.prototype.write = function (chunk, encoding, cb) {
	  return _write(this, chunk, encoding, cb) === true
	};
	Writable.prototype.cork = function () {
	  this._writableState.corked++;
	};
	Writable.prototype.uncork = function () {
	  const state = this._writableState;
	  if (state.corked) {
	    state.corked--;
	    if (!state.writing) clearBuffer(this, state);
	  }
	};
	Writable.prototype.setDefaultEncoding = function setDefaultEncoding(encoding) {
	  // node::ParseEncoding() requires lower case.
	  if (typeof encoding === 'string') encoding = StringPrototypeToLowerCase(encoding);
	  if (!Buffer.isEncoding(encoding)) throw new ERR_UNKNOWN_ENCODING(encoding)
	  this._writableState.defaultEncoding = encoding;
	  return this
	};

	// If we're already writing something, then just put this
	// in the queue, and wait our turn.  Otherwise, call _write
	// If we return false, then we need a drain event, so set that flag.
	function writeOrBuffer(stream, state, chunk, encoding, callback) {
	  const len = state.objectMode ? 1 : chunk.length;
	  state.length += len;

	  // stream._write resets state.length
	  const ret = state.length < state.highWaterMark;
	  // We must ensure that previous needDrain will not be reset to false.
	  if (!ret) state.needDrain = true;
	  if (state.writing || state.corked || state.errored || !state.constructed) {
	    state.buffered.push({
	      chunk,
	      encoding,
	      callback
	    });
	    if (state.allBuffers && encoding !== 'buffer') {
	      state.allBuffers = false;
	    }
	    if (state.allNoop && callback !== nop) {
	      state.allNoop = false;
	    }
	  } else {
	    state.writelen = len;
	    state.writecb = callback;
	    state.writing = true;
	    state.sync = true;
	    stream._write(chunk, encoding, state.onwrite);
	    state.sync = false;
	  }

	  // Return false if errored or destroyed in order to break
	  // any synchronous while(stream.write(data)) loops.
	  return ret && !state.errored && !state.destroyed
	}
	function doWrite(stream, state, writev, len, chunk, encoding, cb) {
	  state.writelen = len;
	  state.writecb = cb;
	  state.writing = true;
	  state.sync = true;
	  if (state.destroyed) state.onwrite(new ERR_STREAM_DESTROYED('write'));
	  else if (writev) stream._writev(chunk, state.onwrite);
	  else stream._write(chunk, encoding, state.onwrite);
	  state.sync = false;
	}
	function onwriteError(stream, state, er, cb) {
	  --state.pendingcb;
	  cb(er);
	  // Ensure callbacks are invoked even when autoDestroy is
	  // not enabled. Passing `er` here doesn't make sense since
	  // it's related to one specific write, not to the buffered
	  // writes.
	  errorBuffer(state);
	  // This can emit error, but error must always follow cb.
	  errorOrDestroy(stream, er);
	}
	function onwrite(stream, er) {
	  const state = stream._writableState;
	  const sync = state.sync;
	  const cb = state.writecb;
	  if (typeof cb !== 'function') {
	    errorOrDestroy(stream, new ERR_MULTIPLE_CALLBACK());
	    return
	  }
	  state.writing = false;
	  state.writecb = null;
	  state.length -= state.writelen;
	  state.writelen = 0;
	  if (er) {
	    // Avoid V8 leak, https://github.com/nodejs/node/pull/34103#issuecomment-652002364
	    er.stack; // eslint-disable-line no-unused-expressions

	    if (!state.errored) {
	      state.errored = er;
	    }

	    // In case of duplex streams we need to notify the readable side of the
	    // error.
	    if (stream._readableState && !stream._readableState.errored) {
	      stream._readableState.errored = er;
	    }
	    if (sync) {
	      process.nextTick(onwriteError, stream, state, er, cb);
	    } else {
	      onwriteError(stream, state, er, cb);
	    }
	  } else {
	    if (state.buffered.length > state.bufferedIndex) {
	      clearBuffer(stream, state);
	    }
	    if (sync) {
	      // It is a common case that the callback passed to .write() is always
	      // the same. In that case, we do not schedule a new nextTick(), but
	      // rather just increase a counter, to improve performance and avoid
	      // memory allocations.
	      if (state.afterWriteTickInfo !== null && state.afterWriteTickInfo.cb === cb) {
	        state.afterWriteTickInfo.count++;
	      } else {
	        state.afterWriteTickInfo = {
	          count: 1,
	          cb,
	          stream,
	          state
	        };
	        process.nextTick(afterWriteTick, state.afterWriteTickInfo);
	      }
	    } else {
	      afterWrite(stream, state, 1, cb);
	    }
	  }
	}
	function afterWriteTick({ stream, state, count, cb }) {
	  state.afterWriteTickInfo = null;
	  return afterWrite(stream, state, count, cb)
	}
	function afterWrite(stream, state, count, cb) {
	  const needDrain = !state.ending && !stream.destroyed && state.length === 0 && state.needDrain;
	  if (needDrain) {
	    state.needDrain = false;
	    stream.emit('drain');
	  }
	  while (count-- > 0) {
	    state.pendingcb--;
	    cb();
	  }
	  if (state.destroyed) {
	    errorBuffer(state);
	  }
	  finishMaybe(stream, state);
	}

	// If there's something in the buffer waiting, then invoke callbacks.
	function errorBuffer(state) {
	  if (state.writing) {
	    return
	  }
	  for (let n = state.bufferedIndex; n < state.buffered.length; ++n) {
	    var _state$errored;
	    const { chunk, callback } = state.buffered[n];
	    const len = state.objectMode ? 1 : chunk.length;
	    state.length -= len;
	    callback(
	      (_state$errored = state.errored) !== null && _state$errored !== undefined
	        ? _state$errored
	        : new ERR_STREAM_DESTROYED('write')
	    );
	  }
	  const onfinishCallbacks = state[kOnFinished].splice(0);
	  for (let i = 0; i < onfinishCallbacks.length; i++) {
	    var _state$errored2;
	    onfinishCallbacks[i](
	      (_state$errored2 = state.errored) !== null && _state$errored2 !== undefined
	        ? _state$errored2
	        : new ERR_STREAM_DESTROYED('end')
	    );
	  }
	  resetBuffer(state);
	}

	// If there's something in the buffer waiting, then process it.
	function clearBuffer(stream, state) {
	  if (state.corked || state.bufferProcessing || state.destroyed || !state.constructed) {
	    return
	  }
	  const { buffered, bufferedIndex, objectMode } = state;
	  const bufferedLength = buffered.length - bufferedIndex;
	  if (!bufferedLength) {
	    return
	  }
	  let i = bufferedIndex;
	  state.bufferProcessing = true;
	  if (bufferedLength > 1 && stream._writev) {
	    state.pendingcb -= bufferedLength - 1;
	    const callback = state.allNoop
	      ? nop
	      : (err) => {
	          for (let n = i; n < buffered.length; ++n) {
	            buffered[n].callback(err);
	          }
	        };
	    // Make a copy of `buffered` if it's going to be used by `callback` above,
	    // since `doWrite` will mutate the array.
	    const chunks = state.allNoop && i === 0 ? buffered : ArrayPrototypeSlice(buffered, i);
	    chunks.allBuffers = state.allBuffers;
	    doWrite(stream, state, true, state.length, chunks, '', callback);
	    resetBuffer(state);
	  } else {
	    do {
	      const { chunk, encoding, callback } = buffered[i];
	      buffered[i++] = null;
	      const len = objectMode ? 1 : chunk.length;
	      doWrite(stream, state, false, len, chunk, encoding, callback);
	    } while (i < buffered.length && !state.writing)
	    if (i === buffered.length) {
	      resetBuffer(state);
	    } else if (i > 256) {
	      buffered.splice(0, i);
	      state.bufferedIndex = 0;
	    } else {
	      state.bufferedIndex = i;
	    }
	  }
	  state.bufferProcessing = false;
	}
	Writable.prototype._write = function (chunk, encoding, cb) {
	  if (this._writev) {
	    this._writev(
	      [
	        {
	          chunk,
	          encoding
	        }
	      ],
	      cb
	    );
	  } else {
	    throw new ERR_METHOD_NOT_IMPLEMENTED('_write()')
	  }
	};
	Writable.prototype._writev = null;
	Writable.prototype.end = function (chunk, encoding, cb) {
	  const state = this._writableState;
	  if (typeof chunk === 'function') {
	    cb = chunk;
	    chunk = null;
	    encoding = null;
	  } else if (typeof encoding === 'function') {
	    cb = encoding;
	    encoding = null;
	  }
	  let err;
	  if (chunk !== null && chunk !== undefined) {
	    const ret = _write(this, chunk, encoding);
	    if (ret instanceof Error) {
	      err = ret;
	    }
	  }

	  // .end() fully uncorks.
	  if (state.corked) {
	    state.corked = 1;
	    this.uncork();
	  }
	  if (err) ; else if (!state.errored && !state.ending) {
	    // This is forgiving in terms of unnecessary calls to end() and can hide
	    // logic errors. However, usually such errors are harmless and causing a
	    // hard error can be disproportionately destructive. It is not always
	    // trivial for the user to determine whether end() needs to be called
	    // or not.

	    state.ending = true;
	    finishMaybe(this, state, true);
	    state.ended = true;
	  } else if (state.finished) {
	    err = new ERR_STREAM_ALREADY_FINISHED('end');
	  } else if (state.destroyed) {
	    err = new ERR_STREAM_DESTROYED('end');
	  }
	  if (typeof cb === 'function') {
	    if (err || state.finished) {
	      process.nextTick(cb, err);
	    } else {
	      state[kOnFinished].push(cb);
	    }
	  }
	  return this
	};
	function needFinish(state) {
	  return (
	    state.ending &&
	    !state.destroyed &&
	    state.constructed &&
	    state.length === 0 &&
	    !state.errored &&
	    state.buffered.length === 0 &&
	    !state.finished &&
	    !state.writing &&
	    !state.errorEmitted &&
	    !state.closeEmitted
	  )
	}
	function callFinal(stream, state) {
	  let called = false;
	  function onFinish(err) {
	    if (called) {
	      errorOrDestroy(stream, err !== null && err !== undefined ? err : ERR_MULTIPLE_CALLBACK());
	      return
	    }
	    called = true;
	    state.pendingcb--;
	    if (err) {
	      const onfinishCallbacks = state[kOnFinished].splice(0);
	      for (let i = 0; i < onfinishCallbacks.length; i++) {
	        onfinishCallbacks[i](err);
	      }
	      errorOrDestroy(stream, err, state.sync);
	    } else if (needFinish(state)) {
	      state.prefinished = true;
	      stream.emit('prefinish');
	      // Backwards compat. Don't check state.sync here.
	      // Some streams assume 'finish' will be emitted
	      // asynchronously relative to _final callback.
	      state.pendingcb++;
	      process.nextTick(finish, stream, state);
	    }
	  }
	  state.sync = true;
	  state.pendingcb++;
	  try {
	    stream._final(onFinish);
	  } catch (err) {
	    onFinish(err);
	  }
	  state.sync = false;
	}
	function prefinish(stream, state) {
	  if (!state.prefinished && !state.finalCalled) {
	    if (typeof stream._final === 'function' && !state.destroyed) {
	      state.finalCalled = true;
	      callFinal(stream, state);
	    } else {
	      state.prefinished = true;
	      stream.emit('prefinish');
	    }
	  }
	}
	function finishMaybe(stream, state, sync) {
	  if (needFinish(state)) {
	    prefinish(stream, state);
	    if (state.pendingcb === 0) {
	      if (sync) {
	        state.pendingcb++;
	        process.nextTick(
	          (stream, state) => {
	            if (needFinish(state)) {
	              finish(stream, state);
	            } else {
	              state.pendingcb--;
	            }
	          },
	          stream,
	          state
	        );
	      } else if (needFinish(state)) {
	        state.pendingcb++;
	        finish(stream, state);
	      }
	    }
	  }
	}
	function finish(stream, state) {
	  state.pendingcb--;
	  state.finished = true;
	  const onfinishCallbacks = state[kOnFinished].splice(0);
	  for (let i = 0; i < onfinishCallbacks.length; i++) {
	    onfinishCallbacks[i]();
	  }
	  stream.emit('finish');
	  if (state.autoDestroy) {
	    // In case of duplex streams we need a way to detect
	    // if the readable side is ready for autoDestroy as well.
	    const rState = stream._readableState;
	    const autoDestroy =
	      !rState ||
	      (rState.autoDestroy &&
	        // We don't expect the readable to ever 'end'
	        // if readable is explicitly set to false.
	        (rState.endEmitted || rState.readable === false));
	    if (autoDestroy) {
	      stream.destroy();
	    }
	  }
	}
	ObjectDefineProperties(Writable.prototype, {
	  closed: {
	    __proto__: null,
	    get() {
	      return this._writableState ? this._writableState.closed : false
	    }
	  },
	  destroyed: {
	    __proto__: null,
	    get() {
	      return this._writableState ? this._writableState.destroyed : false
	    },
	    set(value) {
	      // Backward compatibility, the user is explicitly managing destroyed.
	      if (this._writableState) {
	        this._writableState.destroyed = value;
	      }
	    }
	  },
	  writable: {
	    __proto__: null,
	    get() {
	      const w = this._writableState;
	      // w.writable === false means that this is part of a Duplex stream
	      // where the writable side was disabled upon construction.
	      // Compat. The user might manually disable writable side through
	      // deprecated setter.
	      return !!w && w.writable !== false && !w.destroyed && !w.errored && !w.ending && !w.ended
	    },
	    set(val) {
	      // Backwards compatible.
	      if (this._writableState) {
	        this._writableState.writable = !!val;
	      }
	    }
	  },
	  writableFinished: {
	    __proto__: null,
	    get() {
	      return this._writableState ? this._writableState.finished : false
	    }
	  },
	  writableObjectMode: {
	    __proto__: null,
	    get() {
	      return this._writableState ? this._writableState.objectMode : false
	    }
	  },
	  writableBuffer: {
	    __proto__: null,
	    get() {
	      return this._writableState && this._writableState.getBuffer()
	    }
	  },
	  writableEnded: {
	    __proto__: null,
	    get() {
	      return this._writableState ? this._writableState.ending : false
	    }
	  },
	  writableNeedDrain: {
	    __proto__: null,
	    get() {
	      const wState = this._writableState;
	      if (!wState) return false
	      return !wState.destroyed && !wState.ending && wState.needDrain
	    }
	  },
	  writableHighWaterMark: {
	    __proto__: null,
	    get() {
	      return this._writableState && this._writableState.highWaterMark
	    }
	  },
	  writableCorked: {
	    __proto__: null,
	    get() {
	      return this._writableState ? this._writableState.corked : 0
	    }
	  },
	  writableLength: {
	    __proto__: null,
	    get() {
	      return this._writableState && this._writableState.length
	    }
	  },
	  errored: {
	    __proto__: null,
	    enumerable: false,
	    get() {
	      return this._writableState ? this._writableState.errored : null
	    }
	  },
	  writableAborted: {
	    __proto__: null,
	    enumerable: false,
	    get: function () {
	      return !!(
	        this._writableState.writable !== false &&
	        (this._writableState.destroyed || this._writableState.errored) &&
	        !this._writableState.finished
	      )
	    }
	  }
	});
	const destroy = destroyImpl.destroy;
	Writable.prototype.destroy = function (err, cb) {
	  const state = this._writableState;

	  // Invoke pending callbacks.
	  if (!state.destroyed && (state.bufferedIndex < state.buffered.length || state[kOnFinished].length)) {
	    process.nextTick(errorBuffer, state);
	  }
	  destroy.call(this, err, cb);
	  return this
	};
	Writable.prototype._undestroy = destroyImpl.undestroy;
	Writable.prototype._destroy = function (err, cb) {
	  cb(err);
	};
	Writable.prototype[EE.captureRejectionSymbol] = function (err) {
	  this.destroy(err);
	};
	let webStreamsAdapters;

	// Lazy to avoid circular references
	function lazyWebStreams() {
	  if (webStreamsAdapters === undefined) webStreamsAdapters = {};
	  return webStreamsAdapters
	}
	Writable.fromWeb = function (writableStream, options) {
	  return lazyWebStreams().newStreamWritableFromWritableStream(writableStream, options)
	};
	Writable.toWeb = function (streamWritable) {
	  return lazyWebStreams().newWritableStreamFromStreamWritable(streamWritable)
	};
	return writable;
}

/* replacement start */

var duplexify;
var hasRequiredDuplexify;

function requireDuplexify () {
	if (hasRequiredDuplexify) return duplexify;
	hasRequiredDuplexify = 1;
	const process = requireProcess()

	/* replacement end */

	;	const bufferModule = require$$0;
	const {
	  isReadable,
	  isWritable,
	  isIterable,
	  isNodeStream,
	  isReadableNodeStream,
	  isWritableNodeStream,
	  isDuplexNodeStream
	} = requireUtils();
	const eos = requireEndOfStream();
	const {
	  AbortError,
	  codes: { ERR_INVALID_ARG_TYPE, ERR_INVALID_RETURN_VALUE }
	} = requireErrors();
	const { destroyer } = requireDestroy();
	const Duplex = requireDuplex();
	const Readable = requireReadable();
	const { createDeferredPromise } = requireUtil();
	const from = requireFrom();
	const Blob = globalThis.Blob || bufferModule.Blob;
	const isBlob =
	  typeof Blob !== 'undefined'
	    ? function isBlob(b) {
	        return b instanceof Blob
	      }
	    : function isBlob(b) {
	        return false
	      };
	const AbortController = globalThis.AbortController || require$$9.AbortController;
	const { FunctionPrototypeCall } = requirePrimordials();

	// This is needed for pre node 17.
	class Duplexify extends Duplex {
	  constructor(options) {
	    super(options);

	    // https://github.com/nodejs/node/pull/34385

	    if ((options === null || options === undefined ? undefined : options.readable) === false) {
	      this._readableState.readable = false;
	      this._readableState.ended = true;
	      this._readableState.endEmitted = true;
	    }
	    if ((options === null || options === undefined ? undefined : options.writable) === false) {
	      this._writableState.writable = false;
	      this._writableState.ending = true;
	      this._writableState.ended = true;
	      this._writableState.finished = true;
	    }
	  }
	}
	duplexify = function duplexify(body, name) {
	  if (isDuplexNodeStream(body)) {
	    return body
	  }
	  if (isReadableNodeStream(body)) {
	    return _duplexify({
	      readable: body
	    })
	  }
	  if (isWritableNodeStream(body)) {
	    return _duplexify({
	      writable: body
	    })
	  }
	  if (isNodeStream(body)) {
	    return _duplexify({
	      writable: false,
	      readable: false
	    })
	  }

	  // TODO: Webstreams
	  // if (isReadableStream(body)) {
	  //   return _duplexify({ readable: Readable.fromWeb(body) });
	  // }

	  // TODO: Webstreams
	  // if (isWritableStream(body)) {
	  //   return _duplexify({ writable: Writable.fromWeb(body) });
	  // }

	  if (typeof body === 'function') {
	    const { value, write, final, destroy } = fromAsyncGen(body);
	    if (isIterable(value)) {
	      return from(Duplexify, value, {
	        // TODO (ronag): highWaterMark?
	        objectMode: true,
	        write,
	        final,
	        destroy
	      })
	    }
	    const then = value === null || value === undefined ? undefined : value.then;
	    if (typeof then === 'function') {
	      let d;
	      const promise = FunctionPrototypeCall(
	        then,
	        value,
	        (val) => {
	          if (val != null) {
	            throw new ERR_INVALID_RETURN_VALUE('nully', 'body', val)
	          }
	        },
	        (err) => {
	          destroyer(d, err);
	        }
	      );
	      return (d = new Duplexify({
	        // TODO (ronag): highWaterMark?
	        objectMode: true,
	        readable: false,
	        write,
	        final(cb) {
	          final(async () => {
	            try {
	              await promise;
	              process.nextTick(cb, null);
	            } catch (err) {
	              process.nextTick(cb, err);
	            }
	          });
	        },
	        destroy
	      }))
	    }
	    throw new ERR_INVALID_RETURN_VALUE('Iterable, AsyncIterable or AsyncFunction', name, value)
	  }
	  if (isBlob(body)) {
	    return duplexify(body.arrayBuffer())
	  }
	  if (isIterable(body)) {
	    return from(Duplexify, body, {
	      // TODO (ronag): highWaterMark?
	      objectMode: true,
	      writable: false
	    })
	  }

	  // TODO: Webstreams.
	  // if (
	  //   isReadableStream(body?.readable) &&
	  //   isWritableStream(body?.writable)
	  // ) {
	  //   return Duplexify.fromWeb(body);
	  // }

	  if (
	    typeof (body === null || body === undefined ? undefined : body.writable) === 'object' ||
	    typeof (body === null || body === undefined ? undefined : body.readable) === 'object'
	  ) {
	    const readable =
	      body !== null && body !== undefined && body.readable
	        ? isReadableNodeStream(body === null || body === undefined ? undefined : body.readable)
	          ? body === null || body === undefined
	            ? undefined
	            : body.readable
	          : duplexify(body.readable)
	        : undefined;
	    const writable =
	      body !== null && body !== undefined && body.writable
	        ? isWritableNodeStream(body === null || body === undefined ? undefined : body.writable)
	          ? body === null || body === undefined
	            ? undefined
	            : body.writable
	          : duplexify(body.writable)
	        : undefined;
	    return _duplexify({
	      readable,
	      writable
	    })
	  }
	  const then = body === null || body === undefined ? undefined : body.then;
	  if (typeof then === 'function') {
	    let d;
	    FunctionPrototypeCall(
	      then,
	      body,
	      (val) => {
	        if (val != null) {
	          d.push(val);
	        }
	        d.push(null);
	      },
	      (err) => {
	        destroyer(d, err);
	      }
	    );
	    return (d = new Duplexify({
	      objectMode: true,
	      writable: false,
	      read() {}
	    }))
	  }
	  throw new ERR_INVALID_ARG_TYPE(
	    name,
	    [
	      'Blob',
	      'ReadableStream',
	      'WritableStream',
	      'Stream',
	      'Iterable',
	      'AsyncIterable',
	      'Function',
	      '{ readable, writable } pair',
	      'Promise'
	    ],
	    body
	  )
	};
	function fromAsyncGen(fn) {
	  let { promise, resolve } = createDeferredPromise();
	  const ac = new AbortController();
	  const signal = ac.signal;
	  const value = fn(
	    (async function* () {
	      while (true) {
	        const _promise = promise;
	        promise = null;
	        const { chunk, done, cb } = await _promise;
	        process.nextTick(cb);
	        if (done) return
	        if (signal.aborted)
	          throw new AbortError(undefined, {
	            cause: signal.reason
	          })
	        ;({ promise, resolve } = createDeferredPromise());
	        yield chunk;
	      }
	    })(),
	    {
	      signal
	    }
	  );
	  return {
	    value,
	    write(chunk, encoding, cb) {
	      const _resolve = resolve;
	      resolve = null;
	      _resolve({
	        chunk,
	        done: false,
	        cb
	      });
	    },
	    final(cb) {
	      const _resolve = resolve;
	      resolve = null;
	      _resolve({
	        done: true,
	        cb
	      });
	    },
	    destroy(err, cb) {
	      ac.abort();
	      cb(err);
	    }
	  }
	}
	function _duplexify(pair) {
	  const r = pair.readable && typeof pair.readable.read !== 'function' ? Readable.wrap(pair.readable) : pair.readable;
	  const w = pair.writable;
	  let readable = !!isReadable(r);
	  let writable = !!isWritable(w);
	  let ondrain;
	  let onfinish;
	  let onreadable;
	  let onclose;
	  let d;
	  function onfinished(err) {
	    const cb = onclose;
	    onclose = null;
	    if (cb) {
	      cb(err);
	    } else if (err) {
	      d.destroy(err);
	    } else if (!readable && !writable) {
	      d.destroy();
	    }
	  }

	  // TODO(ronag): Avoid double buffering.
	  // Implement Writable/Readable/Duplex traits.
	  // See, https://github.com/nodejs/node/pull/33515.
	  d = new Duplexify({
	    // TODO (ronag): highWaterMark?
	    readableObjectMode: !!(r !== null && r !== undefined && r.readableObjectMode),
	    writableObjectMode: !!(w !== null && w !== undefined && w.writableObjectMode),
	    readable,
	    writable
	  });
	  if (writable) {
	    eos(w, (err) => {
	      writable = false;
	      if (err) {
	        destroyer(r, err);
	      }
	      onfinished(err);
	    });
	    d._write = function (chunk, encoding, callback) {
	      if (w.write(chunk, encoding)) {
	        callback();
	      } else {
	        ondrain = callback;
	      }
	    };
	    d._final = function (callback) {
	      w.end();
	      onfinish = callback;
	    };
	    w.on('drain', function () {
	      if (ondrain) {
	        const cb = ondrain;
	        ondrain = null;
	        cb();
	      }
	    });
	    w.on('finish', function () {
	      if (onfinish) {
	        const cb = onfinish;
	        onfinish = null;
	        cb();
	      }
	    });
	  }
	  if (readable) {
	    eos(r, (err) => {
	      readable = false;
	      if (err) {
	        destroyer(r, err);
	      }
	      onfinished(err);
	    });
	    r.on('readable', function () {
	      if (onreadable) {
	        const cb = onreadable;
	        onreadable = null;
	        cb();
	      }
	    });
	    r.on('end', function () {
	      d.push(null);
	    });
	    d._read = function () {
	      while (true) {
	        const buf = r.read();
	        if (buf === null) {
	          onreadable = d._read;
	          return
	        }
	        if (!d.push(buf)) {
	          return
	        }
	      }
	    };
	  }
	  d._destroy = function (err, callback) {
	    if (!err && onclose !== null) {
	      err = new AbortError();
	    }
	    onreadable = null;
	    ondrain = null;
	    onfinish = null;
	    if (onclose === null) {
	      callback(err);
	    } else {
	      onclose = callback;
	      destroyer(w, err);
	      destroyer(r, err);
	    }
	  };
	  return d
	}
	return duplexify;
}

var duplex;
var hasRequiredDuplex;

function requireDuplex () {
	if (hasRequiredDuplex) return duplex;
	hasRequiredDuplex = 1;

	const {
	  ObjectDefineProperties,
	  ObjectGetOwnPropertyDescriptor,
	  ObjectKeys,
	  ObjectSetPrototypeOf
	} = requirePrimordials();
	duplex = Duplex;
	const Readable = requireReadable();
	const Writable = requireWritable();
	ObjectSetPrototypeOf(Duplex.prototype, Readable.prototype);
	ObjectSetPrototypeOf(Duplex, Readable);
	{
	  const keys = ObjectKeys(Writable.prototype);
	  // Allow the keys array to be GC'ed.
	  for (let i = 0; i < keys.length; i++) {
	    const method = keys[i];
	    if (!Duplex.prototype[method]) Duplex.prototype[method] = Writable.prototype[method];
	  }
	}
	function Duplex(options) {
	  if (!(this instanceof Duplex)) return new Duplex(options)
	  Readable.call(this, options);
	  Writable.call(this, options);
	  if (options) {
	    this.allowHalfOpen = options.allowHalfOpen !== false;
	    if (options.readable === false) {
	      this._readableState.readable = false;
	      this._readableState.ended = true;
	      this._readableState.endEmitted = true;
	    }
	    if (options.writable === false) {
	      this._writableState.writable = false;
	      this._writableState.ending = true;
	      this._writableState.ended = true;
	      this._writableState.finished = true;
	    }
	  } else {
	    this.allowHalfOpen = true;
	  }
	}
	ObjectDefineProperties(Duplex.prototype, {
	  writable: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writable')
	  },
	  writableHighWaterMark: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableHighWaterMark')
	  },
	  writableObjectMode: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableObjectMode')
	  },
	  writableBuffer: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableBuffer')
	  },
	  writableLength: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableLength')
	  },
	  writableFinished: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableFinished')
	  },
	  writableCorked: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableCorked')
	  },
	  writableEnded: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableEnded')
	  },
	  writableNeedDrain: {
	    __proto__: null,
	    ...ObjectGetOwnPropertyDescriptor(Writable.prototype, 'writableNeedDrain')
	  },
	  destroyed: {
	    __proto__: null,
	    get() {
	      if (this._readableState === undefined || this._writableState === undefined) {
	        return false
	      }
	      return this._readableState.destroyed && this._writableState.destroyed
	    },
	    set(value) {
	      // Backward compatibility, the user is explicitly
	      // managing destroyed.
	      if (this._readableState && this._writableState) {
	        this._readableState.destroyed = value;
	        this._writableState.destroyed = value;
	      }
	    }
	  }
	});
	let webStreamsAdapters;

	// Lazy to avoid circular references
	function lazyWebStreams() {
	  if (webStreamsAdapters === undefined) webStreamsAdapters = {};
	  return webStreamsAdapters
	}
	Duplex.fromWeb = function (pair, options) {
	  return lazyWebStreams().newStreamDuplexFromReadableWritablePair(pair, options)
	};
	Duplex.toWeb = function (duplex) {
	  return lazyWebStreams().newReadableWritablePairFromDuplex(duplex)
	};
	let duplexify;
	Duplex.from = function (body) {
	  if (!duplexify) {
	    duplexify = requireDuplexify();
	  }
	  return duplexify(body, 'body')
	};
	return duplex;
}

var transform;
var hasRequiredTransform;

function requireTransform () {
	if (hasRequiredTransform) return transform;
	hasRequiredTransform = 1;

	const { ObjectSetPrototypeOf, Symbol } = requirePrimordials();
	transform = Transform;
	const { ERR_METHOD_NOT_IMPLEMENTED } = requireErrors().codes;
	const Duplex = requireDuplex();
	const { getHighWaterMark } = requireState();
	ObjectSetPrototypeOf(Transform.prototype, Duplex.prototype);
	ObjectSetPrototypeOf(Transform, Duplex);
	const kCallback = Symbol('kCallback');
	function Transform(options) {
	  if (!(this instanceof Transform)) return new Transform(options)

	  // TODO (ronag): This should preferably always be
	  // applied but would be semver-major. Or even better;
	  // make Transform a Readable with the Writable interface.
	  const readableHighWaterMark = options ? getHighWaterMark(this, options, 'readableHighWaterMark', true) : null;
	  if (readableHighWaterMark === 0) {
	    // A Duplex will buffer both on the writable and readable side while
	    // a Transform just wants to buffer hwm number of elements. To avoid
	    // buffering twice we disable buffering on the writable side.
	    options = {
	      ...options,
	      highWaterMark: null,
	      readableHighWaterMark,
	      // TODO (ronag): 0 is not optimal since we have
	      // a "bug" where we check needDrain before calling _write and not after.
	      // Refs: https://github.com/nodejs/node/pull/32887
	      // Refs: https://github.com/nodejs/node/pull/35941
	      writableHighWaterMark: options.writableHighWaterMark || 0
	    };
	  }
	  Duplex.call(this, options);

	  // We have implemented the _read method, and done the other things
	  // that Readable wants before the first _read call, so unset the
	  // sync guard flag.
	  this._readableState.sync = false;
	  this[kCallback] = null;
	  if (options) {
	    if (typeof options.transform === 'function') this._transform = options.transform;
	    if (typeof options.flush === 'function') this._flush = options.flush;
	  }

	  // When the writable side finishes, then flush out anything remaining.
	  // Backwards compat. Some Transform streams incorrectly implement _final
	  // instead of or in addition to _flush. By using 'prefinish' instead of
	  // implementing _final we continue supporting this unfortunate use case.
	  this.on('prefinish', prefinish);
	}
	function final(cb) {
	  if (typeof this._flush === 'function' && !this.destroyed) {
	    this._flush((er, data) => {
	      if (er) {
	        if (cb) {
	          cb(er);
	        } else {
	          this.destroy(er);
	        }
	        return
	      }
	      if (data != null) {
	        this.push(data);
	      }
	      this.push(null);
	      if (cb) {
	        cb();
	      }
	    });
	  } else {
	    this.push(null);
	    if (cb) {
	      cb();
	    }
	  }
	}
	function prefinish() {
	  if (this._final !== final) {
	    final.call(this);
	  }
	}
	Transform.prototype._final = final;
	Transform.prototype._transform = function (chunk, encoding, callback) {
	  throw new ERR_METHOD_NOT_IMPLEMENTED('_transform()')
	};
	Transform.prototype._write = function (chunk, encoding, callback) {
	  const rState = this._readableState;
	  const wState = this._writableState;
	  const length = rState.length;
	  this._transform(chunk, encoding, (err, val) => {
	    if (err) {
	      callback(err);
	      return
	    }
	    if (val != null) {
	      this.push(val);
	    }
	    if (
	      wState.ended ||
	      // Backwards compat.
	      length === rState.length ||
	      // Backwards compat.
	      rState.length < rState.highWaterMark
	    ) {
	      callback();
	    } else {
	      this[kCallback] = callback;
	    }
	  });
	};
	Transform.prototype._read = function () {
	  if (this[kCallback]) {
	    const callback = this[kCallback];
	    this[kCallback] = null;
	    callback();
	  }
	};
	return transform;
}

var passthrough;
var hasRequiredPassthrough;

function requirePassthrough () {
	if (hasRequiredPassthrough) return passthrough;
	hasRequiredPassthrough = 1;

	const { ObjectSetPrototypeOf } = requirePrimordials();
	passthrough = PassThrough;
	const Transform = requireTransform();
	ObjectSetPrototypeOf(PassThrough.prototype, Transform.prototype);
	ObjectSetPrototypeOf(PassThrough, Transform);
	function PassThrough(options) {
	  if (!(this instanceof PassThrough)) return new PassThrough(options)
	  Transform.call(this, options);
	}
	PassThrough.prototype._transform = function (chunk, encoding, cb) {
	  cb(null, chunk);
	};
	return passthrough;
}

/* replacement start */

var pipeline_1;
var hasRequiredPipeline;

function requirePipeline () {
	if (hasRequiredPipeline) return pipeline_1;
	hasRequiredPipeline = 1;
	const process = requireProcess()

	/* replacement end */
	// Ported from https://github.com/mafintosh/pump with
	// permission from the author, Mathias Buus (@mafintosh).

	;	const { ArrayIsArray, Promise, SymbolAsyncIterator } = requirePrimordials();
	const eos = requireEndOfStream();
	const { once } = requireUtil();
	const destroyImpl = requireDestroy();
	const Duplex = requireDuplex();
	const {
	  aggregateTwoErrors,
	  codes: {
	    ERR_INVALID_ARG_TYPE,
	    ERR_INVALID_RETURN_VALUE,
	    ERR_MISSING_ARGS,
	    ERR_STREAM_DESTROYED,
	    ERR_STREAM_PREMATURE_CLOSE
	  },
	  AbortError
	} = requireErrors();
	const { validateFunction, validateAbortSignal } = requireValidators();
	const { isIterable, isReadable, isReadableNodeStream, isNodeStream } = requireUtils();
	const AbortController = globalThis.AbortController || require$$9.AbortController;
	let PassThrough;
	let Readable;
	function destroyer(stream, reading, writing) {
	  let finished = false;
	  stream.on('close', () => {
	    finished = true;
	  });
	  const cleanup = eos(
	    stream,
	    {
	      readable: reading,
	      writable: writing
	    },
	    (err) => {
	      finished = !err;
	    }
	  );
	  return {
	    destroy: (err) => {
	      if (finished) return
	      finished = true;
	      destroyImpl.destroyer(stream, err || new ERR_STREAM_DESTROYED('pipe'));
	    },
	    cleanup
	  }
	}
	function popCallback(streams) {
	  // Streams should never be an empty array. It should always contain at least
	  // a single stream. Therefore optimize for the average case instead of
	  // checking for length === 0 as well.
	  validateFunction(streams[streams.length - 1], 'streams[stream.length - 1]');
	  return streams.pop()
	}
	function makeAsyncIterable(val) {
	  if (isIterable(val)) {
	    return val
	  } else if (isReadableNodeStream(val)) {
	    // Legacy streams are not Iterable.
	    return fromReadable(val)
	  }
	  throw new ERR_INVALID_ARG_TYPE('val', ['Readable', 'Iterable', 'AsyncIterable'], val)
	}
	async function* fromReadable(val) {
	  if (!Readable) {
	    Readable = requireReadable();
	  }
	  yield* Readable.prototype[SymbolAsyncIterator].call(val);
	}
	async function pump(iterable, writable, finish, { end }) {
	  let error;
	  let onresolve = null;
	  const resume = (err) => {
	    if (err) {
	      error = err;
	    }
	    if (onresolve) {
	      const callback = onresolve;
	      onresolve = null;
	      callback();
	    }
	  };
	  const wait = () =>
	    new Promise((resolve, reject) => {
	      if (error) {
	        reject(error);
	      } else {
	        onresolve = () => {
	          if (error) {
	            reject(error);
	          } else {
	            resolve();
	          }
	        };
	      }
	    });
	  writable.on('drain', resume);
	  const cleanup = eos(
	    writable,
	    {
	      readable: false
	    },
	    resume
	  );
	  try {
	    if (writable.writableNeedDrain) {
	      await wait();
	    }
	    for await (const chunk of iterable) {
	      if (!writable.write(chunk)) {
	        await wait();
	      }
	    }
	    if (end) {
	      writable.end();
	    }
	    await wait();
	    finish();
	  } catch (err) {
	    finish(error !== err ? aggregateTwoErrors(error, err) : err);
	  } finally {
	    cleanup();
	    writable.off('drain', resume);
	  }
	}
	function pipeline(...streams) {
	  return pipelineImpl(streams, once(popCallback(streams)))
	}
	function pipelineImpl(streams, callback, opts) {
	  if (streams.length === 1 && ArrayIsArray(streams[0])) {
	    streams = streams[0];
	  }
	  if (streams.length < 2) {
	    throw new ERR_MISSING_ARGS('streams')
	  }
	  const ac = new AbortController();
	  const signal = ac.signal;
	  const outerSignal = opts === null || opts === undefined ? undefined : opts.signal;

	  // Need to cleanup event listeners if last stream is readable
	  // https://github.com/nodejs/node/issues/35452
	  const lastStreamCleanup = [];
	  validateAbortSignal(outerSignal, 'options.signal');
	  function abort() {
	    finishImpl(new AbortError());
	  }
	  outerSignal === null || outerSignal === undefined ? undefined : outerSignal.addEventListener('abort', abort);
	  let error;
	  let value;
	  const destroys = [];
	  let finishCount = 0;
	  function finish(err) {
	    finishImpl(err, --finishCount === 0);
	  }
	  function finishImpl(err, final) {
	    if (err && (!error || error.code === 'ERR_STREAM_PREMATURE_CLOSE')) {
	      error = err;
	    }
	    if (!error && !final) {
	      return
	    }
	    while (destroys.length) {
	      destroys.shift()(error);
	    }
	    outerSignal === null || outerSignal === undefined ? undefined : outerSignal.removeEventListener('abort', abort);
	    ac.abort();
	    if (final) {
	      if (!error) {
	        lastStreamCleanup.forEach((fn) => fn());
	      }
	      process.nextTick(callback, error, value);
	    }
	  }
	  let ret;
	  for (let i = 0; i < streams.length; i++) {
	    const stream = streams[i];
	    const reading = i < streams.length - 1;
	    const writing = i > 0;
	    const end = reading || (opts === null || opts === undefined ? undefined : opts.end) !== false;
	    const isLastStream = i === streams.length - 1;
	    if (isNodeStream(stream)) {
	      if (end) {
	        const { destroy, cleanup } = destroyer(stream, reading, writing);
	        destroys.push(destroy);
	        if (isReadable(stream) && isLastStream) {
	          lastStreamCleanup.push(cleanup);
	        }
	      }

	      // Catch stream errors that occur after pipe/pump has completed.
	      function onError(err) {
	        if (err && err.name !== 'AbortError' && err.code !== 'ERR_STREAM_PREMATURE_CLOSE') {
	          finish(err);
	        }
	      }
	      stream.on('error', onError);
	      if (isReadable(stream) && isLastStream) {
	        lastStreamCleanup.push(() => {
	          stream.removeListener('error', onError);
	        });
	      }
	    }
	    if (i === 0) {
	      if (typeof stream === 'function') {
	        ret = stream({
	          signal
	        });
	        if (!isIterable(ret)) {
	          throw new ERR_INVALID_RETURN_VALUE('Iterable, AsyncIterable or Stream', 'source', ret)
	        }
	      } else if (isIterable(stream) || isReadableNodeStream(stream)) {
	        ret = stream;
	      } else {
	        ret = Duplex.from(stream);
	      }
	    } else if (typeof stream === 'function') {
	      ret = makeAsyncIterable(ret);
	      ret = stream(ret, {
	        signal
	      });
	      if (reading) {
	        if (!isIterable(ret, true)) {
	          throw new ERR_INVALID_RETURN_VALUE('AsyncIterable', `transform[${i - 1}]`, ret)
	        }
	      } else {
	        var _ret;
	        if (!PassThrough) {
	          PassThrough = requirePassthrough();
	        }

	        // If the last argument to pipeline is not a stream
	        // we must create a proxy stream so that pipeline(...)
	        // always returns a stream which can be further
	        // composed through `.pipe(stream)`.

	        const pt = new PassThrough({
	          objectMode: true
	        });

	        // Handle Promises/A+ spec, `then` could be a getter that throws on
	        // second use.
	        const then = (_ret = ret) === null || _ret === undefined ? undefined : _ret.then;
	        if (typeof then === 'function') {
	          finishCount++;
	          then.call(
	            ret,
	            (val) => {
	              value = val;
	              if (val != null) {
	                pt.write(val);
	              }
	              if (end) {
	                pt.end();
	              }
	              process.nextTick(finish);
	            },
	            (err) => {
	              pt.destroy(err);
	              process.nextTick(finish, err);
	            }
	          );
	        } else if (isIterable(ret, true)) {
	          finishCount++;
	          pump(ret, pt, finish, {
	            end
	          });
	        } else {
	          throw new ERR_INVALID_RETURN_VALUE('AsyncIterable or Promise', 'destination', ret)
	        }
	        ret = pt;
	        const { destroy, cleanup } = destroyer(ret, false, true);
	        destroys.push(destroy);
	        if (isLastStream) {
	          lastStreamCleanup.push(cleanup);
	        }
	      }
	    } else if (isNodeStream(stream)) {
	      if (isReadableNodeStream(ret)) {
	        finishCount += 2;
	        const cleanup = pipe(ret, stream, finish, {
	          end
	        });
	        if (isReadable(stream) && isLastStream) {
	          lastStreamCleanup.push(cleanup);
	        }
	      } else if (isIterable(ret)) {
	        finishCount++;
	        pump(ret, stream, finish, {
	          end
	        });
	      } else {
	        throw new ERR_INVALID_ARG_TYPE('val', ['Readable', 'Iterable', 'AsyncIterable'], ret)
	      }
	      ret = stream;
	    } else {
	      ret = Duplex.from(stream);
	    }
	  }
	  if (
	    (signal !== null && signal !== undefined && signal.aborted) ||
	    (outerSignal !== null && outerSignal !== undefined && outerSignal.aborted)
	  ) {
	    process.nextTick(abort);
	  }
	  return ret
	}
	function pipe(src, dst, finish, { end }) {
	  let ended = false;
	  dst.on('close', () => {
	    if (!ended) {
	      // Finish if the destination closes before the source has completed.
	      finish(new ERR_STREAM_PREMATURE_CLOSE());
	    }
	  });
	  src.pipe(dst, {
	    end
	  });
	  if (end) {
	    // Compat. Before node v10.12.0 stdio used to throw an error so
	    // pipe() did/does not end() stdio destinations.
	    // Now they allow it but "secretly" don't close the underlying fd.
	    src.once('end', () => {
	      ended = true;
	      dst.end();
	    });
	  } else {
	    finish();
	  }
	  eos(
	    src,
	    {
	      readable: true,
	      writable: false
	    },
	    (err) => {
	      const rState = src._readableState;
	      if (
	        err &&
	        err.code === 'ERR_STREAM_PREMATURE_CLOSE' &&
	        rState &&
	        rState.ended &&
	        !rState.errored &&
	        !rState.errorEmitted
	      ) {
	        // Some readable streams will emit 'close' before 'end'. However, since
	        // this is on the readable side 'end' should still be emitted if the
	        // stream has been ended and no error emitted. This should be allowed in
	        // favor of backwards compatibility. Since the stream is piped to a
	        // destination this should not result in any observable difference.
	        // We don't need to check if this is a writable premature close since
	        // eos will only fail with premature close on the reading side for
	        // duplex streams.
	        src.once('end', finish).once('error', finish);
	      } else {
	        finish(err);
	      }
	    }
	  );
	  return eos(
	    dst,
	    {
	      readable: false,
	      writable: true
	    },
	    finish
	  )
	}
	pipeline_1 = {
	  pipelineImpl,
	  pipeline
	};
	return pipeline_1;
}

var compose;
var hasRequiredCompose;

function requireCompose () {
	if (hasRequiredCompose) return compose;
	hasRequiredCompose = 1;

	const { pipeline } = requirePipeline();
	const Duplex = requireDuplex();
	const { destroyer } = requireDestroy();
	const { isNodeStream, isReadable, isWritable } = requireUtils();
	const {
	  AbortError,
	  codes: { ERR_INVALID_ARG_VALUE, ERR_MISSING_ARGS }
	} = requireErrors();
	compose = function compose(...streams) {
	  if (streams.length === 0) {
	    throw new ERR_MISSING_ARGS('streams')
	  }
	  if (streams.length === 1) {
	    return Duplex.from(streams[0])
	  }
	  const orgStreams = [...streams];
	  if (typeof streams[0] === 'function') {
	    streams[0] = Duplex.from(streams[0]);
	  }
	  if (typeof streams[streams.length - 1] === 'function') {
	    const idx = streams.length - 1;
	    streams[idx] = Duplex.from(streams[idx]);
	  }
	  for (let n = 0; n < streams.length; ++n) {
	    if (!isNodeStream(streams[n])) {
	      // TODO(ronag): Add checks for non streams.
	      continue
	    }
	    if (n < streams.length - 1 && !isReadable(streams[n])) {
	      throw new ERR_INVALID_ARG_VALUE(`streams[${n}]`, orgStreams[n], 'must be readable')
	    }
	    if (n > 0 && !isWritable(streams[n])) {
	      throw new ERR_INVALID_ARG_VALUE(`streams[${n}]`, orgStreams[n], 'must be writable')
	    }
	  }
	  let ondrain;
	  let onfinish;
	  let onreadable;
	  let onclose;
	  let d;
	  function onfinished(err) {
	    const cb = onclose;
	    onclose = null;
	    if (cb) {
	      cb(err);
	    } else if (err) {
	      d.destroy(err);
	    } else if (!readable && !writable) {
	      d.destroy();
	    }
	  }
	  const head = streams[0];
	  const tail = pipeline(streams, onfinished);
	  const writable = !!isWritable(head);
	  const readable = !!isReadable(tail);

	  // TODO(ronag): Avoid double buffering.
	  // Implement Writable/Readable/Duplex traits.
	  // See, https://github.com/nodejs/node/pull/33515.
	  d = new Duplex({
	    // TODO (ronag): highWaterMark?
	    writableObjectMode: !!(head !== null && head !== undefined && head.writableObjectMode),
	    readableObjectMode: !!(tail !== null && tail !== undefined && tail.writableObjectMode),
	    writable,
	    readable
	  });
	  if (writable) {
	    d._write = function (chunk, encoding, callback) {
	      if (head.write(chunk, encoding)) {
	        callback();
	      } else {
	        ondrain = callback;
	      }
	    };
	    d._final = function (callback) {
	      head.end();
	      onfinish = callback;
	    };
	    head.on('drain', function () {
	      if (ondrain) {
	        const cb = ondrain;
	        ondrain = null;
	        cb();
	      }
	    });
	    tail.on('finish', function () {
	      if (onfinish) {
	        const cb = onfinish;
	        onfinish = null;
	        cb();
	      }
	    });
	  }
	  if (readable) {
	    tail.on('readable', function () {
	      if (onreadable) {
	        const cb = onreadable;
	        onreadable = null;
	        cb();
	      }
	    });
	    tail.on('end', function () {
	      d.push(null);
	    });
	    d._read = function () {
	      while (true) {
	        const buf = tail.read();
	        if (buf === null) {
	          onreadable = d._read;
	          return
	        }
	        if (!d.push(buf)) {
	          return
	        }
	      }
	    };
	  }
	  d._destroy = function (err, callback) {
	    if (!err && onclose !== null) {
	      err = new AbortError();
	    }
	    onreadable = null;
	    ondrain = null;
	    onfinish = null;
	    if (onclose === null) {
	      callback(err);
	    } else {
	      onclose = callback;
	      destroyer(tail, err);
	    }
	  };
	  return d
	};
	return compose;
}

var promises;
var hasRequiredPromises;

function requirePromises () {
	if (hasRequiredPromises) return promises;
	hasRequiredPromises = 1;

	const { ArrayPrototypePop, Promise } = requirePrimordials();
	const { isIterable, isNodeStream } = requireUtils();
	const { pipelineImpl: pl } = requirePipeline();
	const { finished } = requireEndOfStream();
	function pipeline(...streams) {
	  return new Promise((resolve, reject) => {
	    let signal;
	    let end;
	    const lastArg = streams[streams.length - 1];
	    if (lastArg && typeof lastArg === 'object' && !isNodeStream(lastArg) && !isIterable(lastArg)) {
	      const options = ArrayPrototypePop(streams);
	      signal = options.signal;
	      end = options.end;
	    }
	    pl(
	      streams,
	      (err, value) => {
	        if (err) {
	          reject(err);
	        } else {
	          resolve(value);
	        }
	      },
	      {
	        signal,
	        end
	      }
	    );
	  })
	}
	promises = {
	  finished,
	  pipeline
	};
	return promises;
}

/* replacement start */

var hasRequiredStream;

function requireStream () {
	if (hasRequiredStream) return stream.exports;
	hasRequiredStream = 1;
	const { Buffer } = require$$0

	/* replacement end */
	// Copyright Joyent, Inc. and other Node contributors.
	//
	// Permission is hereby granted, free of charge, to any person obtaining a
	// copy of this software and associated documentation files (the
	// "Software"), to deal in the Software without restriction, including
	// without limitation the rights to use, copy, modify, merge, publish,
	// distribute, sublicense, and/or sell copies of the Software, and to permit
	// persons to whom the Software is furnished to do so, subject to the
	// following conditions:
	//
	// The above copyright notice and this permission notice shall be included
	// in all copies or substantial portions of the Software.
	//
	// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
	// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
	// USE OR OTHER DEALINGS IN THE SOFTWARE.

	;	const { ObjectDefineProperty, ObjectKeys, ReflectApply } = requirePrimordials();
	const {
	  promisify: { custom: customPromisify }
	} = requireUtil();
	const { streamReturningOperators, promiseReturningOperators } = requireOperators();
	const {
	  codes: { ERR_ILLEGAL_CONSTRUCTOR }
	} = requireErrors();
	const compose = requireCompose();
	const { pipeline } = requirePipeline();
	const { destroyer } = requireDestroy();
	const eos = requireEndOfStream();
	const promises = requirePromises();
	const utils = requireUtils();
	const Stream = (stream.exports = requireLegacy().Stream);
	Stream.isDisturbed = utils.isDisturbed;
	Stream.isErrored = utils.isErrored;
	Stream.isReadable = utils.isReadable;
	Stream.Readable = requireReadable();
	for (const key of ObjectKeys(streamReturningOperators)) {
	  const op = streamReturningOperators[key];
	  function fn(...args) {
	    if (new.target) {
	      throw ERR_ILLEGAL_CONSTRUCTOR()
	    }
	    return Stream.Readable.from(ReflectApply(op, this, args))
	  }
	  ObjectDefineProperty(fn, 'name', {
	    __proto__: null,
	    value: op.name
	  });
	  ObjectDefineProperty(fn, 'length', {
	    __proto__: null,
	    value: op.length
	  });
	  ObjectDefineProperty(Stream.Readable.prototype, key, {
	    __proto__: null,
	    value: fn,
	    enumerable: false,
	    configurable: true,
	    writable: true
	  });
	}
	for (const key of ObjectKeys(promiseReturningOperators)) {
	  const op = promiseReturningOperators[key];
	  function fn(...args) {
	    if (new.target) {
	      throw ERR_ILLEGAL_CONSTRUCTOR()
	    }
	    return ReflectApply(op, this, args)
	  }
	  ObjectDefineProperty(fn, 'name', {
	    __proto__: null,
	    value: op.name
	  });
	  ObjectDefineProperty(fn, 'length', {
	    __proto__: null,
	    value: op.length
	  });
	  ObjectDefineProperty(Stream.Readable.prototype, key, {
	    __proto__: null,
	    value: fn,
	    enumerable: false,
	    configurable: true,
	    writable: true
	  });
	}
	Stream.Writable = requireWritable();
	Stream.Duplex = requireDuplex();
	Stream.Transform = requireTransform();
	Stream.PassThrough = requirePassthrough();
	Stream.pipeline = pipeline;
	const { addAbortSignal } = requireAddAbortSignal();
	Stream.addAbortSignal = addAbortSignal;
	Stream.finished = eos;
	Stream.destroy = destroyer;
	Stream.compose = compose;
	ObjectDefineProperty(Stream, 'promises', {
	  __proto__: null,
	  configurable: true,
	  enumerable: true,
	  get() {
	    return promises
	  }
	});
	ObjectDefineProperty(pipeline, customPromisify, {
	  __proto__: null,
	  enumerable: true,
	  get() {
	    return promises.pipeline
	  }
	});
	ObjectDefineProperty(eos, customPromisify, {
	  __proto__: null,
	  enumerable: true,
	  get() {
	    return promises.finished
	  }
	});

	// Backwards-compat with node 0.4.x
	Stream.Stream = Stream;
	Stream._isUint8Array = function isUint8Array(value) {
	  return value instanceof Uint8Array
	};
	Stream._uint8ArrayToBuffer = function _uint8ArrayToBuffer(chunk) {
	  return Buffer.from(chunk.buffer, chunk.byteOffset, chunk.byteLength)
	};
	return stream.exports;
}

(function (module) {

	const Stream = require$$0$1;
	if (Stream && process.env.READABLE_STREAM === 'disable') {
	  const promises = Stream.promises;

	  // Explicit export naming is needed for ESM
	  module.exports._uint8ArrayToBuffer = Stream._uint8ArrayToBuffer;
	  module.exports._isUint8Array = Stream._isUint8Array;
	  module.exports.isDisturbed = Stream.isDisturbed;
	  module.exports.isErrored = Stream.isErrored;
	  module.exports.isReadable = Stream.isReadable;
	  module.exports.Readable = Stream.Readable;
	  module.exports.Writable = Stream.Writable;
	  module.exports.Duplex = Stream.Duplex;
	  module.exports.Transform = Stream.Transform;
	  module.exports.PassThrough = Stream.PassThrough;
	  module.exports.addAbortSignal = Stream.addAbortSignal;
	  module.exports.finished = Stream.finished;
	  module.exports.destroy = Stream.destroy;
	  module.exports.pipeline = Stream.pipeline;
	  module.exports.compose = Stream.compose;
	  Object.defineProperty(Stream, 'promises', {
	    configurable: true,
	    enumerable: true,
	    get() {
	      return promises
	    }
	  });
	  module.exports.Stream = Stream.Stream;
	} else {
	  const CustomStream = requireStream();
	  const promises = requirePromises();
	  const originalDestroy = CustomStream.Readable.destroy;
	  module.exports = CustomStream.Readable;

	  // Explicit export naming is needed for ESM
	  module.exports._uint8ArrayToBuffer = CustomStream._uint8ArrayToBuffer;
	  module.exports._isUint8Array = CustomStream._isUint8Array;
	  module.exports.isDisturbed = CustomStream.isDisturbed;
	  module.exports.isErrored = CustomStream.isErrored;
	  module.exports.isReadable = CustomStream.isReadable;
	  module.exports.Readable = CustomStream.Readable;
	  module.exports.Writable = CustomStream.Writable;
	  module.exports.Duplex = CustomStream.Duplex;
	  module.exports.Transform = CustomStream.Transform;
	  module.exports.PassThrough = CustomStream.PassThrough;
	  module.exports.addAbortSignal = CustomStream.addAbortSignal;
	  module.exports.finished = CustomStream.finished;
	  module.exports.destroy = CustomStream.destroy;
	  module.exports.destroy = originalDestroy;
	  module.exports.pipeline = CustomStream.pipeline;
	  module.exports.compose = CustomStream.compose;
	  Object.defineProperty(CustomStream, 'promises', {
	    configurable: true,
	    enumerable: true,
	    get() {
	      return promises
	    }
	  });
	  module.exports.Stream = CustomStream.Stream;
	}

	// Allow default importing
	module.exports.default = module.exports;
} (ours));

var inherits$1 = {exports: {}};

var inherits_browser = {exports: {}};

var hasRequiredInherits_browser;

function requireInherits_browser () {
	if (hasRequiredInherits_browser) return inherits_browser.exports;
	hasRequiredInherits_browser = 1;
	if (typeof Object.create === 'function') {
	  // implementation from standard node.js 'util' module
	  inherits_browser.exports = function inherits(ctor, superCtor) {
	    if (superCtor) {
	      ctor.super_ = superCtor;
	      ctor.prototype = Object.create(superCtor.prototype, {
	        constructor: {
	          value: ctor,
	          enumerable: false,
	          writable: true,
	          configurable: true
	        }
	      });
	    }
	  };
	} else {
	  // old school shim for old browsers
	  inherits_browser.exports = function inherits(ctor, superCtor) {
	    if (superCtor) {
	      ctor.super_ = superCtor;
	      var TempCtor = function () {};
	      TempCtor.prototype = superCtor.prototype;
	      ctor.prototype = new TempCtor();
	      ctor.prototype.constructor = ctor;
	    }
	  };
	}
	return inherits_browser.exports;
}

(function (module) {
	try {
	  var util = require('util');
	  /* istanbul ignore next */
	  if (typeof util.inherits !== 'function') throw '';
	  module.exports = util.inherits;
	} catch (e) {
	  /* istanbul ignore next */
	  module.exports = requireInherits_browser();
	}
} (inherits$1));

const { Buffer: Buffer$1 } = require$$0;
const symbol = Symbol.for('BufferList');

function BufferList$1 (buf) {
  if (!(this instanceof BufferList$1)) {
    return new BufferList$1(buf)
  }

  BufferList$1._init.call(this, buf);
}

BufferList$1._init = function _init (buf) {
  Object.defineProperty(this, symbol, { value: true });

  this._bufs = [];
  this.length = 0;

  if (buf) {
    this.append(buf);
  }
};

BufferList$1.prototype._new = function _new (buf) {
  return new BufferList$1(buf)
};

BufferList$1.prototype._offset = function _offset (offset) {
  if (offset === 0) {
    return [0, 0]
  }

  let tot = 0;

  for (let i = 0; i < this._bufs.length; i++) {
    const _t = tot + this._bufs[i].length;
    if (offset < _t || i === this._bufs.length - 1) {
      return [i, offset - tot]
    }
    tot = _t;
  }
};

BufferList$1.prototype._reverseOffset = function (blOffset) {
  const bufferId = blOffset[0];
  let offset = blOffset[1];

  for (let i = 0; i < bufferId; i++) {
    offset += this._bufs[i].length;
  }

  return offset
};

BufferList$1.prototype.get = function get (index) {
  if (index > this.length || index < 0) {
    return undefined
  }

  const offset = this._offset(index);

  return this._bufs[offset[0]][offset[1]]
};

BufferList$1.prototype.slice = function slice (start, end) {
  if (typeof start === 'number' && start < 0) {
    start += this.length;
  }

  if (typeof end === 'number' && end < 0) {
    end += this.length;
  }

  return this.copy(null, 0, start, end)
};

BufferList$1.prototype.copy = function copy (dst, dstStart, srcStart, srcEnd) {
  if (typeof srcStart !== 'number' || srcStart < 0) {
    srcStart = 0;
  }

  if (typeof srcEnd !== 'number' || srcEnd > this.length) {
    srcEnd = this.length;
  }

  if (srcStart >= this.length) {
    return dst || Buffer$1.alloc(0)
  }

  if (srcEnd <= 0) {
    return dst || Buffer$1.alloc(0)
  }

  const copy = !!dst;
  const off = this._offset(srcStart);
  const len = srcEnd - srcStart;
  let bytes = len;
  let bufoff = (copy && dstStart) || 0;
  let start = off[1];

  // copy/slice everything
  if (srcStart === 0 && srcEnd === this.length) {
    if (!copy) {
      // slice, but full concat if multiple buffers
      return this._bufs.length === 1
        ? this._bufs[0]
        : Buffer$1.concat(this._bufs, this.length)
    }

    // copy, need to copy individual buffers
    for (let i = 0; i < this._bufs.length; i++) {
      this._bufs[i].copy(dst, bufoff);
      bufoff += this._bufs[i].length;
    }

    return dst
  }

  // easy, cheap case where it's a subset of one of the buffers
  if (bytes <= this._bufs[off[0]].length - start) {
    return copy
      ? this._bufs[off[0]].copy(dst, dstStart, start, start + bytes)
      : this._bufs[off[0]].slice(start, start + bytes)
  }

  if (!copy) {
    // a slice, we need something to copy in to
    dst = Buffer$1.allocUnsafe(len);
  }

  for (let i = off[0]; i < this._bufs.length; i++) {
    const l = this._bufs[i].length - start;

    if (bytes > l) {
      this._bufs[i].copy(dst, bufoff, start);
      bufoff += l;
    } else {
      this._bufs[i].copy(dst, bufoff, start, start + bytes);
      bufoff += l;
      break
    }

    bytes -= l;

    if (start) {
      start = 0;
    }
  }

  // safeguard so that we don't return uninitialized memory
  if (dst.length > bufoff) return dst.slice(0, bufoff)

  return dst
};

BufferList$1.prototype.shallowSlice = function shallowSlice (start, end) {
  start = start || 0;
  end = typeof end !== 'number' ? this.length : end;

  if (start < 0) {
    start += this.length;
  }

  if (end < 0) {
    end += this.length;
  }

  if (start === end) {
    return this._new()
  }

  const startOffset = this._offset(start);
  const endOffset = this._offset(end);
  const buffers = this._bufs.slice(startOffset[0], endOffset[0] + 1);

  if (endOffset[1] === 0) {
    buffers.pop();
  } else {
    buffers[buffers.length - 1] = buffers[buffers.length - 1].slice(0, endOffset[1]);
  }

  if (startOffset[1] !== 0) {
    buffers[0] = buffers[0].slice(startOffset[1]);
  }

  return this._new(buffers)
};

BufferList$1.prototype.toString = function toString (encoding, start, end) {
  return this.slice(start, end).toString(encoding)
};

BufferList$1.prototype.consume = function consume (bytes) {
  // first, normalize the argument, in accordance with how Buffer does it
  bytes = Math.trunc(bytes);
  // do nothing if not a positive number
  if (Number.isNaN(bytes) || bytes <= 0) return this

  while (this._bufs.length) {
    if (bytes >= this._bufs[0].length) {
      bytes -= this._bufs[0].length;
      this.length -= this._bufs[0].length;
      this._bufs.shift();
    } else {
      this._bufs[0] = this._bufs[0].slice(bytes);
      this.length -= bytes;
      break
    }
  }

  return this
};

BufferList$1.prototype.duplicate = function duplicate () {
  const copy = this._new();

  for (let i = 0; i < this._bufs.length; i++) {
    copy.append(this._bufs[i]);
  }

  return copy
};

BufferList$1.prototype.append = function append (buf) {
  if (buf == null) {
    return this
  }

  if (buf.buffer) {
    // append a view of the underlying ArrayBuffer
    this._appendBuffer(Buffer$1.from(buf.buffer, buf.byteOffset, buf.byteLength));
  } else if (Array.isArray(buf)) {
    for (let i = 0; i < buf.length; i++) {
      this.append(buf[i]);
    }
  } else if (this._isBufferList(buf)) {
    // unwrap argument into individual BufferLists
    for (let i = 0; i < buf._bufs.length; i++) {
      this.append(buf._bufs[i]);
    }
  } else {
    // coerce number arguments to strings, since Buffer(number) does
    // uninitialized memory allocation
    if (typeof buf === 'number') {
      buf = buf.toString();
    }

    this._appendBuffer(Buffer$1.from(buf));
  }

  return this
};

BufferList$1.prototype._appendBuffer = function appendBuffer (buf) {
  this._bufs.push(buf);
  this.length += buf.length;
};

BufferList$1.prototype.indexOf = function (search, offset, encoding) {
  if (encoding === undefined && typeof offset === 'string') {
    encoding = offset;
    offset = undefined;
  }

  if (typeof search === 'function' || Array.isArray(search)) {
    throw new TypeError('The "value" argument must be one of type string, Buffer, BufferList, or Uint8Array.')
  } else if (typeof search === 'number') {
    search = Buffer$1.from([search]);
  } else if (typeof search === 'string') {
    search = Buffer$1.from(search, encoding);
  } else if (this._isBufferList(search)) {
    search = search.slice();
  } else if (Array.isArray(search.buffer)) {
    search = Buffer$1.from(search.buffer, search.byteOffset, search.byteLength);
  } else if (!Buffer$1.isBuffer(search)) {
    search = Buffer$1.from(search);
  }

  offset = Number(offset || 0);

  if (isNaN(offset)) {
    offset = 0;
  }

  if (offset < 0) {
    offset = this.length + offset;
  }

  if (offset < 0) {
    offset = 0;
  }

  if (search.length === 0) {
    return offset > this.length ? this.length : offset
  }

  const blOffset = this._offset(offset);
  let blIndex = blOffset[0]; // index of which internal buffer we're working on
  let buffOffset = blOffset[1]; // offset of the internal buffer we're working on

  // scan over each buffer
  for (; blIndex < this._bufs.length; blIndex++) {
    const buff = this._bufs[blIndex];

    while (buffOffset < buff.length) {
      const availableWindow = buff.length - buffOffset;

      if (availableWindow >= search.length) {
        const nativeSearchResult = buff.indexOf(search, buffOffset);

        if (nativeSearchResult !== -1) {
          return this._reverseOffset([blIndex, nativeSearchResult])
        }

        buffOffset = buff.length - search.length + 1; // end of native search window
      } else {
        const revOffset = this._reverseOffset([blIndex, buffOffset]);

        if (this._match(revOffset, search)) {
          return revOffset
        }

        buffOffset++;
      }
    }

    buffOffset = 0;
  }

  return -1
};

BufferList$1.prototype._match = function (offset, search) {
  if (this.length - offset < search.length) {
    return false
  }

  for (let searchOffset = 0; searchOffset < search.length; searchOffset++) {
    if (this.get(offset + searchOffset) !== search[searchOffset]) {
      return false
    }
  }
  return true
}

;(function () {
  const methods = {
    readDoubleBE: 8,
    readDoubleLE: 8,
    readFloatBE: 4,
    readFloatLE: 4,
    readBigInt64BE: 8,
    readBigInt64LE: 8,
    readBigUInt64BE: 8,
    readBigUInt64LE: 8,
    readInt32BE: 4,
    readInt32LE: 4,
    readUInt32BE: 4,
    readUInt32LE: 4,
    readInt16BE: 2,
    readInt16LE: 2,
    readUInt16BE: 2,
    readUInt16LE: 2,
    readInt8: 1,
    readUInt8: 1,
    readIntBE: null,
    readIntLE: null,
    readUIntBE: null,
    readUIntLE: null
  };

  for (const m in methods) {
    (function (m) {
      if (methods[m] === null) {
        BufferList$1.prototype[m] = function (offset, byteLength) {
          return this.slice(offset, offset + byteLength)[m](0, byteLength)
        };
      } else {
        BufferList$1.prototype[m] = function (offset = 0) {
          return this.slice(offset, offset + methods[m])[m](0)
        };
      }
    }(m));
  }
}());

// Used internally by the class and also as an indicator of this object being
// a `BufferList`. It's not possible to use `instanceof BufferList` in a browser
// environment because there could be multiple different copies of the
// BufferList class and some `BufferList`s might be `BufferList`s.
BufferList$1.prototype._isBufferList = function _isBufferList (b) {
  return b instanceof BufferList$1 || BufferList$1.isBufferList(b)
};

BufferList$1.isBufferList = function isBufferList (b) {
  return b != null && b[symbol]
};

var BufferList_1 = BufferList$1;

const DuplexStream = ours.exports.Duplex;
const inherits = inherits$1.exports;
const BufferList = BufferList_1;

function BufferListStream (callback) {
  if (!(this instanceof BufferListStream)) {
    return new BufferListStream(callback)
  }

  if (typeof callback === 'function') {
    this._callback = callback;

    const piper = function piper (err) {
      if (this._callback) {
        this._callback(err);
        this._callback = null;
      }
    }.bind(this);

    this.on('pipe', function onPipe (src) {
      src.on('error', piper);
    });
    this.on('unpipe', function onUnpipe (src) {
      src.removeListener('error', piper);
    });

    callback = null;
  }

  BufferList._init.call(this, callback);
  DuplexStream.call(this);
}

inherits(BufferListStream, DuplexStream);
Object.assign(BufferListStream.prototype, BufferList.prototype);

BufferListStream.prototype._new = function _new (callback) {
  return new BufferListStream(callback)
};

BufferListStream.prototype._write = function _write (buf, encoding, callback) {
  this._appendBuffer(buf);

  if (typeof callback === 'function') {
    callback();
  }
};

BufferListStream.prototype._read = function _read (size) {
  if (!this.length) {
    return this.push(null)
  }

  size = Math.min(size, this.length);
  this.push(this.slice(0, size));
  this.consume(size);
};

BufferListStream.prototype.end = function end (chunk) {
  DuplexStream.prototype.end.call(this, chunk);

  if (this._callback) {
    this._callback(null, this.slice());
    this._callback = null;
  }
};

BufferListStream.prototype._destroy = function _destroy (err, cb) {
  this._bufs.length = 0;
  this.length = 0;
  cb(err);
};

BufferListStream.prototype._isBufferList = function _isBufferList (b) {
  return b instanceof BufferListStream || b instanceof BufferList || BufferListStream.isBufferList(b)
};

BufferListStream.isBufferList = BufferList.isBufferList;

bl.exports = BufferListStream;
bl.exports.BufferListStream = BufferListStream;
bl.exports.BufferList = BufferList;

var queueMicrotask_1;
var hasRequiredQueueMicrotask;

function requireQueueMicrotask () {
	if (hasRequiredQueueMicrotask) return queueMicrotask_1;
	hasRequiredQueueMicrotask = 1;
	queueMicrotask_1 = typeof queueMicrotask === 'function' ? queueMicrotask : (fn) => Promise.resolve().then(fn);
	return queueMicrotask_1;
}

var processNextTick = (typeof process !== 'undefined' && typeof process.nextTick === 'function')
  ? process.nextTick.bind(process)
  : requireQueueMicrotask();

var fixedSize = class FixedFIFO {
  constructor (hwm) {
    if (!(hwm > 0) || ((hwm - 1) & hwm) !== 0) throw new Error('Max size for a FixedFIFO should be a power of two')
    this.buffer = new Array(hwm);
    this.mask = hwm - 1;
    this.top = 0;
    this.btm = 0;
    this.next = null;
  }

  push (data) {
    if (this.buffer[this.top] !== undefined) return false
    this.buffer[this.top] = data;
    this.top = (this.top + 1) & this.mask;
    return true
  }

  shift () {
    const last = this.buffer[this.btm];
    if (last === undefined) return undefined
    this.buffer[this.btm] = undefined;
    this.btm = (this.btm + 1) & this.mask;
    return last
  }

  peek () {
    return this.buffer[this.btm]
  }

  isEmpty () {
    return this.buffer[this.btm] === undefined
  }
};

const FixedFIFO = fixedSize;

var fastFifo = class FastFIFO {
  constructor (hwm) {
    this.hwm = hwm || 16;
    this.head = new FixedFIFO(this.hwm);
    this.tail = this.head;
  }

  push (val) {
    if (!this.head.push(val)) {
      const prev = this.head;
      this.head = prev.next = new FixedFIFO(2 * this.head.buffer.length);
      this.head.push(val);
    }
  }

  shift () {
    const val = this.tail.shift();
    if (val === undefined && this.tail.next) {
      const next = this.tail.next;
      this.tail.next = null;
      this.tail = next;
      return this.tail.shift()
    }
    return val
  }

  peek () {
    return this.tail.peek()
  }

  isEmpty () {
    return this.head.isEmpty()
  }
};

const { EventEmitter } = require$$2;
const STREAM_DESTROYED = new Error('Stream was destroyed');
const PREMATURE_CLOSE = new Error('Premature close');

const queueTick = processNextTick;
const FIFO = fastFifo;

/* eslint-disable no-multi-spaces */

// 26 bits used total (4 from shared, 13 from read, and 9 from write)
const MAX = ((1 << 26) - 1);

// Shared state
const OPENING       = 0b0001;
const PREDESTROYING = 0b0010;
const DESTROYING    = 0b0100;
const DESTROYED     = 0b1000;

const NOT_OPENING = MAX ^ OPENING;
const NOT_PREDESTROYING = MAX ^ PREDESTROYING;

// Read state (4 bit offset from shared state)
const READ_ACTIVE           = 0b0000000000001 << 4;
const READ_PRIMARY          = 0b0000000000010 << 4;
const READ_SYNC             = 0b0000000000100 << 4;
const READ_QUEUED           = 0b0000000001000 << 4;
const READ_RESUMED          = 0b0000000010000 << 4;
const READ_PIPE_DRAINED     = 0b0000000100000 << 4;
const READ_ENDING           = 0b0000001000000 << 4;
const READ_EMIT_DATA        = 0b0000010000000 << 4;
const READ_EMIT_READABLE    = 0b0000100000000 << 4;
const READ_EMITTED_READABLE = 0b0001000000000 << 4;
const READ_DONE             = 0b0010000000000 << 4;
const READ_NEXT_TICK        = 0b0100000000001 << 4; // also active
const READ_NEEDS_PUSH       = 0b1000000000000 << 4;

// Combined read state
const READ_FLOWING = READ_RESUMED | READ_PIPE_DRAINED;
const READ_ACTIVE_AND_SYNC = READ_ACTIVE | READ_SYNC;
const READ_ACTIVE_AND_SYNC_AND_NEEDS_PUSH = READ_ACTIVE | READ_SYNC | READ_NEEDS_PUSH;
const READ_PRIMARY_AND_ACTIVE = READ_PRIMARY | READ_ACTIVE;
const READ_EMIT_READABLE_AND_QUEUED = READ_EMIT_READABLE | READ_QUEUED;

const READ_NOT_ACTIVE             = MAX ^ READ_ACTIVE;
const READ_NON_PRIMARY            = MAX ^ READ_PRIMARY;
const READ_NON_PRIMARY_AND_PUSHED = MAX ^ (READ_PRIMARY | READ_NEEDS_PUSH);
const READ_NOT_SYNC               = MAX ^ READ_SYNC;
const READ_PUSHED                 = MAX ^ READ_NEEDS_PUSH;
const READ_PAUSED                 = MAX ^ READ_RESUMED;
const READ_NOT_QUEUED             = MAX ^ (READ_QUEUED | READ_EMITTED_READABLE);
const READ_NOT_ENDING             = MAX ^ READ_ENDING;
const READ_PIPE_NOT_DRAINED       = MAX ^ READ_FLOWING;
const READ_NOT_NEXT_TICK          = MAX ^ READ_NEXT_TICK;

// Write state (17 bit offset, 4 bit offset from shared state and 13 from read state)
const WRITE_ACTIVE     = 0b000000001 << 17;
const WRITE_PRIMARY    = 0b000000010 << 17;
const WRITE_SYNC       = 0b000000100 << 17;
const WRITE_QUEUED     = 0b000001000 << 17;
const WRITE_UNDRAINED  = 0b000010000 << 17;
const WRITE_DONE       = 0b000100000 << 17;
const WRITE_EMIT_DRAIN = 0b001000000 << 17;
const WRITE_NEXT_TICK  = 0b010000001 << 17; // also active
const WRITE_FINISHING  = 0b100000000 << 17;

const WRITE_NOT_ACTIVE    = MAX ^ WRITE_ACTIVE;
const WRITE_NOT_SYNC      = MAX ^ WRITE_SYNC;
const WRITE_NON_PRIMARY   = MAX ^ WRITE_PRIMARY;
const WRITE_NOT_FINISHING = MAX ^ WRITE_FINISHING;
const WRITE_DRAINED       = MAX ^ WRITE_UNDRAINED;
const WRITE_NOT_QUEUED    = MAX ^ WRITE_QUEUED;
const WRITE_NOT_NEXT_TICK = MAX ^ WRITE_NEXT_TICK;

// Combined shared state
const ACTIVE = READ_ACTIVE | WRITE_ACTIVE;
const NOT_ACTIVE = MAX ^ ACTIVE;
const DONE = READ_DONE | WRITE_DONE;
const DESTROY_STATUS = DESTROYING | DESTROYED | PREDESTROYING;
const OPEN_STATUS = DESTROY_STATUS | OPENING;
const AUTO_DESTROY = DESTROY_STATUS | DONE;
const NON_PRIMARY = WRITE_NON_PRIMARY & READ_NON_PRIMARY;
const ACTIVE_OR_TICKING = WRITE_NEXT_TICK | READ_NEXT_TICK;
const TICKING = ACTIVE_OR_TICKING & NOT_ACTIVE;
const IS_OPENING = OPEN_STATUS | TICKING;

// Combined shared state and read state
const READ_PRIMARY_STATUS = OPEN_STATUS | READ_ENDING | READ_DONE;
const READ_STATUS = OPEN_STATUS | READ_DONE | READ_QUEUED;
const READ_ENDING_STATUS = OPEN_STATUS | READ_ENDING | READ_QUEUED;
const READ_READABLE_STATUS = OPEN_STATUS | READ_EMIT_READABLE | READ_QUEUED | READ_EMITTED_READABLE;
const SHOULD_NOT_READ = OPEN_STATUS | READ_ACTIVE | READ_ENDING | READ_DONE | READ_NEEDS_PUSH;
const READ_BACKPRESSURE_STATUS = DESTROY_STATUS | READ_ENDING | READ_DONE;

// Combined write state
const WRITE_PRIMARY_STATUS = OPEN_STATUS | WRITE_FINISHING | WRITE_DONE;
const WRITE_QUEUED_AND_UNDRAINED = WRITE_QUEUED | WRITE_UNDRAINED;
const WRITE_QUEUED_AND_ACTIVE = WRITE_QUEUED | WRITE_ACTIVE;
const WRITE_DRAIN_STATUS = WRITE_QUEUED | WRITE_UNDRAINED | OPEN_STATUS | WRITE_ACTIVE;
const WRITE_STATUS = OPEN_STATUS | WRITE_ACTIVE | WRITE_QUEUED;
const WRITE_PRIMARY_AND_ACTIVE = WRITE_PRIMARY | WRITE_ACTIVE;
const WRITE_ACTIVE_AND_SYNC = WRITE_ACTIVE | WRITE_SYNC;
const WRITE_FINISHING_STATUS = OPEN_STATUS | WRITE_FINISHING | WRITE_QUEUED_AND_ACTIVE | WRITE_DONE;
const WRITE_BACKPRESSURE_STATUS = WRITE_UNDRAINED | DESTROY_STATUS | WRITE_FINISHING | WRITE_DONE;

const asyncIterator = Symbol.asyncIterator || Symbol('asyncIterator');

class WritableState {
  constructor (stream, { highWaterMark = 16384, map = null, mapWritable, byteLength, byteLengthWritable } = {}) {
    this.stream = stream;
    this.queue = new FIFO();
    this.highWaterMark = highWaterMark;
    this.buffered = 0;
    this.error = null;
    this.pipeline = null;
    this.byteLength = byteLengthWritable || byteLength || defaultByteLength;
    this.map = mapWritable || map;
    this.afterWrite = afterWrite.bind(this);
    this.afterUpdateNextTick = updateWriteNT.bind(this);
  }

  get ended () {
    return (this.stream._duplexState & WRITE_DONE) !== 0
  }

  push (data) {
    if (this.map !== null) data = this.map(data);

    this.buffered += this.byteLength(data);
    this.queue.push(data);

    if (this.buffered < this.highWaterMark) {
      this.stream._duplexState |= WRITE_QUEUED;
      return true
    }

    this.stream._duplexState |= WRITE_QUEUED_AND_UNDRAINED;
    return false
  }

  shift () {
    const data = this.queue.shift();
    const stream = this.stream;

    this.buffered -= this.byteLength(data);
    if (this.buffered === 0) stream._duplexState &= WRITE_NOT_QUEUED;

    return data
  }

  end (data) {
    if (typeof data === 'function') this.stream.once('finish', data);
    else if (data !== undefined && data !== null) this.push(data);
    this.stream._duplexState = (this.stream._duplexState | WRITE_FINISHING) & WRITE_NON_PRIMARY;
  }

  autoBatch (data, cb) {
    const buffer = [];
    const stream = this.stream;

    buffer.push(data);
    while ((stream._duplexState & WRITE_STATUS) === WRITE_QUEUED_AND_ACTIVE) {
      buffer.push(stream._writableState.shift());
    }

    if ((stream._duplexState & OPEN_STATUS) !== 0) return cb(null)
    stream._writev(buffer, cb);
  }

  update () {
    const stream = this.stream;

    while ((stream._duplexState & WRITE_STATUS) === WRITE_QUEUED) {
      const data = this.shift();
      stream._duplexState |= WRITE_ACTIVE_AND_SYNC;
      stream._write(data, this.afterWrite);
      stream._duplexState &= WRITE_NOT_SYNC;
    }

    if ((stream._duplexState & WRITE_PRIMARY_AND_ACTIVE) === 0) this.updateNonPrimary();
  }

  updateNonPrimary () {
    const stream = this.stream;

    if ((stream._duplexState & WRITE_FINISHING_STATUS) === WRITE_FINISHING) {
      stream._duplexState = (stream._duplexState | WRITE_ACTIVE) & WRITE_NOT_FINISHING;
      stream._final(afterFinal.bind(this));
      return
    }

    if ((stream._duplexState & DESTROY_STATUS) === DESTROYING) {
      if ((stream._duplexState & ACTIVE_OR_TICKING) === 0) {
        stream._duplexState |= ACTIVE;
        stream._destroy(afterDestroy.bind(this));
      }
      return
    }

    if ((stream._duplexState & IS_OPENING) === OPENING) {
      stream._duplexState = (stream._duplexState | ACTIVE) & NOT_OPENING;
      stream._open(afterOpen.bind(this));
    }
  }

  updateNextTick () {
    if ((this.stream._duplexState & WRITE_NEXT_TICK) !== 0) return
    this.stream._duplexState |= WRITE_NEXT_TICK;
    queueTick(this.afterUpdateNextTick);
  }
}

class ReadableState {
  constructor (stream, { highWaterMark = 16384, map = null, mapReadable, byteLength, byteLengthReadable } = {}) {
    this.stream = stream;
    this.queue = new FIFO();
    this.highWaterMark = highWaterMark;
    this.buffered = 0;
    this.error = null;
    this.pipeline = null;
    this.byteLength = byteLengthReadable || byteLength || defaultByteLength;
    this.map = mapReadable || map;
    this.pipeTo = null;
    this.afterRead = afterRead.bind(this);
    this.afterUpdateNextTick = updateReadNT.bind(this);
  }

  get ended () {
    return (this.stream._duplexState & READ_DONE) !== 0
  }

  pipe (pipeTo, cb) {
    if (this.pipeTo !== null) throw new Error('Can only pipe to one destination')
    if (typeof cb !== 'function') cb = null;

    this.stream._duplexState |= READ_PIPE_DRAINED;
    this.pipeTo = pipeTo;
    this.pipeline = new Pipeline(this.stream, pipeTo, cb);

    if (cb) this.stream.on('error', noop$1); // We already error handle this so supress crashes

    if (isStreamx(pipeTo)) {
      pipeTo._writableState.pipeline = this.pipeline;
      if (cb) pipeTo.on('error', noop$1); // We already error handle this so supress crashes
      pipeTo.on('finish', this.pipeline.finished.bind(this.pipeline)); // TODO: just call finished from pipeTo itself
    } else {
      const onerror = this.pipeline.done.bind(this.pipeline, pipeTo);
      const onclose = this.pipeline.done.bind(this.pipeline, pipeTo, null); // onclose has a weird bool arg
      pipeTo.on('error', onerror);
      pipeTo.on('close', onclose);
      pipeTo.on('finish', this.pipeline.finished.bind(this.pipeline));
    }

    pipeTo.on('drain', afterDrain.bind(this));
    this.stream.emit('piping', pipeTo);
    pipeTo.emit('pipe', this.stream);
  }

  push (data) {
    const stream = this.stream;

    if (data === null) {
      this.highWaterMark = 0;
      stream._duplexState = (stream._duplexState | READ_ENDING) & READ_NON_PRIMARY_AND_PUSHED;
      return false
    }

    if (this.map !== null) data = this.map(data);
    this.buffered += this.byteLength(data);
    this.queue.push(data);

    stream._duplexState = (stream._duplexState | READ_QUEUED) & READ_PUSHED;

    return this.buffered < this.highWaterMark
  }

  shift () {
    const data = this.queue.shift();

    this.buffered -= this.byteLength(data);
    if (this.buffered === 0) this.stream._duplexState &= READ_NOT_QUEUED;
    return data
  }

  unshift (data) {
    let tail;
    const pending = [];

    while ((tail = this.queue.shift()) !== undefined) {
      pending.push(tail);
    }

    this.push(data);

    for (let i = 0; i < pending.length; i++) {
      this.queue.push(pending[i]);
    }
  }

  read () {
    const stream = this.stream;

    if ((stream._duplexState & READ_STATUS) === READ_QUEUED) {
      const data = this.shift();
      if (this.pipeTo !== null && this.pipeTo.write(data) === false) stream._duplexState &= READ_PIPE_NOT_DRAINED;
      if ((stream._duplexState & READ_EMIT_DATA) !== 0) stream.emit('data', data);
      return data
    }

    return null
  }

  drain () {
    const stream = this.stream;

    while ((stream._duplexState & READ_STATUS) === READ_QUEUED && (stream._duplexState & READ_FLOWING) !== 0) {
      const data = this.shift();
      if (this.pipeTo !== null && this.pipeTo.write(data) === false) stream._duplexState &= READ_PIPE_NOT_DRAINED;
      if ((stream._duplexState & READ_EMIT_DATA) !== 0) stream.emit('data', data);
    }
  }

  update () {
    const stream = this.stream;

    this.drain();

    while (this.buffered < this.highWaterMark && (stream._duplexState & SHOULD_NOT_READ) === 0) {
      stream._duplexState |= READ_ACTIVE_AND_SYNC_AND_NEEDS_PUSH;
      stream._read(this.afterRead);
      stream._duplexState &= READ_NOT_SYNC;
      if ((stream._duplexState & READ_ACTIVE) === 0) this.drain();
    }

    if ((stream._duplexState & READ_READABLE_STATUS) === READ_EMIT_READABLE_AND_QUEUED) {
      stream._duplexState |= READ_EMITTED_READABLE;
      stream.emit('readable');
    }

    if ((stream._duplexState & READ_PRIMARY_AND_ACTIVE) === 0) this.updateNonPrimary();
  }

  updateNonPrimary () {
    const stream = this.stream;

    if ((stream._duplexState & READ_ENDING_STATUS) === READ_ENDING) {
      stream._duplexState = (stream._duplexState | READ_DONE) & READ_NOT_ENDING;
      stream.emit('end');
      if ((stream._duplexState & AUTO_DESTROY) === DONE) stream._duplexState |= DESTROYING;
      if (this.pipeTo !== null) this.pipeTo.end();
    }

    if ((stream._duplexState & DESTROY_STATUS) === DESTROYING) {
      if ((stream._duplexState & ACTIVE_OR_TICKING) === 0) {
        stream._duplexState |= ACTIVE;
        stream._destroy(afterDestroy.bind(this));
      }
      return
    }

    if ((stream._duplexState & IS_OPENING) === OPENING) {
      stream._duplexState = (stream._duplexState | ACTIVE) & NOT_OPENING;
      stream._open(afterOpen.bind(this));
    }
  }

  updateNextTick () {
    if ((this.stream._duplexState & READ_NEXT_TICK) !== 0) return
    this.stream._duplexState |= READ_NEXT_TICK;
    queueTick(this.afterUpdateNextTick);
  }
}

class TransformState {
  constructor (stream) {
    this.data = null;
    this.afterTransform = afterTransform.bind(stream);
    this.afterFinal = null;
  }
}

class Pipeline {
  constructor (src, dst, cb) {
    this.from = src;
    this.to = dst;
    this.afterPipe = cb;
    this.error = null;
    this.pipeToFinished = false;
  }

  finished () {
    this.pipeToFinished = true;
  }

  done (stream, err) {
    if (err) this.error = err;

    if (stream === this.to) {
      this.to = null;

      if (this.from !== null) {
        if ((this.from._duplexState & READ_DONE) === 0 || !this.pipeToFinished) {
          this.from.destroy(this.error || new Error('Writable stream closed prematurely'));
        }
        return
      }
    }

    if (stream === this.from) {
      this.from = null;

      if (this.to !== null) {
        if ((stream._duplexState & READ_DONE) === 0) {
          this.to.destroy(this.error || new Error('Readable stream closed before ending'));
        }
        return
      }
    }

    if (this.afterPipe !== null) this.afterPipe(this.error);
    this.to = this.from = this.afterPipe = null;
  }
}

function afterDrain () {
  this.stream._duplexState |= READ_PIPE_DRAINED;
  if ((this.stream._duplexState & READ_ACTIVE_AND_SYNC) === 0) this.updateNextTick();
  else this.drain();
}

function afterFinal (err) {
  const stream = this.stream;
  if (err) stream.destroy(err);
  if ((stream._duplexState & DESTROY_STATUS) === 0) {
    stream._duplexState |= WRITE_DONE;
    stream.emit('finish');
  }
  if ((stream._duplexState & AUTO_DESTROY) === DONE) {
    stream._duplexState |= DESTROYING;
  }

  stream._duplexState &= WRITE_NOT_ACTIVE;
  this.update();
}

function afterDestroy (err) {
  const stream = this.stream;

  if (!err && this.error !== STREAM_DESTROYED) err = this.error;
  if (err) stream.emit('error', err);
  stream._duplexState |= DESTROYED;
  stream.emit('close');

  const rs = stream._readableState;
  const ws = stream._writableState;

  if (rs !== null && rs.pipeline !== null) rs.pipeline.done(stream, err);
  if (ws !== null && ws.pipeline !== null) ws.pipeline.done(stream, err);
}

function afterWrite (err) {
  const stream = this.stream;

  if (err) stream.destroy(err);
  stream._duplexState &= WRITE_NOT_ACTIVE;

  if ((stream._duplexState & WRITE_DRAIN_STATUS) === WRITE_UNDRAINED) {
    stream._duplexState &= WRITE_DRAINED;
    if ((stream._duplexState & WRITE_EMIT_DRAIN) === WRITE_EMIT_DRAIN) {
      stream.emit('drain');
    }
  }

  if ((stream._duplexState & WRITE_SYNC) === 0) this.update();
}

function afterRead (err) {
  if (err) this.stream.destroy(err);
  this.stream._duplexState &= READ_NOT_ACTIVE;
  if ((this.stream._duplexState & READ_SYNC) === 0) this.update();
}

function updateReadNT () {
  this.stream._duplexState &= READ_NOT_NEXT_TICK;
  this.update();
}

function updateWriteNT () {
  this.stream._duplexState &= WRITE_NOT_NEXT_TICK;
  this.update();
}

function afterOpen (err) {
  const stream = this.stream;

  if (err) stream.destroy(err);

  if ((stream._duplexState & DESTROYING) === 0) {
    if ((stream._duplexState & READ_PRIMARY_STATUS) === 0) stream._duplexState |= READ_PRIMARY;
    if ((stream._duplexState & WRITE_PRIMARY_STATUS) === 0) stream._duplexState |= WRITE_PRIMARY;
    stream.emit('open');
  }

  stream._duplexState &= NOT_ACTIVE;

  if (stream._writableState !== null) {
    stream._writableState.update();
  }

  if (stream._readableState !== null) {
    stream._readableState.update();
  }
}

function afterTransform (err, data) {
  if (data !== undefined && data !== null) this.push(data);
  this._writableState.afterWrite(err);
}

class Stream extends EventEmitter {
  constructor (opts) {
    super();

    this._duplexState = 0;
    this._readableState = null;
    this._writableState = null;

    if (opts) {
      if (opts.open) this._open = opts.open;
      if (opts.destroy) this._destroy = opts.destroy;
      if (opts.predestroy) this._predestroy = opts.predestroy;
      if (opts.signal) {
        opts.signal.addEventListener('abort', abort.bind(this));
      }
    }
  }

  _open (cb) {
    cb(null);
  }

  _destroy (cb) {
    cb(null);
  }

  _predestroy () {
    // does nothing
  }

  get readable () {
    return this._readableState !== null ? true : undefined
  }

  get writable () {
    return this._writableState !== null ? true : undefined
  }

  get destroyed () {
    return (this._duplexState & DESTROYED) !== 0
  }

  get destroying () {
    return (this._duplexState & DESTROY_STATUS) !== 0
  }

  destroy (err) {
    if ((this._duplexState & DESTROY_STATUS) === 0) {
      if (!err) err = STREAM_DESTROYED;
      this._duplexState = (this._duplexState | DESTROYING) & NON_PRIMARY;

      if (this._readableState !== null) this._readableState.error = err;
      if (this._writableState !== null) this._writableState.error = err;

      this._duplexState |= PREDESTROYING;
      this._predestroy();
      this._duplexState &= NOT_PREDESTROYING;

      if (this._readableState !== null) this._readableState.updateNextTick();
      if (this._writableState !== null) this._writableState.updateNextTick();
    }
  }

  on (name, fn) {
    if (this._readableState !== null) {
      if (name === 'data') {
        this._duplexState |= (READ_EMIT_DATA | READ_RESUMED);
        this._readableState.updateNextTick();
      }
      if (name === 'readable') {
        this._duplexState |= READ_EMIT_READABLE;
        this._readableState.updateNextTick();
      }
    }

    if (this._writableState !== null) {
      if (name === 'drain') {
        this._duplexState |= WRITE_EMIT_DRAIN;
        this._writableState.updateNextTick();
      }
    }

    return super.on(name, fn)
  }
}

class Readable$1 extends Stream {
  constructor (opts) {
    super(opts);

    this._duplexState |= OPENING | WRITE_DONE;
    this._readableState = new ReadableState(this, opts);

    if (opts) {
      if (opts.read) this._read = opts.read;
      if (opts.eagerOpen) this.resume().pause();
    }
  }

  _read (cb) {
    cb(null);
  }

  pipe (dest, cb) {
    this._readableState.pipe(dest, cb);
    this._readableState.updateNextTick();
    return dest
  }

  read () {
    this._readableState.updateNextTick();
    return this._readableState.read()
  }

  push (data) {
    this._readableState.updateNextTick();
    return this._readableState.push(data)
  }

  unshift (data) {
    this._readableState.updateNextTick();
    return this._readableState.unshift(data)
  }

  resume () {
    this._duplexState |= READ_RESUMED;
    this._readableState.updateNextTick();
    return this
  }

  pause () {
    this._duplexState &= READ_PAUSED;
    return this
  }

  static _fromAsyncIterator (ite, opts) {
    let destroy;

    const rs = new Readable$1({
      ...opts,
      read (cb) {
        ite.next().then(push).then(cb.bind(null, null)).catch(cb);
      },
      predestroy () {
        destroy = ite.return();
      },
      destroy (cb) {
        if (!destroy) return cb(null)
        destroy.then(cb.bind(null, null)).catch(cb);
      }
    });

    return rs

    function push (data) {
      if (data.done) rs.push(null);
      else rs.push(data.value);
    }
  }

  static from (data, opts) {
    if (isReadStreamx(data)) return data
    if (data[asyncIterator]) return this._fromAsyncIterator(data[asyncIterator](), opts)
    if (!Array.isArray(data)) data = data === undefined ? [] : [data];

    let i = 0;
    return new Readable$1({
      ...opts,
      read (cb) {
        this.push(i === data.length ? null : data[i++]);
        cb(null);
      }
    })
  }

  static isBackpressured (rs) {
    return (rs._duplexState & READ_BACKPRESSURE_STATUS) !== 0 || rs._readableState.buffered >= rs._readableState.highWaterMark
  }

  static isPaused (rs) {
    return (rs._duplexState & READ_RESUMED) === 0
  }

  [asyncIterator] () {
    const stream = this;

    let error = null;
    let promiseResolve = null;
    let promiseReject = null;

    this.on('error', (err) => { error = err; });
    this.on('readable', onreadable);
    this.on('close', onclose);

    return {
      [asyncIterator] () {
        return this
      },
      next () {
        return new Promise(function (resolve, reject) {
          promiseResolve = resolve;
          promiseReject = reject;
          const data = stream.read();
          if (data !== null) ondata(data);
          else if ((stream._duplexState & DESTROYED) !== 0) ondata(null);
        })
      },
      return () {
        return destroy(null)
      },
      throw (err) {
        return destroy(err)
      }
    }

    function onreadable () {
      if (promiseResolve !== null) ondata(stream.read());
    }

    function onclose () {
      if (promiseResolve !== null) ondata(null);
    }

    function ondata (data) {
      if (promiseReject === null) return
      if (error) promiseReject(error);
      else if (data === null && (stream._duplexState & READ_DONE) === 0) promiseReject(STREAM_DESTROYED);
      else promiseResolve({ value: data, done: data === null });
      promiseReject = promiseResolve = null;
    }

    function destroy (err) {
      stream.destroy(err);
      return new Promise((resolve, reject) => {
        if (stream._duplexState & DESTROYED) return resolve({ value: undefined, done: true })
        stream.once('close', function () {
          if (err) reject(err);
          else resolve({ value: undefined, done: true });
        });
      })
    }
  }
}

class Writable$1 extends Stream {
  constructor (opts) {
    super(opts);

    this._duplexState |= OPENING | READ_DONE;
    this._writableState = new WritableState(this, opts);

    if (opts) {
      if (opts.writev) this._writev = opts.writev;
      if (opts.write) this._write = opts.write;
      if (opts.final) this._final = opts.final;
    }
  }

  _writev (batch, cb) {
    cb(null);
  }

  _write (data, cb) {
    this._writableState.autoBatch(data, cb);
  }

  _final (cb) {
    cb(null);
  }

  static isBackpressured (ws) {
    return (ws._duplexState & WRITE_BACKPRESSURE_STATUS) !== 0
  }

  write (data) {
    this._writableState.updateNextTick();
    return this._writableState.push(data)
  }

  end (data) {
    this._writableState.updateNextTick();
    this._writableState.end(data);
    return this
  }
}

class Duplex extends Readable$1 { // and Writable
  constructor (opts) {
    super(opts);

    this._duplexState = OPENING;
    this._writableState = new WritableState(this, opts);

    if (opts) {
      if (opts.writev) this._writev = opts.writev;
      if (opts.write) this._write = opts.write;
      if (opts.final) this._final = opts.final;
    }
  }

  _writev (batch, cb) {
    cb(null);
  }

  _write (data, cb) {
    this._writableState.autoBatch(data, cb);
  }

  _final (cb) {
    cb(null);
  }

  write (data) {
    this._writableState.updateNextTick();
    return this._writableState.push(data)
  }

  end (data) {
    this._writableState.updateNextTick();
    this._writableState.end(data);
    return this
  }
}

class Transform extends Duplex {
  constructor (opts) {
    super(opts);
    this._transformState = new TransformState(this);

    if (opts) {
      if (opts.transform) this._transform = opts.transform;
      if (opts.flush) this._flush = opts.flush;
    }
  }

  _write (data, cb) {
    if (this._readableState.buffered >= this._readableState.highWaterMark) {
      this._transformState.data = data;
    } else {
      this._transform(data, this._transformState.afterTransform);
    }
  }

  _read (cb) {
    if (this._transformState.data !== null) {
      const data = this._transformState.data;
      this._transformState.data = null;
      cb(null);
      this._transform(data, this._transformState.afterTransform);
    } else {
      cb(null);
    }
  }

  _transform (data, cb) {
    cb(null, data);
  }

  _flush (cb) {
    cb(null);
  }

  _final (cb) {
    this._transformState.afterFinal = cb;
    this._flush(transformAfterFlush.bind(this));
  }
}

class PassThrough extends Transform {}

function transformAfterFlush (err, data) {
  const cb = this._transformState.afterFinal;
  if (err) return cb(err)
  if (data !== null && data !== undefined) this.push(data);
  this.push(null);
  cb(null);
}

function pipelinePromise (...streams) {
  return new Promise((resolve, reject) => {
    return pipeline(...streams, (err) => {
      if (err) return reject(err)
      resolve();
    })
  })
}

function pipeline (stream, ...streams) {
  const all = Array.isArray(stream) ? [...stream, ...streams] : [stream, ...streams];
  const done = (all.length && typeof all[all.length - 1] === 'function') ? all.pop() : null;

  if (all.length < 2) throw new Error('Pipeline requires at least 2 streams')

  let src = all[0];
  let dest = null;
  let error = null;

  for (let i = 1; i < all.length; i++) {
    dest = all[i];

    if (isStreamx(src)) {
      src.pipe(dest, onerror);
    } else {
      errorHandle(src, true, i > 1, onerror);
      src.pipe(dest);
    }

    src = dest;
  }

  if (done) {
    let fin = false;

    dest.on('finish', () => { fin = true; });
    dest.on('error', err => { error = error || err; });
    dest.on('close', () => done(error || (fin ? null : PREMATURE_CLOSE)));
  }

  return dest

  function errorHandle (s, rd, wr, onerror) {
    s.on('error', onerror);
    s.on('close', onclose);

    function onclose () {
      if (rd && s._readableState && !s._readableState.ended) return onerror(PREMATURE_CLOSE)
      if (wr && s._writableState && !s._writableState.ended) return onerror(PREMATURE_CLOSE)
    }
  }

  function onerror (err) {
    if (!err || error) return
    error = err;

    for (const s of all) {
      s.destroy(err);
    }
  }
}

function isStream (stream) {
  return !!stream._readableState || !!stream._writableState
}

function isStreamx (stream) {
  return typeof stream._duplexState === 'number' && isStream(stream)
}

function getStreamError (stream) {
  return (stream._readableState && stream._readableState.error) || (stream._writableState && stream._writableState.error)
}

function isReadStreamx (stream) {
  return isStreamx(stream) && stream.readable
}

function isTypedArray (data) {
  return typeof data === 'object' && data !== null && typeof data.byteLength === 'number'
}

function defaultByteLength (data) {
  return isTypedArray(data) ? data.byteLength : 1024
}

function noop$1 () {}

function abort () {
  this.destroy(new Error('Stream aborted.'));
}

var streamx = {
  pipeline,
  pipelinePromise,
  isStream,
  isStreamx,
  getStreamError,
  Stream,
  Writable: Writable$1,
  Readable: Readable$1,
  Duplex,
  Transform,
  // Export PassThrough for compatibility with Node.js core's stream module
  PassThrough
};

var headers$1 = {};

function isBuffer (value) {
  return Buffer.isBuffer(value) || value instanceof Uint8Array
}

function isEncoding (encoding) {
  return Buffer.isEncoding(encoding)
}

function alloc (size, fill, encoding) {
  return Buffer.alloc(size, fill, encoding)
}

function allocUnsafe (size) {
  return Buffer.allocUnsafe(size)
}

function allocUnsafeSlow (size) {
  return Buffer.allocUnsafeSlow(size)
}

function byteLength (string, encoding) {
  return Buffer.byteLength(string, encoding)
}

function compare (a, b) {
  return Buffer.compare(a, b)
}

function concat (buffers, totalLength) {
  return Buffer.concat(buffers, totalLength)
}

function copy (source, target, targetStart, start, end) {
  return toBuffer(source).copy(target, targetStart, start, end)
}

function equals (a, b) {
  return toBuffer(a).equals(b)
}

function fill (buffer, value, offset, end, encoding) {
  return toBuffer(buffer).fill(value, offset, end, encoding)
}

function from (value, encodingOrOffset, length) {
  return Buffer.from(value, encodingOrOffset, length)
}

function includes (buffer, value, byteOffset, encoding) {
  return toBuffer(buffer).includes(value, byteOffset, encoding)
}

function indexOf$1 (buffer, value, byfeOffset, encoding) {
  return toBuffer(buffer).indexOf(value, byfeOffset, encoding)
}

function lastIndexOf (buffer, value, byteOffset, encoding) {
  return toBuffer(buffer).lastIndexOf(value, byteOffset, encoding)
}

function swap16 (buffer) {
  return toBuffer(buffer).swap16()
}

function swap32 (buffer) {
  return toBuffer(buffer).swap32()
}

function swap64 (buffer) {
  return toBuffer(buffer).swap64()
}

function toBuffer (buffer) {
  if (Buffer.isBuffer(buffer)) return buffer
  return Buffer.from(buffer.buffer, buffer.byteOffset, buffer.byteLength)
}

function toString (buffer, encoding, start, end) {
  return toBuffer(buffer).toString(encoding, start, end)
}

function write (buffer, string, offset, length, encoding) {
  return toBuffer(buffer).write(string, offset, length, encoding)
}

function writeDoubleLE (buffer, value, offset) {
  return toBuffer(buffer).writeDoubleLE(value, offset)
}

function writeFloatLE (buffer, value, offset) {
  return toBuffer(buffer).writeFloatLE(value, offset)
}

function writeUInt32LE (buffer, value, offset) {
  return toBuffer(buffer).writeUInt32LE(value, offset)
}

function writeInt32LE (buffer, value, offset) {
  return toBuffer(buffer).writeInt32LE(value, offset)
}

function readDoubleLE (buffer, offset) {
  return toBuffer(buffer).readDoubleLE(offset)
}

function readFloatLE (buffer, offset) {
  return toBuffer(buffer).readFloatLE(offset)
}

function readUInt32LE (buffer, offset) {
  return toBuffer(buffer).readUInt32LE(offset)
}

function readInt32LE (buffer, offset) {
  return toBuffer(buffer).readInt32LE(offset)
}

var b4a$2 = {
  isBuffer,
  isEncoding,
  alloc,
  allocUnsafe,
  allocUnsafeSlow,
  byteLength,
  compare,
  concat,
  copy,
  equals,
  fill,
  from,
  includes,
  indexOf: indexOf$1,
  lastIndexOf,
  swap16,
  swap32,
  swap64,
  toBuffer,
  toString,
  write,
  writeDoubleLE,
  writeFloatLE,
  writeUInt32LE,
  writeInt32LE,
  readDoubleLE,
  readFloatLE,
  readUInt32LE,
  readInt32LE
};

const b4a$1 = b4a$2;

const ZEROS = '0000000000000000000';
const SEVENS = '7777777777777777777';
const ZERO_OFFSET = '0'.charCodeAt(0);
const USTAR_MAGIC = b4a$1.from('ustar\x00', 'binary');
const USTAR_VER = b4a$1.from('00', 'binary');
const GNU_MAGIC = b4a$1.from('ustar\x20', 'binary');
const GNU_VER = b4a$1.from('\x20\x00', 'binary');
const MASK = 0o7777;
const MAGIC_OFFSET = 257;
const VERSION_OFFSET = 263;

const clamp = function (index, len, defaultValue) {
  if (typeof index !== 'number') return defaultValue
  index = ~~index; // Coerce to integer.
  if (index >= len) return len
  if (index >= 0) return index
  index += len;
  if (index >= 0) return index
  return 0
};

const toType = function (flag) {
  switch (flag) {
    case 0:
      return 'file'
    case 1:
      return 'link'
    case 2:
      return 'symlink'
    case 3:
      return 'character-device'
    case 4:
      return 'block-device'
    case 5:
      return 'directory'
    case 6:
      return 'fifo'
    case 7:
      return 'contiguous-file'
    case 72:
      return 'pax-header'
    case 55:
      return 'pax-global-header'
    case 27:
      return 'gnu-long-link-path'
    case 28:
    case 30:
      return 'gnu-long-path'
  }

  return null
};

const toTypeflag = function (flag) {
  switch (flag) {
    case 'file':
      return 0
    case 'link':
      return 1
    case 'symlink':
      return 2
    case 'character-device':
      return 3
    case 'block-device':
      return 4
    case 'directory':
      return 5
    case 'fifo':
      return 6
    case 'contiguous-file':
      return 7
    case 'pax-header':
      return 72
  }

  return 0
};

const indexOf = function (block, num, offset, end) {
  for (; offset < end; offset++) {
    if (block[offset] === num) return offset
  }
  return end
};

const cksum = function (block) {
  let sum = 8 * 32;
  for (let i = 0; i < 148; i++) sum += block[i];
  for (let j = 156; j < 512; j++) sum += block[j];
  return sum
};

const encodeOct = function (val, n) {
  val = val.toString(8);
  if (val.length > n) return SEVENS.slice(0, n) + ' '
  else return ZEROS.slice(0, n - val.length) + val + ' '
};

/* Copied from the node-tar repo and modified to meet
 * tar-stream coding standard.
 *
 * Source: https://github.com/npm/node-tar/blob/51b6627a1f357d2eb433e7378e5f05e83b7aa6cd/lib/header.js#L349
 */
function parse256 (buf) {
  // first byte MUST be either 80 or FF
  // 80 for positive, FF for 2's comp
  let positive;
  if (buf[0] === 0x80) positive = true;
  else if (buf[0] === 0xFF) positive = false;
  else return null

  // build up a base-256 tuple from the least sig to the highest
  const tuple = [];
  let i;
  for (i = buf.length - 1; i > 0; i--) {
    const byte = buf[i];
    if (positive) tuple.push(byte);
    else tuple.push(0xFF - byte);
  }

  let sum = 0;
  const l = tuple.length;
  for (i = 0; i < l; i++) {
    sum += tuple[i] * Math.pow(256, i);
  }

  return positive ? sum : -1 * sum
}

const decodeOct = function (val, offset, length) {
  val = val.slice(offset, offset + length);
  offset = 0;

  // If prefixed with 0x80 then parse as a base-256 integer
  if (val[offset] & 0x80) {
    return parse256(val)
  } else {
    // Older versions of tar can prefix with spaces
    while (offset < val.length && val[offset] === 32) offset++;
    const end = clamp(indexOf(val, 32, offset, val.length), val.length, val.length);
    while (offset < end && val[offset] === 0) offset++;
    if (end === offset) return 0
    return parseInt(val.slice(offset, end).toString(), 8)
  }
};

const decodeStr = function (val, offset, length, encoding) {
  return val.slice(offset, indexOf(val, 0, offset, offset + length)).toString(encoding)
};

const addLength = function (str) {
  const len = b4a$1.byteLength(str);
  let digits = Math.floor(Math.log(len) / Math.log(10)) + 1;
  if (len + digits >= Math.pow(10, digits)) digits++;

  return (len + digits) + str
};

headers$1.decodeLongPath = function (buf, encoding) {
  return decodeStr(buf, 0, buf.length, encoding)
};

headers$1.encodePax = function (opts) { // TODO: encode more stuff in pax
  let result = '';
  if (opts.name) result += addLength(' path=' + opts.name + '\n');
  if (opts.linkname) result += addLength(' linkpath=' + opts.linkname + '\n');
  const pax = opts.pax;
  if (pax) {
    for (const key in pax) {
      result += addLength(' ' + key + '=' + pax[key] + '\n');
    }
  }
  return b4a$1.from(result)
};

headers$1.decodePax = function (buf) {
  const result = {};

  while (buf.length) {
    let i = 0;
    while (i < buf.length && buf[i] !== 32) i++;
    const len = parseInt(buf.slice(0, i).toString(), 10);
    if (!len) return result

    const b = buf.slice(i + 1, len - 1).toString();
    const keyIndex = b.indexOf('=');
    if (keyIndex === -1) return result
    result[b.slice(0, keyIndex)] = b.slice(keyIndex + 1);

    buf = buf.slice(len);
  }

  return result
};

headers$1.encode = function (opts) {
  const buf = b4a$1.alloc(512);
  let name = opts.name;
  let prefix = '';

  if (opts.typeflag === 5 && name[name.length - 1] !== '/') name += '/';
  if (b4a$1.byteLength(name) !== name.length) return null // utf-8

  while (b4a$1.byteLength(name) > 100) {
    const i = name.indexOf('/');
    if (i === -1) return null
    prefix += prefix ? '/' + name.slice(0, i) : name.slice(0, i);
    name = name.slice(i + 1);
  }

  if (b4a$1.byteLength(name) > 100 || b4a$1.byteLength(prefix) > 155) return null
  if (opts.linkname && b4a$1.byteLength(opts.linkname) > 100) return null

  b4a$1.write(buf, name);
  b4a$1.write(buf, encodeOct(opts.mode & MASK, 6), 100);
  b4a$1.write(buf, encodeOct(opts.uid, 6), 108);
  b4a$1.write(buf, encodeOct(opts.gid, 6), 116);
  b4a$1.write(buf, encodeOct(opts.size, 11), 124);
  b4a$1.write(buf, encodeOct((opts.mtime.getTime() / 1000) | 0, 11), 136);

  buf[156] = ZERO_OFFSET + toTypeflag(opts.type);

  if (opts.linkname) b4a$1.write(buf, opts.linkname, 157);

  b4a$1.copy(USTAR_MAGIC, buf, MAGIC_OFFSET);
  b4a$1.copy(USTAR_VER, buf, VERSION_OFFSET);
  if (opts.uname) b4a$1.write(buf, opts.uname, 265);
  if (opts.gname) b4a$1.write(buf, opts.gname, 297);
  b4a$1.write(buf, encodeOct(opts.devmajor || 0, 6), 329);
  b4a$1.write(buf, encodeOct(opts.devminor || 0, 6), 337);

  if (prefix) b4a$1.write(buf, prefix, 345);

  b4a$1.write(buf, encodeOct(cksum(buf), 6), 148);

  return buf
};

headers$1.decode = function (buf, filenameEncoding, allowUnknownFormat) {
  let typeflag = buf[156] === 0 ? 0 : buf[156] - ZERO_OFFSET;

  let name = decodeStr(buf, 0, 100, filenameEncoding);
  const mode = decodeOct(buf, 100, 8);
  const uid = decodeOct(buf, 108, 8);
  const gid = decodeOct(buf, 116, 8);
  const size = decodeOct(buf, 124, 12);
  const mtime = decodeOct(buf, 136, 12);
  const type = toType(typeflag);
  const linkname = buf[157] === 0 ? null : decodeStr(buf, 157, 100, filenameEncoding);
  const uname = decodeStr(buf, 265, 32);
  const gname = decodeStr(buf, 297, 32);
  const devmajor = decodeOct(buf, 329, 8);
  const devminor = decodeOct(buf, 337, 8);

  const c = cksum(buf);

  // checksum is still initial value if header was null.
  if (c === 8 * 32) return null

  // valid checksum
  if (c !== decodeOct(buf, 148, 8)) throw new Error('Invalid tar header. Maybe the tar is corrupted or it needs to be gunzipped?')

  if (USTAR_MAGIC.compare(buf, MAGIC_OFFSET, MAGIC_OFFSET + 6) === 0) {
    // ustar (posix) format.
    // prepend prefix, if present.
    if (buf[345]) name = decodeStr(buf, 345, 155, filenameEncoding) + '/' + name;
  } else if (GNU_MAGIC.compare(buf, MAGIC_OFFSET, MAGIC_OFFSET + 6) === 0 &&
             GNU_VER.compare(buf, VERSION_OFFSET, VERSION_OFFSET + 2) === 0) ; else {
    if (!allowUnknownFormat) {
      throw new Error('Invalid tar header: unknown format.')
    }
  }

  // to support old tar versions that use trailing / to indicate dirs
  if (typeflag === 0 && name && name[name.length - 1] === '/') typeflag = 5;

  return {
    name,
    mode,
    uid,
    gid,
    size,
    mtime: new Date(1000 * mtime),
    type,
    linkname,
    uname,
    gname,
    devmajor,
    devminor
  }
};

const { constants } = require$$0$2;
const { Readable, Writable } = streamx;
const { StringDecoder } = require$$13;
const b4a = b4a$2;

const headers = headers$1;

const DMODE = 0o755;
const FMODE = 0o644;

const END_OF_TAR = b4a.alloc(1024);

const noop = function () {};

const overflow = function (self, size) {
  size &= 511;
  if (size) self.push(END_OF_TAR.subarray(0, 512 - size));
};

function modeToType (mode) {
  switch (mode & constants.S_IFMT) {
    case constants.S_IFBLK: return 'block-device'
    case constants.S_IFCHR: return 'character-device'
    case constants.S_IFDIR: return 'directory'
    case constants.S_IFIFO: return 'fifo'
    case constants.S_IFLNK: return 'symlink'
  }

  return 'file'
}

class Sink extends Writable {
  constructor (to) {
    super();
    this.written = 0;
    this._to = to;
  }

  _write (data, cb) {
    this.written += data.byteLength;
    if (this._to.push(data)) return cb()
    this._to._drain = cb;
  }
}

class LinkSink extends Writable {
  constructor () {
    super();
    this.linkname = '';
    this._decoder = new StringDecoder('utf-8');
  }

  _write (data, cb) {
    this.linkname += this._decoder.write(data);
    cb();
  }
}

class Void extends Writable {
  _write (data, cb) {
    cb(new Error('No body allowed for this entry'));
  }
}

class Pack extends Readable {
  constructor (opts) {
    super(opts);
    this._drain = noop;
    this._finalized = false;
    this._finalizing = false;
    this._stream = null;
  }

  entry (header, buffer, callback) {
    if (this._stream) throw new Error('already piping an entry')
    if (this._finalized || this.destroyed) return

    if (typeof buffer === 'function') {
      callback = buffer;
      buffer = null;
    }

    if (!callback) callback = noop;

    const self = this;

    if (!header.size || header.type === 'symlink') header.size = 0;
    if (!header.type) header.type = modeToType(header.mode);
    if (!header.mode) header.mode = header.type === 'directory' ? DMODE : FMODE;
    if (!header.uid) header.uid = 0;
    if (!header.gid) header.gid = 0;
    if (!header.mtime) header.mtime = new Date();

    if (typeof buffer === 'string') buffer = b4a.from(buffer);
    if (b4a.isBuffer(buffer)) {
      header.size = buffer.byteLength;
      this._encode(header);
      const ok = this.push(buffer);
      overflow(self, header.size);
      if (ok) process.nextTick(callback);
      else this._drain = callback;
      return new Void()
    }

    if (header.type === 'symlink' && !header.linkname) {
      const linkSink = new LinkSink();
      linkSink
        .on('error', function (err) {
          self.destroy();
          callback(err);
        })
        .on('close', function () {
          header.linkname = linkSink.linkname;
          self._encode(header);
          callback();
        });

      return linkSink
    }

    this._encode(header);

    if (header.type !== 'file' && header.type !== 'contiguous-file') {
      process.nextTick(callback);
      return new Void()
    }

    const sink = new Sink(this);
    sink
      .on('error', function (err) {
        self._stream = null;
        self.destroy();
        callback(err);
      })
      .on('close', function () {
        self._stream = null;

        if (sink.written !== header.size) ;

        overflow(self, header.size);
        if (self._finalizing) { self.finalize(); }
        callback();
      });

    this._stream = sink;

    return sink
  }

  finalize () {
    if (this._stream) {
      this._finalizing = true;
      return
    }

    if (this._finalized) return
    this._finalized = true;
    this.push(END_OF_TAR);
    this.push(null);
  }

  _encode (header) {
    if (!header.pax) {
      const buf = headers.encode(header);
      if (buf) {
        this.push(buf);
        return
      }
    }
    this._encodePax(header);
  }

  _encodePax (header) {
    const paxHeader = headers.encodePax({
      name: header.name,
      linkname: header.linkname,
      pax: header.pax
    });

    const newHeader = {
      name: 'PaxHeader',
      mode: header.mode,
      uid: header.uid,
      gid: header.gid,
      size: paxHeader.byteLength,
      mtime: header.mtime,
      type: 'pax-header',
      linkname: header.linkname && 'PaxHeader',
      uname: header.uname,
      gname: header.gname,
      devmajor: header.devmajor,
      devminor: header.devminor
    };

    this.push(headers.encode(newHeader));
    this.push(paxHeader);
    overflow(this, paxHeader.byteLength);

    newHeader.size = header.size;
    newHeader.type = header.type;
    this.push(headers.encode(newHeader));
  }

  _read (cb) {
    const drain = this._drain;
    this._drain = noop;
    drain();
    cb();
  }
}

var pack$1 = function pack (opts) {
  return new Pack(opts)
};

var pack = pack$1;

const MTIME = new Date(0);
function findKeyByValue(entries, value) {
    for (const [key, { dest: val }] of Object.entries(entries)) {
        if (val == value) {
            return key;
        }
    }
    throw new Error(`couldn't map ${value} to a path. please file a bug at https://github.com/aspect-build/rules_js/issues/new/choose`);
}
async function* walk(dir, accumulate = '') {
    const dirents = await readdir(dir, { withFileTypes: true });
    for (const dirent of dirents) {
        if (dirent.isDirectory()) {
            yield* walk(path.join(dir, dirent.name), path.join(accumulate, dirent.name));
        }
        else {
            yield path.join(accumulate, dirent.name);
        }
    }
}
function add_parents(name, pkg, existing_paths) {
    const segments = path.dirname(name).split('/');
    let prev = '';
    const stats = {
        // this is an intermediate directory and bazel does not allow specifying
        // modes for intermediate directories.
        mode: 0o755,
        mtime: MTIME,
    };
    for (const part of segments) {
        if (!part) {
            continue;
        }
        prev = path.join(prev, part);
        // check if the directory has been has been created before.
        if (existing_paths.has(prev)) {
            continue;
        }
        existing_paths.add(prev);
        add_directory(prev, pkg, stats);
    }
}
function add_directory(name, pkg, stats) {
    pkg.entry({
        type: 'directory',
        name: name.replace(/^\//, ''),
        mode: stats.mode,
        mtime: MTIME,
    }).end();
}
function add_symlink(name, linkname, pkg, stats) {
    pkg.entry({
        type: 'symlink',
        name: name.replace(/^\//, ''),
        linkname: linkname,
        mode: stats.mode,
        mtime: MTIME,
    }).end();
}
function add_file(name, content, pkg, stats) {
    return new Promise((resolve, reject) => {
        const entry = pkg.entry({
            type: 'file',
            name: name.replace(/^\//, ''),
            mode: stats.mode,
            size: stats.size,
            mtime: MTIME,
        }, (err) => {
            if (err) {
                reject(err);
            }
            else {
                resolve(undefined);
            }
        });
        content.pipe(entry);
    });
}
async function build(entries, appLayerPath, nodeModulesLayerPath, compression) {
    const app = pack();
    const nm = pack();
    const app_existing_paths = new Set();
    const nm_existing_paths = new Set();
    let app_output = app, nm_output = nm;
    if (compression == "gzip") {
        app_output = app_output.pipe(createGzip());
        nm_output = nm_output.pipe(createGzip());
    }
    app_output.pipe(createWriteStream(appLayerPath));
    nm_output.pipe(createWriteStream(nodeModulesLayerPath));
    for (const key of Object.keys(entries).sort()) {
        const { dest, is_directory, is_source, root, remove_non_hermetic_lines } = entries[key];
        const output = dest.indexOf('node_modules') != -1 ? nm : app;
        const existing_paths = dest.indexOf('node_modules') != -1
            ? nm_existing_paths
            : app_existing_paths;
        // its a treeartifact. expand it and add individual entries.
        if (is_directory) {
            for await (const sub_key of walk(dest)) {
                const new_key = path.join(key, sub_key);
                const new_dest = path.join(dest, sub_key);
                add_parents(new_key, output, existing_paths);
                const stats = await stat(new_dest);
                await add_file(new_key, createReadStream(new_dest), output, stats);
            }
            continue;
        }
        // create parents of current path.
        add_parents(key, output, existing_paths);
        // A source file from workspace, not an output of a target.
        if (is_source) {
            const stats = await stat(dest);
            await add_file(key, createReadStream(dest), output, stats);
            continue;
        }
        // root indicates where the generated source comes from. it looks like
        // `bazel-out/darwin_arm64-fastbuild` when there's no transition.
        if (!root) {
            // everything except sources should have
            throw new Error(`unexpected entry format. ${JSON.stringify(entries[key])}. please file a bug at https://github.com/aspect-build/rules_js/issues/new/choose`);
        }
        const realp = await realpath(dest);
        const output_path = realp.slice(realp.indexOf(root));
        if (output_path != dest) {
            const stats = await stat(dest);
            const linkname = findKeyByValue(entries, output_path);
            add_symlink(key, linkname, output, stats);
        }
        else {
            const stats = await stat(dest);
            let stream = createReadStream(dest);
            if (remove_non_hermetic_lines) {
                const content = await readFile(dest);
                const replaced = Buffer.from(content.toString()
                    .replace(/.*JS_BINARY__TARGET_CPU=".*?"/g, `export JS_BINARY__TARGET_CPU="$(uname -m)"`)
                    .replace(/.*JS_BINARY__BINDIR=".*"/g, `export JS_BINARY__BINDIR="$(pwd)"`));
                stream = Readable$2.from(replaced);
                stats.size = replaced.byteLength;
            }
            await add_file(key, stream, output, stats);
        }
    }
    app.finalize();
    nm.finalize();
}
if (import.meta.url === pathToFileURL(process.argv[1]).href) {
    const [entriesPath, appLayerPath, nodeModulesLayerPath, compression] = process.argv.slice(2);
    const raw_entries = await readFile(entriesPath);
    const entries = JSON.parse(raw_entries.toString());
    build(entries, appLayerPath, nodeModulesLayerPath, compression);
}

export { build };
