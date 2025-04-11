'use strict';

var stream = require('stream');

/******************************************************************************
Copyright (c) Microsoft Corporation.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
***************************************************************************** */
/* global Reflect, Promise, SuppressedError, Symbol, Iterator */

var extendStatics = function(d, b) {
    extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
    return extendStatics(d, b);
};

function __extends(d, b) {
    if (typeof b !== "function" && b !== null)
        throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
    extendStatics(d, b);
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
}

function __awaiter(thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
}

function __generator(thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
}

function __values(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
}

function __asyncValues(o) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var m = o[Symbol.asyncIterator], i;
    return m ? m.call(o) : (o = typeof __values === "function" ? __values(o) : o[Symbol.iterator](), i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function () { return this; }, i);
    function verb(n) { i[n] = o[n] && function (v) { return new Promise(function (resolve, reject) { v = o[n](v), settle(resolve, reject, v.done, v.value); }); }; }
    function settle(resolve, reject, d, v) { Promise.resolve(v).then(function(v) { resolve({ value: v, done: d }); }, reject); }
}

function __classPrivateFieldGet(receiver, state, kind, f) {
    if (kind === "a" && !f) throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver)) throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
}

typeof SuppressedError === "function" ? SuppressedError : function (error, suppressed, message) {
    var e = new Error(message);
    return e.name = "SuppressedError", e.error = error, e.suppressed = suppressed, e;
};

var commonjsGlobal = typeof globalThis !== 'undefined' ? globalThis : typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};

var abortcontrollerPolyfillOnly = {};

var hasRequiredAbortcontrollerPolyfillOnly;

function requireAbortcontrollerPolyfillOnly () {
	if (hasRequiredAbortcontrollerPolyfillOnly) return abortcontrollerPolyfillOnly;
	hasRequiredAbortcontrollerPolyfillOnly = 1;
	(function (factory) {
	  factory();
	})((function () {
	  function _classCallCheck(instance, Constructor) {
	    if (!(instance instanceof Constructor)) {
	      throw new TypeError("Cannot call a class as a function");
	    }
	  }

	  function _defineProperties(target, props) {
	    for (var i = 0; i < props.length; i++) {
	      var descriptor = props[i];
	      descriptor.enumerable = descriptor.enumerable || false;
	      descriptor.configurable = true;
	      if ("value" in descriptor) descriptor.writable = true;
	      Object.defineProperty(target, descriptor.key, descriptor);
	    }
	  }

	  function _createClass(Constructor, protoProps, staticProps) {
	    if (protoProps) _defineProperties(Constructor.prototype, protoProps);
	    Object.defineProperty(Constructor, "prototype", {
	      writable: false
	    });
	    return Constructor;
	  }

	  function _inherits(subClass, superClass) {
	    if (typeof superClass !== "function" && superClass !== null) {
	      throw new TypeError("Super expression must either be null or a function");
	    }

	    subClass.prototype = Object.create(superClass && superClass.prototype, {
	      constructor: {
	        value: subClass,
	        writable: true,
	        configurable: true
	      }
	    });
	    Object.defineProperty(subClass, "prototype", {
	      writable: false
	    });
	    if (superClass) _setPrototypeOf(subClass, superClass);
	  }

	  function _getPrototypeOf(o) {
	    _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function _getPrototypeOf(o) {
	      return o.__proto__ || Object.getPrototypeOf(o);
	    };
	    return _getPrototypeOf(o);
	  }

	  function _setPrototypeOf(o, p) {
	    _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function _setPrototypeOf(o, p) {
	      o.__proto__ = p;
	      return o;
	    };
	    return _setPrototypeOf(o, p);
	  }

	  function _isNativeReflectConstruct() {
	    if (typeof Reflect === "undefined" || !Reflect.construct) return false;
	    if (Reflect.construct.sham) return false;
	    if (typeof Proxy === "function") return true;

	    try {
	      Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
	      return true;
	    } catch (e) {
	      return false;
	    }
	  }

	  function _assertThisInitialized(self) {
	    if (self === void 0) {
	      throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
	    }

	    return self;
	  }

	  function _possibleConstructorReturn(self, call) {
	    if (call && (typeof call === "object" || typeof call === "function")) {
	      return call;
	    } else if (call !== void 0) {
	      throw new TypeError("Derived constructors may only return object or undefined");
	    }

	    return _assertThisInitialized(self);
	  }

	  function _createSuper(Derived) {
	    var hasNativeReflectConstruct = _isNativeReflectConstruct();

	    return function _createSuperInternal() {
	      var Super = _getPrototypeOf(Derived),
	          result;

	      if (hasNativeReflectConstruct) {
	        var NewTarget = _getPrototypeOf(this).constructor;

	        result = Reflect.construct(Super, arguments, NewTarget);
	      } else {
	        result = Super.apply(this, arguments);
	      }

	      return _possibleConstructorReturn(this, result);
	    };
	  }

	  function _superPropBase(object, property) {
	    while (!Object.prototype.hasOwnProperty.call(object, property)) {
	      object = _getPrototypeOf(object);
	      if (object === null) break;
	    }

	    return object;
	  }

	  function _get() {
	    if (typeof Reflect !== "undefined" && Reflect.get) {
	      _get = Reflect.get.bind();
	    } else {
	      _get = function _get(target, property, receiver) {
	        var base = _superPropBase(target, property);

	        if (!base) return;
	        var desc = Object.getOwnPropertyDescriptor(base, property);

	        if (desc.get) {
	          return desc.get.call(arguments.length < 3 ? target : receiver);
	        }

	        return desc.value;
	      };
	    }

	    return _get.apply(this, arguments);
	  }

	  var Emitter = /*#__PURE__*/function () {
	    function Emitter() {
	      _classCallCheck(this, Emitter);

	      Object.defineProperty(this, 'listeners', {
	        value: {},
	        writable: true,
	        configurable: true
	      });
	    }

	    _createClass(Emitter, [{
	      key: "addEventListener",
	      value: function addEventListener(type, callback, options) {
	        if (!(type in this.listeners)) {
	          this.listeners[type] = [];
	        }

	        this.listeners[type].push({
	          callback: callback,
	          options: options
	        });
	      }
	    }, {
	      key: "removeEventListener",
	      value: function removeEventListener(type, callback) {
	        if (!(type in this.listeners)) {
	          return;
	        }

	        var stack = this.listeners[type];

	        for (var i = 0, l = stack.length; i < l; i++) {
	          if (stack[i].callback === callback) {
	            stack.splice(i, 1);
	            return;
	          }
	        }
	      }
	    }, {
	      key: "dispatchEvent",
	      value: function dispatchEvent(event) {
	        if (!(event.type in this.listeners)) {
	          return;
	        }

	        var stack = this.listeners[event.type];
	        var stackToCall = stack.slice();

	        for (var i = 0, l = stackToCall.length; i < l; i++) {
	          var listener = stackToCall[i];

	          try {
	            listener.callback.call(this, event);
	          } catch (e) {
	            Promise.resolve().then(function () {
	              throw e;
	            });
	          }

	          if (listener.options && listener.options.once) {
	            this.removeEventListener(event.type, listener.callback);
	          }
	        }

	        return !event.defaultPrevented;
	      }
	    }]);

	    return Emitter;
	  }();

	  var AbortSignal = /*#__PURE__*/function (_Emitter) {
	    _inherits(AbortSignal, _Emitter);

	    var _super = _createSuper(AbortSignal);

	    function AbortSignal() {
	      var _this;

	      _classCallCheck(this, AbortSignal);

	      _this = _super.call(this); // Some versions of babel does not transpile super() correctly for IE <= 10, if the parent
	      // constructor has failed to run, then "this.listeners" will still be undefined and then we call
	      // the parent constructor directly instead as a workaround. For general details, see babel bug:
	      // https://github.com/babel/babel/issues/3041
	      // This hack was added as a fix for the issue described here:
	      // https://github.com/Financial-Times/polyfill-library/pull/59#issuecomment-477558042

	      if (!_this.listeners) {
	        Emitter.call(_assertThisInitialized(_this));
	      } // Compared to assignment, Object.defineProperty makes properties non-enumerable by default and
	      // we want Object.keys(new AbortController().signal) to be [] for compat with the native impl


	      Object.defineProperty(_assertThisInitialized(_this), 'aborted', {
	        value: false,
	        writable: true,
	        configurable: true
	      });
	      Object.defineProperty(_assertThisInitialized(_this), 'onabort', {
	        value: null,
	        writable: true,
	        configurable: true
	      });
	      Object.defineProperty(_assertThisInitialized(_this), 'reason', {
	        value: undefined,
	        writable: true,
	        configurable: true
	      });
	      return _this;
	    }

	    _createClass(AbortSignal, [{
	      key: "toString",
	      value: function toString() {
	        return '[object AbortSignal]';
	      }
	    }, {
	      key: "dispatchEvent",
	      value: function dispatchEvent(event) {
	        if (event.type === 'abort') {
	          this.aborted = true;

	          if (typeof this.onabort === 'function') {
	            this.onabort.call(this, event);
	          }
	        }

	        _get(_getPrototypeOf(AbortSignal.prototype), "dispatchEvent", this).call(this, event);
	      }
	    }]);

	    return AbortSignal;
	  }(Emitter);
	  var AbortController = /*#__PURE__*/function () {
	    function AbortController() {
	      _classCallCheck(this, AbortController);

	      // Compared to assignment, Object.defineProperty makes properties non-enumerable by default and
	      // we want Object.keys(new AbortController()) to be [] for compat with the native impl
	      Object.defineProperty(this, 'signal', {
	        value: new AbortSignal(),
	        writable: true,
	        configurable: true
	      });
	    }

	    _createClass(AbortController, [{
	      key: "abort",
	      value: function abort(reason) {
	        var event;

	        try {
	          event = new Event('abort');
	        } catch (e) {
	          if (typeof document !== 'undefined') {
	            if (!document.createEvent) {
	              // For Internet Explorer 8:
	              event = document.createEventObject();
	              event.type = 'abort';
	            } else {
	              // For Internet Explorer 11:
	              event = document.createEvent('Event');
	              event.initEvent('abort', false, false);
	            }
	          } else {
	            // Fallback where document isn't available:
	            event = {
	              type: 'abort',
	              bubbles: false,
	              cancelable: false
	            };
	          }
	        }

	        var signalReason = reason;

	        if (signalReason === undefined) {
	          if (typeof document === 'undefined') {
	            signalReason = new Error('This operation was aborted');
	            signalReason.name = 'AbortError';
	          } else {
	            try {
	              signalReason = new DOMException('signal is aborted without reason');
	            } catch (err) {
	              // IE 11 does not support calling the DOMException constructor, use a
	              // regular error object on it instead.
	              signalReason = new Error('This operation was aborted');
	              signalReason.name = 'AbortError';
	            }
	          }
	        }

	        this.signal.reason = signalReason;
	        this.signal.dispatchEvent(event);
	      }
	    }, {
	      key: "toString",
	      value: function toString() {
	        return '[object AbortController]';
	      }
	    }]);

	    return AbortController;
	  }();

	  if (typeof Symbol !== 'undefined' && Symbol.toStringTag) {
	    // These are necessary to make sure that we get correct output for:
	    // Object.prototype.toString.call(new AbortController())
	    AbortController.prototype[Symbol.toStringTag] = 'AbortController';
	    AbortSignal.prototype[Symbol.toStringTag] = 'AbortSignal';
	  }

	  function polyfillNeeded(self) {
	    if (self.__FORCE_INSTALL_ABORTCONTROLLER_POLYFILL) {
	      console.log('__FORCE_INSTALL_ABORTCONTROLLER_POLYFILL=true is set, will force install polyfill');
	      return true;
	    } // Note that the "unfetch" minimal fetch polyfill defines fetch() without
	    // defining window.Request, and this polyfill need to work on top of unfetch
	    // so the below feature detection needs the !self.AbortController part.
	    // The Request.prototype check is also needed because Safari versions 11.1.2
	    // up to and including 12.1.x has a window.AbortController present but still
	    // does NOT correctly implement abortable fetch:
	    // https://bugs.webkit.org/show_bug.cgi?id=174980#c2


	    return typeof self.Request === 'function' && !self.Request.prototype.hasOwnProperty('signal') || !self.AbortController;
	  }

	  (function (self) {

	    if (!polyfillNeeded(self)) {
	      return;
	    }

	    self.AbortController = AbortController;
	    self.AbortSignal = AbortSignal;
	  })(typeof self !== 'undefined' ? self : commonjsGlobal);

	}));
	return abortcontrollerPolyfillOnly;
}

requireAbortcontrollerPolyfillOnly();

/**
 * Each protocol buffer message is preceded by its length in varint format
 * The flow goes as
 * --->
 * WorkRequestMessageSize (varint)
 * WorkRequest {}
 * <----
 * WorkResponseMessageSize (varint)
 * WorkResponse
 * See: https://docs.bazel.build/versions/main/creating-workers.html#work-responses
 */
/**
 * Extract the delimited header information from a buffer.
 * Size in bytes may vary depending on the size of the original message. Specified by `headerSize`
 * @param buffer the buffer to extract the varint message size
 * @returns an object that contains how long is the header and the size of the WorkRequest
 */
function readWorkRequestSize(buffer) {
    var b;
    var result = 0;
    var intOffset = 0;
    for (var i = 0; i < 5; i++) {
        b = buffer[intOffset++];
        result |= (b & 0x7f) << (7 * i);
        if (!(b & 0x80)) {
            break;
        }
    }
    return { size: result, headerSize: intOffset };
}
/**
 * Creates a varint header message that specifies size of the WorkResponse in bytes.
 * @param size Size of the WorkResponse in bytes.
 * @returns A buffer containing the size information in varint
 */
function writeWorkResponseSize(size) {
    var buffer = Buffer.alloc(10);
    var index = 0;
    while (size > 127) {
        buffer[index] = (size & 0x7f) | 0x80;
        size = size >>> 7;
        index++;
    }
    buffer[index] = size;
    return buffer.slice(0, index + 1);
}

var googleProtobuf = {};

/*

 Copyright The Closure Library Authors.
 SPDX-License-Identifier: Apache-2.0
*/

var hasRequiredGoogleProtobuf;

function requireGoogleProtobuf () {
	if (hasRequiredGoogleProtobuf) return googleProtobuf;
	hasRequiredGoogleProtobuf = 1;
	(function (exports) {
		var aa="function"==typeof Object.defineProperties?Object.defineProperty:function(a,b,c){a!=Array.prototype&&a!=Object.prototype&&(a[b]=c.value);},e="undefined"!=typeof window&&window===googleProtobuf?googleProtobuf:"undefined"!=typeof commonjsGlobal&&null!=commonjsGlobal?commonjsGlobal:googleProtobuf;function ba(a,b){if(b){var c=e;a=a.split(".");for(var d=0;d<a.length-1;d++){var f=a[d];f in c||(c[f]={});c=c[f];}a=a[a.length-1];d=c[a];b=b(d);b!=d&&null!=b&&aa(c,a,{configurable:true,writable:true,value:b});}}
		function ca(a){var b=0;return function(){return b<a.length?{done:false,value:a[b++]}:{done:true}}}function da(){da=function(){};e.Symbol||(e.Symbol=ea);}function fa(a,b){this.a=a;aa(this,"description",{configurable:true,writable:true,value:b});}fa.prototype.toString=function(){return this.a};var ea=function(){function a(c){if(this instanceof a)throw new TypeError("Symbol is not a constructor");return new fa("jscomp_symbol_"+(c||"")+"_"+b++,c)}var b=0;return a}();
		function ha(){da();var a=e.Symbol.iterator;a||(a=e.Symbol.iterator=e.Symbol("Symbol.iterator"));"function"!=typeof Array.prototype[a]&&aa(Array.prototype,a,{configurable:true,writable:true,value:function(){return ia(ca(this))}});ha=function(){};}function ia(a){ha();a={next:a};a[e.Symbol.iterator]=function(){return this};return a}
		function ja(a,b){ha();a instanceof String&&(a+="");var c=0,d={next:function(){if(c<a.length){var f=c++;return {value:b(f,a[f]),done:false}}d.next=function(){return {done:true,value:void 0}};return d.next()}};d[Symbol.iterator]=function(){return d};return d}ba("Array.prototype.entries",function(a){return a?a:function(){return ja(this,function(b,c){return [b,c]})}});var ka=googleProtobuf||self;
		function g(a,b,c){a=a.split(".");c=c||ka;a[0]in c||"undefined"==typeof c.execScript||c.execScript("var "+a[0]);for(var d;a.length&&(d=a.shift());)a.length||void 0===b?c[d]&&c[d]!==Object.prototype[d]?c=c[d]:c=c[d]={}:c[d]=b;}
		function k(a){var b=typeof a;if("object"==b)if(a){if(a instanceof Array)return "array";if(a instanceof Object)return b;var c=Object.prototype.toString.call(a);if("[object Window]"==c)return "object";if("[object Array]"==c||"number"==typeof a.length&&"undefined"!=typeof a.splice&&"undefined"!=typeof a.propertyIsEnumerable&&!a.propertyIsEnumerable("splice"))return "array";if("[object Function]"==c||"undefined"!=typeof a.call&&"undefined"!=typeof a.propertyIsEnumerable&&!a.propertyIsEnumerable("call"))return "function"}else return "null";
		else if("function"==b&&"undefined"==typeof a.call)return "object";return b}function la(a){var b=typeof a;return "object"==b&&null!=a||"function"==b}function ma(a,b,c){g(a,b,c);}function na(a,b){function c(){}c.prototype=b.prototype;a.prototype=new c;a.prototype.constructor=a;}var oa="constructor hasOwnProperty isPrototypeOf propertyIsEnumerable toLocaleString toString valueOf".split(" ");function pa(a,b){for(var c,d,f=1;f<arguments.length;f++){d=arguments[f];for(c in d)a[c]=d[c];for(var h=0;h<oa.length;h++)c=oa[h],Object.prototype.hasOwnProperty.call(d,c)&&(a[c]=d[c]);}}var qa=Array.prototype.forEach?function(a,b){Array.prototype.forEach.call(a,b,void 0);}:function(a,b){for(var c=a.length,d="string"===typeof a?a.split(""):a,f=0;f<c;f++)f in d&&b.call(void 0,d[f],f,a);},l=Array.prototype.map?function(a,b){return Array.prototype.map.call(a,b,void 0)}:function(a,b){for(var c=a.length,d=Array(c),f="string"===typeof a?a.split(""):a,h=0;h<c;h++)h in f&&(d[h]=b.call(void 0,f[h],h,a));return d};
		function ra(a,b,c){return 2>=arguments.length?Array.prototype.slice.call(a,b):Array.prototype.slice.call(a,b,c)}function sa(a,b,c,d){var f="Assertion failed";if(c){f+=": "+c;var h=d;}else a&&(f+=": "+a,h=b);throw Error(f,h||[]);}function n(a,b,c){for(var d=[],f=2;f<arguments.length;++f)d[f-2]=arguments[f];a||sa("",null,b,d);return a}function ta(a,b,c){for(var d=[],f=2;f<arguments.length;++f)d[f-2]=arguments[f];"string"!==typeof a&&sa("Expected string but got %s: %s.",[k(a),a],b,d);}
		function ua(a,b,c){for(var d=[],f=2;f<arguments.length;++f)d[f-2]=arguments[f];Array.isArray(a)||sa("Expected array but got %s: %s.",[k(a),a],b,d);}function p(a,b){for(var c=[],d=1;d<arguments.length;++d)c[d-1]=arguments[d];throw Error("Failure"+(a?": "+a:""),c);}function q(a,b,c,d){for(var f=[],h=3;h<arguments.length;++h)f[h-3]=arguments[h];a instanceof b||sa("Expected instanceof %s but got %s.",[va(b),va(a)],c,f);}
		function va(a){return a instanceof Function?a.displayName||a.name||"unknown type name":a instanceof Object?a.constructor.displayName||a.constructor.name||Object.prototype.toString.call(a):null===a?"null":typeof a}function r(a,b){this.c=a;this.b=b;this.a={};this.arrClean=true;if(0<this.c.length){for(a=0;a<this.c.length;a++){b=this.c[a];var c=b[0];this.a[c.toString()]=new wa(c,b[1]);}this.arrClean=true;}}g("jspb.Map",r,void 0);
		r.prototype.g=function(){if(this.arrClean){if(this.b){var a=this.a,b;for(b in a)if(Object.prototype.hasOwnProperty.call(a,b)){var c=a[b].a;c&&c.g();}}}else {this.c.length=0;a=u(this);a.sort();for(b=0;b<a.length;b++){var d=this.a[a[b]];(c=d.a)&&c.g();this.c.push([d.key,d.value]);}this.arrClean=true;}return this.c};r.prototype.toArray=r.prototype.g;
		r.prototype.Mc=function(a,b){for(var c=this.g(),d=[],f=0;f<c.length;f++){var h=this.a[c[f][0].toString()];v(this,h);var m=h.a;m?(n(b),d.push([h.key,b(a,m)])):d.push([h.key,h.value]);}return d};r.prototype.toObject=r.prototype.Mc;r.fromObject=function(a,b,c){b=new r([],b);for(var d=0;d<a.length;d++){var f=a[d][0],h=c(a[d][1]);b.set(f,h);}return b};function w(a){this.a=0;this.b=a;}w.prototype.next=function(){return this.a<this.b.length?{done:false,value:this.b[this.a++]}:{done:true,value:void 0}};
		"undefined"!=typeof Symbol&&(w.prototype[Symbol.iterator]=function(){return this});r.prototype.Jb=function(){return u(this).length};r.prototype.getLength=r.prototype.Jb;r.prototype.clear=function(){this.a={};this.arrClean=false;};r.prototype.clear=r.prototype.clear;r.prototype.Cb=function(a){a=a.toString();var b=this.a.hasOwnProperty(a);delete this.a[a];this.arrClean=false;return b};r.prototype.del=r.prototype.Cb;
		r.prototype.Eb=function(){var a=[],b=u(this);b.sort();for(var c=0;c<b.length;c++){var d=this.a[b[c]];a.push([d.key,d.value]);}return a};r.prototype.getEntryList=r.prototype.Eb;r.prototype.entries=function(){var a=[],b=u(this);b.sort();for(var c=0;c<b.length;c++){var d=this.a[b[c]];a.push([d.key,v(this,d)]);}return new w(a)};r.prototype.entries=r.prototype.entries;r.prototype.keys=function(){var a=[],b=u(this);b.sort();for(var c=0;c<b.length;c++)a.push(this.a[b[c]].key);return new w(a)};
		r.prototype.keys=r.prototype.keys;r.prototype.values=function(){var a=[],b=u(this);b.sort();for(var c=0;c<b.length;c++)a.push(v(this,this.a[b[c]]));return new w(a)};r.prototype.values=r.prototype.values;r.prototype.forEach=function(a,b){var c=u(this);c.sort();for(var d=0;d<c.length;d++){var f=this.a[c[d]];a.call(b,v(this,f),f.key,this);}};r.prototype.forEach=r.prototype.forEach;
		r.prototype.set=function(a,b){var c=new wa(a);this.b?(c.a=b,c.value=b.g()):c.value=b;this.a[a.toString()]=c;this.arrClean=false;return this};r.prototype.set=r.prototype.set;function v(a,b){return a.b?(b.a||(b.a=new a.b(b.value)),b.a):b.value}r.prototype.get=function(a){if(a=this.a[a.toString()])return v(this,a)};r.prototype.get=r.prototype.get;r.prototype.has=function(a){return a.toString()in this.a};r.prototype.has=r.prototype.has;
		r.prototype.Jc=function(a,b,c,d,f){var h=u(this);h.sort();for(var m=0;m<h.length;m++){var t=this.a[h[m]];b.Va(a);c.call(b,1,t.key);this.b?d.call(b,2,v(this,t),f):d.call(b,2,t.value);b.Ya();}};r.prototype.serializeBinary=r.prototype.Jc;r.deserializeBinary=function(a,b,c,d,f,h,m){for(;b.oa()&&!b.bb();){var t=b.c;1==t?h=c.call(b):2==t&&(a.b?(n(f),m||(m=new a.b),d.call(b,m,f)):m=d.call(b));}n(void 0!=h);n(void 0!=m);a.set(h,m);};
		function u(a){a=a.a;var b=[],c;for(c in a)Object.prototype.hasOwnProperty.call(a,c)&&b.push(c);return b}function wa(a,b){this.key=a;this.value=b;this.a=void 0;}function xa(a){if(8192>=a.length)return String.fromCharCode.apply(null,a);for(var b="",c=0;c<a.length;c+=8192)b+=String.fromCharCode.apply(null,ra(a,c,c+8192));return b}var ya={"\x00":"\\0","\b":"\\b","\f":"\\f","\n":"\\n","\r":"\\r","\t":"\\t","\x0B":"\\x0B",'"':'\\"',"\\":"\\\\","<":"\\u003C"},za={"'":"\\'"};var Aa={},x=null;function Ba(a,b){ void 0===b&&(b=0);Ca();b=Aa[b];for(var c=[],d=0;d<a.length;d+=3){var f=a[d],h=d+1<a.length,m=h?a[d+1]:0,t=d+2<a.length,B=t?a[d+2]:0,M=f>>2;f=(f&3)<<4|m>>4;m=(m&15)<<2|B>>6;B&=63;t||(B=64,h||(m=64));c.push(b[M],b[f],b[m]||"",b[B]||"");}return c.join("")}function Da(a){var b=a.length,c=3*b/4;c%3?c=Math.floor(c):-1!="=.".indexOf(a[b-1])&&(c=-1!="=.".indexOf(a[b-2])?c-2:c-1);var d=new Uint8Array(c),f=0;Ea(a,function(h){d[f++]=h;});return d.subarray(0,f)}
		function Ea(a,b){function c(B){for(;d<a.length;){var M=a.charAt(d++),La=x[M];if(null!=La)return La;if(!/^[\s\xa0]*$/.test(M))throw Error("Unknown base64 encoding at char: "+M);}return B}Ca();for(var d=0;;){var f=c(-1),h=c(0),m=c(64),t=c(64);if(64===t&&-1===f)break;b(f<<2|h>>4);64!=m&&(b(h<<4&240|m>>2),64!=t&&b(m<<6&192|t));}}
		function Ca(){if(!x){x={};for(var a="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".split(""),b=["+/=","+/","-_=","-_.","-_"],c=0;5>c;c++){var d=a.concat(b[c].split(""));Aa[c]=d;for(var f=0;f<d.length;f++){var h=d[f];void 0===x[h]&&(x[h]=f);}}}}g("jspb.ConstBinaryMessage",function(){},void 0);g("jspb.BinaryMessage",function(){},void 0);g("jspb.BinaryConstants.FieldType",{yb:-1,ee:1,FLOAT:2,ke:3,te:4,je:5,xb:6,wb:7,BOOL:8,re:9,ie:10,le:11,ce:12,se:13,ge:14,me:15,ne:16,oe:17,pe:18,he:30,ve:31},void 0);g("jspb.BinaryConstants.WireType",{yb:-1,ue:0,xb:1,de:2,qe:3,fe:4,wb:5},void 0);
		g("jspb.BinaryConstants.FieldTypeToWireType",function(a){switch(a){case 5:case 3:case 13:case 4:case 17:case 18:case 8:case 14:case 31:return 0;case 1:case 6:case 16:case 30:return 1;case 9:case 11:case 12:return 2;case 2:case 7:case 15:return 5;default:return  -1}},void 0);g("jspb.BinaryConstants.INVALID_FIELD_NUMBER",-1,void 0);g("jspb.BinaryConstants.FLOAT32_EPS",1.401298464324817E-45,void 0);g("jspb.BinaryConstants.FLOAT32_MIN",1.1754943508222875E-38,void 0);
		g("jspb.BinaryConstants.FLOAT32_MAX",3.4028234663852886E38,void 0);g("jspb.BinaryConstants.FLOAT64_EPS",4.9E-324,void 0);g("jspb.BinaryConstants.FLOAT64_MIN",2.2250738585072014E-308,void 0);g("jspb.BinaryConstants.FLOAT64_MAX",1.7976931348623157E308,void 0);g("jspb.BinaryConstants.TWO_TO_20",1048576,void 0);g("jspb.BinaryConstants.TWO_TO_23",8388608,void 0);g("jspb.BinaryConstants.TWO_TO_31",2147483648,void 0);g("jspb.BinaryConstants.TWO_TO_32",4294967296,void 0);
		g("jspb.BinaryConstants.TWO_TO_52",4503599627370496,void 0);g("jspb.BinaryConstants.TWO_TO_63",0x7fffffffffffffff,void 0);g("jspb.BinaryConstants.TWO_TO_64",1.8446744073709552E19,void 0);g("jspb.BinaryConstants.ZERO_HASH","\x00\x00\x00\x00\x00\x00\x00\x00",void 0);var y=0,z=0;g("jspb.utils.getSplit64Low",function(){return y},void 0);g("jspb.utils.getSplit64High",function(){return z},void 0);function Fa(a){var b=a>>>0;a=Math.floor((a-b)/4294967296)>>>0;y=b;z=a;}g("jspb.utils.splitUint64",Fa,void 0);function A(a){var b=0>a;a=Math.abs(a);var c=a>>>0;a=Math.floor((a-c)/4294967296);a>>>=0;b&&(a=~a>>>0,c=(~c>>>0)+1,4294967295<c&&(c=0,a++,4294967295<a&&(a=0)));y=c;z=a;}g("jspb.utils.splitInt64",A,void 0);
		function Ga(a){var b=0>a;a=2*Math.abs(a);Fa(a);a=y;var c=z;b&&(0==a?0==c?c=a=4294967295:(c--,a=4294967295):a--);y=a;z=c;}g("jspb.utils.splitZigzag64",Ga,void 0);
		function Ha(a){var b=0>a?1:0;a=b?-a:a;if(0===a)0<1/a?y=z=0:(z=0,y=2147483648);else if(isNaN(a))z=0,y=2147483647;else if(3.4028234663852886E38<a)z=0,y=(b<<31|2139095040)>>>0;else if(1.1754943508222875E-38>a)a=Math.round(a/Math.pow(2,-149)),z=0,y=(b<<31|a)>>>0;else {var c=Math.floor(Math.log(a)/Math.LN2);a*=Math.pow(2,-c);a=Math.round(8388608*a);16777216<=a&&++c;z=0;y=(b<<31|c+127<<23|a&8388607)>>>0;}}g("jspb.utils.splitFloat32",Ha,void 0);
		function Ia(a){var b=0>a?1:0;a=b?-a:a;if(0===a)z=0<1/a?0:2147483648,y=0;else if(isNaN(a))z=2147483647,y=4294967295;else if(1.7976931348623157E308<a)z=(b<<31|2146435072)>>>0,y=0;else if(2.2250738585072014E-308>a)a/=Math.pow(2,-1074),z=(b<<31|a/4294967296)>>>0,y=a>>>0;else {var c=a,d=0;if(2<=c)for(;2<=c&&1023>d;)d++,c/=2;else for(;1>c&&-1022<d;)c*=2,d--;a*=Math.pow(2,-d);z=(b<<31|d+1023<<20|1048576*a&1048575)>>>0;y=4503599627370496*a>>>0;}}g("jspb.utils.splitFloat64",Ia,void 0);
		function C(a){var b=a.charCodeAt(4),c=a.charCodeAt(5),d=a.charCodeAt(6),f=a.charCodeAt(7);y=a.charCodeAt(0)+(a.charCodeAt(1)<<8)+(a.charCodeAt(2)<<16)+(a.charCodeAt(3)<<24)>>>0;z=b+(c<<8)+(d<<16)+(f<<24)>>>0;}g("jspb.utils.splitHash64",C,void 0);function D(a,b){return 4294967296*b+(a>>>0)}g("jspb.utils.joinUint64",D,void 0);function E(a,b){var c=b&2147483648;c&&(a=~a+1>>>0,b=~b>>>0,0==a&&(b=b+1>>>0));a=D(a,b);return c?-a:a}g("jspb.utils.joinInt64",E,void 0);
		function Ja(a,b,c){var d=b>>31;return c(a<<1^d,(b<<1|a>>>31)^d)}g("jspb.utils.toZigzag64",Ja,void 0);function Ka(a,b){return Ma(a,b,E)}g("jspb.utils.joinZigzag64",Ka,void 0);function Ma(a,b,c){var d=-(a&1);return c((a>>>1|b<<31)^d,b>>>1^d)}g("jspb.utils.fromZigzag64",Ma,void 0);function Na(a){var b=2*(a>>31)+1,c=a>>>23&255;a&=8388607;return 255==c?a?NaN:Infinity*b:0==c?b*Math.pow(2,-149)*a:b*Math.pow(2,c-150)*(a+Math.pow(2,23))}g("jspb.utils.joinFloat32",Na,void 0);
		function Oa(a,b){var c=2*(b>>31)+1,d=b>>>20&2047;a=4294967296*(b&1048575)+a;return 2047==d?a?NaN:Infinity*c:0==d?c*Math.pow(2,-1074)*a:c*Math.pow(2,d-1075)*(a+4503599627370496)}g("jspb.utils.joinFloat64",Oa,void 0);function Pa(a,b){return String.fromCharCode(a>>>0&255,a>>>8&255,a>>>16&255,a>>>24&255,b>>>0&255,b>>>8&255,b>>>16&255,b>>>24&255)}g("jspb.utils.joinHash64",Pa,void 0);g("jspb.utils.DIGITS","0123456789abcdef".split(""),void 0);
		function F(a,b){function c(f,h){f=f?String(f):"";return h?"0000000".slice(f.length)+f:f}if(2097151>=b)return ""+D(a,b);var d=(a>>>24|b<<8)>>>0&16777215;b=b>>16&65535;a=(a&16777215)+6777216*d+6710656*b;d+=8147497*b;b*=2;1E7<=a&&(d+=Math.floor(a/1E7),a%=1E7);1E7<=d&&(b+=Math.floor(d/1E7),d%=1E7);return c(b,0)+c(d,b)+c(a,1)}g("jspb.utils.joinUnsignedDecimalString",F,void 0);function G(a,b){var c=b&2147483648;c&&(a=~a+1>>>0,b=~b+(0==a?1:0)>>>0);a=F(a,b);return c?"-"+a:a}
		g("jspb.utils.joinSignedDecimalString",G,void 0);function Qa(a,b){C(a);a=y;var c=z;return b?G(a,c):F(a,c)}g("jspb.utils.hash64ToDecimalString",Qa,void 0);g("jspb.utils.hash64ArrayToDecimalStrings",function(a,b){for(var c=Array(a.length),d=0;d<a.length;d++)c[d]=Qa(a[d],b);return c},void 0);
		function H(a){function b(m,t){for(var B=0;8>B&&(1!==m||0<t);B++)t=m*f[B]+t,f[B]=t&255,t>>>=8;}function c(){for(var m=0;8>m;m++)f[m]=~f[m]&255;}n(0<a.length);var d=false;"-"===a[0]&&(d=true,a=a.slice(1));for(var f=[0,0,0,0,0,0,0,0],h=0;h<a.length;h++)b(10,a.charCodeAt(h)-48);d&&(c(),b(1,1));return xa(f)}g("jspb.utils.decimalStringToHash64",H,void 0);g("jspb.utils.splitDecimalString",function(a){C(H(a));},void 0);function Ra(a){return String.fromCharCode(10>a?48+a:87+a)}
		function Sa(a){return 97<=a?a-97+10:a-48}g("jspb.utils.hash64ToHexString",function(a){var b=Array(18);b[0]="0";b[1]="x";for(var c=0;8>c;c++){var d=a.charCodeAt(7-c);b[2*c+2]=Ra(d>>4);b[2*c+3]=Ra(d&15);}return b.join("")},void 0);g("jspb.utils.hexStringToHash64",function(a){a=a.toLowerCase();n(18==a.length);n("0"==a[0]);n("x"==a[1]);for(var b="",c=0;8>c;c++)b=String.fromCharCode(16*Sa(a.charCodeAt(2*c+2))+Sa(a.charCodeAt(2*c+3)))+b;return b},void 0);
		g("jspb.utils.hash64ToNumber",function(a,b){C(a);a=y;var c=z;return b?E(a,c):D(a,c)},void 0);g("jspb.utils.numberToHash64",function(a){A(a);return Pa(y,z)},void 0);g("jspb.utils.countVarints",function(a,b,c){for(var d=0,f=b;f<c;f++)d+=a[f]>>7;return c-b-d},void 0);
		g("jspb.utils.countVarintFields",function(a,b,c,d){var f=0;d*=8;if(128>d)for(;b<c&&a[b++]==d;)for(f++;;){var h=a[b++];if(0==(h&128))break}else for(;b<c;){for(h=d;128<h;){if(a[b]!=(h&127|128))return f;b++;h>>=7;}if(a[b++]!=h)break;for(f++;h=a[b++],0!=(h&128););}return f},void 0);function Ta(a,b,c,d,f){var h=0;if(128>d)for(;b<c&&a[b++]==d;)h++,b+=f;else for(;b<c;){for(var m=d;128<m;){if(a[b++]!=(m&127|128))return h;m>>=7;}if(a[b++]!=m)break;h++;b+=f;}return h}
		g("jspb.utils.countFixed32Fields",function(a,b,c,d){return Ta(a,b,c,8*d+5,4)},void 0);g("jspb.utils.countFixed64Fields",function(a,b,c,d){return Ta(a,b,c,8*d+1,8)},void 0);g("jspb.utils.countDelimitedFields",function(a,b,c,d){var f=0;for(d=8*d+2;b<c;){for(var h=d;128<h;){if(a[b++]!=(h&127|128))return f;h>>=7;}if(a[b++]!=h)break;f++;for(var m=0,t=1;h=a[b++],m+=(h&127)*t,t*=128,0!=(h&128););b+=m;}return f},void 0);
		g("jspb.utils.debugBytesToTextFormat",function(a){var b='"';if(a){a=Ua(a);for(var c=0;c<a.length;c++)b+="\\x",16>a[c]&&(b+="0"),b+=a[c].toString(16);}return b+'"'},void 0);
		g("jspb.utils.debugScalarToTextFormat",function(a){if("string"===typeof a){a=String(a);for(var b=['"'],c=0;c<a.length;c++){var d=a.charAt(c),f=d.charCodeAt(0),h=c+1,m;if(!(m=ya[d])){if(!(31<f&&127>f))if(f=d,f in za)d=za[f];else if(f in ya)d=za[f]=ya[f];else {m=f.charCodeAt(0);if(31<m&&127>m)d=f;else {if(256>m){if(d="\\x",16>m||256<m)d+="0";}else d="\\u",4096>m&&(d+="0");d+=m.toString(16).toUpperCase();}d=za[f]=d;}m=d;}b[h]=m;}b.push('"');a=b.join("");}else a=a.toString();return a},void 0);
		g("jspb.utils.stringToByteArray",function(a){for(var b=new Uint8Array(a.length),c=0;c<a.length;c++){var d=a.charCodeAt(c);if(255<d)throw Error("Conversion error: string contains codepoint outside of byte range");b[c]=d;}return b},void 0);
		function Ua(a){if(a.constructor===Uint8Array)return a;if(a.constructor===ArrayBuffer)return new Uint8Array(a);if(a.constructor===Array)return new Uint8Array(a);if(a.constructor===String)return Da(a);if(a instanceof Uint8Array)return new Uint8Array(a.buffer,a.byteOffset,a.byteLength);p("Type not convertible to Uint8Array.");return new Uint8Array(0)}g("jspb.utils.byteSourceToUint8Array",Ua,void 0);function I(a,b,c){this.b=null;this.a=this.c=this.h=0;this.v=false;a&&this.H(a,b,c);}g("jspb.BinaryDecoder",I,void 0);var Va=[];I.getInstanceCacheLength=function(){return Va.length};function Wa(a,b,c){if(Va.length){var d=Va.pop();a&&d.H(a,b,c);return d}return new I(a,b,c)}I.alloc=Wa;I.prototype.Ca=function(){this.clear();100>Va.length&&Va.push(this);};I.prototype.free=I.prototype.Ca;I.prototype.clone=function(){return Wa(this.b,this.h,this.c-this.h)};I.prototype.clone=I.prototype.clone;
		I.prototype.clear=function(){this.b=null;this.a=this.c=this.h=0;this.v=false;};I.prototype.clear=I.prototype.clear;I.prototype.Y=function(){return this.b};I.prototype.getBuffer=I.prototype.Y;I.prototype.H=function(a,b,c){this.b=Ua(a);this.h=void 0!==b?b:0;this.c=void 0!==c?this.h+c:this.b.length;this.a=this.h;};I.prototype.setBlock=I.prototype.H;I.prototype.Db=function(){return this.c};I.prototype.getEnd=I.prototype.Db;I.prototype.setEnd=function(a){this.c=a;};I.prototype.setEnd=I.prototype.setEnd;
		I.prototype.reset=function(){this.a=this.h;};I.prototype.reset=I.prototype.reset;I.prototype.B=function(){return this.a};I.prototype.getCursor=I.prototype.B;I.prototype.Ma=function(a){this.a=a;};I.prototype.setCursor=I.prototype.Ma;I.prototype.advance=function(a){this.a+=a;n(this.a<=this.c);};I.prototype.advance=I.prototype.advance;I.prototype.ya=function(){return this.a==this.c};I.prototype.atEnd=I.prototype.ya;I.prototype.Qb=function(){return this.a>this.c};I.prototype.pastEnd=I.prototype.Qb;
		I.prototype.getError=function(){return this.v||0>this.a||this.a>this.c};I.prototype.getError=I.prototype.getError;I.prototype.w=function(a){for(var b=128,c=0,d=0,f=0;4>f&&128<=b;f++)b=this.b[this.a++],c|=(b&127)<<7*f;128<=b&&(b=this.b[this.a++],c|=(b&127)<<28,d|=(b&127)>>4);if(128<=b)for(f=0;5>f&&128<=b;f++)b=this.b[this.a++],d|=(b&127)<<7*f+3;if(128>b)return a(c>>>0,d>>>0);p("Failed to read varint, encoding is invalid.");this.v=true;};I.prototype.readSplitVarint64=I.prototype.w;
		I.prototype.ea=function(a){return this.w(function(b,c){return Ma(b,c,a)})};I.prototype.readSplitZigzagVarint64=I.prototype.ea;I.prototype.ta=function(a){var b=this.b,c=this.a;this.a+=8;for(var d=0,f=0,h=c+7;h>=c;h--)d=d<<8|b[h],f=f<<8|b[h+4];return a(d,f)};I.prototype.readSplitFixed64=I.prototype.ta;I.prototype.kb=function(){for(;this.b[this.a]&128;)this.a++;this.a++;};I.prototype.skipVarint=I.prototype.kb;I.prototype.mb=function(a){for(;128<a;)this.a--,a>>>=7;this.a--;};I.prototype.unskipVarint=I.prototype.mb;
		I.prototype.o=function(){var a=this.b;var b=a[this.a];var c=b&127;if(128>b)return this.a+=1,n(this.a<=this.c),c;b=a[this.a+1];c|=(b&127)<<7;if(128>b)return this.a+=2,n(this.a<=this.c),c;b=a[this.a+2];c|=(b&127)<<14;if(128>b)return this.a+=3,n(this.a<=this.c),c;b=a[this.a+3];c|=(b&127)<<21;if(128>b)return this.a+=4,n(this.a<=this.c),c;b=a[this.a+4];c|=(b&15)<<28;if(128>b)return this.a+=5,n(this.a<=this.c),c>>>0;this.a+=5;128<=a[this.a++]&&128<=a[this.a++]&&128<=a[this.a++]&&128<=a[this.a++]&&128<=
		a[this.a++]&&n(false);n(this.a<=this.c);return c};I.prototype.readUnsignedVarint32=I.prototype.o;I.prototype.da=function(){return ~~this.o()};I.prototype.readSignedVarint32=I.prototype.da;I.prototype.O=function(){return this.o().toString()};I.prototype.Ea=function(){return this.da().toString()};I.prototype.readSignedVarint32String=I.prototype.Ea;I.prototype.Ia=function(){var a=this.o();return a>>>1^-(a&1)};I.prototype.readZigzagVarint32=I.prototype.Ia;I.prototype.Ga=function(){return this.w(D)};
		I.prototype.readUnsignedVarint64=I.prototype.Ga;I.prototype.Ha=function(){return this.w(F)};I.prototype.readUnsignedVarint64String=I.prototype.Ha;I.prototype.sa=function(){return this.w(E)};I.prototype.readSignedVarint64=I.prototype.sa;I.prototype.Fa=function(){return this.w(G)};I.prototype.readSignedVarint64String=I.prototype.Fa;I.prototype.Ja=function(){return this.w(Ka)};I.prototype.readZigzagVarint64=I.prototype.Ja;I.prototype.fb=function(){return this.ea(Pa)};
		I.prototype.readZigzagVarintHash64=I.prototype.fb;I.prototype.Ka=function(){return this.ea(G)};I.prototype.readZigzagVarint64String=I.prototype.Ka;I.prototype.Gc=function(){var a=this.b[this.a];this.a+=1;n(this.a<=this.c);return a};I.prototype.readUint8=I.prototype.Gc;I.prototype.Ec=function(){var a=this.b[this.a],b=this.b[this.a+1];this.a+=2;n(this.a<=this.c);return a<<0|b<<8};I.prototype.readUint16=I.prototype.Ec;
		I.prototype.m=function(){var a=this.b[this.a],b=this.b[this.a+1],c=this.b[this.a+2],d=this.b[this.a+3];this.a+=4;n(this.a<=this.c);return (a<<0|b<<8|c<<16|d<<24)>>>0};I.prototype.readUint32=I.prototype.m;I.prototype.ga=function(){var a=this.m(),b=this.m();return D(a,b)};I.prototype.readUint64=I.prototype.ga;I.prototype.ha=function(){var a=this.m(),b=this.m();return F(a,b)};I.prototype.readUint64String=I.prototype.ha;
		I.prototype.Xb=function(){var a=this.b[this.a];this.a+=1;n(this.a<=this.c);return a<<24>>24};I.prototype.readInt8=I.prototype.Xb;I.prototype.Vb=function(){var a=this.b[this.a],b=this.b[this.a+1];this.a+=2;n(this.a<=this.c);return (a<<0|b<<8)<<16>>16};I.prototype.readInt16=I.prototype.Vb;I.prototype.P=function(){var a=this.b[this.a],b=this.b[this.a+1],c=this.b[this.a+2],d=this.b[this.a+3];this.a+=4;n(this.a<=this.c);return a<<0|b<<8|c<<16|d<<24};I.prototype.readInt32=I.prototype.P;
		I.prototype.ba=function(){var a=this.m(),b=this.m();return E(a,b)};I.prototype.readInt64=I.prototype.ba;I.prototype.ca=function(){var a=this.m(),b=this.m();return G(a,b)};I.prototype.readInt64String=I.prototype.ca;I.prototype.aa=function(){var a=this.m();return Na(a)};I.prototype.readFloat=I.prototype.aa;I.prototype.Z=function(){var a=this.m(),b=this.m();return Oa(a,b)};I.prototype.readDouble=I.prototype.Z;I.prototype.pa=function(){return !!this.b[this.a++]};I.prototype.readBool=I.prototype.pa;
		I.prototype.ra=function(){return this.da()};I.prototype.readEnum=I.prototype.ra;
		I.prototype.fa=function(a){var b=this.b,c=this.a;a=c+a;for(var d=[],f="";c<a;){var h=b[c++];if(128>h)d.push(h);else if(192>h)continue;else if(224>h){var m=b[c++];d.push((h&31)<<6|m&63);}else if(240>h){m=b[c++];var t=b[c++];d.push((h&15)<<12|(m&63)<<6|t&63);}else if(248>h){m=b[c++];t=b[c++];var B=b[c++];h=(h&7)<<18|(m&63)<<12|(t&63)<<6|B&63;h-=65536;d.push((h>>10&1023)+55296,(h&1023)+56320);}8192<=d.length&&(f+=String.fromCharCode.apply(null,d),d.length=0);}f+=xa(d);this.a=c;return f};
		I.prototype.readString=I.prototype.fa;I.prototype.Dc=function(){var a=this.o();return this.fa(a)};I.prototype.readStringWithLength=I.prototype.Dc;I.prototype.qa=function(a){if(0>a||this.a+a>this.b.length)return this.v=true,p("Invalid byte length!"),new Uint8Array(0);var b=this.b.subarray(this.a,this.a+a);this.a+=a;n(this.a<=this.c);return b};I.prototype.readBytes=I.prototype.qa;I.prototype.ia=function(){return this.w(Pa)};I.prototype.readVarintHash64=I.prototype.ia;
		I.prototype.$=function(){var a=this.b,b=this.a,c=a[b],d=a[b+1],f=a[b+2],h=a[b+3],m=a[b+4],t=a[b+5],B=a[b+6];a=a[b+7];this.a+=8;return String.fromCharCode(c,d,f,h,m,t,B,a)};I.prototype.readFixedHash64=I.prototype.$;function J(a,b,c){this.a=Wa(a,b,c);this.O=this.a.B();this.b=this.c=-1;this.h=false;this.v=null;}g("jspb.BinaryReader",J,void 0);var K=[];J.clearInstanceCache=function(){K=[];};J.getInstanceCacheLength=function(){return K.length};function Xa(a,b,c){if(K.length){var d=K.pop();a&&d.a.H(a,b,c);return d}return new J(a,b,c)}J.alloc=Xa;J.prototype.zb=Xa;J.prototype.alloc=J.prototype.zb;J.prototype.Ca=function(){this.a.clear();this.b=this.c=-1;this.h=false;this.v=null;100>K.length&&K.push(this);};
		J.prototype.free=J.prototype.Ca;J.prototype.Fb=function(){return this.O};J.prototype.getFieldCursor=J.prototype.Fb;J.prototype.B=function(){return this.a.B()};J.prototype.getCursor=J.prototype.B;J.prototype.Y=function(){return this.a.Y()};J.prototype.getBuffer=J.prototype.Y;J.prototype.Hb=function(){return this.c};J.prototype.getFieldNumber=J.prototype.Hb;J.prototype.Lb=function(){return this.b};J.prototype.getWireType=J.prototype.Lb;J.prototype.Mb=function(){return 2==this.b};
		J.prototype.isDelimited=J.prototype.Mb;J.prototype.bb=function(){return 4==this.b};J.prototype.isEndGroup=J.prototype.bb;J.prototype.getError=function(){return this.h||this.a.getError()};J.prototype.getError=J.prototype.getError;J.prototype.H=function(a,b,c){this.a.H(a,b,c);this.b=this.c=-1;};J.prototype.setBlock=J.prototype.H;J.prototype.reset=function(){this.a.reset();this.b=this.c=-1;};J.prototype.reset=J.prototype.reset;J.prototype.advance=function(a){this.a.advance(a);};J.prototype.advance=J.prototype.advance;
		J.prototype.oa=function(){if(this.a.ya())return  false;if(this.getError())return p("Decoder hit an error"),false;this.O=this.a.B();var a=this.a.o(),b=a>>>3;a&=7;if(0!=a&&5!=a&&1!=a&&2!=a&&3!=a&&4!=a)return p("Invalid wire type: %s (at position %s)",a,this.O),this.h=true,false;this.c=b;this.b=a;return  true};J.prototype.nextField=J.prototype.oa;J.prototype.Oa=function(){this.a.mb(this.c<<3|this.b);};J.prototype.unskipHeader=J.prototype.Oa;
		J.prototype.Lc=function(){var a=this.c;for(this.Oa();this.oa()&&this.c==a;)this.C();this.a.ya()||this.Oa();};J.prototype.skipMatchingFields=J.prototype.Lc;J.prototype.lb=function(){0!=this.b?(p("Invalid wire type for skipVarintField"),this.C()):this.a.kb();};J.prototype.skipVarintField=J.prototype.lb;J.prototype.gb=function(){if(2!=this.b)p("Invalid wire type for skipDelimitedField"),this.C();else {var a=this.a.o();this.a.advance(a);}};J.prototype.skipDelimitedField=J.prototype.gb;
		J.prototype.hb=function(){5!=this.b?(p("Invalid wire type for skipFixed32Field"),this.C()):this.a.advance(4);};J.prototype.skipFixed32Field=J.prototype.hb;J.prototype.ib=function(){1!=this.b?(p("Invalid wire type for skipFixed64Field"),this.C()):this.a.advance(8);};J.prototype.skipFixed64Field=J.prototype.ib;J.prototype.jb=function(){var a=this.c;do{if(!this.oa()){p("Unmatched start-group tag: stream EOF");this.h=true;break}if(4==this.b){this.c!=a&&(p("Unmatched end-group tag"),this.h=true);break}this.C();}while(1)};
		J.prototype.skipGroup=J.prototype.jb;J.prototype.C=function(){switch(this.b){case 0:this.lb();break;case 1:this.ib();break;case 2:this.gb();break;case 5:this.hb();break;case 3:this.jb();break;default:p("Invalid wire encoding for field.");}};J.prototype.skipField=J.prototype.C;J.prototype.Hc=function(a,b){null===this.v&&(this.v={});n(!this.v[a]);this.v[a]=b;};J.prototype.registerReadCallback=J.prototype.Hc;J.prototype.Ic=function(a){n(null!==this.v);a=this.v[a];n(a);return a(this)};
		J.prototype.runReadCallback=J.prototype.Ic;J.prototype.Yb=function(a,b){n(2==this.b);var c=this.a.c,d=this.a.o();d=this.a.B()+d;this.a.setEnd(d);b(a,this);this.a.Ma(d);this.a.setEnd(c);};J.prototype.readMessage=J.prototype.Yb;J.prototype.Ub=function(a,b,c){n(3==this.b);n(this.c==a);c(b,this);this.h||4==this.b||(p("Group submessage did not end with an END_GROUP tag"),this.h=true);};J.prototype.readGroup=J.prototype.Ub;
		J.prototype.Gb=function(){n(2==this.b);var a=this.a.o(),b=this.a.B(),c=b+a;a=Wa(this.a.Y(),b,a);this.a.Ma(c);return a};J.prototype.getFieldDecoder=J.prototype.Gb;J.prototype.P=function(){n(0==this.b);return this.a.da()};J.prototype.readInt32=J.prototype.P;J.prototype.Wb=function(){n(0==this.b);return this.a.Ea()};J.prototype.readInt32String=J.prototype.Wb;J.prototype.ba=function(){n(0==this.b);return this.a.sa()};J.prototype.readInt64=J.prototype.ba;J.prototype.ca=function(){n(0==this.b);return this.a.Fa()};
		J.prototype.readInt64String=J.prototype.ca;J.prototype.m=function(){n(0==this.b);return this.a.o()};J.prototype.readUint32=J.prototype.m;J.prototype.Fc=function(){n(0==this.b);return this.a.O()};J.prototype.readUint32String=J.prototype.Fc;J.prototype.ga=function(){n(0==this.b);return this.a.Ga()};J.prototype.readUint64=J.prototype.ga;J.prototype.ha=function(){n(0==this.b);return this.a.Ha()};J.prototype.readUint64String=J.prototype.ha;J.prototype.zc=function(){n(0==this.b);return this.a.Ia()};
		J.prototype.readSint32=J.prototype.zc;J.prototype.Ac=function(){n(0==this.b);return this.a.Ja()};J.prototype.readSint64=J.prototype.Ac;J.prototype.Bc=function(){n(0==this.b);return this.a.Ka()};J.prototype.readSint64String=J.prototype.Bc;J.prototype.Rb=function(){n(5==this.b);return this.a.m()};J.prototype.readFixed32=J.prototype.Rb;J.prototype.Sb=function(){n(1==this.b);return this.a.ga()};J.prototype.readFixed64=J.prototype.Sb;J.prototype.Tb=function(){n(1==this.b);return this.a.ha()};
		J.prototype.readFixed64String=J.prototype.Tb;J.prototype.vc=function(){n(5==this.b);return this.a.P()};J.prototype.readSfixed32=J.prototype.vc;J.prototype.wc=function(){n(5==this.b);return this.a.P().toString()};J.prototype.readSfixed32String=J.prototype.wc;J.prototype.xc=function(){n(1==this.b);return this.a.ba()};J.prototype.readSfixed64=J.prototype.xc;J.prototype.yc=function(){n(1==this.b);return this.a.ca()};J.prototype.readSfixed64String=J.prototype.yc;
		J.prototype.aa=function(){n(5==this.b);return this.a.aa()};J.prototype.readFloat=J.prototype.aa;J.prototype.Z=function(){n(1==this.b);return this.a.Z()};J.prototype.readDouble=J.prototype.Z;J.prototype.pa=function(){n(0==this.b);return !!this.a.o()};J.prototype.readBool=J.prototype.pa;J.prototype.ra=function(){n(0==this.b);return this.a.sa()};J.prototype.readEnum=J.prototype.ra;J.prototype.fa=function(){n(2==this.b);var a=this.a.o();return this.a.fa(a)};J.prototype.readString=J.prototype.fa;
		J.prototype.qa=function(){n(2==this.b);var a=this.a.o();return this.a.qa(a)};J.prototype.readBytes=J.prototype.qa;J.prototype.ia=function(){n(0==this.b);return this.a.ia()};J.prototype.readVarintHash64=J.prototype.ia;J.prototype.Cc=function(){n(0==this.b);return this.a.fb()};J.prototype.readSintHash64=J.prototype.Cc;J.prototype.w=function(a){n(0==this.b);return this.a.w(a)};J.prototype.readSplitVarint64=J.prototype.w;
		J.prototype.ea=function(a){n(0==this.b);return this.a.w(function(b,c){return Ma(b,c,a)})};J.prototype.readSplitZigzagVarint64=J.prototype.ea;J.prototype.$=function(){n(1==this.b);return this.a.$()};J.prototype.readFixedHash64=J.prototype.$;J.prototype.ta=function(a){n(1==this.b);return this.a.ta(a)};J.prototype.readSplitFixed64=J.prototype.ta;function L(a,b){n(2==a.b);var c=a.a.o();c=a.a.B()+c;for(var d=[];a.a.B()<c;)d.push(b.call(a.a));return d}J.prototype.gc=function(){return L(this,this.a.da)};
		J.prototype.readPackedInt32=J.prototype.gc;J.prototype.hc=function(){return L(this,this.a.Ea)};J.prototype.readPackedInt32String=J.prototype.hc;J.prototype.ic=function(){return L(this,this.a.sa)};J.prototype.readPackedInt64=J.prototype.ic;J.prototype.jc=function(){return L(this,this.a.Fa)};J.prototype.readPackedInt64String=J.prototype.jc;J.prototype.qc=function(){return L(this,this.a.o)};J.prototype.readPackedUint32=J.prototype.qc;J.prototype.rc=function(){return L(this,this.a.O)};
		J.prototype.readPackedUint32String=J.prototype.rc;J.prototype.sc=function(){return L(this,this.a.Ga)};J.prototype.readPackedUint64=J.prototype.sc;J.prototype.tc=function(){return L(this,this.a.Ha)};J.prototype.readPackedUint64String=J.prototype.tc;J.prototype.nc=function(){return L(this,this.a.Ia)};J.prototype.readPackedSint32=J.prototype.nc;J.prototype.oc=function(){return L(this,this.a.Ja)};J.prototype.readPackedSint64=J.prototype.oc;J.prototype.pc=function(){return L(this,this.a.Ka)};
		J.prototype.readPackedSint64String=J.prototype.pc;J.prototype.bc=function(){return L(this,this.a.m)};J.prototype.readPackedFixed32=J.prototype.bc;J.prototype.cc=function(){return L(this,this.a.ga)};J.prototype.readPackedFixed64=J.prototype.cc;J.prototype.dc=function(){return L(this,this.a.ha)};J.prototype.readPackedFixed64String=J.prototype.dc;J.prototype.kc=function(){return L(this,this.a.P)};J.prototype.readPackedSfixed32=J.prototype.kc;J.prototype.lc=function(){return L(this,this.a.ba)};
		J.prototype.readPackedSfixed64=J.prototype.lc;J.prototype.mc=function(){return L(this,this.a.ca)};J.prototype.readPackedSfixed64String=J.prototype.mc;J.prototype.fc=function(){return L(this,this.a.aa)};J.prototype.readPackedFloat=J.prototype.fc;J.prototype.$b=function(){return L(this,this.a.Z)};J.prototype.readPackedDouble=J.prototype.$b;J.prototype.Zb=function(){return L(this,this.a.pa)};J.prototype.readPackedBool=J.prototype.Zb;J.prototype.ac=function(){return L(this,this.a.ra)};
		J.prototype.readPackedEnum=J.prototype.ac;J.prototype.uc=function(){return L(this,this.a.ia)};J.prototype.readPackedVarintHash64=J.prototype.uc;J.prototype.ec=function(){return L(this,this.a.$)};J.prototype.readPackedFixedHash64=J.prototype.ec;function Ya(a,b,c,d,f){this.ma=a;this.Ba=b;this.la=c;this.Na=d;this.na=f;}g("jspb.ExtensionFieldInfo",Ya,void 0);function Za(a,b,c,d,f,h){this.Za=a;this.za=b;this.Aa=c;this.Wa=d;this.Ab=f;this.Nb=h;}g("jspb.ExtensionFieldBinaryInfo",Za,void 0);Ya.prototype.F=function(){return !!this.la};Ya.prototype.isMessageType=Ya.prototype.F;function N(){}g("jspb.Message",N,void 0);N.GENERATE_TO_OBJECT=true;N.GENERATE_FROM_OBJECT=true;var $a="function"==typeof Uint8Array;N.prototype.Ib=function(){return this.b};
		N.prototype.getJsPbMessageId=N.prototype.Ib;
		N.initialize=function(a,b,c,d,f,h){a.f=null;b||(b=c?[c]:[]);a.b=c?String(c):void 0;a.D=0===c?-1:0;a.u=b;a:{c=a.u.length;b=-1;if(c&&(b=c-1,c=a.u[b],!(null===c||"object"!=typeof c||Array.isArray(c)||$a&&c instanceof Uint8Array))){a.G=b-a.D;a.i=c;break a} -1<d?(a.G=Math.max(d,b+1-a.D),a.i=null):a.G=Number.MAX_VALUE;}a.a={};if(f)for(d=0;d<f.length;d++)b=f[d],b<a.G?(b+=a.D,a.u[b]=a.u[b]||ab):(bb(a),a.i[b]=a.i[b]||ab);if(h&&h.length)for(d=0;d<h.length;d++)cb(a,h[d]);};
		var ab=Object.freeze?Object.freeze([]):[];function bb(a){var b=a.G+a.D;a.u[b]||(a.i=a.u[b]={});}function db(a,b,c){for(var d=[],f=0;f<a.length;f++)d[f]=b.call(a[f],c,a[f]);return d}N.toObjectList=db;N.toObjectExtension=function(a,b,c,d,f){for(var h in c){var m=c[h],t=d.call(a,m);if(null!=t){for(var B in m.Ba)if(m.Ba.hasOwnProperty(B))break;b[B]=m.Na?m.na?db(t,m.Na,f):m.Na(f,t):t;}}};
		N.serializeBinaryExtensions=function(a,b,c,d){for(var f in c){var h=c[f],m=h.Za;if(!h.Aa)throw Error("Message extension present that was generated without binary serialization support");var t=d.call(a,m);if(null!=t)if(m.F())if(h.Wa)h.Aa.call(b,m.ma,t,h.Wa);else throw Error("Message extension present holding submessage without binary support enabled, and message is being serialized to binary format");else h.Aa.call(b,m.ma,t);}};
		N.readBinaryExtension=function(a,b,c,d,f){var h=c[b.c];if(h){c=h.Za;if(!h.za)throw Error("Deserializing extension whose generated code does not support binary format");if(c.F()){var m=new c.la;h.za.call(b,m,h.Ab);}else m=h.za.call(b);c.na&&!h.Nb?(b=d.call(a,c))?b.push(m):f.call(a,c,[m]):f.call(a,c,m);}else b.C();};function O(a,b){if(b<a.G){b+=a.D;var c=a.u[b];return c===ab?a.u[b]=[]:c}if(a.i)return c=a.i[b],c===ab?a.i[b]=[]:c}N.getField=O;N.getRepeatedField=function(a,b){return O(a,b)};
		function eb(a,b){a=O(a,b);return null==a?a:+a}N.getOptionalFloatingPointField=eb;function fb(a,b){a=O(a,b);return null==a?a:!!a}N.getBooleanField=fb;N.getRepeatedFloatingPointField=function(a,b){var c=O(a,b);a.a||(a.a={});if(!a.a[b]){for(var d=0;d<c.length;d++)c[d]=+c[d];a.a[b]=true;}return c};N.getRepeatedBooleanField=function(a,b){var c=O(a,b);a.a||(a.a={});if(!a.a[b]){for(var d=0;d<c.length;d++)c[d]=!!c[d];a.a[b]=true;}return c};
		function gb(a){if(null==a||"string"===typeof a)return a;if($a&&a instanceof Uint8Array)return Ba(a);p("Cannot coerce to b64 string: "+k(a));return null}N.bytesAsB64=gb;function hb(a){if(null==a||a instanceof Uint8Array)return a;if("string"===typeof a)return Da(a);p("Cannot coerce to Uint8Array: "+k(a));return null}N.bytesAsU8=hb;N.bytesListAsB64=function(a){ib(a);return a.length&&"string"!==typeof a[0]?l(a,gb):a};N.bytesListAsU8=function(a){ib(a);return !a.length||a[0]instanceof Uint8Array?a:l(a,hb)};
		function ib(a){if(a&&1<a.length){var b=k(a[0]);qa(a,function(c){k(c)!=b&&p("Inconsistent type in JSPB repeated field array. Got "+k(c)+" expected "+b);});}}function jb(a,b,c){a=O(a,b);return null==a?c:a}N.getFieldWithDefault=jb;N.getBooleanFieldWithDefault=function(a,b,c){a=fb(a,b);return null==a?c:a};N.getFloatingPointFieldWithDefault=function(a,b,c){a=eb(a,b);return null==a?c:a};N.getFieldProto3=jb;
		N.getMapField=function(a,b,c,d){a.f||(a.f={});if(b in a.f)return a.f[b];var f=O(a,b);if(!f){if(c)return;f=[];P(a,b,f);}return a.f[b]=new r(f,d)};function P(a,b,c){q(a,N);b<a.G?a.u[b+a.D]=c:(bb(a),a.i[b]=c);return a}N.setField=P;N.setProto3IntField=function(a,b,c){return Q(a,b,c,0)};N.setProto3FloatField=function(a,b,c){return Q(a,b,c,0)};N.setProto3BooleanField=function(a,b,c){return Q(a,b,c,false)};N.setProto3StringField=function(a,b,c){return Q(a,b,c,"")};
		N.setProto3BytesField=function(a,b,c){return Q(a,b,c,"")};N.setProto3EnumField=function(a,b,c){return Q(a,b,c,0)};N.setProto3StringIntField=function(a,b,c){return Q(a,b,c,"0")};function Q(a,b,c,d){q(a,N);c!==d?P(a,b,c):b<a.G?a.u[b+a.D]=null:(bb(a),delete a.i[b]);return a}N.addToRepeatedField=function(a,b,c,d){q(a,N);b=O(a,b);void 0!=d?b.splice(d,0,c):b.push(c);return a};function kb(a,b,c,d){q(a,N);(c=cb(a,c))&&c!==b&&void 0!==d&&(a.f&&c in a.f&&(a.f[c]=void 0),P(a,c,void 0));return P(a,b,d)}
		N.setOneofField=kb;function cb(a,b){for(var c,d,f=0;f<b.length;f++){var h=b[f],m=O(a,h);null!=m&&(c=h,d=m,P(a,h,void 0));}return c?(P(a,c,d),c):0}N.computeOneofCase=cb;N.getWrapperField=function(a,b,c,d){a.f||(a.f={});if(!a.f[c]){var f=O(a,c);if(d||f)a.f[c]=new b(f);}return a.f[c]};N.getRepeatedWrapperField=function(a,b,c){lb(a,b,c);b=a.f[c];b==ab&&(b=a.f[c]=[]);return b};function lb(a,b,c){a.f||(a.f={});if(!a.f[c]){for(var d=O(a,c),f=[],h=0;h<d.length;h++)f[h]=new b(d[h]);a.f[c]=f;}}
		N.setWrapperField=function(a,b,c){q(a,N);a.f||(a.f={});var d=c?c.g():c;a.f[b]=c;return P(a,b,d)};N.setOneofWrapperField=function(a,b,c,d){q(a,N);a.f||(a.f={});var f=d?d.g():d;a.f[b]=d;return kb(a,b,c,f)};N.setRepeatedWrapperField=function(a,b,c){q(a,N);a.f||(a.f={});c=c||[];for(var d=[],f=0;f<c.length;f++)d[f]=c[f].g();a.f[b]=c;return P(a,b,d)};
		N.addToRepeatedWrapperField=function(a,b,c,d,f){lb(a,d,b);var h=a.f[b];h||(h=a.f[b]=[]);c=c?c:new d;a=O(a,b);void 0!=f?(h.splice(f,0,c),a.splice(f,0,c.g())):(h.push(c),a.push(c.g()));return c};N.toMap=function(a,b,c,d){for(var f={},h=0;h<a.length;h++)f[b.call(a[h])]=c?c.call(a[h],d,a[h]):a[h];return f};function mb(a){if(a.f)for(var b in a.f){var c=a.f[b];if(Array.isArray(c))for(var d=0;d<c.length;d++)c[d]&&c[d].g();else c&&c.g();}}N.prototype.g=function(){mb(this);return this.u};
		N.prototype.toArray=N.prototype.g;N.prototype.toString=function(){mb(this);return this.u.toString()};N.prototype.getExtension=function(a){if(this.i){this.f||(this.f={});var b=a.ma;if(a.na){if(a.F())return this.f[b]||(this.f[b]=l(this.i[b]||[],function(c){return new a.la(c)})),this.f[b]}else if(a.F())return !this.f[b]&&this.i[b]&&(this.f[b]=new a.la(this.i[b])),this.f[b];return this.i[b]}};N.prototype.getExtension=N.prototype.getExtension;
		N.prototype.Kc=function(a,b){this.f||(this.f={});bb(this);var c=a.ma;a.na?(b=b||[],a.F()?(this.f[c]=b,this.i[c]=l(b,function(d){return d.g()})):this.i[c]=b):a.F()?(this.f[c]=b,this.i[c]=b?b.g():b):this.i[c]=b;return this};N.prototype.setExtension=N.prototype.Kc;N.difference=function(a,b){if(!(a instanceof b.constructor))throw Error("Messages have different types.");var c=a.g();b=b.g();var d=[],f=0,h=c.length>b.length?c.length:b.length;a.b&&(d[0]=a.b,f=1);for(;f<h;f++)nb(c[f],b[f])||(d[f]=b[f]);return new a.constructor(d)};
		N.equals=function(a,b){return a==b||!(!a||!b)&&a instanceof b.constructor&&nb(a.g(),b.g())};function ob(a,b){a=a||{};b=b||{};var c={},d;for(d in a)c[d]=0;for(d in b)c[d]=0;for(d in c)if(!nb(a[d],b[d]))return  false;return  true}N.compareExtensions=ob;
		function nb(a,b){if(a==b)return  true;if(!la(a)||!la(b))return "number"===typeof a&&isNaN(a)||"number"===typeof b&&isNaN(b)?String(a)==String(b):false;if(a.constructor!=b.constructor)return  false;if($a&&a.constructor===Uint8Array){if(a.length!=b.length)return  false;for(var c=0;c<a.length;c++)if(a[c]!=b[c])return  false;return  true}if(a.constructor===Array){var d=void 0,f=void 0,h=Math.max(a.length,b.length);for(c=0;c<h;c++){var m=a[c],t=b[c];m&&m.constructor==Object&&(n(void 0===d),n(c===a.length-1),d=m,m=void 0);t&&t.constructor==
		Object&&(n(void 0===f),n(c===b.length-1),f=t,t=void 0);if(!nb(m,t))return  false}return d||f?(d=d||{},f=f||{},ob(d,f)):true}if(a.constructor===Object)return ob(a,b);throw Error("Invalid type in JSPB array");}N.compareFields=nb;N.prototype.Bb=function(){return pb(this)};N.prototype.cloneMessage=N.prototype.Bb;N.prototype.clone=function(){return pb(this)};N.prototype.clone=N.prototype.clone;N.clone=function(a){return pb(a)};function pb(a){return new a.constructor(qb(a.g()))}
		N.copyInto=function(a,b){q(a,N);q(b,N);n(a.constructor==b.constructor,"Copy source and target message should have the same type.");a=pb(a);for(var c=b.g(),d=a.g(),f=c.length=0;f<d.length;f++)c[f]=d[f];b.f=a.f;b.i=a.i;};function qb(a){if(Array.isArray(a)){for(var b=Array(a.length),c=0;c<a.length;c++){var d=a[c];null!=d&&(b[c]="object"==typeof d?qb(n(d)):d);}return b}if($a&&a instanceof Uint8Array)return new Uint8Array(a);b={};for(c in a)d=a[c],null!=d&&(b[c]="object"==typeof d?qb(n(d)):d);return b}
		N.registerMessageType=function(a,b){b.we=a;};var R={dump:function(a){q(a,N,"jspb.Message instance expected");n(a.getExtension,"Only unobfuscated and unoptimized compilation modes supported.");return R.X(a)}};g("jspb.debug.dump",R.dump,void 0);
		R.X=function(a){var b=k(a);if("number"==b||"string"==b||"boolean"==b||"null"==b||"undefined"==b||"undefined"!==typeof Uint8Array&&a instanceof Uint8Array)return a;if("array"==b)return ua(a),l(a,R.X);if(a instanceof r){var c={};a=a.entries();for(var d=a.next();!d.done;d=a.next())c[d.value[0]]=R.X(d.value[1]);return c}q(a,N,"Only messages expected: "+a);b=a.constructor;var f={$name:b.name||b.displayName};for(t in b.prototype){var h=/^get([A-Z]\w*)/.exec(t);if(h&&"getExtension"!=t&&"getJsPbMessageId"!=
		t){var m="has"+h[1];if(!a[m]||a[m]())m=a[t](),f[R.$a(h[1])]=R.X(m);}}if(a.extensionObject_)return f.$extensions="Recursive dumping of extensions not supported in compiled code. Switch to uncompiled or dump extension object directly",f;for(d in b.extensions)if(/^\d+$/.test(d)){m=b.extensions[d];var t=a.getExtension(m);h=void 0;m=m.Ba;var B=[],M=0;for(h in m)B[M++]=h;h=B[0];null!=t&&(c||(c=f.$extensions={}),c[R.$a(h)]=R.X(t));}return f};R.$a=function(a){return a.replace(/^[A-Z]/,function(b){return b.toLowerCase()})};function S(){this.a=[];}g("jspb.BinaryEncoder",S,void 0);S.prototype.length=function(){return this.a.length};S.prototype.length=S.prototype.length;S.prototype.end=function(){var a=this.a;this.a=[];return a};S.prototype.end=S.prototype.end;S.prototype.l=function(a,b){n(a==Math.floor(a));n(b==Math.floor(b));n(0<=a&&4294967296>a);for(n(0<=b&&4294967296>b);0<b||127<a;)this.a.push(a&127|128),a=(a>>>7|b<<25)>>>0,b>>>=7;this.a.push(a);};S.prototype.writeSplitVarint64=S.prototype.l;
		S.prototype.A=function(a,b){n(a==Math.floor(a));n(b==Math.floor(b));n(0<=a&&4294967296>a);n(0<=b&&4294967296>b);this.s(a);this.s(b);};S.prototype.writeSplitFixed64=S.prototype.A;S.prototype.j=function(a){n(a==Math.floor(a));for(n(0<=a&&4294967296>a);127<a;)this.a.push(a&127|128),a>>>=7;this.a.push(a);};S.prototype.writeUnsignedVarint32=S.prototype.j;S.prototype.M=function(a){n(a==Math.floor(a));n(-2147483648<=a&&2147483648>a);if(0<=a)this.j(a);else {for(var b=0;9>b;b++)this.a.push(a&127|128),a>>=7;this.a.push(1);}};
		S.prototype.writeSignedVarint32=S.prototype.M;S.prototype.va=function(a){n(a==Math.floor(a));n(0<=a&&1.8446744073709552E19>a);A(a);this.l(y,z);};S.prototype.writeUnsignedVarint64=S.prototype.va;S.prototype.ua=function(a){n(a==Math.floor(a));n(-9223372036854776e3<=a&&0x7fffffffffffffff>a);A(a);this.l(y,z);};S.prototype.writeSignedVarint64=S.prototype.ua;S.prototype.wa=function(a){n(a==Math.floor(a));n(-2147483648<=a&&2147483648>a);this.j((a<<1^a>>31)>>>0);};S.prototype.writeZigzagVarint32=S.prototype.wa;
		S.prototype.xa=function(a){n(a==Math.floor(a));n(-9223372036854776e3<=a&&0x7fffffffffffffff>a);Ga(a);this.l(y,z);};S.prototype.writeZigzagVarint64=S.prototype.xa;S.prototype.Ta=function(a){this.W(H(a));};S.prototype.writeZigzagVarint64String=S.prototype.Ta;S.prototype.W=function(a){var b=this;C(a);Ja(y,z,function(c,d){b.l(c>>>0,d>>>0);});};S.prototype.writeZigzagVarintHash64=S.prototype.W;S.prototype.be=function(a){n(a==Math.floor(a));n(0<=a&&256>a);this.a.push(a>>>0&255);};S.prototype.writeUint8=S.prototype.be;
		S.prototype.ae=function(a){n(a==Math.floor(a));n(0<=a&&65536>a);this.a.push(a>>>0&255);this.a.push(a>>>8&255);};S.prototype.writeUint16=S.prototype.ae;S.prototype.s=function(a){n(a==Math.floor(a));n(0<=a&&4294967296>a);this.a.push(a>>>0&255);this.a.push(a>>>8&255);this.a.push(a>>>16&255);this.a.push(a>>>24&255);};S.prototype.writeUint32=S.prototype.s;S.prototype.V=function(a){n(a==Math.floor(a));n(0<=a&&1.8446744073709552E19>a);Fa(a);this.s(y);this.s(z);};S.prototype.writeUint64=S.prototype.V;
		S.prototype.Qc=function(a){n(a==Math.floor(a));n(-128<=a&&128>a);this.a.push(a>>>0&255);};S.prototype.writeInt8=S.prototype.Qc;S.prototype.Pc=function(a){n(a==Math.floor(a));n(-32768<=a&&32768>a);this.a.push(a>>>0&255);this.a.push(a>>>8&255);};S.prototype.writeInt16=S.prototype.Pc;S.prototype.S=function(a){n(a==Math.floor(a));n(-2147483648<=a&&2147483648>a);this.a.push(a>>>0&255);this.a.push(a>>>8&255);this.a.push(a>>>16&255);this.a.push(a>>>24&255);};S.prototype.writeInt32=S.prototype.S;
		S.prototype.T=function(a){n(a==Math.floor(a));n(-9223372036854776e3<=a&&0x7fffffffffffffff>a);A(a);this.A(y,z);};S.prototype.writeInt64=S.prototype.T;S.prototype.ka=function(a){n(a==Math.floor(a));n(-9223372036854776e3<=+a&&0x7fffffffffffffff>+a);C(H(a));this.A(y,z);};S.prototype.writeInt64String=S.prototype.ka;S.prototype.L=function(a){n(Infinity===a||-Infinity===a||isNaN(a)||-34028234663852886e22<=a&&3.4028234663852886E38>=a);Ha(a);this.s(y);};S.prototype.writeFloat=S.prototype.L;
		S.prototype.J=function(a){n(Infinity===a||-Infinity===a||isNaN(a)||-17976931348623157e292<=a&&1.7976931348623157E308>=a);Ia(a);this.s(y);this.s(z);};S.prototype.writeDouble=S.prototype.J;S.prototype.I=function(a){n("boolean"===typeof a||"number"===typeof a);this.a.push(a?1:0);};S.prototype.writeBool=S.prototype.I;S.prototype.R=function(a){n(a==Math.floor(a));n(-2147483648<=a&&2147483648>a);this.M(a);};S.prototype.writeEnum=S.prototype.R;S.prototype.ja=function(a){this.a.push.apply(this.a,a);};
		S.prototype.writeBytes=S.prototype.ja;S.prototype.N=function(a){C(a);this.l(y,z);};S.prototype.writeVarintHash64=S.prototype.N;S.prototype.K=function(a){C(a);this.s(y);this.s(z);};S.prototype.writeFixedHash64=S.prototype.K;
		S.prototype.U=function(a){var b=this.a.length;ta(a);for(var c=0;c<a.length;c++){var d=a.charCodeAt(c);if(128>d)this.a.push(d);else if(2048>d)this.a.push(d>>6|192),this.a.push(d&63|128);else if(65536>d)if(55296<=d&&56319>=d&&c+1<a.length){var f=a.charCodeAt(c+1);56320<=f&&57343>=f&&(d=1024*(d-55296)+f-56320+65536,this.a.push(d>>18|240),this.a.push(d>>12&63|128),this.a.push(d>>6&63|128),this.a.push(d&63|128),c++);}else this.a.push(d>>12|224),this.a.push(d>>6&63|128),this.a.push(d&63|128);}return this.a.length-
		b};S.prototype.writeString=S.prototype.U;function T(a,b){this.lo=a;this.hi=b;}g("jspb.arith.UInt64",T,void 0);T.prototype.cmp=function(a){return this.hi<a.hi||this.hi==a.hi&&this.lo<a.lo?-1:this.hi==a.hi&&this.lo==a.lo?0:1};T.prototype.cmp=T.prototype.cmp;T.prototype.La=function(){return new T((this.lo>>>1|(this.hi&1)<<31)>>>0,this.hi>>>1>>>0)};T.prototype.rightShift=T.prototype.La;T.prototype.Da=function(){return new T(this.lo<<1>>>0,(this.hi<<1|this.lo>>>31)>>>0)};T.prototype.leftShift=T.prototype.Da;
		T.prototype.cb=function(){return !!(this.hi&2147483648)};T.prototype.msb=T.prototype.cb;T.prototype.Ob=function(){return !!(this.lo&1)};T.prototype.lsb=T.prototype.Ob;T.prototype.Ua=function(){return 0==this.lo&&0==this.hi};T.prototype.zero=T.prototype.Ua;T.prototype.add=function(a){return new T((this.lo+a.lo&4294967295)>>>0>>>0,((this.hi+a.hi&4294967295)>>>0)+(4294967296<=this.lo+a.lo?1:0)>>>0)};T.prototype.add=T.prototype.add;
		T.prototype.sub=function(a){return new T((this.lo-a.lo&4294967295)>>>0>>>0,((this.hi-a.hi&4294967295)>>>0)-(0>this.lo-a.lo?1:0)>>>0)};T.prototype.sub=T.prototype.sub;function rb(a,b){var c=a&65535;a>>>=16;var d=b&65535,f=b>>>16;b=c*d+65536*(c*f&65535)+65536*(a*d&65535);for(c=a*f+(c*f>>>16)+(a*d>>>16);4294967296<=b;)b-=4294967296,c+=1;return new T(b>>>0,c>>>0)}T.mul32x32=rb;T.prototype.eb=function(a){var b=rb(this.lo,a);a=rb(this.hi,a);a.hi=a.lo;a.lo=0;return b.add(a)};T.prototype.mul=T.prototype.eb;
		T.prototype.Xa=function(a){if(0==a)return [];var b=new T(0,0),c=new T(this.lo,this.hi);a=new T(a,0);for(var d=new T(1,0);!a.cb();)a=a.Da(),d=d.Da();for(;!d.Ua();)0>=a.cmp(c)&&(b=b.add(d),c=c.sub(a)),a=a.La(),d=d.La();return [b,c]};T.prototype.div=T.prototype.Xa;T.prototype.toString=function(){for(var a="",b=this;!b.Ua();){b=b.Xa(10);var c=b[0];a=b[1].lo+a;b=c;}""==a&&(a="0");return a};T.prototype.toString=T.prototype.toString;
		function U(a){for(var b=new T(0,0),c=new T(0,0),d=0;d<a.length;d++){if("0">a[d]||"9"<a[d])return null;c.lo=parseInt(a[d],10);b=b.eb(10).add(c);}return b}T.fromString=U;T.prototype.clone=function(){return new T(this.lo,this.hi)};T.prototype.clone=T.prototype.clone;function V(a,b){this.lo=a;this.hi=b;}g("jspb.arith.Int64",V,void 0);V.prototype.add=function(a){return new V((this.lo+a.lo&4294967295)>>>0>>>0,((this.hi+a.hi&4294967295)>>>0)+(4294967296<=this.lo+a.lo?1:0)>>>0)};V.prototype.add=V.prototype.add;
		V.prototype.sub=function(a){return new V((this.lo-a.lo&4294967295)>>>0>>>0,((this.hi-a.hi&4294967295)>>>0)-(0>this.lo-a.lo?1:0)>>>0)};V.prototype.sub=V.prototype.sub;V.prototype.clone=function(){return new V(this.lo,this.hi)};V.prototype.clone=V.prototype.clone;V.prototype.toString=function(){var a=0!=(this.hi&2147483648),b=new T(this.lo,this.hi);a&&(b=(new T(0,0)).sub(b));return (a?"-":"")+b.toString()};V.prototype.toString=V.prototype.toString;
		function sb(a){var b=0<a.length&&"-"==a[0];b&&(a=a.substring(1));a=U(a);if(null===a)return null;b&&(a=(new T(0,0)).sub(a));return new V(a.lo,a.hi)}V.fromString=sb;function W(){this.c=[];this.b=0;this.a=new S;this.h=[];}g("jspb.BinaryWriter",W,void 0);function tb(a,b){var c=a.a.end();a.c.push(c);a.c.push(b);a.b+=c.length+b.length;}function X(a,b){Y(a,b,2);b=a.a.end();a.c.push(b);a.b+=b.length;b.push(a.b);return b}function Z(a,b){var c=b.pop();c=a.b+a.a.length()-c;for(n(0<=c);127<c;)b.push(c&127|128),c>>>=7,a.b++;b.push(c);a.b++;}W.prototype.pb=function(a,b,c){tb(this,a.subarray(b,c));};W.prototype.writeSerializedMessage=W.prototype.pb;
		W.prototype.Pb=function(a,b,c){null!=a&&null!=b&&null!=c&&this.pb(a,b,c);};W.prototype.maybeWriteSerializedMessage=W.prototype.Pb;W.prototype.reset=function(){this.c=[];this.a.end();this.b=0;this.h=[];};W.prototype.reset=W.prototype.reset;W.prototype.ab=function(){n(0==this.h.length);for(var a=new Uint8Array(this.b+this.a.length()),b=this.c,c=b.length,d=0,f=0;f<c;f++){var h=b[f];a.set(h,d);d+=h.length;}b=this.a.end();a.set(b,d);d+=b.length;n(d==a.length);this.c=[a];return a};
		W.prototype.getResultBuffer=W.prototype.ab;W.prototype.Kb=function(a){return Ba(this.ab(),a)};W.prototype.getResultBase64String=W.prototype.Kb;W.prototype.Va=function(a){this.h.push(X(this,a));};W.prototype.beginSubMessage=W.prototype.Va;W.prototype.Ya=function(){n(0<=this.h.length);Z(this,this.h.pop());};W.prototype.endSubMessage=W.prototype.Ya;function Y(a,b,c){n(1<=b&&b==Math.floor(b));a.a.j(8*b+c);}
		W.prototype.Nc=function(a,b,c){switch(a){case 1:this.J(b,c);break;case 2:this.L(b,c);break;case 3:this.T(b,c);break;case 4:this.V(b,c);break;case 5:this.S(b,c);break;case 6:this.Qa(b,c);break;case 7:this.Pa(b,c);break;case 8:this.I(b,c);break;case 9:this.U(b,c);break;case 10:p("Group field type not supported in writeAny()");break;case 11:p("Message field type not supported in writeAny()");break;case 12:this.ja(b,c);break;case 13:this.s(b,c);break;case 14:this.R(b,c);break;case 15:this.Ra(b,c);break;
		case 16:this.Sa(b,c);break;case 17:this.rb(b,c);break;case 18:this.sb(b,c);break;case 30:this.K(b,c);break;case 31:this.N(b,c);break;default:p("Invalid field type in writeAny()");}};W.prototype.writeAny=W.prototype.Nc;function ub(a,b,c){null!=c&&(Y(a,b,0),a.a.j(c));}function vb(a,b,c){null!=c&&(Y(a,b,0),a.a.M(c));}W.prototype.S=function(a,b){null!=b&&(n(-2147483648<=b&&2147483648>b),vb(this,a,b));};W.prototype.writeInt32=W.prototype.S;
		W.prototype.ob=function(a,b){null!=b&&(b=parseInt(b,10),n(-2147483648<=b&&2147483648>b),vb(this,a,b));};W.prototype.writeInt32String=W.prototype.ob;W.prototype.T=function(a,b){null!=b&&(n(-9223372036854776e3<=b&&0x7fffffffffffffff>b),null!=b&&(Y(this,a,0),this.a.ua(b)));};W.prototype.writeInt64=W.prototype.T;W.prototype.ka=function(a,b){null!=b&&(b=sb(b),Y(this,a,0),this.a.l(b.lo,b.hi));};W.prototype.writeInt64String=W.prototype.ka;
		W.prototype.s=function(a,b){null!=b&&(n(0<=b&&4294967296>b),ub(this,a,b));};W.prototype.writeUint32=W.prototype.s;W.prototype.ub=function(a,b){null!=b&&(b=parseInt(b,10),n(0<=b&&4294967296>b),ub(this,a,b));};W.prototype.writeUint32String=W.prototype.ub;W.prototype.V=function(a,b){null!=b&&(n(0<=b&&1.8446744073709552E19>b),null!=b&&(Y(this,a,0),this.a.va(b)));};W.prototype.writeUint64=W.prototype.V;W.prototype.vb=function(a,b){null!=b&&(b=U(b),Y(this,a,0),this.a.l(b.lo,b.hi));};
		W.prototype.writeUint64String=W.prototype.vb;W.prototype.rb=function(a,b){null!=b&&(n(-2147483648<=b&&2147483648>b),null!=b&&(Y(this,a,0),this.a.wa(b)));};W.prototype.writeSint32=W.prototype.rb;W.prototype.sb=function(a,b){null!=b&&(n(-9223372036854776e3<=b&&0x7fffffffffffffff>b),null!=b&&(Y(this,a,0),this.a.xa(b)));};W.prototype.writeSint64=W.prototype.sb;W.prototype.$d=function(a,b){null!=b&&null!=b&&(Y(this,a,0),this.a.W(b));};W.prototype.writeSintHash64=W.prototype.$d;
		W.prototype.Zd=function(a,b){null!=b&&null!=b&&(Y(this,a,0),this.a.Ta(b));};W.prototype.writeSint64String=W.prototype.Zd;W.prototype.Pa=function(a,b){null!=b&&(n(0<=b&&4294967296>b),Y(this,a,5),this.a.s(b));};W.prototype.writeFixed32=W.prototype.Pa;W.prototype.Qa=function(a,b){null!=b&&(n(0<=b&&1.8446744073709552E19>b),Y(this,a,1),this.a.V(b));};W.prototype.writeFixed64=W.prototype.Qa;W.prototype.nb=function(a,b){null!=b&&(b=U(b),Y(this,a,1),this.a.A(b.lo,b.hi));};W.prototype.writeFixed64String=W.prototype.nb;
		W.prototype.Ra=function(a,b){null!=b&&(n(-2147483648<=b&&2147483648>b),Y(this,a,5),this.a.S(b));};W.prototype.writeSfixed32=W.prototype.Ra;W.prototype.Sa=function(a,b){null!=b&&(n(-9223372036854776e3<=b&&0x7fffffffffffffff>b),Y(this,a,1),this.a.T(b));};W.prototype.writeSfixed64=W.prototype.Sa;W.prototype.qb=function(a,b){null!=b&&(b=sb(b),Y(this,a,1),this.a.A(b.lo,b.hi));};W.prototype.writeSfixed64String=W.prototype.qb;W.prototype.L=function(a,b){null!=b&&(Y(this,a,5),this.a.L(b));};
		W.prototype.writeFloat=W.prototype.L;W.prototype.J=function(a,b){null!=b&&(Y(this,a,1),this.a.J(b));};W.prototype.writeDouble=W.prototype.J;W.prototype.I=function(a,b){null!=b&&(n("boolean"===typeof b||"number"===typeof b),Y(this,a,0),this.a.I(b));};W.prototype.writeBool=W.prototype.I;W.prototype.R=function(a,b){null!=b&&(n(-2147483648<=b&&2147483648>b),Y(this,a,0),this.a.M(b));};W.prototype.writeEnum=W.prototype.R;W.prototype.U=function(a,b){null!=b&&(a=X(this,a),this.a.U(b),Z(this,a));};
		W.prototype.writeString=W.prototype.U;W.prototype.ja=function(a,b){null!=b&&(b=Ua(b),Y(this,a,2),this.a.j(b.length),tb(this,b));};W.prototype.writeBytes=W.prototype.ja;W.prototype.Rc=function(a,b,c){null!=b&&(a=X(this,a),c(b,this),Z(this,a));};W.prototype.writeMessage=W.prototype.Rc;W.prototype.Sc=function(a,b,c){null!=b&&(Y(this,1,3),Y(this,2,0),this.a.M(a),a=X(this,3),c(b,this),Z(this,a),Y(this,1,4));};W.prototype.writeMessageSet=W.prototype.Sc;
		W.prototype.Oc=function(a,b,c){null!=b&&(Y(this,a,3),c(b,this),Y(this,a,4));};W.prototype.writeGroup=W.prototype.Oc;W.prototype.K=function(a,b){null!=b&&(n(8==b.length),Y(this,a,1),this.a.K(b));};W.prototype.writeFixedHash64=W.prototype.K;W.prototype.N=function(a,b){null!=b&&(n(8==b.length),Y(this,a,0),this.a.N(b));};W.prototype.writeVarintHash64=W.prototype.N;W.prototype.A=function(a,b,c){Y(this,a,1);this.a.A(b,c);};W.prototype.writeSplitFixed64=W.prototype.A;
		W.prototype.l=function(a,b,c){Y(this,a,0);this.a.l(b,c);};W.prototype.writeSplitVarint64=W.prototype.l;W.prototype.tb=function(a,b,c){Y(this,a,0);var d=this.a;Ja(b,c,function(f,h){d.l(f>>>0,h>>>0);});};W.prototype.writeSplitZigzagVarint64=W.prototype.tb;W.prototype.Ed=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)vb(this,a,b[c]);};W.prototype.writeRepeatedInt32=W.prototype.Ed;W.prototype.Fd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.ob(a,b[c]);};
		W.prototype.writeRepeatedInt32String=W.prototype.Fd;W.prototype.Gd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++){var d=b[c];null!=d&&(Y(this,a,0),this.a.ua(d));}};W.prototype.writeRepeatedInt64=W.prototype.Gd;W.prototype.Qd=function(a,b,c,d){if(null!=b)for(var f=0;f<b.length;f++)this.A(a,c(b[f]),d(b[f]));};W.prototype.writeRepeatedSplitFixed64=W.prototype.Qd;W.prototype.Rd=function(a,b,c,d){if(null!=b)for(var f=0;f<b.length;f++)this.l(a,c(b[f]),d(b[f]));};
		W.prototype.writeRepeatedSplitVarint64=W.prototype.Rd;W.prototype.Sd=function(a,b,c,d){if(null!=b)for(var f=0;f<b.length;f++)this.tb(a,c(b[f]),d(b[f]));};W.prototype.writeRepeatedSplitZigzagVarint64=W.prototype.Sd;W.prototype.Hd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.ka(a,b[c]);};W.prototype.writeRepeatedInt64String=W.prototype.Hd;W.prototype.Ud=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)ub(this,a,b[c]);};W.prototype.writeRepeatedUint32=W.prototype.Ud;
		W.prototype.Vd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.ub(a,b[c]);};W.prototype.writeRepeatedUint32String=W.prototype.Vd;W.prototype.Wd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++){var d=b[c];null!=d&&(Y(this,a,0),this.a.va(d));}};W.prototype.writeRepeatedUint64=W.prototype.Wd;W.prototype.Xd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.vb(a,b[c]);};W.prototype.writeRepeatedUint64String=W.prototype.Xd;
		W.prototype.Md=function(a,b){if(null!=b)for(var c=0;c<b.length;c++){var d=b[c];null!=d&&(Y(this,a,0),this.a.wa(d));}};W.prototype.writeRepeatedSint32=W.prototype.Md;W.prototype.Nd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++){var d=b[c];null!=d&&(Y(this,a,0),this.a.xa(d));}};W.prototype.writeRepeatedSint64=W.prototype.Nd;W.prototype.Od=function(a,b){if(null!=b)for(var c=0;c<b.length;c++){var d=b[c];null!=d&&(Y(this,a,0),this.a.Ta(d));}};W.prototype.writeRepeatedSint64String=W.prototype.Od;
		W.prototype.Pd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++){var d=b[c];null!=d&&(Y(this,a,0),this.a.W(d));}};W.prototype.writeRepeatedSintHash64=W.prototype.Pd;W.prototype.yd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.Pa(a,b[c]);};W.prototype.writeRepeatedFixed32=W.prototype.yd;W.prototype.zd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.Qa(a,b[c]);};W.prototype.writeRepeatedFixed64=W.prototype.zd;
		W.prototype.Ad=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.nb(a,b[c]);};W.prototype.writeRepeatedFixed64String=W.prototype.Ad;W.prototype.Jd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.Ra(a,b[c]);};W.prototype.writeRepeatedSfixed32=W.prototype.Jd;W.prototype.Kd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.Sa(a,b[c]);};W.prototype.writeRepeatedSfixed64=W.prototype.Kd;W.prototype.Ld=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.qb(a,b[c]);};
		W.prototype.writeRepeatedSfixed64String=W.prototype.Ld;W.prototype.Cd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.L(a,b[c]);};W.prototype.writeRepeatedFloat=W.prototype.Cd;W.prototype.wd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.J(a,b[c]);};W.prototype.writeRepeatedDouble=W.prototype.wd;W.prototype.ud=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.I(a,b[c]);};W.prototype.writeRepeatedBool=W.prototype.ud;
		W.prototype.xd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.R(a,b[c]);};W.prototype.writeRepeatedEnum=W.prototype.xd;W.prototype.Td=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.U(a,b[c]);};W.prototype.writeRepeatedString=W.prototype.Td;W.prototype.vd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.ja(a,b[c]);};W.prototype.writeRepeatedBytes=W.prototype.vd;W.prototype.Id=function(a,b,c){if(null!=b)for(var d=0;d<b.length;d++){var f=X(this,a);c(b[d],this);Z(this,f);}};
		W.prototype.writeRepeatedMessage=W.prototype.Id;W.prototype.Dd=function(a,b,c){if(null!=b)for(var d=0;d<b.length;d++)Y(this,a,3),c(b[d],this),Y(this,a,4);};W.prototype.writeRepeatedGroup=W.prototype.Dd;W.prototype.Bd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.K(a,b[c]);};W.prototype.writeRepeatedFixedHash64=W.prototype.Bd;W.prototype.Yd=function(a,b){if(null!=b)for(var c=0;c<b.length;c++)this.N(a,b[c]);};W.prototype.writeRepeatedVarintHash64=W.prototype.Yd;
		W.prototype.ad=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.M(b[c]);Z(this,a);}};W.prototype.writePackedInt32=W.prototype.ad;W.prototype.bd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.M(parseInt(b[c],10));Z(this,a);}};W.prototype.writePackedInt32String=W.prototype.bd;W.prototype.cd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.ua(b[c]);Z(this,a);}};W.prototype.writePackedInt64=W.prototype.cd;
		W.prototype.md=function(a,b,c,d){if(null!=b){a=X(this,a);for(var f=0;f<b.length;f++)this.a.A(c(b[f]),d(b[f]));Z(this,a);}};W.prototype.writePackedSplitFixed64=W.prototype.md;W.prototype.nd=function(a,b,c,d){if(null!=b){a=X(this,a);for(var f=0;f<b.length;f++)this.a.l(c(b[f]),d(b[f]));Z(this,a);}};W.prototype.writePackedSplitVarint64=W.prototype.nd;W.prototype.od=function(a,b,c,d){if(null!=b){a=X(this,a);for(var f=this.a,h=0;h<b.length;h++)Ja(c(b[h]),d(b[h]),function(m,t){f.l(m>>>0,t>>>0);});Z(this,a);}};
		W.prototype.writePackedSplitZigzagVarint64=W.prototype.od;W.prototype.dd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++){var d=sb(b[c]);this.a.l(d.lo,d.hi);}Z(this,a);}};W.prototype.writePackedInt64String=W.prototype.dd;W.prototype.pd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.j(b[c]);Z(this,a);}};W.prototype.writePackedUint32=W.prototype.pd;
		W.prototype.qd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.j(parseInt(b[c],10));Z(this,a);}};W.prototype.writePackedUint32String=W.prototype.qd;W.prototype.rd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.va(b[c]);Z(this,a);}};W.prototype.writePackedUint64=W.prototype.rd;W.prototype.sd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++){var d=U(b[c]);this.a.l(d.lo,d.hi);}Z(this,a);}};
		W.prototype.writePackedUint64String=W.prototype.sd;W.prototype.hd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.wa(b[c]);Z(this,a);}};W.prototype.writePackedSint32=W.prototype.hd;W.prototype.jd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.xa(b[c]);Z(this,a);}};W.prototype.writePackedSint64=W.prototype.jd;W.prototype.kd=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.W(H(b[c]));Z(this,a);}};
		W.prototype.writePackedSint64String=W.prototype.kd;W.prototype.ld=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.W(b[c]);Z(this,a);}};W.prototype.writePackedSintHash64=W.prototype.ld;W.prototype.Wc=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(4*b.length),a=0;a<b.length;a++)this.a.s(b[a]);};W.prototype.writePackedFixed32=W.prototype.Wc;W.prototype.Xc=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(8*b.length),a=0;a<b.length;a++)this.a.V(b[a]);};
		W.prototype.writePackedFixed64=W.prototype.Xc;W.prototype.Yc=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(8*b.length),a=0;a<b.length;a++){var c=U(b[a]);this.a.A(c.lo,c.hi);}};W.prototype.writePackedFixed64String=W.prototype.Yc;W.prototype.ed=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(4*b.length),a=0;a<b.length;a++)this.a.S(b[a]);};W.prototype.writePackedSfixed32=W.prototype.ed;
		W.prototype.fd=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(8*b.length),a=0;a<b.length;a++)this.a.T(b[a]);};W.prototype.writePackedSfixed64=W.prototype.fd;W.prototype.gd=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(8*b.length),a=0;a<b.length;a++)this.a.ka(b[a]);};W.prototype.writePackedSfixed64String=W.prototype.gd;W.prototype.$c=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(4*b.length),a=0;a<b.length;a++)this.a.L(b[a]);};W.prototype.writePackedFloat=W.prototype.$c;
		W.prototype.Uc=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(8*b.length),a=0;a<b.length;a++)this.a.J(b[a]);};W.prototype.writePackedDouble=W.prototype.Uc;W.prototype.Tc=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(b.length),a=0;a<b.length;a++)this.a.I(b[a]);};W.prototype.writePackedBool=W.prototype.Tc;W.prototype.Vc=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.R(b[c]);Z(this,a);}};W.prototype.writePackedEnum=W.prototype.Vc;
		W.prototype.Zc=function(a,b){if(null!=b&&b.length)for(Y(this,a,2),this.a.j(8*b.length),a=0;a<b.length;a++)this.a.K(b[a]);};W.prototype.writePackedFixedHash64=W.prototype.Zc;W.prototype.td=function(a,b){if(null!=b&&b.length){a=X(this,a);for(var c=0;c<b.length;c++)this.a.N(b[c]);Z(this,a);}};W.prototype.writePackedVarintHash64=W.prototype.td;(exports.debug=R,exports.Map=r,exports.Message=N,exports.BinaryReader=J,exports.BinaryWriter=W,exports.ExtensionFieldInfo=Ya,exports.ExtensionFieldBinaryInfo=Za,exports.exportSymbol=ma,exports.inherits=na,exports.object={extend:pa},exports.typeOf=k); 
	} (googleProtobuf));
	return googleProtobuf;
}

var googleProtobufExports = requireGoogleProtobuf();

var blaze;
(function (blaze) {
    (function (worker) {
        var _Input_one_of_decls, _WorkRequest_one_of_decls, _WorkResponse_one_of_decls;
        var Input = /** @class */ (function (_super) {
            __extends(Input, _super);
            function Input(data) {
                var _this = _super.call(this) || this;
                _Input_one_of_decls.set(_this, []);
                googleProtobufExports.Message.initialize(_this, Array.isArray(data) ? data : [], 0, -1, [], __classPrivateFieldGet(_this, _Input_one_of_decls, "f"));
                if (!Array.isArray(data) && typeof data == "object") {
                    if ("path" in data && data.path != undefined) {
                        _this.path = data.path;
                    }
                    if ("digest" in data && data.digest != undefined) {
                        _this.digest = data.digest;
                    }
                }
                return _this;
            }
            Object.defineProperty(Input.prototype, "path", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 1, "");
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 1, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(Input.prototype, "digest", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 2, new Uint8Array(0));
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 2, value);
                },
                enumerable: false,
                configurable: true
            });
            Input.fromObject = function (data) {
                var message = new Input({});
                if (data.path != null) {
                    message.path = data.path;
                }
                if (data.digest != null) {
                    message.digest = data.digest;
                }
                return message;
            };
            Input.prototype.toObject = function () {
                var data = {};
                if (this.path != null) {
                    data.path = this.path;
                }
                if (this.digest != null) {
                    data.digest = this.digest;
                }
                return data;
            };
            Input.prototype.serialize = function (w) {
                var writer = w || new googleProtobufExports.BinaryWriter();
                if (this.path.length)
                    writer.writeString(1, this.path);
                if (this.digest.length)
                    writer.writeBytes(2, this.digest);
                if (!w)
                    return writer.getResultBuffer();
            };
            Input.deserialize = function (bytes) {
                var reader = bytes instanceof googleProtobufExports.BinaryReader ? bytes : new googleProtobufExports.BinaryReader(bytes), message = new Input();
                while (reader.nextField()) {
                    if (reader.isEndGroup())
                        break;
                    switch (reader.getFieldNumber()) {
                        case 1:
                            message.path = reader.readString();
                            break;
                        case 2:
                            message.digest = reader.readBytes();
                            break;
                        default: reader.skipField();
                    }
                }
                return message;
            };
            Input.prototype.serializeBinary = function () {
                return this.serialize();
            };
            Input.deserializeBinary = function (bytes) {
                return Input.deserialize(bytes);
            };
            return Input;
        }(googleProtobufExports.Message));
        _Input_one_of_decls = new WeakMap();
        worker.Input = Input;
        var WorkRequest = /** @class */ (function (_super) {
            __extends(WorkRequest, _super);
            function WorkRequest(data) {
                var _this = _super.call(this) || this;
                _WorkRequest_one_of_decls.set(_this, []);
                googleProtobufExports.Message.initialize(_this, Array.isArray(data) ? data : [], 0, -1, [1, 2], __classPrivateFieldGet(_this, _WorkRequest_one_of_decls, "f"));
                if (!Array.isArray(data) && typeof data == "object") {
                    if ("arguments" in data && data.arguments != undefined) {
                        _this.arguments = data.arguments;
                    }
                    if ("inputs" in data && data.inputs != undefined) {
                        _this.inputs = data.inputs;
                    }
                    if ("request_id" in data && data.request_id != undefined) {
                        _this.request_id = data.request_id;
                    }
                    if ("cancel" in data && data.cancel != undefined) {
                        _this.cancel = data.cancel;
                    }
                    if ("verbosity" in data && data.verbosity != undefined) {
                        _this.verbosity = data.verbosity;
                    }
                    if ("sandbox_dir" in data && data.sandbox_dir != undefined) {
                        _this.sandbox_dir = data.sandbox_dir;
                    }
                }
                return _this;
            }
            Object.defineProperty(WorkRequest.prototype, "arguments", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 1, []);
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 1, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkRequest.prototype, "inputs", {
                get: function () {
                    return googleProtobufExports.Message.getRepeatedWrapperField(this, Input, 2);
                },
                set: function (value) {
                    googleProtobufExports.Message.setRepeatedWrapperField(this, 2, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkRequest.prototype, "request_id", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 3, 0);
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 3, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkRequest.prototype, "cancel", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 4, false);
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 4, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkRequest.prototype, "verbosity", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 5, 0);
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 5, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkRequest.prototype, "sandbox_dir", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 6, "");
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 6, value);
                },
                enumerable: false,
                configurable: true
            });
            WorkRequest.fromObject = function (data) {
                var message = new WorkRequest({});
                if (data.arguments != null) {
                    message.arguments = data.arguments;
                }
                if (data.inputs != null) {
                    message.inputs = data.inputs.map(function (item) { return Input.fromObject(item); });
                }
                if (data.request_id != null) {
                    message.request_id = data.request_id;
                }
                if (data.cancel != null) {
                    message.cancel = data.cancel;
                }
                if (data.verbosity != null) {
                    message.verbosity = data.verbosity;
                }
                if (data.sandbox_dir != null) {
                    message.sandbox_dir = data.sandbox_dir;
                }
                return message;
            };
            WorkRequest.prototype.toObject = function () {
                var data = {};
                if (this.arguments != null) {
                    data.arguments = this.arguments;
                }
                if (this.inputs != null) {
                    data.inputs = this.inputs.map(function (item) { return item.toObject(); });
                }
                if (this.request_id != null) {
                    data.request_id = this.request_id;
                }
                if (this.cancel != null) {
                    data.cancel = this.cancel;
                }
                if (this.verbosity != null) {
                    data.verbosity = this.verbosity;
                }
                if (this.sandbox_dir != null) {
                    data.sandbox_dir = this.sandbox_dir;
                }
                return data;
            };
            WorkRequest.prototype.serialize = function (w) {
                var writer = w || new googleProtobufExports.BinaryWriter();
                if (this.arguments.length)
                    writer.writeRepeatedString(1, this.arguments);
                if (this.inputs.length)
                    writer.writeRepeatedMessage(2, this.inputs, function (item) { return item.serialize(writer); });
                if (this.request_id != 0)
                    writer.writeInt32(3, this.request_id);
                if (this.cancel != false)
                    writer.writeBool(4, this.cancel);
                if (this.verbosity != 0)
                    writer.writeInt32(5, this.verbosity);
                if (this.sandbox_dir.length)
                    writer.writeString(6, this.sandbox_dir);
                if (!w)
                    return writer.getResultBuffer();
            };
            WorkRequest.deserialize = function (bytes) {
                var reader = bytes instanceof googleProtobufExports.BinaryReader ? bytes : new googleProtobufExports.BinaryReader(bytes), message = new WorkRequest();
                while (reader.nextField()) {
                    if (reader.isEndGroup())
                        break;
                    switch (reader.getFieldNumber()) {
                        case 1:
                            googleProtobufExports.Message.addToRepeatedField(message, 1, reader.readString());
                            break;
                        case 2:
                            reader.readMessage(message.inputs, function () { return googleProtobufExports.Message.addToRepeatedWrapperField(message, 2, Input.deserialize(reader), Input); });
                            break;
                        case 3:
                            message.request_id = reader.readInt32();
                            break;
                        case 4:
                            message.cancel = reader.readBool();
                            break;
                        case 5:
                            message.verbosity = reader.readInt32();
                            break;
                        case 6:
                            message.sandbox_dir = reader.readString();
                            break;
                        default: reader.skipField();
                    }
                }
                return message;
            };
            WorkRequest.prototype.serializeBinary = function () {
                return this.serialize();
            };
            WorkRequest.deserializeBinary = function (bytes) {
                return WorkRequest.deserialize(bytes);
            };
            return WorkRequest;
        }(googleProtobufExports.Message));
        _WorkRequest_one_of_decls = new WeakMap();
        worker.WorkRequest = WorkRequest;
        var WorkResponse = /** @class */ (function (_super) {
            __extends(WorkResponse, _super);
            function WorkResponse(data) {
                var _this = _super.call(this) || this;
                _WorkResponse_one_of_decls.set(_this, []);
                googleProtobufExports.Message.initialize(_this, Array.isArray(data) ? data : [], 0, -1, [], __classPrivateFieldGet(_this, _WorkResponse_one_of_decls, "f"));
                if (!Array.isArray(data) && typeof data == "object") {
                    if ("exit_code" in data && data.exit_code != undefined) {
                        _this.exit_code = data.exit_code;
                    }
                    if ("output" in data && data.output != undefined) {
                        _this.output = data.output;
                    }
                    if ("request_id" in data && data.request_id != undefined) {
                        _this.request_id = data.request_id;
                    }
                    if ("was_cancelled" in data && data.was_cancelled != undefined) {
                        _this.was_cancelled = data.was_cancelled;
                    }
                }
                return _this;
            }
            Object.defineProperty(WorkResponse.prototype, "exit_code", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 1, 0);
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 1, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkResponse.prototype, "output", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 2, "");
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 2, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkResponse.prototype, "request_id", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 3, 0);
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 3, value);
                },
                enumerable: false,
                configurable: true
            });
            Object.defineProperty(WorkResponse.prototype, "was_cancelled", {
                get: function () {
                    return googleProtobufExports.Message.getFieldWithDefault(this, 4, false);
                },
                set: function (value) {
                    googleProtobufExports.Message.setField(this, 4, value);
                },
                enumerable: false,
                configurable: true
            });
            WorkResponse.fromObject = function (data) {
                var message = new WorkResponse({});
                if (data.exit_code != null) {
                    message.exit_code = data.exit_code;
                }
                if (data.output != null) {
                    message.output = data.output;
                }
                if (data.request_id != null) {
                    message.request_id = data.request_id;
                }
                if (data.was_cancelled != null) {
                    message.was_cancelled = data.was_cancelled;
                }
                return message;
            };
            WorkResponse.prototype.toObject = function () {
                var data = {};
                if (this.exit_code != null) {
                    data.exit_code = this.exit_code;
                }
                if (this.output != null) {
                    data.output = this.output;
                }
                if (this.request_id != null) {
                    data.request_id = this.request_id;
                }
                if (this.was_cancelled != null) {
                    data.was_cancelled = this.was_cancelled;
                }
                return data;
            };
            WorkResponse.prototype.serialize = function (w) {
                var writer = w || new googleProtobufExports.BinaryWriter();
                if (this.exit_code != 0)
                    writer.writeInt32(1, this.exit_code);
                if (this.output.length)
                    writer.writeString(2, this.output);
                if (this.request_id != 0)
                    writer.writeInt32(3, this.request_id);
                if (this.was_cancelled != false)
                    writer.writeBool(4, this.was_cancelled);
                if (!w)
                    return writer.getResultBuffer();
            };
            WorkResponse.deserialize = function (bytes) {
                var reader = bytes instanceof googleProtobufExports.BinaryReader ? bytes : new googleProtobufExports.BinaryReader(bytes), message = new WorkResponse();
                while (reader.nextField()) {
                    if (reader.isEndGroup())
                        break;
                    switch (reader.getFieldNumber()) {
                        case 1:
                            message.exit_code = reader.readInt32();
                            break;
                        case 2:
                            message.output = reader.readString();
                            break;
                        case 3:
                            message.request_id = reader.readInt32();
                            break;
                        case 4:
                            message.was_cancelled = reader.readBool();
                            break;
                        default: reader.skipField();
                    }
                }
                return message;
            };
            WorkResponse.prototype.serializeBinary = function () {
                return this.serialize();
            };
            WorkResponse.deserializeBinary = function (bytes) {
                return WorkResponse.deserialize(bytes);
            };
            return WorkResponse;
        }(googleProtobufExports.Message));
        _WorkResponse_one_of_decls = new WeakMap();
        worker.WorkResponse = WorkResponse;
    })(blaze.worker || (blaze.worker = {}));
})(blaze || (blaze = {}));

function enterWorkerLoop(implementation) {
    var _a, e_1, _b, _c;
    var _d;
    return __awaiter(this, void 0, void 0, function () {
        var abortionMap, prev, _loop_1, _e, _f, _g, e_1_1;
        return __generator(this, function (_h) {
            switch (_h.label) {
                case 0:
                    abortionMap = new Map();
                    prev = Buffer.alloc(0);
                    _h.label = 1;
                case 1:
                    _h.trys.push([1, 6, 7, 12]);
                    _loop_1 = function () {
                        _c = _g.value;
                        _e = false;
                        try {
                            var buffer = _c;
                            var chunk = Buffer.concat([prev, buffer]);
                            var current = void 0;
                            var size = readWorkRequestSize(chunk);
                            if (size.size <= chunk.length + size.headerSize) {
                                chunk = chunk.slice(size.headerSize);
                                current = chunk.slice(0, size.size);
                                prev = chunk.slice(size.size);
                            }
                            else {
                                prev = chunk;
                                return "continue";
                            }
                            var request = blaze.worker.WorkRequest.deserialize(current);
                            if (request.cancel) {
                                (_d = abortionMap.get(request.request_id)) === null || _d === void 0 ? void 0 : _d.abort();
                                return "continue";
                            }
                            var abortController = new AbortController();
                            abortionMap.set(request.request_id, abortController);
                            var response = new blaze.worker.WorkResponse({
                                request_id: request.request_id
                            });
                            var outputChunks = new Array();
                            var outputStream = new stream.Writable({
                                write: function (chunk, encoding, callback) {
                                    outputChunks.push(Buffer.from(chunk, encoding));
                                    callback === null || callback === void 0 ? void 0 : callback(undefined);
                                },
                                defaultEncoding: 'utf-8'
                            });
                            implementation({
                                arguments: request.arguments,
                                inputs: request.inputs,
                                request_id: request.request_id,
                                verbosity: request.verbosity,
                                sandbox_dir: request.sandbox_dir,
                                signal: abortController.signal,
                                output: outputStream
                            })
                                .then(function (exitCode) {
                                response.exit_code = exitCode;
                            })["catch"](function (reason) {
                                response.exit_code = 1;
                                var error;
                                if (typeof reason == 'object' && 'stack' in reason) {
                                    error = String(reason.stack);
                                }
                                else {
                                    error = String(reason);
                                }
                                outputStream.write(error);
                                // also output worker log if verbose.
                                request.verbosity > 0 && console.error(error);
                            })["finally"](function () {
                                abortionMap["delete"](request.request_id);
                                outputStream.end();
                                response.was_cancelled = abortController.signal.aborted;
                                response.output = Buffer.concat(outputChunks).toString('utf-8');
                                var responseBytes = response.serialize();
                                var responseSizeBytes = writeWorkResponseSize(responseBytes.byteLength);
                                process.stdout.write(Buffer.concat([responseSizeBytes, responseBytes]));
                            });
                        }
                        finally {
                            _e = true;
                        }
                    };
                    _e = true, _f = __asyncValues(process.stdin);
                    _h.label = 2;
                case 2: return [4 /*yield*/, _f.next()];
                case 3:
                    if (!(_g = _h.sent(), _a = _g.done, !_a)) return [3 /*break*/, 5];
                    _loop_1();
                    _h.label = 4;
                case 4: return [3 /*break*/, 2];
                case 5: return [3 /*break*/, 12];
                case 6:
                    e_1_1 = _h.sent();
                    e_1 = { error: e_1_1 };
                    return [3 /*break*/, 12];
                case 7:
                    _h.trys.push([7, , 10, 11]);
                    if (!(!_e && !_a && (_b = _f["return"]))) return [3 /*break*/, 9];
                    return [4 /*yield*/, _b.call(_f)];
                case 8:
                    _h.sent();
                    _h.label = 9;
                case 9: return [3 /*break*/, 11];
                case 10:
                    if (e_1) throw e_1.error;
                    return [7 /*endfinally*/];
                case 11: return [7 /*endfinally*/];
                case 12: return [2 /*return*/];
            }
        });
    });
}
function isPersistentWorker(args) {
    return args.indexOf('--persistent_worker') !== -1;
}

exports.enterWorkerLoop = enterWorkerLoop;
exports.isPersistentWorker = isPersistentWorker;
