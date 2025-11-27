'use strict';

var require$$0$2 = require('path');
var require$$2$1 = require('node:url');
var require$$1$1 = require('node:path');
var require$$0$1 = require('fs');
var require$$4 = require('node:fs');
var require$$5 = require('node:fs/promises');
var require$$0 = require('node:events');
var require$$1 = require('node:stream');
var require$$2 = require('node:string_decoder');
var require$$2$2 = require('util');
var require$$0$3 = require('os');
var require$$1$2 = require('tty');
var require$$1$3 = require('url');
var require$$0$4 = require('assert');
var require$$12 = require('module');

var c8 = {};

var commonjs$4 = {};

var commonjs$3 = {};

var balancedMatch;
var hasRequiredBalancedMatch;

function requireBalancedMatch () {
	if (hasRequiredBalancedMatch) return balancedMatch;
	hasRequiredBalancedMatch = 1;
	balancedMatch = balanced;
	function balanced(a, b, str) {
	  if (a instanceof RegExp) a = maybeMatch(a, str);
	  if (b instanceof RegExp) b = maybeMatch(b, str);

	  var r = range(a, b, str);

	  return r && {
	    start: r[0],
	    end: r[1],
	    pre: str.slice(0, r[0]),
	    body: str.slice(r[0] + a.length, r[1]),
	    post: str.slice(r[1] + b.length)
	  };
	}

	function maybeMatch(reg, str) {
	  var m = str.match(reg);
	  return m ? m[0] : null;
	}

	balanced.range = range;
	function range(a, b, str) {
	  var begs, beg, left, right, result;
	  var ai = str.indexOf(a);
	  var bi = str.indexOf(b, ai + 1);
	  var i = ai;

	  if (ai >= 0 && bi > 0) {
	    if(a===b) {
	      return [ai, bi];
	    }
	    begs = [];
	    left = str.length;

	    while (i >= 0 && !result) {
	      if (i == ai) {
	        begs.push(i);
	        ai = str.indexOf(a, i + 1);
	      } else if (begs.length == 1) {
	        result = [ begs.pop(), bi ];
	      } else {
	        beg = begs.pop();
	        if (beg < left) {
	          left = beg;
	          right = bi;
	        }

	        bi = str.indexOf(b, i + 1);
	      }

	      i = ai < bi && ai >= 0 ? ai : bi;
	    }

	    if (begs.length) {
	      result = [ left, right ];
	    }
	  }

	  return result;
	}
	return balancedMatch;
}

var braceExpansion;
var hasRequiredBraceExpansion;

function requireBraceExpansion () {
	if (hasRequiredBraceExpansion) return braceExpansion;
	hasRequiredBraceExpansion = 1;
	var balanced = requireBalancedMatch();

	braceExpansion = expandTop;

	var escSlash = '\0SLASH'+Math.random()+'\0';
	var escOpen = '\0OPEN'+Math.random()+'\0';
	var escClose = '\0CLOSE'+Math.random()+'\0';
	var escComma = '\0COMMA'+Math.random()+'\0';
	var escPeriod = '\0PERIOD'+Math.random()+'\0';

	function numeric(str) {
	  return parseInt(str, 10) == str
	    ? parseInt(str, 10)
	    : str.charCodeAt(0);
	}

	function escapeBraces(str) {
	  return str.split('\\\\').join(escSlash)
	            .split('\\{').join(escOpen)
	            .split('\\}').join(escClose)
	            .split('\\,').join(escComma)
	            .split('\\.').join(escPeriod);
	}

	function unescapeBraces(str) {
	  return str.split(escSlash).join('\\')
	            .split(escOpen).join('{')
	            .split(escClose).join('}')
	            .split(escComma).join(',')
	            .split(escPeriod).join('.');
	}


	// Basically just str.split(","), but handling cases
	// where we have nested braced sections, which should be
	// treated as individual members, like {a,{b,c},d}
	function parseCommaParts(str) {
	  if (!str)
	    return [''];

	  var parts = [];
	  var m = balanced('{', '}', str);

	  if (!m)
	    return str.split(',');

	  var pre = m.pre;
	  var body = m.body;
	  var post = m.post;
	  var p = pre.split(',');

	  p[p.length-1] += '{' + body + '}';
	  var postParts = parseCommaParts(post);
	  if (post.length) {
	    p[p.length-1] += postParts.shift();
	    p.push.apply(p, postParts);
	  }

	  parts.push.apply(parts, p);

	  return parts;
	}

	function expandTop(str) {
	  if (!str)
	    return [];

	  // I don't know why Bash 4.3 does this, but it does.
	  // Anything starting with {} will have the first two bytes preserved
	  // but *only* at the top level, so {},a}b will not expand to anything,
	  // but a{},b}c will be expanded to [a}c,abc].
	  // One could argue that this is a bug in Bash, but since the goal of
	  // this module is to match Bash's rules, we escape a leading {}
	  if (str.substr(0, 2) === '{}') {
	    str = '\\{\\}' + str.substr(2);
	  }

	  return expand(escapeBraces(str), true).map(unescapeBraces);
	}

	function embrace(str) {
	  return '{' + str + '}';
	}
	function isPadded(el) {
	  return /^-?0\d/.test(el);
	}

	function lte(i, y) {
	  return i <= y;
	}
	function gte(i, y) {
	  return i >= y;
	}

	function expand(str, isTop) {
	  var expansions = [];

	  var m = balanced('{', '}', str);
	  if (!m) return [str];

	  // no need to expand pre, since it is guaranteed to be free of brace-sets
	  var pre = m.pre;
	  var post = m.post.length
	    ? expand(m.post, false)
	    : [''];

	  if (/\$$/.test(m.pre)) {    
	    for (var k = 0; k < post.length; k++) {
	      var expansion = pre+ '{' + m.body + '}' + post[k];
	      expansions.push(expansion);
	    }
	  } else {
	    var isNumericSequence = /^-?\d+\.\.-?\d+(?:\.\.-?\d+)?$/.test(m.body);
	    var isAlphaSequence = /^[a-zA-Z]\.\.[a-zA-Z](?:\.\.-?\d+)?$/.test(m.body);
	    var isSequence = isNumericSequence || isAlphaSequence;
	    var isOptions = m.body.indexOf(',') >= 0;
	    if (!isSequence && !isOptions) {
	      // {a},b}
	      if (m.post.match(/,(?!,).*\}/)) {
	        str = m.pre + '{' + m.body + escClose + m.post;
	        return expand(str);
	      }
	      return [str];
	    }

	    var n;
	    if (isSequence) {
	      n = m.body.split(/\.\./);
	    } else {
	      n = parseCommaParts(m.body);
	      if (n.length === 1) {
	        // x{{a,b}}y ==> x{a}y x{b}y
	        n = expand(n[0], false).map(embrace);
	        if (n.length === 1) {
	          return post.map(function(p) {
	            return m.pre + n[0] + p;
	          });
	        }
	      }
	    }

	    // at this point, n is the parts, and we know it's not a comma set
	    // with a single entry.
	    var N;

	    if (isSequence) {
	      var x = numeric(n[0]);
	      var y = numeric(n[1]);
	      var width = Math.max(n[0].length, n[1].length);
	      var incr = n.length == 3
	        ? Math.abs(numeric(n[2]))
	        : 1;
	      var test = lte;
	      var reverse = y < x;
	      if (reverse) {
	        incr *= -1;
	        test = gte;
	      }
	      var pad = n.some(isPadded);

	      N = [];

	      for (var i = x; test(i, y); i += incr) {
	        var c;
	        if (isAlphaSequence) {
	          c = String.fromCharCode(i);
	          if (c === '\\')
	            c = '';
	        } else {
	          c = String(i);
	          if (pad) {
	            var need = width - c.length;
	            if (need > 0) {
	              var z = new Array(need + 1).join('0');
	              if (i < 0)
	                c = '-' + z + c.slice(1);
	              else
	                c = z + c;
	            }
	          }
	        }
	        N.push(c);
	      }
	    } else {
	      N = [];

	      for (var j = 0; j < n.length; j++) {
	        N.push.apply(N, expand(n[j], false));
	      }
	    }

	    for (var j = 0; j < N.length; j++) {
	      for (var k = 0; k < post.length; k++) {
	        var expansion = pre + N[j] + post[k];
	        if (!isTop || isSequence || expansion)
	          expansions.push(expansion);
	      }
	    }
	  }

	  return expansions;
	}
	return braceExpansion;
}

var assertValidPattern = {};

var hasRequiredAssertValidPattern;

function requireAssertValidPattern () {
	if (hasRequiredAssertValidPattern) return assertValidPattern;
	hasRequiredAssertValidPattern = 1;
	Object.defineProperty(assertValidPattern, "__esModule", { value: true });
	assertValidPattern.assertValidPattern = void 0;
	const MAX_PATTERN_LENGTH = 1024 * 64;
	const assertValidPattern$1 = (pattern) => {
	    if (typeof pattern !== 'string') {
	        throw new TypeError('invalid pattern');
	    }
	    if (pattern.length > MAX_PATTERN_LENGTH) {
	        throw new TypeError('pattern is too long');
	    }
	};
	assertValidPattern.assertValidPattern = assertValidPattern$1;
	
	return assertValidPattern;
}

var ast = {};

var braceExpressions = {};

var hasRequiredBraceExpressions;

function requireBraceExpressions () {
	if (hasRequiredBraceExpressions) return braceExpressions;
	hasRequiredBraceExpressions = 1;
	// translate the various posix character classes into unicode properties
	// this works across all unicode locales
	Object.defineProperty(braceExpressions, "__esModule", { value: true });
	braceExpressions.parseClass = void 0;
	// { <posix class>: [<translation>, /u flag required, negated]
	const posixClasses = {
	    '[:alnum:]': ['\\p{L}\\p{Nl}\\p{Nd}', true],
	    '[:alpha:]': ['\\p{L}\\p{Nl}', true],
	    '[:ascii:]': ['\\x' + '00-\\x' + '7f', false],
	    '[:blank:]': ['\\p{Zs}\\t', true],
	    '[:cntrl:]': ['\\p{Cc}', true],
	    '[:digit:]': ['\\p{Nd}', true],
	    '[:graph:]': ['\\p{Z}\\p{C}', true, true],
	    '[:lower:]': ['\\p{Ll}', true],
	    '[:print:]': ['\\p{C}', true],
	    '[:punct:]': ['\\p{P}', true],
	    '[:space:]': ['\\p{Z}\\t\\r\\n\\v\\f', true],
	    '[:upper:]': ['\\p{Lu}', true],
	    '[:word:]': ['\\p{L}\\p{Nl}\\p{Nd}\\p{Pc}', true],
	    '[:xdigit:]': ['A-Fa-f0-9', false],
	};
	// only need to escape a few things inside of brace expressions
	// escapes: [ \ ] -
	const braceEscape = (s) => s.replace(/[[\]\\-]/g, '\\$&');
	// escape all regexp magic characters
	const regexpEscape = (s) => s.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
	// everything has already been escaped, we just have to join
	const rangesToString = (ranges) => ranges.join('');
	// takes a glob string at a posix brace expression, and returns
	// an equivalent regular expression source, and boolean indicating
	// whether the /u flag needs to be applied, and the number of chars
	// consumed to parse the character class.
	// This also removes out of order ranges, and returns ($.) if the
	// entire class just no good.
	const parseClass = (glob, position) => {
	    const pos = position;
	    /* c8 ignore start */
	    if (glob.charAt(pos) !== '[') {
	        throw new Error('not in a brace expression');
	    }
	    /* c8 ignore stop */
	    const ranges = [];
	    const negs = [];
	    let i = pos + 1;
	    let sawStart = false;
	    let uflag = false;
	    let escaping = false;
	    let negate = false;
	    let endPos = pos;
	    let rangeStart = '';
	    WHILE: while (i < glob.length) {
	        const c = glob.charAt(i);
	        if ((c === '!' || c === '^') && i === pos + 1) {
	            negate = true;
	            i++;
	            continue;
	        }
	        if (c === ']' && sawStart && !escaping) {
	            endPos = i + 1;
	            break;
	        }
	        sawStart = true;
	        if (c === '\\') {
	            if (!escaping) {
	                escaping = true;
	                i++;
	                continue;
	            }
	            // escaped \ char, fall through and treat like normal char
	        }
	        if (c === '[' && !escaping) {
	            // either a posix class, a collation equivalent, or just a [
	            for (const [cls, [unip, u, neg]] of Object.entries(posixClasses)) {
	                if (glob.startsWith(cls, i)) {
	                    // invalid, [a-[] is fine, but not [a-[:alpha]]
	                    if (rangeStart) {
	                        return ['$.', false, glob.length - pos, true];
	                    }
	                    i += cls.length;
	                    if (neg)
	                        negs.push(unip);
	                    else
	                        ranges.push(unip);
	                    uflag = uflag || u;
	                    continue WHILE;
	                }
	            }
	        }
	        // now it's just a normal character, effectively
	        escaping = false;
	        if (rangeStart) {
	            // throw this range away if it's not valid, but others
	            // can still match.
	            if (c > rangeStart) {
	                ranges.push(braceEscape(rangeStart) + '-' + braceEscape(c));
	            }
	            else if (c === rangeStart) {
	                ranges.push(braceEscape(c));
	            }
	            rangeStart = '';
	            i++;
	            continue;
	        }
	        // now might be the start of a range.
	        // can be either c-d or c-] or c<more...>] or c] at this point
	        if (glob.startsWith('-]', i + 1)) {
	            ranges.push(braceEscape(c + '-'));
	            i += 2;
	            continue;
	        }
	        if (glob.startsWith('-', i + 1)) {
	            rangeStart = c;
	            i += 2;
	            continue;
	        }
	        // not the start of a range, just a single character
	        ranges.push(braceEscape(c));
	        i++;
	    }
	    if (endPos < i) {
	        // didn't see the end of the class, not a valid class,
	        // but might still be valid as a literal match.
	        return ['', false, 0, false];
	    }
	    // if we got no ranges and no negates, then we have a range that
	    // cannot possibly match anything, and that poisons the whole glob
	    if (!ranges.length && !negs.length) {
	        return ['$.', false, glob.length - pos, true];
	    }
	    // if we got one positive range, and it's a single character, then that's
	    // not actually a magic pattern, it's just that one literal character.
	    // we should not treat that as "magic", we should just return the literal
	    // character. [_] is a perfectly valid way to escape glob magic chars.
	    if (negs.length === 0 &&
	        ranges.length === 1 &&
	        /^\\?.$/.test(ranges[0]) &&
	        !negate) {
	        const r = ranges[0].length === 2 ? ranges[0].slice(-1) : ranges[0];
	        return [regexpEscape(r), false, endPos - pos, false];
	    }
	    const sranges = '[' + (negate ? '^' : '') + rangesToString(ranges) + ']';
	    const snegs = '[' + (negate ? '' : '^') + rangesToString(negs) + ']';
	    const comb = ranges.length && negs.length
	        ? '(' + sranges + '|' + snegs + ')'
	        : ranges.length
	            ? sranges
	            : snegs;
	    return [comb, uflag, endPos - pos, true];
	};
	braceExpressions.parseClass = parseClass;
	
	return braceExpressions;
}

var _unescape = {};

var hasRequired_unescape;

function require_unescape () {
	if (hasRequired_unescape) return _unescape;
	hasRequired_unescape = 1;
	Object.defineProperty(_unescape, "__esModule", { value: true });
	_unescape.unescape = void 0;
	/**
	 * Un-escape a string that has been escaped with {@link escape}.
	 *
	 * If the {@link windowsPathsNoEscape} option is used, then square-brace
	 * escapes are removed, but not backslash escapes.  For example, it will turn
	 * the string `'[*]'` into `*`, but it will not turn `'\\*'` into `'*'`,
	 * becuase `\` is a path separator in `windowsPathsNoEscape` mode.
	 *
	 * When `windowsPathsNoEscape` is not set, then both brace escapes and
	 * backslash escapes are removed.
	 *
	 * Slashes (and backslashes in `windowsPathsNoEscape` mode) cannot be escaped
	 * or unescaped.
	 */
	const unescape = (s, { windowsPathsNoEscape = false, } = {}) => {
	    return windowsPathsNoEscape
	        ? s.replace(/\[([^\/\\])\]/g, '$1')
	        : s.replace(/((?!\\).|^)\[([^\/\\])\]/g, '$1$2').replace(/\\([^\/])/g, '$1');
	};
	_unescape.unescape = unescape;
	
	return _unescape;
}

var hasRequiredAst;

function requireAst () {
	if (hasRequiredAst) return ast;
	hasRequiredAst = 1;
	// parse a single path portion
	Object.defineProperty(ast, "__esModule", { value: true });
	ast.AST = void 0;
	const brace_expressions_js_1 = requireBraceExpressions();
	const unescape_js_1 = require_unescape();
	const types = new Set(['!', '?', '+', '*', '@']);
	const isExtglobType = (c) => types.has(c);
	// Patterns that get prepended to bind to the start of either the
	// entire string, or just a single path portion, to prevent dots
	// and/or traversal patterns, when needed.
	// Exts don't need the ^ or / bit, because the root binds that already.
	const startNoTraversal = '(?!(?:^|/)\\.\\.?(?:$|/))';
	const startNoDot = '(?!\\.)';
	// characters that indicate a start of pattern needs the "no dots" bit,
	// because a dot *might* be matched. ( is not in the list, because in
	// the case of a child extglob, it will handle the prevention itself.
	const addPatternStart = new Set(['[', '.']);
	// cases where traversal is A-OK, no dot prevention needed
	const justDots = new Set(['..', '.']);
	const reSpecials = new Set('().*{}+?[]^$\\!');
	const regExpEscape = (s) => s.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
	// any single thing other than /
	const qmark = '[^/]';
	// * => any number of characters
	const star = qmark + '*?';
	// use + when we need to ensure that *something* matches, because the * is
	// the only thing in the path portion.
	const starNoEmpty = qmark + '+?';
	// remove the \ chars that we added if we end up doing a nonmagic compare
	// const deslash = (s: string) => s.replace(/\\(.)/g, '$1')
	class AST {
	    type;
	    #root;
	    #hasMagic;
	    #uflag = false;
	    #parts = [];
	    #parent;
	    #parentIndex;
	    #negs;
	    #filledNegs = false;
	    #options;
	    #toString;
	    // set to true if it's an extglob with no children
	    // (which really means one child of '')
	    #emptyExt = false;
	    constructor(type, parent, options = {}) {
	        this.type = type;
	        // extglobs are inherently magical
	        if (type)
	            this.#hasMagic = true;
	        this.#parent = parent;
	        this.#root = this.#parent ? this.#parent.#root : this;
	        this.#options = this.#root === this ? options : this.#root.#options;
	        this.#negs = this.#root === this ? [] : this.#root.#negs;
	        if (type === '!' && !this.#root.#filledNegs)
	            this.#negs.push(this);
	        this.#parentIndex = this.#parent ? this.#parent.#parts.length : 0;
	    }
	    get hasMagic() {
	        /* c8 ignore start */
	        if (this.#hasMagic !== undefined)
	            return this.#hasMagic;
	        /* c8 ignore stop */
	        for (const p of this.#parts) {
	            if (typeof p === 'string')
	                continue;
	            if (p.type || p.hasMagic)
	                return (this.#hasMagic = true);
	        }
	        // note: will be undefined until we generate the regexp src and find out
	        return this.#hasMagic;
	    }
	    // reconstructs the pattern
	    toString() {
	        if (this.#toString !== undefined)
	            return this.#toString;
	        if (!this.type) {
	            return (this.#toString = this.#parts.map(p => String(p)).join(''));
	        }
	        else {
	            return (this.#toString =
	                this.type + '(' + this.#parts.map(p => String(p)).join('|') + ')');
	        }
	    }
	    #fillNegs() {
	        /* c8 ignore start */
	        if (this !== this.#root)
	            throw new Error('should only call on root');
	        if (this.#filledNegs)
	            return this;
	        /* c8 ignore stop */
	        // call toString() once to fill this out
	        this.toString();
	        this.#filledNegs = true;
	        let n;
	        while ((n = this.#negs.pop())) {
	            if (n.type !== '!')
	                continue;
	            // walk up the tree, appending everthing that comes AFTER parentIndex
	            let p = n;
	            let pp = p.#parent;
	            while (pp) {
	                for (let i = p.#parentIndex + 1; !pp.type && i < pp.#parts.length; i++) {
	                    for (const part of n.#parts) {
	                        /* c8 ignore start */
	                        if (typeof part === 'string') {
	                            throw new Error('string part in extglob AST??');
	                        }
	                        /* c8 ignore stop */
	                        part.copyIn(pp.#parts[i]);
	                    }
	                }
	                p = pp;
	                pp = p.#parent;
	            }
	        }
	        return this;
	    }
	    push(...parts) {
	        for (const p of parts) {
	            if (p === '')
	                continue;
	            /* c8 ignore start */
	            if (typeof p !== 'string' && !(p instanceof AST && p.#parent === this)) {
	                throw new Error('invalid part: ' + p);
	            }
	            /* c8 ignore stop */
	            this.#parts.push(p);
	        }
	    }
	    toJSON() {
	        const ret = this.type === null
	            ? this.#parts.slice().map(p => (typeof p === 'string' ? p : p.toJSON()))
	            : [this.type, ...this.#parts.map(p => p.toJSON())];
	        if (this.isStart() && !this.type)
	            ret.unshift([]);
	        if (this.isEnd() &&
	            (this === this.#root ||
	                (this.#root.#filledNegs && this.#parent?.type === '!'))) {
	            ret.push({});
	        }
	        return ret;
	    }
	    isStart() {
	        if (this.#root === this)
	            return true;
	        // if (this.type) return !!this.#parent?.isStart()
	        if (!this.#parent?.isStart())
	            return false;
	        if (this.#parentIndex === 0)
	            return true;
	        // if everything AHEAD of this is a negation, then it's still the "start"
	        const p = this.#parent;
	        for (let i = 0; i < this.#parentIndex; i++) {
	            const pp = p.#parts[i];
	            if (!(pp instanceof AST && pp.type === '!')) {
	                return false;
	            }
	        }
	        return true;
	    }
	    isEnd() {
	        if (this.#root === this)
	            return true;
	        if (this.#parent?.type === '!')
	            return true;
	        if (!this.#parent?.isEnd())
	            return false;
	        if (!this.type)
	            return this.#parent?.isEnd();
	        // if not root, it'll always have a parent
	        /* c8 ignore start */
	        const pl = this.#parent ? this.#parent.#parts.length : 0;
	        /* c8 ignore stop */
	        return this.#parentIndex === pl - 1;
	    }
	    copyIn(part) {
	        if (typeof part === 'string')
	            this.push(part);
	        else
	            this.push(part.clone(this));
	    }
	    clone(parent) {
	        const c = new AST(this.type, parent);
	        for (const p of this.#parts) {
	            c.copyIn(p);
	        }
	        return c;
	    }
	    static #parseAST(str, ast, pos, opt) {
	        let escaping = false;
	        let inBrace = false;
	        let braceStart = -1;
	        let braceNeg = false;
	        if (ast.type === null) {
	            // outside of a extglob, append until we find a start
	            let i = pos;
	            let acc = '';
	            while (i < str.length) {
	                const c = str.charAt(i++);
	                // still accumulate escapes at this point, but we do ignore
	                // starts that are escaped
	                if (escaping || c === '\\') {
	                    escaping = !escaping;
	                    acc += c;
	                    continue;
	                }
	                if (inBrace) {
	                    if (i === braceStart + 1) {
	                        if (c === '^' || c === '!') {
	                            braceNeg = true;
	                        }
	                    }
	                    else if (c === ']' && !(i === braceStart + 2 && braceNeg)) {
	                        inBrace = false;
	                    }
	                    acc += c;
	                    continue;
	                }
	                else if (c === '[') {
	                    inBrace = true;
	                    braceStart = i;
	                    braceNeg = false;
	                    acc += c;
	                    continue;
	                }
	                if (!opt.noext && isExtglobType(c) && str.charAt(i) === '(') {
	                    ast.push(acc);
	                    acc = '';
	                    const ext = new AST(c, ast);
	                    i = AST.#parseAST(str, ext, i, opt);
	                    ast.push(ext);
	                    continue;
	                }
	                acc += c;
	            }
	            ast.push(acc);
	            return i;
	        }
	        // some kind of extglob, pos is at the (
	        // find the next | or )
	        let i = pos + 1;
	        let part = new AST(null, ast);
	        const parts = [];
	        let acc = '';
	        while (i < str.length) {
	            const c = str.charAt(i++);
	            // still accumulate escapes at this point, but we do ignore
	            // starts that are escaped
	            if (escaping || c === '\\') {
	                escaping = !escaping;
	                acc += c;
	                continue;
	            }
	            if (inBrace) {
	                if (i === braceStart + 1) {
	                    if (c === '^' || c === '!') {
	                        braceNeg = true;
	                    }
	                }
	                else if (c === ']' && !(i === braceStart + 2 && braceNeg)) {
	                    inBrace = false;
	                }
	                acc += c;
	                continue;
	            }
	            else if (c === '[') {
	                inBrace = true;
	                braceStart = i;
	                braceNeg = false;
	                acc += c;
	                continue;
	            }
	            if (isExtglobType(c) && str.charAt(i) === '(') {
	                part.push(acc);
	                acc = '';
	                const ext = new AST(c, part);
	                part.push(ext);
	                i = AST.#parseAST(str, ext, i, opt);
	                continue;
	            }
	            if (c === '|') {
	                part.push(acc);
	                acc = '';
	                parts.push(part);
	                part = new AST(null, ast);
	                continue;
	            }
	            if (c === ')') {
	                if (acc === '' && ast.#parts.length === 0) {
	                    ast.#emptyExt = true;
	                }
	                part.push(acc);
	                acc = '';
	                ast.push(...parts, part);
	                return i;
	            }
	            acc += c;
	        }
	        // unfinished extglob
	        // if we got here, it was a malformed extglob! not an extglob, but
	        // maybe something else in there.
	        ast.type = null;
	        ast.#hasMagic = undefined;
	        ast.#parts = [str.substring(pos - 1)];
	        return i;
	    }
	    static fromGlob(pattern, options = {}) {
	        const ast = new AST(null, undefined, options);
	        AST.#parseAST(pattern, ast, 0, options);
	        return ast;
	    }
	    // returns the regular expression if there's magic, or the unescaped
	    // string if not.
	    toMMPattern() {
	        // should only be called on root
	        /* c8 ignore start */
	        if (this !== this.#root)
	            return this.#root.toMMPattern();
	        /* c8 ignore stop */
	        const glob = this.toString();
	        const [re, body, hasMagic, uflag] = this.toRegExpSource();
	        // if we're in nocase mode, and not nocaseMagicOnly, then we do
	        // still need a regular expression if we have to case-insensitively
	        // match capital/lowercase characters.
	        const anyMagic = hasMagic ||
	            this.#hasMagic ||
	            (this.#options.nocase &&
	                !this.#options.nocaseMagicOnly &&
	                glob.toUpperCase() !== glob.toLowerCase());
	        if (!anyMagic) {
	            return body;
	        }
	        const flags = (this.#options.nocase ? 'i' : '') + (uflag ? 'u' : '');
	        return Object.assign(new RegExp(`^${re}$`, flags), {
	            _src: re,
	            _glob: glob,
	        });
	    }
	    get options() {
	        return this.#options;
	    }
	    // returns the string match, the regexp source, whether there's magic
	    // in the regexp (so a regular expression is required) and whether or
	    // not the uflag is needed for the regular expression (for posix classes)
	    // TODO: instead of injecting the start/end at this point, just return
	    // the BODY of the regexp, along with the start/end portions suitable
	    // for binding the start/end in either a joined full-path makeRe context
	    // (where we bind to (^|/), or a standalone matchPart context (where
	    // we bind to ^, and not /).  Otherwise slashes get duped!
	    //
	    // In part-matching mode, the start is:
	    // - if not isStart: nothing
	    // - if traversal possible, but not allowed: ^(?!\.\.?$)
	    // - if dots allowed or not possible: ^
	    // - if dots possible and not allowed: ^(?!\.)
	    // end is:
	    // - if not isEnd(): nothing
	    // - else: $
	    //
	    // In full-path matching mode, we put the slash at the START of the
	    // pattern, so start is:
	    // - if first pattern: same as part-matching mode
	    // - if not isStart(): nothing
	    // - if traversal possible, but not allowed: /(?!\.\.?(?:$|/))
	    // - if dots allowed or not possible: /
	    // - if dots possible and not allowed: /(?!\.)
	    // end is:
	    // - if last pattern, same as part-matching mode
	    // - else nothing
	    //
	    // Always put the (?:$|/) on negated tails, though, because that has to be
	    // there to bind the end of the negated pattern portion, and it's easier to
	    // just stick it in now rather than try to inject it later in the middle of
	    // the pattern.
	    //
	    // We can just always return the same end, and leave it up to the caller
	    // to know whether it's going to be used joined or in parts.
	    // And, if the start is adjusted slightly, can do the same there:
	    // - if not isStart: nothing
	    // - if traversal possible, but not allowed: (?:/|^)(?!\.\.?$)
	    // - if dots allowed or not possible: (?:/|^)
	    // - if dots possible and not allowed: (?:/|^)(?!\.)
	    //
	    // But it's better to have a simpler binding without a conditional, for
	    // performance, so probably better to return both start options.
	    //
	    // Then the caller just ignores the end if it's not the first pattern,
	    // and the start always gets applied.
	    //
	    // But that's always going to be $ if it's the ending pattern, or nothing,
	    // so the caller can just attach $ at the end of the pattern when building.
	    //
	    // So the todo is:
	    // - better detect what kind of start is needed
	    // - return both flavors of starting pattern
	    // - attach $ at the end of the pattern when creating the actual RegExp
	    //
	    // Ah, but wait, no, that all only applies to the root when the first pattern
	    // is not an extglob. If the first pattern IS an extglob, then we need all
	    // that dot prevention biz to live in the extglob portions, because eg
	    // +(*|.x*) can match .xy but not .yx.
	    //
	    // So, return the two flavors if it's #root and the first child is not an
	    // AST, otherwise leave it to the child AST to handle it, and there,
	    // use the (?:^|/) style of start binding.
	    //
	    // Even simplified further:
	    // - Since the start for a join is eg /(?!\.) and the start for a part
	    // is ^(?!\.), we can just prepend (?!\.) to the pattern (either root
	    // or start or whatever) and prepend ^ or / at the Regexp construction.
	    toRegExpSource(allowDot) {
	        const dot = allowDot ?? !!this.#options.dot;
	        if (this.#root === this)
	            this.#fillNegs();
	        if (!this.type) {
	            const noEmpty = this.isStart() && this.isEnd();
	            const src = this.#parts
	                .map(p => {
	                const [re, _, hasMagic, uflag] = typeof p === 'string'
	                    ? AST.#parseGlob(p, this.#hasMagic, noEmpty)
	                    : p.toRegExpSource(allowDot);
	                this.#hasMagic = this.#hasMagic || hasMagic;
	                this.#uflag = this.#uflag || uflag;
	                return re;
	            })
	                .join('');
	            let start = '';
	            if (this.isStart()) {
	                if (typeof this.#parts[0] === 'string') {
	                    // this is the string that will match the start of the pattern,
	                    // so we need to protect against dots and such.
	                    // '.' and '..' cannot match unless the pattern is that exactly,
	                    // even if it starts with . or dot:true is set.
	                    const dotTravAllowed = this.#parts.length === 1 && justDots.has(this.#parts[0]);
	                    if (!dotTravAllowed) {
	                        const aps = addPatternStart;
	                        // check if we have a possibility of matching . or ..,
	                        // and prevent that.
	                        const needNoTrav = 
	                        // dots are allowed, and the pattern starts with [ or .
	                        (dot && aps.has(src.charAt(0))) ||
	                            // the pattern starts with \., and then [ or .
	                            (src.startsWith('\\.') && aps.has(src.charAt(2))) ||
	                            // the pattern starts with \.\., and then [ or .
	                            (src.startsWith('\\.\\.') && aps.has(src.charAt(4)));
	                        // no need to prevent dots if it can't match a dot, or if a
	                        // sub-pattern will be preventing it anyway.
	                        const needNoDot = !dot && !allowDot && aps.has(src.charAt(0));
	                        start = needNoTrav ? startNoTraversal : needNoDot ? startNoDot : '';
	                    }
	                }
	            }
	            // append the "end of path portion" pattern to negation tails
	            let end = '';
	            if (this.isEnd() &&
	                this.#root.#filledNegs &&
	                this.#parent?.type === '!') {
	                end = '(?:$|\\/)';
	            }
	            const final = start + src + end;
	            return [
	                final,
	                (0, unescape_js_1.unescape)(src),
	                (this.#hasMagic = !!this.#hasMagic),
	                this.#uflag,
	            ];
	        }
	        // We need to calculate the body *twice* if it's a repeat pattern
	        // at the start, once in nodot mode, then again in dot mode, so a
	        // pattern like *(?) can match 'x.y'
	        const repeated = this.type === '*' || this.type === '+';
	        // some kind of extglob
	        const start = this.type === '!' ? '(?:(?!(?:' : '(?:';
	        let body = this.#partsToRegExp(dot);
	        if (this.isStart() && this.isEnd() && !body && this.type !== '!') {
	            // invalid extglob, has to at least be *something* present, if it's
	            // the entire path portion.
	            const s = this.toString();
	            this.#parts = [s];
	            this.type = null;
	            this.#hasMagic = undefined;
	            return [s, (0, unescape_js_1.unescape)(this.toString()), false, false];
	        }
	        // XXX abstract out this map method
	        let bodyDotAllowed = !repeated || allowDot || dot || false
	            ? ''
	            : this.#partsToRegExp(true);
	        if (bodyDotAllowed === body) {
	            bodyDotAllowed = '';
	        }
	        if (bodyDotAllowed) {
	            body = `(?:${body})(?:${bodyDotAllowed})*?`;
	        }
	        // an empty !() is exactly equivalent to a starNoEmpty
	        let final = '';
	        if (this.type === '!' && this.#emptyExt) {
	            final = (this.isStart() && !dot ? startNoDot : '') + starNoEmpty;
	        }
	        else {
	            const close = this.type === '!'
	                ? // !() must match something,but !(x) can match ''
	                    '))' +
	                        (this.isStart() && !dot && !allowDot ? startNoDot : '') +
	                        star +
	                        ')'
	                : this.type === '@'
	                    ? ')'
	                    : this.type === '?'
	                        ? ')?'
	                        : this.type === '+' && bodyDotAllowed
	                            ? ')'
	                            : this.type === '*' && bodyDotAllowed
	                                ? `)?`
	                                : `)${this.type}`;
	            final = start + body + close;
	        }
	        return [
	            final,
	            (0, unescape_js_1.unescape)(body),
	            (this.#hasMagic = !!this.#hasMagic),
	            this.#uflag,
	        ];
	    }
	    #partsToRegExp(dot) {
	        return this.#parts
	            .map(p => {
	            // extglob ASTs should only contain parent ASTs
	            /* c8 ignore start */
	            if (typeof p === 'string') {
	                throw new Error('string type in extglob ast??');
	            }
	            /* c8 ignore stop */
	            // can ignore hasMagic, because extglobs are already always magic
	            const [re, _, _hasMagic, uflag] = p.toRegExpSource(dot);
	            this.#uflag = this.#uflag || uflag;
	            return re;
	        })
	            .filter(p => !(this.isStart() && this.isEnd()) || !!p)
	            .join('|');
	    }
	    static #parseGlob(glob, hasMagic, noEmpty = false) {
	        let escaping = false;
	        let re = '';
	        let uflag = false;
	        for (let i = 0; i < glob.length; i++) {
	            const c = glob.charAt(i);
	            if (escaping) {
	                escaping = false;
	                re += (reSpecials.has(c) ? '\\' : '') + c;
	                continue;
	            }
	            if (c === '\\') {
	                if (i === glob.length - 1) {
	                    re += '\\\\';
	                }
	                else {
	                    escaping = true;
	                }
	                continue;
	            }
	            if (c === '[') {
	                const [src, needUflag, consumed, magic] = (0, brace_expressions_js_1.parseClass)(glob, i);
	                if (consumed) {
	                    re += src;
	                    uflag = uflag || needUflag;
	                    i += consumed - 1;
	                    hasMagic = hasMagic || magic;
	                    continue;
	                }
	            }
	            if (c === '*') {
	                if (noEmpty && glob === '*')
	                    re += starNoEmpty;
	                else
	                    re += star;
	                hasMagic = true;
	                continue;
	            }
	            if (c === '?') {
	                re += qmark;
	                hasMagic = true;
	                continue;
	            }
	            re += regExpEscape(c);
	        }
	        return [re, (0, unescape_js_1.unescape)(glob), !!hasMagic, uflag];
	    }
	}
	ast.AST = AST;
	
	return ast;
}

var _escape = {};

var hasRequired_escape;

function require_escape () {
	if (hasRequired_escape) return _escape;
	hasRequired_escape = 1;
	Object.defineProperty(_escape, "__esModule", { value: true });
	_escape.escape = void 0;
	/**
	 * Escape all magic characters in a glob pattern.
	 *
	 * If the {@link windowsPathsNoEscape | GlobOptions.windowsPathsNoEscape}
	 * option is used, then characters are escaped by wrapping in `[]`, because
	 * a magic character wrapped in a character class can only be satisfied by
	 * that exact character.  In this mode, `\` is _not_ escaped, because it is
	 * not interpreted as a magic character, but instead as a path separator.
	 */
	const escape = (s, { windowsPathsNoEscape = false, } = {}) => {
	    // don't need to escape +@! because we escape the parens
	    // that make those magic, and escaping ! as [!] isn't valid,
	    // because [!]] is a valid glob class meaning not ']'.
	    return windowsPathsNoEscape
	        ? s.replace(/[?*()[\]]/g, '[$&]')
	        : s.replace(/[?*()[\]\\]/g, '\\$&');
	};
	_escape.escape = escape;
	
	return _escape;
}

var hasRequiredCommonjs$4;

function requireCommonjs$4 () {
	if (hasRequiredCommonjs$4) return commonjs$3;
	hasRequiredCommonjs$4 = 1;
	(function (exports) {
		var __importDefault = (commonjs$3 && commonjs$3.__importDefault) || function (mod) {
		    return (mod && mod.__esModule) ? mod : { "default": mod };
		};
		Object.defineProperty(exports, "__esModule", { value: true });
		exports.unescape = exports.escape = exports.AST = exports.Minimatch = exports.match = exports.makeRe = exports.braceExpand = exports.defaults = exports.filter = exports.GLOBSTAR = exports.sep = exports.minimatch = void 0;
		const brace_expansion_1 = __importDefault(requireBraceExpansion());
		const assert_valid_pattern_js_1 = requireAssertValidPattern();
		const ast_js_1 = requireAst();
		const escape_js_1 = require_escape();
		const unescape_js_1 = require_unescape();
		const minimatch = (p, pattern, options = {}) => {
		    (0, assert_valid_pattern_js_1.assertValidPattern)(pattern);
		    // shortcut: comments match nothing.
		    if (!options.nocomment && pattern.charAt(0) === '#') {
		        return false;
		    }
		    return new Minimatch(pattern, options).match(p);
		};
		exports.minimatch = minimatch;
		// Optimized checking for the most common glob patterns.
		const starDotExtRE = /^\*+([^+@!?\*\[\(]*)$/;
		const starDotExtTest = (ext) => (f) => !f.startsWith('.') && f.endsWith(ext);
		const starDotExtTestDot = (ext) => (f) => f.endsWith(ext);
		const starDotExtTestNocase = (ext) => {
		    ext = ext.toLowerCase();
		    return (f) => !f.startsWith('.') && f.toLowerCase().endsWith(ext);
		};
		const starDotExtTestNocaseDot = (ext) => {
		    ext = ext.toLowerCase();
		    return (f) => f.toLowerCase().endsWith(ext);
		};
		const starDotStarRE = /^\*+\.\*+$/;
		const starDotStarTest = (f) => !f.startsWith('.') && f.includes('.');
		const starDotStarTestDot = (f) => f !== '.' && f !== '..' && f.includes('.');
		const dotStarRE = /^\.\*+$/;
		const dotStarTest = (f) => f !== '.' && f !== '..' && f.startsWith('.');
		const starRE = /^\*+$/;
		const starTest = (f) => f.length !== 0 && !f.startsWith('.');
		const starTestDot = (f) => f.length !== 0 && f !== '.' && f !== '..';
		const qmarksRE = /^\?+([^+@!?\*\[\(]*)?$/;
		const qmarksTestNocase = ([$0, ext = '']) => {
		    const noext = qmarksTestNoExt([$0]);
		    if (!ext)
		        return noext;
		    ext = ext.toLowerCase();
		    return (f) => noext(f) && f.toLowerCase().endsWith(ext);
		};
		const qmarksTestNocaseDot = ([$0, ext = '']) => {
		    const noext = qmarksTestNoExtDot([$0]);
		    if (!ext)
		        return noext;
		    ext = ext.toLowerCase();
		    return (f) => noext(f) && f.toLowerCase().endsWith(ext);
		};
		const qmarksTestDot = ([$0, ext = '']) => {
		    const noext = qmarksTestNoExtDot([$0]);
		    return !ext ? noext : (f) => noext(f) && f.endsWith(ext);
		};
		const qmarksTest = ([$0, ext = '']) => {
		    const noext = qmarksTestNoExt([$0]);
		    return !ext ? noext : (f) => noext(f) && f.endsWith(ext);
		};
		const qmarksTestNoExt = ([$0]) => {
		    const len = $0.length;
		    return (f) => f.length === len && !f.startsWith('.');
		};
		const qmarksTestNoExtDot = ([$0]) => {
		    const len = $0.length;
		    return (f) => f.length === len && f !== '.' && f !== '..';
		};
		/* c8 ignore start */
		const defaultPlatform = (typeof process === 'object' && process
		    ? (typeof process.env === 'object' &&
		        process.env &&
		        process.env.__MINIMATCH_TESTING_PLATFORM__) ||
		        process.platform
		    : 'posix');
		const path = {
		    win32: { sep: '\\' },
		    posix: { sep: '/' },
		};
		/* c8 ignore stop */
		exports.sep = defaultPlatform === 'win32' ? path.win32.sep : path.posix.sep;
		exports.minimatch.sep = exports.sep;
		exports.GLOBSTAR = Symbol('globstar **');
		exports.minimatch.GLOBSTAR = exports.GLOBSTAR;
		// any single thing other than /
		// don't need to escape / when using new RegExp()
		const qmark = '[^/]';
		// * => any number of characters
		const star = qmark + '*?';
		// ** when dots are allowed.  Anything goes, except .. and .
		// not (^ or / followed by one or two dots followed by $ or /),
		// followed by anything, any number of times.
		const twoStarDot = '(?:(?!(?:\\/|^)(?:\\.{1,2})($|\\/)).)*?';
		// not a ^ or / followed by a dot,
		// followed by anything, any number of times.
		const twoStarNoDot = '(?:(?!(?:\\/|^)\\.).)*?';
		const filter = (pattern, options = {}) => (p) => (0, exports.minimatch)(p, pattern, options);
		exports.filter = filter;
		exports.minimatch.filter = exports.filter;
		const ext = (a, b = {}) => Object.assign({}, a, b);
		const defaults = (def) => {
		    if (!def || typeof def !== 'object' || !Object.keys(def).length) {
		        return exports.minimatch;
		    }
		    const orig = exports.minimatch;
		    const m = (p, pattern, options = {}) => orig(p, pattern, ext(def, options));
		    return Object.assign(m, {
		        Minimatch: class Minimatch extends orig.Minimatch {
		            constructor(pattern, options = {}) {
		                super(pattern, ext(def, options));
		            }
		            static defaults(options) {
		                return orig.defaults(ext(def, options)).Minimatch;
		            }
		        },
		        AST: class AST extends orig.AST {
		            /* c8 ignore start */
		            constructor(type, parent, options = {}) {
		                super(type, parent, ext(def, options));
		            }
		            /* c8 ignore stop */
		            static fromGlob(pattern, options = {}) {
		                return orig.AST.fromGlob(pattern, ext(def, options));
		            }
		        },
		        unescape: (s, options = {}) => orig.unescape(s, ext(def, options)),
		        escape: (s, options = {}) => orig.escape(s, ext(def, options)),
		        filter: (pattern, options = {}) => orig.filter(pattern, ext(def, options)),
		        defaults: (options) => orig.defaults(ext(def, options)),
		        makeRe: (pattern, options = {}) => orig.makeRe(pattern, ext(def, options)),
		        braceExpand: (pattern, options = {}) => orig.braceExpand(pattern, ext(def, options)),
		        match: (list, pattern, options = {}) => orig.match(list, pattern, ext(def, options)),
		        sep: orig.sep,
		        GLOBSTAR: exports.GLOBSTAR,
		    });
		};
		exports.defaults = defaults;
		exports.minimatch.defaults = exports.defaults;
		// Brace expansion:
		// a{b,c}d -> abd acd
		// a{b,}c -> abc ac
		// a{0..3}d -> a0d a1d a2d a3d
		// a{b,c{d,e}f}g -> abg acdfg acefg
		// a{b,c}d{e,f}g -> abdeg acdeg abdeg abdfg
		//
		// Invalid sets are not expanded.
		// a{2..}b -> a{2..}b
		// a{b}c -> a{b}c
		const braceExpand = (pattern, options = {}) => {
		    (0, assert_valid_pattern_js_1.assertValidPattern)(pattern);
		    // Thanks to Yeting Li <https://github.com/yetingli> for
		    // improving this regexp to avoid a ReDOS vulnerability.
		    if (options.nobrace || !/\{(?:(?!\{).)*\}/.test(pattern)) {
		        // shortcut. no need to expand.
		        return [pattern];
		    }
		    return (0, brace_expansion_1.default)(pattern);
		};
		exports.braceExpand = braceExpand;
		exports.minimatch.braceExpand = exports.braceExpand;
		// parse a component of the expanded set.
		// At this point, no pattern may contain "/" in it
		// so we're going to return a 2d array, where each entry is the full
		// pattern, split on '/', and then turned into a regular expression.
		// A regexp is made at the end which joins each array with an
		// escaped /, and another full one which joins each regexp with |.
		//
		// Following the lead of Bash 4.1, note that "**" only has special meaning
		// when it is the *only* thing in a path portion.  Otherwise, any series
		// of * is equivalent to a single *.  Globstar behavior is enabled by
		// default, and can be disabled by setting options.noglobstar.
		const makeRe = (pattern, options = {}) => new Minimatch(pattern, options).makeRe();
		exports.makeRe = makeRe;
		exports.minimatch.makeRe = exports.makeRe;
		const match = (list, pattern, options = {}) => {
		    const mm = new Minimatch(pattern, options);
		    list = list.filter(f => mm.match(f));
		    if (mm.options.nonull && !list.length) {
		        list.push(pattern);
		    }
		    return list;
		};
		exports.match = match;
		exports.minimatch.match = exports.match;
		// replace stuff like \* with *
		const globMagic = /[?*]|[+@!]\(.*?\)|\[|\]/;
		const regExpEscape = (s) => s.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
		class Minimatch {
		    options;
		    set;
		    pattern;
		    windowsPathsNoEscape;
		    nonegate;
		    negate;
		    comment;
		    empty;
		    preserveMultipleSlashes;
		    partial;
		    globSet;
		    globParts;
		    nocase;
		    isWindows;
		    platform;
		    windowsNoMagicRoot;
		    regexp;
		    constructor(pattern, options = {}) {
		        (0, assert_valid_pattern_js_1.assertValidPattern)(pattern);
		        options = options || {};
		        this.options = options;
		        this.pattern = pattern;
		        this.platform = options.platform || defaultPlatform;
		        this.isWindows = this.platform === 'win32';
		        this.windowsPathsNoEscape =
		            !!options.windowsPathsNoEscape || options.allowWindowsEscape === false;
		        if (this.windowsPathsNoEscape) {
		            this.pattern = this.pattern.replace(/\\/g, '/');
		        }
		        this.preserveMultipleSlashes = !!options.preserveMultipleSlashes;
		        this.regexp = null;
		        this.negate = false;
		        this.nonegate = !!options.nonegate;
		        this.comment = false;
		        this.empty = false;
		        this.partial = !!options.partial;
		        this.nocase = !!this.options.nocase;
		        this.windowsNoMagicRoot =
		            options.windowsNoMagicRoot !== undefined
		                ? options.windowsNoMagicRoot
		                : !!(this.isWindows && this.nocase);
		        this.globSet = [];
		        this.globParts = [];
		        this.set = [];
		        // make the set of regexps etc.
		        this.make();
		    }
		    hasMagic() {
		        if (this.options.magicalBraces && this.set.length > 1) {
		            return true;
		        }
		        for (const pattern of this.set) {
		            for (const part of pattern) {
		                if (typeof part !== 'string')
		                    return true;
		            }
		        }
		        return false;
		    }
		    debug(..._) { }
		    make() {
		        const pattern = this.pattern;
		        const options = this.options;
		        // empty patterns and comments match nothing.
		        if (!options.nocomment && pattern.charAt(0) === '#') {
		            this.comment = true;
		            return;
		        }
		        if (!pattern) {
		            this.empty = true;
		            return;
		        }
		        // step 1: figure out negation, etc.
		        this.parseNegate();
		        // step 2: expand braces
		        this.globSet = [...new Set(this.braceExpand())];
		        if (options.debug) {
		            this.debug = (...args) => console.error(...args);
		        }
		        this.debug(this.pattern, this.globSet);
		        // step 3: now we have a set, so turn each one into a series of
		        // path-portion matching patterns.
		        // These will be regexps, except in the case of "**", which is
		        // set to the GLOBSTAR object for globstar behavior,
		        // and will not contain any / characters
		        //
		        // First, we preprocess to make the glob pattern sets a bit simpler
		        // and deduped.  There are some perf-killing patterns that can cause
		        // problems with a glob walk, but we can simplify them down a bit.
		        const rawGlobParts = this.globSet.map(s => this.slashSplit(s));
		        this.globParts = this.preprocess(rawGlobParts);
		        this.debug(this.pattern, this.globParts);
		        // glob --> regexps
		        let set = this.globParts.map((s, _, __) => {
		            if (this.isWindows && this.windowsNoMagicRoot) {
		                // check if it's a drive or unc path.
		                const isUNC = s[0] === '' &&
		                    s[1] === '' &&
		                    (s[2] === '?' || !globMagic.test(s[2])) &&
		                    !globMagic.test(s[3]);
		                const isDrive = /^[a-z]:/i.test(s[0]);
		                if (isUNC) {
		                    return [...s.slice(0, 4), ...s.slice(4).map(ss => this.parse(ss))];
		                }
		                else if (isDrive) {
		                    return [s[0], ...s.slice(1).map(ss => this.parse(ss))];
		                }
		            }
		            return s.map(ss => this.parse(ss));
		        });
		        this.debug(this.pattern, set);
		        // filter out everything that didn't compile properly.
		        this.set = set.filter(s => s.indexOf(false) === -1);
		        // do not treat the ? in UNC paths as magic
		        if (this.isWindows) {
		            for (let i = 0; i < this.set.length; i++) {
		                const p = this.set[i];
		                if (p[0] === '' &&
		                    p[1] === '' &&
		                    this.globParts[i][2] === '?' &&
		                    typeof p[3] === 'string' &&
		                    /^[a-z]:$/i.test(p[3])) {
		                    p[2] = '?';
		                }
		            }
		        }
		        this.debug(this.pattern, this.set);
		    }
		    // various transforms to equivalent pattern sets that are
		    // faster to process in a filesystem walk.  The goal is to
		    // eliminate what we can, and push all ** patterns as far
		    // to the right as possible, even if it increases the number
		    // of patterns that we have to process.
		    preprocess(globParts) {
		        // if we're not in globstar mode, then turn all ** into *
		        if (this.options.noglobstar) {
		            for (let i = 0; i < globParts.length; i++) {
		                for (let j = 0; j < globParts[i].length; j++) {
		                    if (globParts[i][j] === '**') {
		                        globParts[i][j] = '*';
		                    }
		                }
		            }
		        }
		        const { optimizationLevel = 1 } = this.options;
		        if (optimizationLevel >= 2) {
		            // aggressive optimization for the purpose of fs walking
		            globParts = this.firstPhasePreProcess(globParts);
		            globParts = this.secondPhasePreProcess(globParts);
		        }
		        else if (optimizationLevel >= 1) {
		            // just basic optimizations to remove some .. parts
		            globParts = this.levelOneOptimize(globParts);
		        }
		        else {
		            // just collapse multiple ** portions into one
		            globParts = this.adjascentGlobstarOptimize(globParts);
		        }
		        return globParts;
		    }
		    // just get rid of adjascent ** portions
		    adjascentGlobstarOptimize(globParts) {
		        return globParts.map(parts => {
		            let gs = -1;
		            while (-1 !== (gs = parts.indexOf('**', gs + 1))) {
		                let i = gs;
		                while (parts[i + 1] === '**') {
		                    i++;
		                }
		                if (i !== gs) {
		                    parts.splice(gs, i - gs);
		                }
		            }
		            return parts;
		        });
		    }
		    // get rid of adjascent ** and resolve .. portions
		    levelOneOptimize(globParts) {
		        return globParts.map(parts => {
		            parts = parts.reduce((set, part) => {
		                const prev = set[set.length - 1];
		                if (part === '**' && prev === '**') {
		                    return set;
		                }
		                if (part === '..') {
		                    if (prev && prev !== '..' && prev !== '.' && prev !== '**') {
		                        set.pop();
		                        return set;
		                    }
		                }
		                set.push(part);
		                return set;
		            }, []);
		            return parts.length === 0 ? [''] : parts;
		        });
		    }
		    levelTwoFileOptimize(parts) {
		        if (!Array.isArray(parts)) {
		            parts = this.slashSplit(parts);
		        }
		        let didSomething = false;
		        do {
		            didSomething = false;
		            // <pre>/<e>/<rest> -> <pre>/<rest>
		            if (!this.preserveMultipleSlashes) {
		                for (let i = 1; i < parts.length - 1; i++) {
		                    const p = parts[i];
		                    // don't squeeze out UNC patterns
		                    if (i === 1 && p === '' && parts[0] === '')
		                        continue;
		                    if (p === '.' || p === '') {
		                        didSomething = true;
		                        parts.splice(i, 1);
		                        i--;
		                    }
		                }
		                if (parts[0] === '.' &&
		                    parts.length === 2 &&
		                    (parts[1] === '.' || parts[1] === '')) {
		                    didSomething = true;
		                    parts.pop();
		                }
		            }
		            // <pre>/<p>/../<rest> -> <pre>/<rest>
		            let dd = 0;
		            while (-1 !== (dd = parts.indexOf('..', dd + 1))) {
		                const p = parts[dd - 1];
		                if (p && p !== '.' && p !== '..' && p !== '**') {
		                    didSomething = true;
		                    parts.splice(dd - 1, 2);
		                    dd -= 2;
		                }
		            }
		        } while (didSomething);
		        return parts.length === 0 ? [''] : parts;
		    }
		    // First phase: single-pattern processing
		    // <pre> is 1 or more portions
		    // <rest> is 1 or more portions
		    // <p> is any portion other than ., .., '', or **
		    // <e> is . or ''
		    //
		    // **/.. is *brutal* for filesystem walking performance, because
		    // it effectively resets the recursive walk each time it occurs,
		    // and ** cannot be reduced out by a .. pattern part like a regexp
		    // or most strings (other than .., ., and '') can be.
		    //
		    // <pre>/**/../<p>/<p>/<rest> -> {<pre>/../<p>/<p>/<rest>,<pre>/**/<p>/<p>/<rest>}
		    // <pre>/<e>/<rest> -> <pre>/<rest>
		    // <pre>/<p>/../<rest> -> <pre>/<rest>
		    // **/**/<rest> -> **/<rest>
		    //
		    // **/*/<rest> -> */**/<rest> <== not valid because ** doesn't follow
		    // this WOULD be allowed if ** did follow symlinks, or * didn't
		    firstPhasePreProcess(globParts) {
		        let didSomething = false;
		        do {
		            didSomething = false;
		            // <pre>/**/../<p>/<p>/<rest> -> {<pre>/../<p>/<p>/<rest>,<pre>/**/<p>/<p>/<rest>}
		            for (let parts of globParts) {
		                let gs = -1;
		                while (-1 !== (gs = parts.indexOf('**', gs + 1))) {
		                    let gss = gs;
		                    while (parts[gss + 1] === '**') {
		                        // <pre>/**/**/<rest> -> <pre>/**/<rest>
		                        gss++;
		                    }
		                    // eg, if gs is 2 and gss is 4, that means we have 3 **
		                    // parts, and can remove 2 of them.
		                    if (gss > gs) {
		                        parts.splice(gs + 1, gss - gs);
		                    }
		                    let next = parts[gs + 1];
		                    const p = parts[gs + 2];
		                    const p2 = parts[gs + 3];
		                    if (next !== '..')
		                        continue;
		                    if (!p ||
		                        p === '.' ||
		                        p === '..' ||
		                        !p2 ||
		                        p2 === '.' ||
		                        p2 === '..') {
		                        continue;
		                    }
		                    didSomething = true;
		                    // edit parts in place, and push the new one
		                    parts.splice(gs, 1);
		                    const other = parts.slice(0);
		                    other[gs] = '**';
		                    globParts.push(other);
		                    gs--;
		                }
		                // <pre>/<e>/<rest> -> <pre>/<rest>
		                if (!this.preserveMultipleSlashes) {
		                    for (let i = 1; i < parts.length - 1; i++) {
		                        const p = parts[i];
		                        // don't squeeze out UNC patterns
		                        if (i === 1 && p === '' && parts[0] === '')
		                            continue;
		                        if (p === '.' || p === '') {
		                            didSomething = true;
		                            parts.splice(i, 1);
		                            i--;
		                        }
		                    }
		                    if (parts[0] === '.' &&
		                        parts.length === 2 &&
		                        (parts[1] === '.' || parts[1] === '')) {
		                        didSomething = true;
		                        parts.pop();
		                    }
		                }
		                // <pre>/<p>/../<rest> -> <pre>/<rest>
		                let dd = 0;
		                while (-1 !== (dd = parts.indexOf('..', dd + 1))) {
		                    const p = parts[dd - 1];
		                    if (p && p !== '.' && p !== '..' && p !== '**') {
		                        didSomething = true;
		                        const needDot = dd === 1 && parts[dd + 1] === '**';
		                        const splin = needDot ? ['.'] : [];
		                        parts.splice(dd - 1, 2, ...splin);
		                        if (parts.length === 0)
		                            parts.push('');
		                        dd -= 2;
		                    }
		                }
		            }
		        } while (didSomething);
		        return globParts;
		    }
		    // second phase: multi-pattern dedupes
		    // {<pre>/*/<rest>,<pre>/<p>/<rest>} -> <pre>/*/<rest>
		    // {<pre>/<rest>,<pre>/<rest>} -> <pre>/<rest>
		    // {<pre>/**/<rest>,<pre>/<rest>} -> <pre>/**/<rest>
		    //
		    // {<pre>/**/<rest>,<pre>/**/<p>/<rest>} -> <pre>/**/<rest>
		    // ^-- not valid because ** doens't follow symlinks
		    secondPhasePreProcess(globParts) {
		        for (let i = 0; i < globParts.length - 1; i++) {
		            for (let j = i + 1; j < globParts.length; j++) {
		                const matched = this.partsMatch(globParts[i], globParts[j], !this.preserveMultipleSlashes);
		                if (matched) {
		                    globParts[i] = [];
		                    globParts[j] = matched;
		                    break;
		                }
		            }
		        }
		        return globParts.filter(gs => gs.length);
		    }
		    partsMatch(a, b, emptyGSMatch = false) {
		        let ai = 0;
		        let bi = 0;
		        let result = [];
		        let which = '';
		        while (ai < a.length && bi < b.length) {
		            if (a[ai] === b[bi]) {
		                result.push(which === 'b' ? b[bi] : a[ai]);
		                ai++;
		                bi++;
		            }
		            else if (emptyGSMatch && a[ai] === '**' && b[bi] === a[ai + 1]) {
		                result.push(a[ai]);
		                ai++;
		            }
		            else if (emptyGSMatch && b[bi] === '**' && a[ai] === b[bi + 1]) {
		                result.push(b[bi]);
		                bi++;
		            }
		            else if (a[ai] === '*' &&
		                b[bi] &&
		                (this.options.dot || !b[bi].startsWith('.')) &&
		                b[bi] !== '**') {
		                if (which === 'b')
		                    return false;
		                which = 'a';
		                result.push(a[ai]);
		                ai++;
		                bi++;
		            }
		            else if (b[bi] === '*' &&
		                a[ai] &&
		                (this.options.dot || !a[ai].startsWith('.')) &&
		                a[ai] !== '**') {
		                if (which === 'a')
		                    return false;
		                which = 'b';
		                result.push(b[bi]);
		                ai++;
		                bi++;
		            }
		            else {
		                return false;
		            }
		        }
		        // if we fall out of the loop, it means they two are identical
		        // as long as their lengths match
		        return a.length === b.length && result;
		    }
		    parseNegate() {
		        if (this.nonegate)
		            return;
		        const pattern = this.pattern;
		        let negate = false;
		        let negateOffset = 0;
		        for (let i = 0; i < pattern.length && pattern.charAt(i) === '!'; i++) {
		            negate = !negate;
		            negateOffset++;
		        }
		        if (negateOffset)
		            this.pattern = pattern.slice(negateOffset);
		        this.negate = negate;
		    }
		    // set partial to true to test if, for example,
		    // "/a/b" matches the start of "/*/b/*/d"
		    // Partial means, if you run out of file before you run
		    // out of pattern, then that's fine, as long as all
		    // the parts match.
		    matchOne(file, pattern, partial = false) {
		        const options = this.options;
		        // UNC paths like //?/X:/... can match X:/... and vice versa
		        // Drive letters in absolute drive or unc paths are always compared
		        // case-insensitively.
		        if (this.isWindows) {
		            const fileDrive = typeof file[0] === 'string' && /^[a-z]:$/i.test(file[0]);
		            const fileUNC = !fileDrive &&
		                file[0] === '' &&
		                file[1] === '' &&
		                file[2] === '?' &&
		                /^[a-z]:$/i.test(file[3]);
		            const patternDrive = typeof pattern[0] === 'string' && /^[a-z]:$/i.test(pattern[0]);
		            const patternUNC = !patternDrive &&
		                pattern[0] === '' &&
		                pattern[1] === '' &&
		                pattern[2] === '?' &&
		                typeof pattern[3] === 'string' &&
		                /^[a-z]:$/i.test(pattern[3]);
		            const fdi = fileUNC ? 3 : fileDrive ? 0 : undefined;
		            const pdi = patternUNC ? 3 : patternDrive ? 0 : undefined;
		            if (typeof fdi === 'number' && typeof pdi === 'number') {
		                const [fd, pd] = [file[fdi], pattern[pdi]];
		                if (fd.toLowerCase() === pd.toLowerCase()) {
		                    pattern[pdi] = fd;
		                    if (pdi > fdi) {
		                        pattern = pattern.slice(pdi);
		                    }
		                    else if (fdi > pdi) {
		                        file = file.slice(fdi);
		                    }
		                }
		            }
		        }
		        // resolve and reduce . and .. portions in the file as well.
		        // dont' need to do the second phase, because it's only one string[]
		        const { optimizationLevel = 1 } = this.options;
		        if (optimizationLevel >= 2) {
		            file = this.levelTwoFileOptimize(file);
		        }
		        this.debug('matchOne', this, { file, pattern });
		        this.debug('matchOne', file.length, pattern.length);
		        for (var fi = 0, pi = 0, fl = file.length, pl = pattern.length; fi < fl && pi < pl; fi++, pi++) {
		            this.debug('matchOne loop');
		            var p = pattern[pi];
		            var f = file[fi];
		            this.debug(pattern, p, f);
		            // should be impossible.
		            // some invalid regexp stuff in the set.
		            /* c8 ignore start */
		            if (p === false) {
		                return false;
		            }
		            /* c8 ignore stop */
		            if (p === exports.GLOBSTAR) {
		                this.debug('GLOBSTAR', [pattern, p, f]);
		                // "**"
		                // a/**/b/**/c would match the following:
		                // a/b/x/y/z/c
		                // a/x/y/z/b/c
		                // a/b/x/b/x/c
		                // a/b/c
		                // To do this, take the rest of the pattern after
		                // the **, and see if it would match the file remainder.
		                // If so, return success.
		                // If not, the ** "swallows" a segment, and try again.
		                // This is recursively awful.
		                //
		                // a/**/b/**/c matching a/b/x/y/z/c
		                // - a matches a
		                // - doublestar
		                //   - matchOne(b/x/y/z/c, b/**/c)
		                //     - b matches b
		                //     - doublestar
		                //       - matchOne(x/y/z/c, c) -> no
		                //       - matchOne(y/z/c, c) -> no
		                //       - matchOne(z/c, c) -> no
		                //       - matchOne(c, c) yes, hit
		                var fr = fi;
		                var pr = pi + 1;
		                if (pr === pl) {
		                    this.debug('** at the end');
		                    // a ** at the end will just swallow the rest.
		                    // We have found a match.
		                    // however, it will not swallow /.x, unless
		                    // options.dot is set.
		                    // . and .. are *never* matched by **, for explosively
		                    // exponential reasons.
		                    for (; fi < fl; fi++) {
		                        if (file[fi] === '.' ||
		                            file[fi] === '..' ||
		                            (!options.dot && file[fi].charAt(0) === '.'))
		                            return false;
		                    }
		                    return true;
		                }
		                // ok, let's see if we can swallow whatever we can.
		                while (fr < fl) {
		                    var swallowee = file[fr];
		                    this.debug('\nglobstar while', file, fr, pattern, pr, swallowee);
		                    // XXX remove this slice.  Just pass the start index.
		                    if (this.matchOne(file.slice(fr), pattern.slice(pr), partial)) {
		                        this.debug('globstar found match!', fr, fl, swallowee);
		                        // found a match.
		                        return true;
		                    }
		                    else {
		                        // can't swallow "." or ".." ever.
		                        // can only swallow ".foo" when explicitly asked.
		                        if (swallowee === '.' ||
		                            swallowee === '..' ||
		                            (!options.dot && swallowee.charAt(0) === '.')) {
		                            this.debug('dot detected!', file, fr, pattern, pr);
		                            break;
		                        }
		                        // ** swallows a segment, and continue.
		                        this.debug('globstar swallow a segment, and continue');
		                        fr++;
		                    }
		                }
		                // no match was found.
		                // However, in partial mode, we can't say this is necessarily over.
		                /* c8 ignore start */
		                if (partial) {
		                    // ran out of file
		                    this.debug('\n>>> no match, partial?', file, fr, pattern, pr);
		                    if (fr === fl) {
		                        return true;
		                    }
		                }
		                /* c8 ignore stop */
		                return false;
		            }
		            // something other than **
		            // non-magic patterns just have to match exactly
		            // patterns with magic have been turned into regexps.
		            let hit;
		            if (typeof p === 'string') {
		                hit = f === p;
		                this.debug('string match', p, f, hit);
		            }
		            else {
		                hit = p.test(f);
		                this.debug('pattern match', p, f, hit);
		            }
		            if (!hit)
		                return false;
		        }
		        // Note: ending in / means that we'll get a final ""
		        // at the end of the pattern.  This can only match a
		        // corresponding "" at the end of the file.
		        // If the file ends in /, then it can only match a
		        // a pattern that ends in /, unless the pattern just
		        // doesn't have any more for it. But, a/b/ should *not*
		        // match "a/b/*", even though "" matches against the
		        // [^/]*? pattern, except in partial mode, where it might
		        // simply not be reached yet.
		        // However, a/b/ should still satisfy a/*
		        // now either we fell off the end of the pattern, or we're done.
		        if (fi === fl && pi === pl) {
		            // ran out of pattern and filename at the same time.
		            // an exact hit!
		            return true;
		        }
		        else if (fi === fl) {
		            // ran out of file, but still had pattern left.
		            // this is ok if we're doing the match as part of
		            // a glob fs traversal.
		            return partial;
		        }
		        else if (pi === pl) {
		            // ran out of pattern, still have file left.
		            // this is only acceptable if we're on the very last
		            // empty segment of a file with a trailing slash.
		            // a/* should match a/b/
		            return fi === fl - 1 && file[fi] === '';
		            /* c8 ignore start */
		        }
		        else {
		            // should be unreachable.
		            throw new Error('wtf?');
		        }
		        /* c8 ignore stop */
		    }
		    braceExpand() {
		        return (0, exports.braceExpand)(this.pattern, this.options);
		    }
		    parse(pattern) {
		        (0, assert_valid_pattern_js_1.assertValidPattern)(pattern);
		        const options = this.options;
		        // shortcuts
		        if (pattern === '**')
		            return exports.GLOBSTAR;
		        if (pattern === '')
		            return '';
		        // far and away, the most common glob pattern parts are
		        // *, *.*, and *.<ext>  Add a fast check method for those.
		        let m;
		        let fastTest = null;
		        if ((m = pattern.match(starRE))) {
		            fastTest = options.dot ? starTestDot : starTest;
		        }
		        else if ((m = pattern.match(starDotExtRE))) {
		            fastTest = (options.nocase
		                ? options.dot
		                    ? starDotExtTestNocaseDot
		                    : starDotExtTestNocase
		                : options.dot
		                    ? starDotExtTestDot
		                    : starDotExtTest)(m[1]);
		        }
		        else if ((m = pattern.match(qmarksRE))) {
		            fastTest = (options.nocase
		                ? options.dot
		                    ? qmarksTestNocaseDot
		                    : qmarksTestNocase
		                : options.dot
		                    ? qmarksTestDot
		                    : qmarksTest)(m);
		        }
		        else if ((m = pattern.match(starDotStarRE))) {
		            fastTest = options.dot ? starDotStarTestDot : starDotStarTest;
		        }
		        else if ((m = pattern.match(dotStarRE))) {
		            fastTest = dotStarTest;
		        }
		        const re = ast_js_1.AST.fromGlob(pattern, this.options).toMMPattern();
		        if (fastTest && typeof re === 'object') {
		            // Avoids overriding in frozen environments
		            Reflect.defineProperty(re, 'test', { value: fastTest });
		        }
		        return re;
		    }
		    makeRe() {
		        if (this.regexp || this.regexp === false)
		            return this.regexp;
		        // at this point, this.set is a 2d array of partial
		        // pattern strings, or "**".
		        //
		        // It's better to use .match().  This function shouldn't
		        // be used, really, but it's pretty convenient sometimes,
		        // when you just want to work with a regex.
		        const set = this.set;
		        if (!set.length) {
		            this.regexp = false;
		            return this.regexp;
		        }
		        const options = this.options;
		        const twoStar = options.noglobstar
		            ? star
		            : options.dot
		                ? twoStarDot
		                : twoStarNoDot;
		        const flags = new Set(options.nocase ? ['i'] : []);
		        // regexpify non-globstar patterns
		        // if ** is only item, then we just do one twoStar
		        // if ** is first, and there are more, prepend (\/|twoStar\/)? to next
		        // if ** is last, append (\/twoStar|) to previous
		        // if ** is in the middle, append (\/|\/twoStar\/) to previous
		        // then filter out GLOBSTAR symbols
		        let re = set
		            .map(pattern => {
		            const pp = pattern.map(p => {
		                if (p instanceof RegExp) {
		                    for (const f of p.flags.split(''))
		                        flags.add(f);
		                }
		                return typeof p === 'string'
		                    ? regExpEscape(p)
		                    : p === exports.GLOBSTAR
		                        ? exports.GLOBSTAR
		                        : p._src;
		            });
		            pp.forEach((p, i) => {
		                const next = pp[i + 1];
		                const prev = pp[i - 1];
		                if (p !== exports.GLOBSTAR || prev === exports.GLOBSTAR) {
		                    return;
		                }
		                if (prev === undefined) {
		                    if (next !== undefined && next !== exports.GLOBSTAR) {
		                        pp[i + 1] = '(?:\\/|' + twoStar + '\\/)?' + next;
		                    }
		                    else {
		                        pp[i] = twoStar;
		                    }
		                }
		                else if (next === undefined) {
		                    pp[i - 1] = prev + '(?:\\/|' + twoStar + ')?';
		                }
		                else if (next !== exports.GLOBSTAR) {
		                    pp[i - 1] = prev + '(?:\\/|\\/' + twoStar + '\\/)' + next;
		                    pp[i + 1] = exports.GLOBSTAR;
		                }
		            });
		            return pp.filter(p => p !== exports.GLOBSTAR).join('/');
		        })
		            .join('|');
		        // need to wrap in parens if we had more than one thing with |,
		        // otherwise only the first will be anchored to ^ and the last to $
		        const [open, close] = set.length > 1 ? ['(?:', ')'] : ['', ''];
		        // must match entire pattern
		        // ending in a * or ** will make it less strict.
		        re = '^' + open + re + close + '$';
		        // can match anything, as long as it's not this.
		        if (this.negate)
		            re = '^(?!' + re + ').+$';
		        try {
		            this.regexp = new RegExp(re, [...flags].join(''));
		            /* c8 ignore start */
		        }
		        catch (ex) {
		            // should be impossible
		            this.regexp = false;
		        }
		        /* c8 ignore stop */
		        return this.regexp;
		    }
		    slashSplit(p) {
		        // if p starts with // on windows, we preserve that
		        // so that UNC paths aren't broken.  Otherwise, any number of
		        // / characters are coalesced into one, unless
		        // preserveMultipleSlashes is set to true.
		        if (this.preserveMultipleSlashes) {
		            return p.split('/');
		        }
		        else if (this.isWindows && /^\/\/[^\/]+/.test(p)) {
		            // add an extra '' for the one we lose
		            return ['', ...p.split(/\/+/)];
		        }
		        else {
		            return p.split(/\/+/);
		        }
		    }
		    match(f, partial = this.partial) {
		        this.debug('match', f, this.pattern);
		        // short-circuit in the case of busted things.
		        // comments, etc.
		        if (this.comment) {
		            return false;
		        }
		        if (this.empty) {
		            return f === '';
		        }
		        if (f === '/' && partial) {
		            return true;
		        }
		        const options = this.options;
		        // windows: need to use /, not \
		        if (this.isWindows) {
		            f = f.split('\\').join('/');
		        }
		        // treat the test path as a set of pathparts.
		        const ff = this.slashSplit(f);
		        this.debug(this.pattern, 'split', ff);
		        // just ONE of the pattern sets in this.set needs to match
		        // in order for it to be valid.  If negating, then just one
		        // match means that we have failed.
		        // Either way, return on the first hit.
		        const set = this.set;
		        this.debug(this.pattern, 'set', set);
		        // Find the basename of the path by looking for the last non-empty segment
		        let filename = ff[ff.length - 1];
		        if (!filename) {
		            for (let i = ff.length - 2; !filename && i >= 0; i--) {
		                filename = ff[i];
		            }
		        }
		        for (let i = 0; i < set.length; i++) {
		            const pattern = set[i];
		            let file = ff;
		            if (options.matchBase && pattern.length === 1) {
		                file = [filename];
		            }
		            const hit = this.matchOne(file, pattern, partial);
		            if (hit) {
		                if (options.flipNegate) {
		                    return true;
		                }
		                return !this.negate;
		            }
		        }
		        // didn't get any hits.  this is success if it's a negative
		        // pattern, failure otherwise.
		        if (options.flipNegate) {
		            return false;
		        }
		        return this.negate;
		    }
		    static defaults(def) {
		        return exports.minimatch.defaults(def).Minimatch;
		    }
		}
		exports.Minimatch = Minimatch;
		/* c8 ignore start */
		var ast_js_2 = requireAst();
		Object.defineProperty(exports, "AST", { enumerable: true, get: function () { return ast_js_2.AST; } });
		var escape_js_2 = require_escape();
		Object.defineProperty(exports, "escape", { enumerable: true, get: function () { return escape_js_2.escape; } });
		var unescape_js_2 = require_unescape();
		Object.defineProperty(exports, "unescape", { enumerable: true, get: function () { return unescape_js_2.unescape; } });
		/* c8 ignore stop */
		exports.minimatch.AST = ast_js_1.AST;
		exports.minimatch.Minimatch = Minimatch;
		exports.minimatch.escape = escape_js_1.escape;
		exports.minimatch.unescape = unescape_js_1.unescape;
		
	} (commonjs$3));
	return commonjs$3;
}

var glob = {};

var commonjs$2 = {};

var commonjs$1 = {};

var hasRequiredCommonjs$3;

function requireCommonjs$3 () {
	if (hasRequiredCommonjs$3) return commonjs$1;
	hasRequiredCommonjs$3 = 1;
	/**
	 * @module LRUCache
	 */
	Object.defineProperty(commonjs$1, "__esModule", { value: true });
	commonjs$1.LRUCache = void 0;
	const perf = typeof performance === 'object' &&
	    performance &&
	    typeof performance.now === 'function'
	    ? performance
	    : Date;
	const warned = new Set();
	/* c8 ignore start */
	const PROCESS = (typeof process === 'object' && !!process ? process : {});
	/* c8 ignore start */
	const emitWarning = (msg, type, code, fn) => {
	    typeof PROCESS.emitWarning === 'function'
	        ? PROCESS.emitWarning(msg, type, code, fn)
	        : console.error(`[${code}] ${type}: ${msg}`);
	};
	let AC = globalThis.AbortController;
	let AS = globalThis.AbortSignal;
	/* c8 ignore start */
	if (typeof AC === 'undefined') {
	    //@ts-ignore
	    AS = class AbortSignal {
	        onabort;
	        _onabort = [];
	        reason;
	        aborted = false;
	        addEventListener(_, fn) {
	            this._onabort.push(fn);
	        }
	    };
	    //@ts-ignore
	    AC = class AbortController {
	        constructor() {
	            warnACPolyfill();
	        }
	        signal = new AS();
	        abort(reason) {
	            if (this.signal.aborted)
	                return;
	            //@ts-ignore
	            this.signal.reason = reason;
	            //@ts-ignore
	            this.signal.aborted = true;
	            //@ts-ignore
	            for (const fn of this.signal._onabort) {
	                fn(reason);
	            }
	            this.signal.onabort?.(reason);
	        }
	    };
	    let printACPolyfillWarning = PROCESS.env?.LRU_CACHE_IGNORE_AC_WARNING !== '1';
	    const warnACPolyfill = () => {
	        if (!printACPolyfillWarning)
	            return;
	        printACPolyfillWarning = false;
	        emitWarning('AbortController is not defined. If using lru-cache in ' +
	            'node 14, load an AbortController polyfill from the ' +
	            '`node-abort-controller` package. A minimal polyfill is ' +
	            'provided for use by LRUCache.fetch(), but it should not be ' +
	            'relied upon in other contexts (eg, passing it to other APIs that ' +
	            'use AbortController/AbortSignal might have undesirable effects). ' +
	            'You may disable this with LRU_CACHE_IGNORE_AC_WARNING=1 in the env.', 'NO_ABORT_CONTROLLER', 'ENOTSUP', warnACPolyfill);
	    };
	}
	/* c8 ignore stop */
	const shouldWarn = (code) => !warned.has(code);
	const isPosInt = (n) => n && n === Math.floor(n) && n > 0 && isFinite(n);
	/* c8 ignore start */
	// This is a little bit ridiculous, tbh.
	// The maximum array length is 2^32-1 or thereabouts on most JS impls.
	// And well before that point, you're caching the entire world, I mean,
	// that's ~32GB of just integers for the next/prev links, plus whatever
	// else to hold that many keys and values.  Just filling the memory with
	// zeroes at init time is brutal when you get that big.
	// But why not be complete?
	// Maybe in the future, these limits will have expanded.
	const getUintArray = (max) => !isPosInt(max)
	    ? null
	    : max <= Math.pow(2, 8)
	        ? Uint8Array
	        : max <= Math.pow(2, 16)
	            ? Uint16Array
	            : max <= Math.pow(2, 32)
	                ? Uint32Array
	                : max <= Number.MAX_SAFE_INTEGER
	                    ? ZeroArray
	                    : null;
	/* c8 ignore stop */
	class ZeroArray extends Array {
	    constructor(size) {
	        super(size);
	        this.fill(0);
	    }
	}
	class Stack {
	    heap;
	    length;
	    // private constructor
	    static #constructing = false;
	    static create(max) {
	        const HeapCls = getUintArray(max);
	        if (!HeapCls)
	            return [];
	        Stack.#constructing = true;
	        const s = new Stack(max, HeapCls);
	        Stack.#constructing = false;
	        return s;
	    }
	    constructor(max, HeapCls) {
	        /* c8 ignore start */
	        if (!Stack.#constructing) {
	            throw new TypeError('instantiate Stack using Stack.create(n)');
	        }
	        /* c8 ignore stop */
	        this.heap = new HeapCls(max);
	        this.length = 0;
	    }
	    push(n) {
	        this.heap[this.length++] = n;
	    }
	    pop() {
	        return this.heap[--this.length];
	    }
	}
	/**
	 * Default export, the thing you're using this module to get.
	 *
	 * The `K` and `V` types define the key and value types, respectively. The
	 * optional `FC` type defines the type of the `context` object passed to
	 * `cache.fetch()` and `cache.memo()`.
	 *
	 * Keys and values **must not** be `null` or `undefined`.
	 *
	 * All properties from the options object (with the exception of `max`,
	 * `maxSize`, `fetchMethod`, `memoMethod`, `dispose` and `disposeAfter`) are
	 * added as normal public members. (The listed options are read-only getters.)
	 *
	 * Changing any of these will alter the defaults for subsequent method calls.
	 */
	class LRUCache {
	    // options that cannot be changed without disaster
	    #max;
	    #maxSize;
	    #dispose;
	    #disposeAfter;
	    #fetchMethod;
	    #memoMethod;
	    /**
	     * {@link LRUCache.OptionsBase.ttl}
	     */
	    ttl;
	    /**
	     * {@link LRUCache.OptionsBase.ttlResolution}
	     */
	    ttlResolution;
	    /**
	     * {@link LRUCache.OptionsBase.ttlAutopurge}
	     */
	    ttlAutopurge;
	    /**
	     * {@link LRUCache.OptionsBase.updateAgeOnGet}
	     */
	    updateAgeOnGet;
	    /**
	     * {@link LRUCache.OptionsBase.updateAgeOnHas}
	     */
	    updateAgeOnHas;
	    /**
	     * {@link LRUCache.OptionsBase.allowStale}
	     */
	    allowStale;
	    /**
	     * {@link LRUCache.OptionsBase.noDisposeOnSet}
	     */
	    noDisposeOnSet;
	    /**
	     * {@link LRUCache.OptionsBase.noUpdateTTL}
	     */
	    noUpdateTTL;
	    /**
	     * {@link LRUCache.OptionsBase.maxEntrySize}
	     */
	    maxEntrySize;
	    /**
	     * {@link LRUCache.OptionsBase.sizeCalculation}
	     */
	    sizeCalculation;
	    /**
	     * {@link LRUCache.OptionsBase.noDeleteOnFetchRejection}
	     */
	    noDeleteOnFetchRejection;
	    /**
	     * {@link LRUCache.OptionsBase.noDeleteOnStaleGet}
	     */
	    noDeleteOnStaleGet;
	    /**
	     * {@link LRUCache.OptionsBase.allowStaleOnFetchAbort}
	     */
	    allowStaleOnFetchAbort;
	    /**
	     * {@link LRUCache.OptionsBase.allowStaleOnFetchRejection}
	     */
	    allowStaleOnFetchRejection;
	    /**
	     * {@link LRUCache.OptionsBase.ignoreFetchAbort}
	     */
	    ignoreFetchAbort;
	    // computed properties
	    #size;
	    #calculatedSize;
	    #keyMap;
	    #keyList;
	    #valList;
	    #next;
	    #prev;
	    #head;
	    #tail;
	    #free;
	    #disposed;
	    #sizes;
	    #starts;
	    #ttls;
	    #hasDispose;
	    #hasFetchMethod;
	    #hasDisposeAfter;
	    /**
	     * Do not call this method unless you need to inspect the
	     * inner workings of the cache.  If anything returned by this
	     * object is modified in any way, strange breakage may occur.
	     *
	     * These fields are private for a reason!
	     *
	     * @internal
	     */
	    static unsafeExposeInternals(c) {
	        return {
	            // properties
	            starts: c.#starts,
	            ttls: c.#ttls,
	            sizes: c.#sizes,
	            keyMap: c.#keyMap,
	            keyList: c.#keyList,
	            valList: c.#valList,
	            next: c.#next,
	            prev: c.#prev,
	            get head() {
	                return c.#head;
	            },
	            get tail() {
	                return c.#tail;
	            },
	            free: c.#free,
	            // methods
	            isBackgroundFetch: (p) => c.#isBackgroundFetch(p),
	            backgroundFetch: (k, index, options, context) => c.#backgroundFetch(k, index, options, context),
	            moveToTail: (index) => c.#moveToTail(index),
	            indexes: (options) => c.#indexes(options),
	            rindexes: (options) => c.#rindexes(options),
	            isStale: (index) => c.#isStale(index),
	        };
	    }
	    // Protected read-only members
	    /**
	     * {@link LRUCache.OptionsBase.max} (read-only)
	     */
	    get max() {
	        return this.#max;
	    }
	    /**
	     * {@link LRUCache.OptionsBase.maxSize} (read-only)
	     */
	    get maxSize() {
	        return this.#maxSize;
	    }
	    /**
	     * The total computed size of items in the cache (read-only)
	     */
	    get calculatedSize() {
	        return this.#calculatedSize;
	    }
	    /**
	     * The number of items stored in the cache (read-only)
	     */
	    get size() {
	        return this.#size;
	    }
	    /**
	     * {@link LRUCache.OptionsBase.fetchMethod} (read-only)
	     */
	    get fetchMethod() {
	        return this.#fetchMethod;
	    }
	    get memoMethod() {
	        return this.#memoMethod;
	    }
	    /**
	     * {@link LRUCache.OptionsBase.dispose} (read-only)
	     */
	    get dispose() {
	        return this.#dispose;
	    }
	    /**
	     * {@link LRUCache.OptionsBase.disposeAfter} (read-only)
	     */
	    get disposeAfter() {
	        return this.#disposeAfter;
	    }
	    constructor(options) {
	        const { max = 0, ttl, ttlResolution = 1, ttlAutopurge, updateAgeOnGet, updateAgeOnHas, allowStale, dispose, disposeAfter, noDisposeOnSet, noUpdateTTL, maxSize = 0, maxEntrySize = 0, sizeCalculation, fetchMethod, memoMethod, noDeleteOnFetchRejection, noDeleteOnStaleGet, allowStaleOnFetchRejection, allowStaleOnFetchAbort, ignoreFetchAbort, } = options;
	        if (max !== 0 && !isPosInt(max)) {
	            throw new TypeError('max option must be a nonnegative integer');
	        }
	        const UintArray = max ? getUintArray(max) : Array;
	        if (!UintArray) {
	            throw new Error('invalid max value: ' + max);
	        }
	        this.#max = max;
	        this.#maxSize = maxSize;
	        this.maxEntrySize = maxEntrySize || this.#maxSize;
	        this.sizeCalculation = sizeCalculation;
	        if (this.sizeCalculation) {
	            if (!this.#maxSize && !this.maxEntrySize) {
	                throw new TypeError('cannot set sizeCalculation without setting maxSize or maxEntrySize');
	            }
	            if (typeof this.sizeCalculation !== 'function') {
	                throw new TypeError('sizeCalculation set to non-function');
	            }
	        }
	        if (memoMethod !== undefined &&
	            typeof memoMethod !== 'function') {
	            throw new TypeError('memoMethod must be a function if defined');
	        }
	        this.#memoMethod = memoMethod;
	        if (fetchMethod !== undefined &&
	            typeof fetchMethod !== 'function') {
	            throw new TypeError('fetchMethod must be a function if specified');
	        }
	        this.#fetchMethod = fetchMethod;
	        this.#hasFetchMethod = !!fetchMethod;
	        this.#keyMap = new Map();
	        this.#keyList = new Array(max).fill(undefined);
	        this.#valList = new Array(max).fill(undefined);
	        this.#next = new UintArray(max);
	        this.#prev = new UintArray(max);
	        this.#head = 0;
	        this.#tail = 0;
	        this.#free = Stack.create(max);
	        this.#size = 0;
	        this.#calculatedSize = 0;
	        if (typeof dispose === 'function') {
	            this.#dispose = dispose;
	        }
	        if (typeof disposeAfter === 'function') {
	            this.#disposeAfter = disposeAfter;
	            this.#disposed = [];
	        }
	        else {
	            this.#disposeAfter = undefined;
	            this.#disposed = undefined;
	        }
	        this.#hasDispose = !!this.#dispose;
	        this.#hasDisposeAfter = !!this.#disposeAfter;
	        this.noDisposeOnSet = !!noDisposeOnSet;
	        this.noUpdateTTL = !!noUpdateTTL;
	        this.noDeleteOnFetchRejection = !!noDeleteOnFetchRejection;
	        this.allowStaleOnFetchRejection = !!allowStaleOnFetchRejection;
	        this.allowStaleOnFetchAbort = !!allowStaleOnFetchAbort;
	        this.ignoreFetchAbort = !!ignoreFetchAbort;
	        // NB: maxEntrySize is set to maxSize if it's set
	        if (this.maxEntrySize !== 0) {
	            if (this.#maxSize !== 0) {
	                if (!isPosInt(this.#maxSize)) {
	                    throw new TypeError('maxSize must be a positive integer if specified');
	                }
	            }
	            if (!isPosInt(this.maxEntrySize)) {
	                throw new TypeError('maxEntrySize must be a positive integer if specified');
	            }
	            this.#initializeSizeTracking();
	        }
	        this.allowStale = !!allowStale;
	        this.noDeleteOnStaleGet = !!noDeleteOnStaleGet;
	        this.updateAgeOnGet = !!updateAgeOnGet;
	        this.updateAgeOnHas = !!updateAgeOnHas;
	        this.ttlResolution =
	            isPosInt(ttlResolution) || ttlResolution === 0
	                ? ttlResolution
	                : 1;
	        this.ttlAutopurge = !!ttlAutopurge;
	        this.ttl = ttl || 0;
	        if (this.ttl) {
	            if (!isPosInt(this.ttl)) {
	                throw new TypeError('ttl must be a positive integer if specified');
	            }
	            this.#initializeTTLTracking();
	        }
	        // do not allow completely unbounded caches
	        if (this.#max === 0 && this.ttl === 0 && this.#maxSize === 0) {
	            throw new TypeError('At least one of max, maxSize, or ttl is required');
	        }
	        if (!this.ttlAutopurge && !this.#max && !this.#maxSize) {
	            const code = 'LRU_CACHE_UNBOUNDED';
	            if (shouldWarn(code)) {
	                warned.add(code);
	                const msg = 'TTL caching without ttlAutopurge, max, or maxSize can ' +
	                    'result in unbounded memory consumption.';
	                emitWarning(msg, 'UnboundedCacheWarning', code, LRUCache);
	            }
	        }
	    }
	    /**
	     * Return the number of ms left in the item's TTL. If item is not in cache,
	     * returns `0`. Returns `Infinity` if item is in cache without a defined TTL.
	     */
	    getRemainingTTL(key) {
	        return this.#keyMap.has(key) ? Infinity : 0;
	    }
	    #initializeTTLTracking() {
	        const ttls = new ZeroArray(this.#max);
	        const starts = new ZeroArray(this.#max);
	        this.#ttls = ttls;
	        this.#starts = starts;
	        this.#setItemTTL = (index, ttl, start = perf.now()) => {
	            starts[index] = ttl !== 0 ? start : 0;
	            ttls[index] = ttl;
	            if (ttl !== 0 && this.ttlAutopurge) {
	                const t = setTimeout(() => {
	                    if (this.#isStale(index)) {
	                        this.#delete(this.#keyList[index], 'expire');
	                    }
	                }, ttl + 1);
	                // unref() not supported on all platforms
	                /* c8 ignore start */
	                if (t.unref) {
	                    t.unref();
	                }
	                /* c8 ignore stop */
	            }
	        };
	        this.#updateItemAge = index => {
	            starts[index] = ttls[index] !== 0 ? perf.now() : 0;
	        };
	        this.#statusTTL = (status, index) => {
	            if (ttls[index]) {
	                const ttl = ttls[index];
	                const start = starts[index];
	                /* c8 ignore next */
	                if (!ttl || !start)
	                    return;
	                status.ttl = ttl;
	                status.start = start;
	                status.now = cachedNow || getNow();
	                const age = status.now - start;
	                status.remainingTTL = ttl - age;
	            }
	        };
	        // debounce calls to perf.now() to 1s so we're not hitting
	        // that costly call repeatedly.
	        let cachedNow = 0;
	        const getNow = () => {
	            const n = perf.now();
	            if (this.ttlResolution > 0) {
	                cachedNow = n;
	                const t = setTimeout(() => (cachedNow = 0), this.ttlResolution);
	                // not available on all platforms
	                /* c8 ignore start */
	                if (t.unref) {
	                    t.unref();
	                }
	                /* c8 ignore stop */
	            }
	            return n;
	        };
	        this.getRemainingTTL = key => {
	            const index = this.#keyMap.get(key);
	            if (index === undefined) {
	                return 0;
	            }
	            const ttl = ttls[index];
	            const start = starts[index];
	            if (!ttl || !start) {
	                return Infinity;
	            }
	            const age = (cachedNow || getNow()) - start;
	            return ttl - age;
	        };
	        this.#isStale = index => {
	            const s = starts[index];
	            const t = ttls[index];
	            return !!t && !!s && (cachedNow || getNow()) - s > t;
	        };
	    }
	    // conditionally set private methods related to TTL
	    #updateItemAge = () => { };
	    #statusTTL = () => { };
	    #setItemTTL = () => { };
	    /* c8 ignore stop */
	    #isStale = () => false;
	    #initializeSizeTracking() {
	        const sizes = new ZeroArray(this.#max);
	        this.#calculatedSize = 0;
	        this.#sizes = sizes;
	        this.#removeItemSize = index => {
	            this.#calculatedSize -= sizes[index];
	            sizes[index] = 0;
	        };
	        this.#requireSize = (k, v, size, sizeCalculation) => {
	            // provisionally accept background fetches.
	            // actual value size will be checked when they return.
	            if (this.#isBackgroundFetch(v)) {
	                return 0;
	            }
	            if (!isPosInt(size)) {
	                if (sizeCalculation) {
	                    if (typeof sizeCalculation !== 'function') {
	                        throw new TypeError('sizeCalculation must be a function');
	                    }
	                    size = sizeCalculation(v, k);
	                    if (!isPosInt(size)) {
	                        throw new TypeError('sizeCalculation return invalid (expect positive integer)');
	                    }
	                }
	                else {
	                    throw new TypeError('invalid size value (must be positive integer). ' +
	                        'When maxSize or maxEntrySize is used, sizeCalculation ' +
	                        'or size must be set.');
	                }
	            }
	            return size;
	        };
	        this.#addItemSize = (index, size, status) => {
	            sizes[index] = size;
	            if (this.#maxSize) {
	                const maxSize = this.#maxSize - sizes[index];
	                while (this.#calculatedSize > maxSize) {
	                    this.#evict(true);
	                }
	            }
	            this.#calculatedSize += sizes[index];
	            if (status) {
	                status.entrySize = size;
	                status.totalCalculatedSize = this.#calculatedSize;
	            }
	        };
	    }
	    #removeItemSize = _i => { };
	    #addItemSize = (_i, _s, _st) => { };
	    #requireSize = (_k, _v, size, sizeCalculation) => {
	        if (size || sizeCalculation) {
	            throw new TypeError('cannot set size without setting maxSize or maxEntrySize on cache');
	        }
	        return 0;
	    };
	    *#indexes({ allowStale = this.allowStale } = {}) {
	        if (this.#size) {
	            for (let i = this.#tail; true;) {
	                if (!this.#isValidIndex(i)) {
	                    break;
	                }
	                if (allowStale || !this.#isStale(i)) {
	                    yield i;
	                }
	                if (i === this.#head) {
	                    break;
	                }
	                else {
	                    i = this.#prev[i];
	                }
	            }
	        }
	    }
	    *#rindexes({ allowStale = this.allowStale } = {}) {
	        if (this.#size) {
	            for (let i = this.#head; true;) {
	                if (!this.#isValidIndex(i)) {
	                    break;
	                }
	                if (allowStale || !this.#isStale(i)) {
	                    yield i;
	                }
	                if (i === this.#tail) {
	                    break;
	                }
	                else {
	                    i = this.#next[i];
	                }
	            }
	        }
	    }
	    #isValidIndex(index) {
	        return (index !== undefined &&
	            this.#keyMap.get(this.#keyList[index]) === index);
	    }
	    /**
	     * Return a generator yielding `[key, value]` pairs,
	     * in order from most recently used to least recently used.
	     */
	    *entries() {
	        for (const i of this.#indexes()) {
	            if (this.#valList[i] !== undefined &&
	                this.#keyList[i] !== undefined &&
	                !this.#isBackgroundFetch(this.#valList[i])) {
	                yield [this.#keyList[i], this.#valList[i]];
	            }
	        }
	    }
	    /**
	     * Inverse order version of {@link LRUCache.entries}
	     *
	     * Return a generator yielding `[key, value]` pairs,
	     * in order from least recently used to most recently used.
	     */
	    *rentries() {
	        for (const i of this.#rindexes()) {
	            if (this.#valList[i] !== undefined &&
	                this.#keyList[i] !== undefined &&
	                !this.#isBackgroundFetch(this.#valList[i])) {
	                yield [this.#keyList[i], this.#valList[i]];
	            }
	        }
	    }
	    /**
	     * Return a generator yielding the keys in the cache,
	     * in order from most recently used to least recently used.
	     */
	    *keys() {
	        for (const i of this.#indexes()) {
	            const k = this.#keyList[i];
	            if (k !== undefined &&
	                !this.#isBackgroundFetch(this.#valList[i])) {
	                yield k;
	            }
	        }
	    }
	    /**
	     * Inverse order version of {@link LRUCache.keys}
	     *
	     * Return a generator yielding the keys in the cache,
	     * in order from least recently used to most recently used.
	     */
	    *rkeys() {
	        for (const i of this.#rindexes()) {
	            const k = this.#keyList[i];
	            if (k !== undefined &&
	                !this.#isBackgroundFetch(this.#valList[i])) {
	                yield k;
	            }
	        }
	    }
	    /**
	     * Return a generator yielding the values in the cache,
	     * in order from most recently used to least recently used.
	     */
	    *values() {
	        for (const i of this.#indexes()) {
	            const v = this.#valList[i];
	            if (v !== undefined &&
	                !this.#isBackgroundFetch(this.#valList[i])) {
	                yield this.#valList[i];
	            }
	        }
	    }
	    /**
	     * Inverse order version of {@link LRUCache.values}
	     *
	     * Return a generator yielding the values in the cache,
	     * in order from least recently used to most recently used.
	     */
	    *rvalues() {
	        for (const i of this.#rindexes()) {
	            const v = this.#valList[i];
	            if (v !== undefined &&
	                !this.#isBackgroundFetch(this.#valList[i])) {
	                yield this.#valList[i];
	            }
	        }
	    }
	    /**
	     * Iterating over the cache itself yields the same results as
	     * {@link LRUCache.entries}
	     */
	    [Symbol.iterator]() {
	        return this.entries();
	    }
	    /**
	     * A String value that is used in the creation of the default string
	     * description of an object. Called by the built-in method
	     * `Object.prototype.toString`.
	     */
	    [Symbol.toStringTag] = 'LRUCache';
	    /**
	     * Find a value for which the supplied fn method returns a truthy value,
	     * similar to `Array.find()`. fn is called as `fn(value, key, cache)`.
	     */
	    find(fn, getOptions = {}) {
	        for (const i of this.#indexes()) {
	            const v = this.#valList[i];
	            const value = this.#isBackgroundFetch(v)
	                ? v.__staleWhileFetching
	                : v;
	            if (value === undefined)
	                continue;
	            if (fn(value, this.#keyList[i], this)) {
	                return this.get(this.#keyList[i], getOptions);
	            }
	        }
	    }
	    /**
	     * Call the supplied function on each item in the cache, in order from most
	     * recently used to least recently used.
	     *
	     * `fn` is called as `fn(value, key, cache)`.
	     *
	     * If `thisp` is provided, function will be called in the `this`-context of
	     * the provided object, or the cache if no `thisp` object is provided.
	     *
	     * Does not update age or recenty of use, or iterate over stale values.
	     */
	    forEach(fn, thisp = this) {
	        for (const i of this.#indexes()) {
	            const v = this.#valList[i];
	            const value = this.#isBackgroundFetch(v)
	                ? v.__staleWhileFetching
	                : v;
	            if (value === undefined)
	                continue;
	            fn.call(thisp, value, this.#keyList[i], this);
	        }
	    }
	    /**
	     * The same as {@link LRUCache.forEach} but items are iterated over in
	     * reverse order.  (ie, less recently used items are iterated over first.)
	     */
	    rforEach(fn, thisp = this) {
	        for (const i of this.#rindexes()) {
	            const v = this.#valList[i];
	            const value = this.#isBackgroundFetch(v)
	                ? v.__staleWhileFetching
	                : v;
	            if (value === undefined)
	                continue;
	            fn.call(thisp, value, this.#keyList[i], this);
	        }
	    }
	    /**
	     * Delete any stale entries. Returns true if anything was removed,
	     * false otherwise.
	     */
	    purgeStale() {
	        let deleted = false;
	        for (const i of this.#rindexes({ allowStale: true })) {
	            if (this.#isStale(i)) {
	                this.#delete(this.#keyList[i], 'expire');
	                deleted = true;
	            }
	        }
	        return deleted;
	    }
	    /**
	     * Get the extended info about a given entry, to get its value, size, and
	     * TTL info simultaneously. Returns `undefined` if the key is not present.
	     *
	     * Unlike {@link LRUCache#dump}, which is designed to be portable and survive
	     * serialization, the `start` value is always the current timestamp, and the
	     * `ttl` is a calculated remaining time to live (negative if expired).
	     *
	     * Always returns stale values, if their info is found in the cache, so be
	     * sure to check for expirations (ie, a negative {@link LRUCache.Entry#ttl})
	     * if relevant.
	     */
	    info(key) {
	        const i = this.#keyMap.get(key);
	        if (i === undefined)
	            return undefined;
	        const v = this.#valList[i];
	        const value = this.#isBackgroundFetch(v)
	            ? v.__staleWhileFetching
	            : v;
	        if (value === undefined)
	            return undefined;
	        const entry = { value };
	        if (this.#ttls && this.#starts) {
	            const ttl = this.#ttls[i];
	            const start = this.#starts[i];
	            if (ttl && start) {
	                const remain = ttl - (perf.now() - start);
	                entry.ttl = remain;
	                entry.start = Date.now();
	            }
	        }
	        if (this.#sizes) {
	            entry.size = this.#sizes[i];
	        }
	        return entry;
	    }
	    /**
	     * Return an array of [key, {@link LRUCache.Entry}] tuples which can be
	     * passed to {@link LRLUCache#load}.
	     *
	     * The `start` fields are calculated relative to a portable `Date.now()`
	     * timestamp, even if `performance.now()` is available.
	     *
	     * Stale entries are always included in the `dump`, even if
	     * {@link LRUCache.OptionsBase.allowStale} is false.
	     *
	     * Note: this returns an actual array, not a generator, so it can be more
	     * easily passed around.
	     */
	    dump() {
	        const arr = [];
	        for (const i of this.#indexes({ allowStale: true })) {
	            const key = this.#keyList[i];
	            const v = this.#valList[i];
	            const value = this.#isBackgroundFetch(v)
	                ? v.__staleWhileFetching
	                : v;
	            if (value === undefined || key === undefined)
	                continue;
	            const entry = { value };
	            if (this.#ttls && this.#starts) {
	                entry.ttl = this.#ttls[i];
	                // always dump the start relative to a portable timestamp
	                // it's ok for this to be a bit slow, it's a rare operation.
	                const age = perf.now() - this.#starts[i];
	                entry.start = Math.floor(Date.now() - age);
	            }
	            if (this.#sizes) {
	                entry.size = this.#sizes[i];
	            }
	            arr.unshift([key, entry]);
	        }
	        return arr;
	    }
	    /**
	     * Reset the cache and load in the items in entries in the order listed.
	     *
	     * The shape of the resulting cache may be different if the same options are
	     * not used in both caches.
	     *
	     * The `start` fields are assumed to be calculated relative to a portable
	     * `Date.now()` timestamp, even if `performance.now()` is available.
	     */
	    load(arr) {
	        this.clear();
	        for (const [key, entry] of arr) {
	            if (entry.start) {
	                // entry.start is a portable timestamp, but we may be using
	                // node's performance.now(), so calculate the offset, so that
	                // we get the intended remaining TTL, no matter how long it's
	                // been on ice.
	                //
	                // it's ok for this to be a bit slow, it's a rare operation.
	                const age = Date.now() - entry.start;
	                entry.start = perf.now() - age;
	            }
	            this.set(key, entry.value, entry);
	        }
	    }
	    /**
	     * Add a value to the cache.
	     *
	     * Note: if `undefined` is specified as a value, this is an alias for
	     * {@link LRUCache#delete}
	     *
	     * Fields on the {@link LRUCache.SetOptions} options param will override
	     * their corresponding values in the constructor options for the scope
	     * of this single `set()` operation.
	     *
	     * If `start` is provided, then that will set the effective start
	     * time for the TTL calculation. Note that this must be a previous
	     * value of `performance.now()` if supported, or a previous value of
	     * `Date.now()` if not.
	     *
	     * Options object may also include `size`, which will prevent
	     * calling the `sizeCalculation` function and just use the specified
	     * number if it is a positive integer, and `noDisposeOnSet` which
	     * will prevent calling a `dispose` function in the case of
	     * overwrites.
	     *
	     * If the `size` (or return value of `sizeCalculation`) for a given
	     * entry is greater than `maxEntrySize`, then the item will not be
	     * added to the cache.
	     *
	     * Will update the recency of the entry.
	     *
	     * If the value is `undefined`, then this is an alias for
	     * `cache.delete(key)`. `undefined` is never stored in the cache.
	     */
	    set(k, v, setOptions = {}) {
	        if (v === undefined) {
	            this.delete(k);
	            return this;
	        }
	        const { ttl = this.ttl, start, noDisposeOnSet = this.noDisposeOnSet, sizeCalculation = this.sizeCalculation, status, } = setOptions;
	        let { noUpdateTTL = this.noUpdateTTL } = setOptions;
	        const size = this.#requireSize(k, v, setOptions.size || 0, sizeCalculation);
	        // if the item doesn't fit, don't do anything
	        // NB: maxEntrySize set to maxSize by default
	        if (this.maxEntrySize && size > this.maxEntrySize) {
	            if (status) {
	                status.set = 'miss';
	                status.maxEntrySizeExceeded = true;
	            }
	            // have to delete, in case something is there already.
	            this.#delete(k, 'set');
	            return this;
	        }
	        let index = this.#size === 0 ? undefined : this.#keyMap.get(k);
	        if (index === undefined) {
	            // addition
	            index = (this.#size === 0
	                ? this.#tail
	                : this.#free.length !== 0
	                    ? this.#free.pop()
	                    : this.#size === this.#max
	                        ? this.#evict(false)
	                        : this.#size);
	            this.#keyList[index] = k;
	            this.#valList[index] = v;
	            this.#keyMap.set(k, index);
	            this.#next[this.#tail] = index;
	            this.#prev[index] = this.#tail;
	            this.#tail = index;
	            this.#size++;
	            this.#addItemSize(index, size, status);
	            if (status)
	                status.set = 'add';
	            noUpdateTTL = false;
	        }
	        else {
	            // update
	            this.#moveToTail(index);
	            const oldVal = this.#valList[index];
	            if (v !== oldVal) {
	                if (this.#hasFetchMethod && this.#isBackgroundFetch(oldVal)) {
	                    oldVal.__abortController.abort(new Error('replaced'));
	                    const { __staleWhileFetching: s } = oldVal;
	                    if (s !== undefined && !noDisposeOnSet) {
	                        if (this.#hasDispose) {
	                            this.#dispose?.(s, k, 'set');
	                        }
	                        if (this.#hasDisposeAfter) {
	                            this.#disposed?.push([s, k, 'set']);
	                        }
	                    }
	                }
	                else if (!noDisposeOnSet) {
	                    if (this.#hasDispose) {
	                        this.#dispose?.(oldVal, k, 'set');
	                    }
	                    if (this.#hasDisposeAfter) {
	                        this.#disposed?.push([oldVal, k, 'set']);
	                    }
	                }
	                this.#removeItemSize(index);
	                this.#addItemSize(index, size, status);
	                this.#valList[index] = v;
	                if (status) {
	                    status.set = 'replace';
	                    const oldValue = oldVal && this.#isBackgroundFetch(oldVal)
	                        ? oldVal.__staleWhileFetching
	                        : oldVal;
	                    if (oldValue !== undefined)
	                        status.oldValue = oldValue;
	                }
	            }
	            else if (status) {
	                status.set = 'update';
	            }
	        }
	        if (ttl !== 0 && !this.#ttls) {
	            this.#initializeTTLTracking();
	        }
	        if (this.#ttls) {
	            if (!noUpdateTTL) {
	                this.#setItemTTL(index, ttl, start);
	            }
	            if (status)
	                this.#statusTTL(status, index);
	        }
	        if (!noDisposeOnSet && this.#hasDisposeAfter && this.#disposed) {
	            const dt = this.#disposed;
	            let task;
	            while ((task = dt?.shift())) {
	                this.#disposeAfter?.(...task);
	            }
	        }
	        return this;
	    }
	    /**
	     * Evict the least recently used item, returning its value or
	     * `undefined` if cache is empty.
	     */
	    pop() {
	        try {
	            while (this.#size) {
	                const val = this.#valList[this.#head];
	                this.#evict(true);
	                if (this.#isBackgroundFetch(val)) {
	                    if (val.__staleWhileFetching) {
	                        return val.__staleWhileFetching;
	                    }
	                }
	                else if (val !== undefined) {
	                    return val;
	                }
	            }
	        }
	        finally {
	            if (this.#hasDisposeAfter && this.#disposed) {
	                const dt = this.#disposed;
	                let task;
	                while ((task = dt?.shift())) {
	                    this.#disposeAfter?.(...task);
	                }
	            }
	        }
	    }
	    #evict(free) {
	        const head = this.#head;
	        const k = this.#keyList[head];
	        const v = this.#valList[head];
	        if (this.#hasFetchMethod && this.#isBackgroundFetch(v)) {
	            v.__abortController.abort(new Error('evicted'));
	        }
	        else if (this.#hasDispose || this.#hasDisposeAfter) {
	            if (this.#hasDispose) {
	                this.#dispose?.(v, k, 'evict');
	            }
	            if (this.#hasDisposeAfter) {
	                this.#disposed?.push([v, k, 'evict']);
	            }
	        }
	        this.#removeItemSize(head);
	        // if we aren't about to use the index, then null these out
	        if (free) {
	            this.#keyList[head] = undefined;
	            this.#valList[head] = undefined;
	            this.#free.push(head);
	        }
	        if (this.#size === 1) {
	            this.#head = this.#tail = 0;
	            this.#free.length = 0;
	        }
	        else {
	            this.#head = this.#next[head];
	        }
	        this.#keyMap.delete(k);
	        this.#size--;
	        return head;
	    }
	    /**
	     * Check if a key is in the cache, without updating the recency of use.
	     * Will return false if the item is stale, even though it is technically
	     * in the cache.
	     *
	     * Check if a key is in the cache, without updating the recency of
	     * use. Age is updated if {@link LRUCache.OptionsBase.updateAgeOnHas} is set
	     * to `true` in either the options or the constructor.
	     *
	     * Will return `false` if the item is stale, even though it is technically in
	     * the cache. The difference can be determined (if it matters) by using a
	     * `status` argument, and inspecting the `has` field.
	     *
	     * Will not update item age unless
	     * {@link LRUCache.OptionsBase.updateAgeOnHas} is set.
	     */
	    has(k, hasOptions = {}) {
	        const { updateAgeOnHas = this.updateAgeOnHas, status } = hasOptions;
	        const index = this.#keyMap.get(k);
	        if (index !== undefined) {
	            const v = this.#valList[index];
	            if (this.#isBackgroundFetch(v) &&
	                v.__staleWhileFetching === undefined) {
	                return false;
	            }
	            if (!this.#isStale(index)) {
	                if (updateAgeOnHas) {
	                    this.#updateItemAge(index);
	                }
	                if (status) {
	                    status.has = 'hit';
	                    this.#statusTTL(status, index);
	                }
	                return true;
	            }
	            else if (status) {
	                status.has = 'stale';
	                this.#statusTTL(status, index);
	            }
	        }
	        else if (status) {
	            status.has = 'miss';
	        }
	        return false;
	    }
	    /**
	     * Like {@link LRUCache#get} but doesn't update recency or delete stale
	     * items.
	     *
	     * Returns `undefined` if the item is stale, unless
	     * {@link LRUCache.OptionsBase.allowStale} is set.
	     */
	    peek(k, peekOptions = {}) {
	        const { allowStale = this.allowStale } = peekOptions;
	        const index = this.#keyMap.get(k);
	        if (index === undefined ||
	            (!allowStale && this.#isStale(index))) {
	            return;
	        }
	        const v = this.#valList[index];
	        // either stale and allowed, or forcing a refresh of non-stale value
	        return this.#isBackgroundFetch(v) ? v.__staleWhileFetching : v;
	    }
	    #backgroundFetch(k, index, options, context) {
	        const v = index === undefined ? undefined : this.#valList[index];
	        if (this.#isBackgroundFetch(v)) {
	            return v;
	        }
	        const ac = new AC();
	        const { signal } = options;
	        // when/if our AC signals, then stop listening to theirs.
	        signal?.addEventListener('abort', () => ac.abort(signal.reason), {
	            signal: ac.signal,
	        });
	        const fetchOpts = {
	            signal: ac.signal,
	            options,
	            context,
	        };
	        const cb = (v, updateCache = false) => {
	            const { aborted } = ac.signal;
	            const ignoreAbort = options.ignoreFetchAbort && v !== undefined;
	            if (options.status) {
	                if (aborted && !updateCache) {
	                    options.status.fetchAborted = true;
	                    options.status.fetchError = ac.signal.reason;
	                    if (ignoreAbort)
	                        options.status.fetchAbortIgnored = true;
	                }
	                else {
	                    options.status.fetchResolved = true;
	                }
	            }
	            if (aborted && !ignoreAbort && !updateCache) {
	                return fetchFail(ac.signal.reason);
	            }
	            // either we didn't abort, and are still here, or we did, and ignored
	            const bf = p;
	            if (this.#valList[index] === p) {
	                if (v === undefined) {
	                    if (bf.__staleWhileFetching) {
	                        this.#valList[index] = bf.__staleWhileFetching;
	                    }
	                    else {
	                        this.#delete(k, 'fetch');
	                    }
	                }
	                else {
	                    if (options.status)
	                        options.status.fetchUpdated = true;
	                    this.set(k, v, fetchOpts.options);
	                }
	            }
	            return v;
	        };
	        const eb = (er) => {
	            if (options.status) {
	                options.status.fetchRejected = true;
	                options.status.fetchError = er;
	            }
	            return fetchFail(er);
	        };
	        const fetchFail = (er) => {
	            const { aborted } = ac.signal;
	            const allowStaleAborted = aborted && options.allowStaleOnFetchAbort;
	            const allowStale = allowStaleAborted || options.allowStaleOnFetchRejection;
	            const noDelete = allowStale || options.noDeleteOnFetchRejection;
	            const bf = p;
	            if (this.#valList[index] === p) {
	                // if we allow stale on fetch rejections, then we need to ensure that
	                // the stale value is not removed from the cache when the fetch fails.
	                const del = !noDelete || bf.__staleWhileFetching === undefined;
	                if (del) {
	                    this.#delete(k, 'fetch');
	                }
	                else if (!allowStaleAborted) {
	                    // still replace the *promise* with the stale value,
	                    // since we are done with the promise at this point.
	                    // leave it untouched if we're still waiting for an
	                    // aborted background fetch that hasn't yet returned.
	                    this.#valList[index] = bf.__staleWhileFetching;
	                }
	            }
	            if (allowStale) {
	                if (options.status && bf.__staleWhileFetching !== undefined) {
	                    options.status.returnedStale = true;
	                }
	                return bf.__staleWhileFetching;
	            }
	            else if (bf.__returned === bf) {
	                throw er;
	            }
	        };
	        const pcall = (res, rej) => {
	            const fmp = this.#fetchMethod?.(k, v, fetchOpts);
	            if (fmp && fmp instanceof Promise) {
	                fmp.then(v => res(v === undefined ? undefined : v), rej);
	            }
	            // ignored, we go until we finish, regardless.
	            // defer check until we are actually aborting,
	            // so fetchMethod can override.
	            ac.signal.addEventListener('abort', () => {
	                if (!options.ignoreFetchAbort ||
	                    options.allowStaleOnFetchAbort) {
	                    res(undefined);
	                    // when it eventually resolves, update the cache.
	                    if (options.allowStaleOnFetchAbort) {
	                        res = v => cb(v, true);
	                    }
	                }
	            });
	        };
	        if (options.status)
	            options.status.fetchDispatched = true;
	        const p = new Promise(pcall).then(cb, eb);
	        const bf = Object.assign(p, {
	            __abortController: ac,
	            __staleWhileFetching: v,
	            __returned: undefined,
	        });
	        if (index === undefined) {
	            // internal, don't expose status.
	            this.set(k, bf, { ...fetchOpts.options, status: undefined });
	            index = this.#keyMap.get(k);
	        }
	        else {
	            this.#valList[index] = bf;
	        }
	        return bf;
	    }
	    #isBackgroundFetch(p) {
	        if (!this.#hasFetchMethod)
	            return false;
	        const b = p;
	        return (!!b &&
	            b instanceof Promise &&
	            b.hasOwnProperty('__staleWhileFetching') &&
	            b.__abortController instanceof AC);
	    }
	    async fetch(k, fetchOptions = {}) {
	        const { 
	        // get options
	        allowStale = this.allowStale, updateAgeOnGet = this.updateAgeOnGet, noDeleteOnStaleGet = this.noDeleteOnStaleGet, 
	        // set options
	        ttl = this.ttl, noDisposeOnSet = this.noDisposeOnSet, size = 0, sizeCalculation = this.sizeCalculation, noUpdateTTL = this.noUpdateTTL, 
	        // fetch exclusive options
	        noDeleteOnFetchRejection = this.noDeleteOnFetchRejection, allowStaleOnFetchRejection = this.allowStaleOnFetchRejection, ignoreFetchAbort = this.ignoreFetchAbort, allowStaleOnFetchAbort = this.allowStaleOnFetchAbort, context, forceRefresh = false, status, signal, } = fetchOptions;
	        if (!this.#hasFetchMethod) {
	            if (status)
	                status.fetch = 'get';
	            return this.get(k, {
	                allowStale,
	                updateAgeOnGet,
	                noDeleteOnStaleGet,
	                status,
	            });
	        }
	        const options = {
	            allowStale,
	            updateAgeOnGet,
	            noDeleteOnStaleGet,
	            ttl,
	            noDisposeOnSet,
	            size,
	            sizeCalculation,
	            noUpdateTTL,
	            noDeleteOnFetchRejection,
	            allowStaleOnFetchRejection,
	            allowStaleOnFetchAbort,
	            ignoreFetchAbort,
	            status,
	            signal,
	        };
	        let index = this.#keyMap.get(k);
	        if (index === undefined) {
	            if (status)
	                status.fetch = 'miss';
	            const p = this.#backgroundFetch(k, index, options, context);
	            return (p.__returned = p);
	        }
	        else {
	            // in cache, maybe already fetching
	            const v = this.#valList[index];
	            if (this.#isBackgroundFetch(v)) {
	                const stale = allowStale && v.__staleWhileFetching !== undefined;
	                if (status) {
	                    status.fetch = 'inflight';
	                    if (stale)
	                        status.returnedStale = true;
	                }
	                return stale ? v.__staleWhileFetching : (v.__returned = v);
	            }
	            // if we force a refresh, that means do NOT serve the cached value,
	            // unless we are already in the process of refreshing the cache.
	            const isStale = this.#isStale(index);
	            if (!forceRefresh && !isStale) {
	                if (status)
	                    status.fetch = 'hit';
	                this.#moveToTail(index);
	                if (updateAgeOnGet) {
	                    this.#updateItemAge(index);
	                }
	                if (status)
	                    this.#statusTTL(status, index);
	                return v;
	            }
	            // ok, it is stale or a forced refresh, and not already fetching.
	            // refresh the cache.
	            const p = this.#backgroundFetch(k, index, options, context);
	            const hasStale = p.__staleWhileFetching !== undefined;
	            const staleVal = hasStale && allowStale;
	            if (status) {
	                status.fetch = isStale ? 'stale' : 'refresh';
	                if (staleVal && isStale)
	                    status.returnedStale = true;
	            }
	            return staleVal ? p.__staleWhileFetching : (p.__returned = p);
	        }
	    }
	    async forceFetch(k, fetchOptions = {}) {
	        const v = await this.fetch(k, fetchOptions);
	        if (v === undefined)
	            throw new Error('fetch() returned undefined');
	        return v;
	    }
	    memo(k, memoOptions = {}) {
	        const memoMethod = this.#memoMethod;
	        if (!memoMethod) {
	            throw new Error('no memoMethod provided to constructor');
	        }
	        const { context, forceRefresh, ...options } = memoOptions;
	        const v = this.get(k, options);
	        if (!forceRefresh && v !== undefined)
	            return v;
	        const vv = memoMethod(k, v, {
	            options,
	            context,
	        });
	        this.set(k, vv, options);
	        return vv;
	    }
	    /**
	     * Return a value from the cache. Will update the recency of the cache
	     * entry found.
	     *
	     * If the key is not found, get() will return `undefined`.
	     */
	    get(k, getOptions = {}) {
	        const { allowStale = this.allowStale, updateAgeOnGet = this.updateAgeOnGet, noDeleteOnStaleGet = this.noDeleteOnStaleGet, status, } = getOptions;
	        const index = this.#keyMap.get(k);
	        if (index !== undefined) {
	            const value = this.#valList[index];
	            const fetching = this.#isBackgroundFetch(value);
	            if (status)
	                this.#statusTTL(status, index);
	            if (this.#isStale(index)) {
	                if (status)
	                    status.get = 'stale';
	                // delete only if not an in-flight background fetch
	                if (!fetching) {
	                    if (!noDeleteOnStaleGet) {
	                        this.#delete(k, 'expire');
	                    }
	                    if (status && allowStale)
	                        status.returnedStale = true;
	                    return allowStale ? value : undefined;
	                }
	                else {
	                    if (status &&
	                        allowStale &&
	                        value.__staleWhileFetching !== undefined) {
	                        status.returnedStale = true;
	                    }
	                    return allowStale ? value.__staleWhileFetching : undefined;
	                }
	            }
	            else {
	                if (status)
	                    status.get = 'hit';
	                // if we're currently fetching it, we don't actually have it yet
	                // it's not stale, which means this isn't a staleWhileRefetching.
	                // If it's not stale, and fetching, AND has a __staleWhileFetching
	                // value, then that means the user fetched with {forceRefresh:true},
	                // so it's safe to return that value.
	                if (fetching) {
	                    return value.__staleWhileFetching;
	                }
	                this.#moveToTail(index);
	                if (updateAgeOnGet) {
	                    this.#updateItemAge(index);
	                }
	                return value;
	            }
	        }
	        else if (status) {
	            status.get = 'miss';
	        }
	    }
	    #connect(p, n) {
	        this.#prev[n] = p;
	        this.#next[p] = n;
	    }
	    #moveToTail(index) {
	        // if tail already, nothing to do
	        // if head, move head to next[index]
	        // else
	        //   move next[prev[index]] to next[index] (head has no prev)
	        //   move prev[next[index]] to prev[index]
	        // prev[index] = tail
	        // next[tail] = index
	        // tail = index
	        if (index !== this.#tail) {
	            if (index === this.#head) {
	                this.#head = this.#next[index];
	            }
	            else {
	                this.#connect(this.#prev[index], this.#next[index]);
	            }
	            this.#connect(this.#tail, index);
	            this.#tail = index;
	        }
	    }
	    /**
	     * Deletes a key out of the cache.
	     *
	     * Returns true if the key was deleted, false otherwise.
	     */
	    delete(k) {
	        return this.#delete(k, 'delete');
	    }
	    #delete(k, reason) {
	        let deleted = false;
	        if (this.#size !== 0) {
	            const index = this.#keyMap.get(k);
	            if (index !== undefined) {
	                deleted = true;
	                if (this.#size === 1) {
	                    this.#clear(reason);
	                }
	                else {
	                    this.#removeItemSize(index);
	                    const v = this.#valList[index];
	                    if (this.#isBackgroundFetch(v)) {
	                        v.__abortController.abort(new Error('deleted'));
	                    }
	                    else if (this.#hasDispose || this.#hasDisposeAfter) {
	                        if (this.#hasDispose) {
	                            this.#dispose?.(v, k, reason);
	                        }
	                        if (this.#hasDisposeAfter) {
	                            this.#disposed?.push([v, k, reason]);
	                        }
	                    }
	                    this.#keyMap.delete(k);
	                    this.#keyList[index] = undefined;
	                    this.#valList[index] = undefined;
	                    if (index === this.#tail) {
	                        this.#tail = this.#prev[index];
	                    }
	                    else if (index === this.#head) {
	                        this.#head = this.#next[index];
	                    }
	                    else {
	                        const pi = this.#prev[index];
	                        this.#next[pi] = this.#next[index];
	                        const ni = this.#next[index];
	                        this.#prev[ni] = this.#prev[index];
	                    }
	                    this.#size--;
	                    this.#free.push(index);
	                }
	            }
	        }
	        if (this.#hasDisposeAfter && this.#disposed?.length) {
	            const dt = this.#disposed;
	            let task;
	            while ((task = dt?.shift())) {
	                this.#disposeAfter?.(...task);
	            }
	        }
	        return deleted;
	    }
	    /**
	     * Clear the cache entirely, throwing away all values.
	     */
	    clear() {
	        return this.#clear('delete');
	    }
	    #clear(reason) {
	        for (const index of this.#rindexes({ allowStale: true })) {
	            const v = this.#valList[index];
	            if (this.#isBackgroundFetch(v)) {
	                v.__abortController.abort(new Error('deleted'));
	            }
	            else {
	                const k = this.#keyList[index];
	                if (this.#hasDispose) {
	                    this.#dispose?.(v, k, reason);
	                }
	                if (this.#hasDisposeAfter) {
	                    this.#disposed?.push([v, k, reason]);
	                }
	            }
	        }
	        this.#keyMap.clear();
	        this.#valList.fill(undefined);
	        this.#keyList.fill(undefined);
	        if (this.#ttls && this.#starts) {
	            this.#ttls.fill(0);
	            this.#starts.fill(0);
	        }
	        if (this.#sizes) {
	            this.#sizes.fill(0);
	        }
	        this.#head = 0;
	        this.#tail = 0;
	        this.#free.length = 0;
	        this.#calculatedSize = 0;
	        this.#size = 0;
	        if (this.#hasDisposeAfter && this.#disposed) {
	            const dt = this.#disposed;
	            let task;
	            while ((task = dt?.shift())) {
	                this.#disposeAfter?.(...task);
	            }
	        }
	    }
	}
	commonjs$1.LRUCache = LRUCache;
	
	return commonjs$1;
}

var commonjs = {};

var hasRequiredCommonjs$2;

function requireCommonjs$2 () {
	if (hasRequiredCommonjs$2) return commonjs;
	hasRequiredCommonjs$2 = 1;
	(function (exports) {
		var __importDefault = (commonjs && commonjs.__importDefault) || function (mod) {
		    return (mod && mod.__esModule) ? mod : { "default": mod };
		};
		Object.defineProperty(exports, "__esModule", { value: true });
		exports.Minipass = exports.isWritable = exports.isReadable = exports.isStream = void 0;
		const proc = typeof process === 'object' && process
		    ? process
		    : {
		        stdout: null,
		        stderr: null,
		    };
		const node_events_1 = require$$0;
		const node_stream_1 = __importDefault(require$$1);
		const node_string_decoder_1 = require$$2;
		/**
		 * Return true if the argument is a Minipass stream, Node stream, or something
		 * else that Minipass can interact with.
		 */
		const isStream = (s) => !!s &&
		    typeof s === 'object' &&
		    (s instanceof Minipass ||
		        s instanceof node_stream_1.default ||
		        (0, exports.isReadable)(s) ||
		        (0, exports.isWritable)(s));
		exports.isStream = isStream;
		/**
		 * Return true if the argument is a valid {@link Minipass.Readable}
		 */
		const isReadable = (s) => !!s &&
		    typeof s === 'object' &&
		    s instanceof node_events_1.EventEmitter &&
		    typeof s.pipe === 'function' &&
		    // node core Writable streams have a pipe() method, but it throws
		    s.pipe !== node_stream_1.default.Writable.prototype.pipe;
		exports.isReadable = isReadable;
		/**
		 * Return true if the argument is a valid {@link Minipass.Writable}
		 */
		const isWritable = (s) => !!s &&
		    typeof s === 'object' &&
		    s instanceof node_events_1.EventEmitter &&
		    typeof s.write === 'function' &&
		    typeof s.end === 'function';
		exports.isWritable = isWritable;
		const EOF = Symbol('EOF');
		const MAYBE_EMIT_END = Symbol('maybeEmitEnd');
		const EMITTED_END = Symbol('emittedEnd');
		const EMITTING_END = Symbol('emittingEnd');
		const EMITTED_ERROR = Symbol('emittedError');
		const CLOSED = Symbol('closed');
		const READ = Symbol('read');
		const FLUSH = Symbol('flush');
		const FLUSHCHUNK = Symbol('flushChunk');
		const ENCODING = Symbol('encoding');
		const DECODER = Symbol('decoder');
		const FLOWING = Symbol('flowing');
		const PAUSED = Symbol('paused');
		const RESUME = Symbol('resume');
		const BUFFER = Symbol('buffer');
		const PIPES = Symbol('pipes');
		const BUFFERLENGTH = Symbol('bufferLength');
		const BUFFERPUSH = Symbol('bufferPush');
		const BUFFERSHIFT = Symbol('bufferShift');
		const OBJECTMODE = Symbol('objectMode');
		// internal event when stream is destroyed
		const DESTROYED = Symbol('destroyed');
		// internal event when stream has an error
		const ERROR = Symbol('error');
		const EMITDATA = Symbol('emitData');
		const EMITEND = Symbol('emitEnd');
		const EMITEND2 = Symbol('emitEnd2');
		const ASYNC = Symbol('async');
		const ABORT = Symbol('abort');
		const ABORTED = Symbol('aborted');
		const SIGNAL = Symbol('signal');
		const DATALISTENERS = Symbol('dataListeners');
		const DISCARDED = Symbol('discarded');
		const defer = (fn) => Promise.resolve().then(fn);
		const nodefer = (fn) => fn();
		const isEndish = (ev) => ev === 'end' || ev === 'finish' || ev === 'prefinish';
		const isArrayBufferLike = (b) => b instanceof ArrayBuffer ||
		    (!!b &&
		        typeof b === 'object' &&
		        b.constructor &&
		        b.constructor.name === 'ArrayBuffer' &&
		        b.byteLength >= 0);
		const isArrayBufferView = (b) => !Buffer.isBuffer(b) && ArrayBuffer.isView(b);
		/**
		 * Internal class representing a pipe to a destination stream.
		 *
		 * @internal
		 */
		class Pipe {
		    src;
		    dest;
		    opts;
		    ondrain;
		    constructor(src, dest, opts) {
		        this.src = src;
		        this.dest = dest;
		        this.opts = opts;
		        this.ondrain = () => src[RESUME]();
		        this.dest.on('drain', this.ondrain);
		    }
		    unpipe() {
		        this.dest.removeListener('drain', this.ondrain);
		    }
		    // only here for the prototype
		    /* c8 ignore start */
		    proxyErrors(_er) { }
		    /* c8 ignore stop */
		    end() {
		        this.unpipe();
		        if (this.opts.end)
		            this.dest.end();
		    }
		}
		/**
		 * Internal class representing a pipe to a destination stream where
		 * errors are proxied.
		 *
		 * @internal
		 */
		class PipeProxyErrors extends Pipe {
		    unpipe() {
		        this.src.removeListener('error', this.proxyErrors);
		        super.unpipe();
		    }
		    constructor(src, dest, opts) {
		        super(src, dest, opts);
		        this.proxyErrors = er => dest.emit('error', er);
		        src.on('error', this.proxyErrors);
		    }
		}
		const isObjectModeOptions = (o) => !!o.objectMode;
		const isEncodingOptions = (o) => !o.objectMode && !!o.encoding && o.encoding !== 'buffer';
		/**
		 * Main export, the Minipass class
		 *
		 * `RType` is the type of data emitted, defaults to Buffer
		 *
		 * `WType` is the type of data to be written, if RType is buffer or string,
		 * then any {@link Minipass.ContiguousData} is allowed.
		 *
		 * `Events` is the set of event handler signatures that this object
		 * will emit, see {@link Minipass.Events}
		 */
		class Minipass extends node_events_1.EventEmitter {
		    [FLOWING] = false;
		    [PAUSED] = false;
		    [PIPES] = [];
		    [BUFFER] = [];
		    [OBJECTMODE];
		    [ENCODING];
		    [ASYNC];
		    [DECODER];
		    [EOF] = false;
		    [EMITTED_END] = false;
		    [EMITTING_END] = false;
		    [CLOSED] = false;
		    [EMITTED_ERROR] = null;
		    [BUFFERLENGTH] = 0;
		    [DESTROYED] = false;
		    [SIGNAL];
		    [ABORTED] = false;
		    [DATALISTENERS] = 0;
		    [DISCARDED] = false;
		    /**
		     * true if the stream can be written
		     */
		    writable = true;
		    /**
		     * true if the stream can be read
		     */
		    readable = true;
		    /**
		     * If `RType` is Buffer, then options do not need to be provided.
		     * Otherwise, an options object must be provided to specify either
		     * {@link Minipass.SharedOptions.objectMode} or
		     * {@link Minipass.SharedOptions.encoding}, as appropriate.
		     */
		    constructor(...args) {
		        const options = (args[0] ||
		            {});
		        super();
		        if (options.objectMode && typeof options.encoding === 'string') {
		            throw new TypeError('Encoding and objectMode may not be used together');
		        }
		        if (isObjectModeOptions(options)) {
		            this[OBJECTMODE] = true;
		            this[ENCODING] = null;
		        }
		        else if (isEncodingOptions(options)) {
		            this[ENCODING] = options.encoding;
		            this[OBJECTMODE] = false;
		        }
		        else {
		            this[OBJECTMODE] = false;
		            this[ENCODING] = null;
		        }
		        this[ASYNC] = !!options.async;
		        this[DECODER] = this[ENCODING]
		            ? new node_string_decoder_1.StringDecoder(this[ENCODING])
		            : null;
		        //@ts-ignore - private option for debugging and testing
		        if (options && options.debugExposeBuffer === true) {
		            Object.defineProperty(this, 'buffer', { get: () => this[BUFFER] });
		        }
		        //@ts-ignore - private option for debugging and testing
		        if (options && options.debugExposePipes === true) {
		            Object.defineProperty(this, 'pipes', { get: () => this[PIPES] });
		        }
		        const { signal } = options;
		        if (signal) {
		            this[SIGNAL] = signal;
		            if (signal.aborted) {
		                this[ABORT]();
		            }
		            else {
		                signal.addEventListener('abort', () => this[ABORT]());
		            }
		        }
		    }
		    /**
		     * The amount of data stored in the buffer waiting to be read.
		     *
		     * For Buffer strings, this will be the total byte length.
		     * For string encoding streams, this will be the string character length,
		     * according to JavaScript's `string.length` logic.
		     * For objectMode streams, this is a count of the items waiting to be
		     * emitted.
		     */
		    get bufferLength() {
		        return this[BUFFERLENGTH];
		    }
		    /**
		     * The `BufferEncoding` currently in use, or `null`
		     */
		    get encoding() {
		        return this[ENCODING];
		    }
		    /**
		     * @deprecated - This is a read only property
		     */
		    set encoding(_enc) {
		        throw new Error('Encoding must be set at instantiation time');
		    }
		    /**
		     * @deprecated - Encoding may only be set at instantiation time
		     */
		    setEncoding(_enc) {
		        throw new Error('Encoding must be set at instantiation time');
		    }
		    /**
		     * True if this is an objectMode stream
		     */
		    get objectMode() {
		        return this[OBJECTMODE];
		    }
		    /**
		     * @deprecated - This is a read-only property
		     */
		    set objectMode(_om) {
		        throw new Error('objectMode must be set at instantiation time');
		    }
		    /**
		     * true if this is an async stream
		     */
		    get ['async']() {
		        return this[ASYNC];
		    }
		    /**
		     * Set to true to make this stream async.
		     *
		     * Once set, it cannot be unset, as this would potentially cause incorrect
		     * behavior.  Ie, a sync stream can be made async, but an async stream
		     * cannot be safely made sync.
		     */
		    set ['async'](a) {
		        this[ASYNC] = this[ASYNC] || !!a;
		    }
		    // drop everything and get out of the flow completely
		    [ABORT]() {
		        this[ABORTED] = true;
		        this.emit('abort', this[SIGNAL]?.reason);
		        this.destroy(this[SIGNAL]?.reason);
		    }
		    /**
		     * True if the stream has been aborted.
		     */
		    get aborted() {
		        return this[ABORTED];
		    }
		    /**
		     * No-op setter. Stream aborted status is set via the AbortSignal provided
		     * in the constructor options.
		     */
		    set aborted(_) { }
		    write(chunk, encoding, cb) {
		        if (this[ABORTED])
		            return false;
		        if (this[EOF])
		            throw new Error('write after end');
		        if (this[DESTROYED]) {
		            this.emit('error', Object.assign(new Error('Cannot call write after a stream was destroyed'), { code: 'ERR_STREAM_DESTROYED' }));
		            return true;
		        }
		        if (typeof encoding === 'function') {
		            cb = encoding;
		            encoding = 'utf8';
		        }
		        if (!encoding)
		            encoding = 'utf8';
		        const fn = this[ASYNC] ? defer : nodefer;
		        // convert array buffers and typed array views into buffers
		        // at some point in the future, we may want to do the opposite!
		        // leave strings and buffers as-is
		        // anything is only allowed if in object mode, so throw
		        if (!this[OBJECTMODE] && !Buffer.isBuffer(chunk)) {
		            if (isArrayBufferView(chunk)) {
		                //@ts-ignore - sinful unsafe type changing
		                chunk = Buffer.from(chunk.buffer, chunk.byteOffset, chunk.byteLength);
		            }
		            else if (isArrayBufferLike(chunk)) {
		                //@ts-ignore - sinful unsafe type changing
		                chunk = Buffer.from(chunk);
		            }
		            else if (typeof chunk !== 'string') {
		                throw new Error('Non-contiguous data written to non-objectMode stream');
		            }
		        }
		        // handle object mode up front, since it's simpler
		        // this yields better performance, fewer checks later.
		        if (this[OBJECTMODE]) {
		            // maybe impossible?
		            /* c8 ignore start */
		            if (this[FLOWING] && this[BUFFERLENGTH] !== 0)
		                this[FLUSH](true);
		            /* c8 ignore stop */
		            if (this[FLOWING])
		                this.emit('data', chunk);
		            else
		                this[BUFFERPUSH](chunk);
		            if (this[BUFFERLENGTH] !== 0)
		                this.emit('readable');
		            if (cb)
		                fn(cb);
		            return this[FLOWING];
		        }
		        // at this point the chunk is a buffer or string
		        // don't buffer it up or send it to the decoder
		        if (!chunk.length) {
		            if (this[BUFFERLENGTH] !== 0)
		                this.emit('readable');
		            if (cb)
		                fn(cb);
		            return this[FLOWING];
		        }
		        // fast-path writing strings of same encoding to a stream with
		        // an empty buffer, skipping the buffer/decoder dance
		        if (typeof chunk === 'string' &&
		            // unless it is a string already ready for us to use
		            !(encoding === this[ENCODING] && !this[DECODER]?.lastNeed)) {
		            //@ts-ignore - sinful unsafe type change
		            chunk = Buffer.from(chunk, encoding);
		        }
		        if (Buffer.isBuffer(chunk) && this[ENCODING]) {
		            //@ts-ignore - sinful unsafe type change
		            chunk = this[DECODER].write(chunk);
		        }
		        // Note: flushing CAN potentially switch us into not-flowing mode
		        if (this[FLOWING] && this[BUFFERLENGTH] !== 0)
		            this[FLUSH](true);
		        if (this[FLOWING])
		            this.emit('data', chunk);
		        else
		            this[BUFFERPUSH](chunk);
		        if (this[BUFFERLENGTH] !== 0)
		            this.emit('readable');
		        if (cb)
		            fn(cb);
		        return this[FLOWING];
		    }
		    /**
		     * Low-level explicit read method.
		     *
		     * In objectMode, the argument is ignored, and one item is returned if
		     * available.
		     *
		     * `n` is the number of bytes (or in the case of encoding streams,
		     * characters) to consume. If `n` is not provided, then the entire buffer
		     * is returned, or `null` is returned if no data is available.
		     *
		     * If `n` is greater that the amount of data in the internal buffer,
		     * then `null` is returned.
		     */
		    read(n) {
		        if (this[DESTROYED])
		            return null;
		        this[DISCARDED] = false;
		        if (this[BUFFERLENGTH] === 0 ||
		            n === 0 ||
		            (n && n > this[BUFFERLENGTH])) {
		            this[MAYBE_EMIT_END]();
		            return null;
		        }
		        if (this[OBJECTMODE])
		            n = null;
		        if (this[BUFFER].length > 1 && !this[OBJECTMODE]) {
		            // not object mode, so if we have an encoding, then RType is string
		            // otherwise, must be Buffer
		            this[BUFFER] = [
		                (this[ENCODING]
		                    ? this[BUFFER].join('')
		                    : Buffer.concat(this[BUFFER], this[BUFFERLENGTH])),
		            ];
		        }
		        const ret = this[READ](n || null, this[BUFFER][0]);
		        this[MAYBE_EMIT_END]();
		        return ret;
		    }
		    [READ](n, chunk) {
		        if (this[OBJECTMODE])
		            this[BUFFERSHIFT]();
		        else {
		            const c = chunk;
		            if (n === c.length || n === null)
		                this[BUFFERSHIFT]();
		            else if (typeof c === 'string') {
		                this[BUFFER][0] = c.slice(n);
		                chunk = c.slice(0, n);
		                this[BUFFERLENGTH] -= n;
		            }
		            else {
		                this[BUFFER][0] = c.subarray(n);
		                chunk = c.subarray(0, n);
		                this[BUFFERLENGTH] -= n;
		            }
		        }
		        this.emit('data', chunk);
		        if (!this[BUFFER].length && !this[EOF])
		            this.emit('drain');
		        return chunk;
		    }
		    end(chunk, encoding, cb) {
		        if (typeof chunk === 'function') {
		            cb = chunk;
		            chunk = undefined;
		        }
		        if (typeof encoding === 'function') {
		            cb = encoding;
		            encoding = 'utf8';
		        }
		        if (chunk !== undefined)
		            this.write(chunk, encoding);
		        if (cb)
		            this.once('end', cb);
		        this[EOF] = true;
		        this.writable = false;
		        // if we haven't written anything, then go ahead and emit,
		        // even if we're not reading.
		        // we'll re-emit if a new 'end' listener is added anyway.
		        // This makes MP more suitable to write-only use cases.
		        if (this[FLOWING] || !this[PAUSED])
		            this[MAYBE_EMIT_END]();
		        return this;
		    }
		    // don't let the internal resume be overwritten
		    [RESUME]() {
		        if (this[DESTROYED])
		            return;
		        if (!this[DATALISTENERS] && !this[PIPES].length) {
		            this[DISCARDED] = true;
		        }
		        this[PAUSED] = false;
		        this[FLOWING] = true;
		        this.emit('resume');
		        if (this[BUFFER].length)
		            this[FLUSH]();
		        else if (this[EOF])
		            this[MAYBE_EMIT_END]();
		        else
		            this.emit('drain');
		    }
		    /**
		     * Resume the stream if it is currently in a paused state
		     *
		     * If called when there are no pipe destinations or `data` event listeners,
		     * this will place the stream in a "discarded" state, where all data will
		     * be thrown away. The discarded state is removed if a pipe destination or
		     * data handler is added, if pause() is called, or if any synchronous or
		     * asynchronous iteration is started.
		     */
		    resume() {
		        return this[RESUME]();
		    }
		    /**
		     * Pause the stream
		     */
		    pause() {
		        this[FLOWING] = false;
		        this[PAUSED] = true;
		        this[DISCARDED] = false;
		    }
		    /**
		     * true if the stream has been forcibly destroyed
		     */
		    get destroyed() {
		        return this[DESTROYED];
		    }
		    /**
		     * true if the stream is currently in a flowing state, meaning that
		     * any writes will be immediately emitted.
		     */
		    get flowing() {
		        return this[FLOWING];
		    }
		    /**
		     * true if the stream is currently in a paused state
		     */
		    get paused() {
		        return this[PAUSED];
		    }
		    [BUFFERPUSH](chunk) {
		        if (this[OBJECTMODE])
		            this[BUFFERLENGTH] += 1;
		        else
		            this[BUFFERLENGTH] += chunk.length;
		        this[BUFFER].push(chunk);
		    }
		    [BUFFERSHIFT]() {
		        if (this[OBJECTMODE])
		            this[BUFFERLENGTH] -= 1;
		        else
		            this[BUFFERLENGTH] -= this[BUFFER][0].length;
		        return this[BUFFER].shift();
		    }
		    [FLUSH](noDrain = false) {
		        do { } while (this[FLUSHCHUNK](this[BUFFERSHIFT]()) &&
		            this[BUFFER].length);
		        if (!noDrain && !this[BUFFER].length && !this[EOF])
		            this.emit('drain');
		    }
		    [FLUSHCHUNK](chunk) {
		        this.emit('data', chunk);
		        return this[FLOWING];
		    }
		    /**
		     * Pipe all data emitted by this stream into the destination provided.
		     *
		     * Triggers the flow of data.
		     */
		    pipe(dest, opts) {
		        if (this[DESTROYED])
		            return dest;
		        this[DISCARDED] = false;
		        const ended = this[EMITTED_END];
		        opts = opts || {};
		        if (dest === proc.stdout || dest === proc.stderr)
		            opts.end = false;
		        else
		            opts.end = opts.end !== false;
		        opts.proxyErrors = !!opts.proxyErrors;
		        // piping an ended stream ends immediately
		        if (ended) {
		            if (opts.end)
		                dest.end();
		        }
		        else {
		            // "as" here just ignores the WType, which pipes don't care about,
		            // since they're only consuming from us, and writing to the dest
		            this[PIPES].push(!opts.proxyErrors
		                ? new Pipe(this, dest, opts)
		                : new PipeProxyErrors(this, dest, opts));
		            if (this[ASYNC])
		                defer(() => this[RESUME]());
		            else
		                this[RESUME]();
		        }
		        return dest;
		    }
		    /**
		     * Fully unhook a piped destination stream.
		     *
		     * If the destination stream was the only consumer of this stream (ie,
		     * there are no other piped destinations or `'data'` event listeners)
		     * then the flow of data will stop until there is another consumer or
		     * {@link Minipass#resume} is explicitly called.
		     */
		    unpipe(dest) {
		        const p = this[PIPES].find(p => p.dest === dest);
		        if (p) {
		            if (this[PIPES].length === 1) {
		                if (this[FLOWING] && this[DATALISTENERS] === 0) {
		                    this[FLOWING] = false;
		                }
		                this[PIPES] = [];
		            }
		            else
		                this[PIPES].splice(this[PIPES].indexOf(p), 1);
		            p.unpipe();
		        }
		    }
		    /**
		     * Alias for {@link Minipass#on}
		     */
		    addListener(ev, handler) {
		        return this.on(ev, handler);
		    }
		    /**
		     * Mostly identical to `EventEmitter.on`, with the following
		     * behavior differences to prevent data loss and unnecessary hangs:
		     *
		     * - Adding a 'data' event handler will trigger the flow of data
		     *
		     * - Adding a 'readable' event handler when there is data waiting to be read
		     *   will cause 'readable' to be emitted immediately.
		     *
		     * - Adding an 'endish' event handler ('end', 'finish', etc.) which has
		     *   already passed will cause the event to be emitted immediately and all
		     *   handlers removed.
		     *
		     * - Adding an 'error' event handler after an error has been emitted will
		     *   cause the event to be re-emitted immediately with the error previously
		     *   raised.
		     */
		    on(ev, handler) {
		        const ret = super.on(ev, handler);
		        if (ev === 'data') {
		            this[DISCARDED] = false;
		            this[DATALISTENERS]++;
		            if (!this[PIPES].length && !this[FLOWING]) {
		                this[RESUME]();
		            }
		        }
		        else if (ev === 'readable' && this[BUFFERLENGTH] !== 0) {
		            super.emit('readable');
		        }
		        else if (isEndish(ev) && this[EMITTED_END]) {
		            super.emit(ev);
		            this.removeAllListeners(ev);
		        }
		        else if (ev === 'error' && this[EMITTED_ERROR]) {
		            const h = handler;
		            if (this[ASYNC])
		                defer(() => h.call(this, this[EMITTED_ERROR]));
		            else
		                h.call(this, this[EMITTED_ERROR]);
		        }
		        return ret;
		    }
		    /**
		     * Alias for {@link Minipass#off}
		     */
		    removeListener(ev, handler) {
		        return this.off(ev, handler);
		    }
		    /**
		     * Mostly identical to `EventEmitter.off`
		     *
		     * If a 'data' event handler is removed, and it was the last consumer
		     * (ie, there are no pipe destinations or other 'data' event listeners),
		     * then the flow of data will stop until there is another consumer or
		     * {@link Minipass#resume} is explicitly called.
		     */
		    off(ev, handler) {
		        const ret = super.off(ev, handler);
		        // if we previously had listeners, and now we don't, and we don't
		        // have any pipes, then stop the flow, unless it's been explicitly
		        // put in a discarded flowing state via stream.resume().
		        if (ev === 'data') {
		            this[DATALISTENERS] = this.listeners('data').length;
		            if (this[DATALISTENERS] === 0 &&
		                !this[DISCARDED] &&
		                !this[PIPES].length) {
		                this[FLOWING] = false;
		            }
		        }
		        return ret;
		    }
		    /**
		     * Mostly identical to `EventEmitter.removeAllListeners`
		     *
		     * If all 'data' event handlers are removed, and they were the last consumer
		     * (ie, there are no pipe destinations), then the flow of data will stop
		     * until there is another consumer or {@link Minipass#resume} is explicitly
		     * called.
		     */
		    removeAllListeners(ev) {
		        const ret = super.removeAllListeners(ev);
		        if (ev === 'data' || ev === undefined) {
		            this[DATALISTENERS] = 0;
		            if (!this[DISCARDED] && !this[PIPES].length) {
		                this[FLOWING] = false;
		            }
		        }
		        return ret;
		    }
		    /**
		     * true if the 'end' event has been emitted
		     */
		    get emittedEnd() {
		        return this[EMITTED_END];
		    }
		    [MAYBE_EMIT_END]() {
		        if (!this[EMITTING_END] &&
		            !this[EMITTED_END] &&
		            !this[DESTROYED] &&
		            this[BUFFER].length === 0 &&
		            this[EOF]) {
		            this[EMITTING_END] = true;
		            this.emit('end');
		            this.emit('prefinish');
		            this.emit('finish');
		            if (this[CLOSED])
		                this.emit('close');
		            this[EMITTING_END] = false;
		        }
		    }
		    /**
		     * Mostly identical to `EventEmitter.emit`, with the following
		     * behavior differences to prevent data loss and unnecessary hangs:
		     *
		     * If the stream has been destroyed, and the event is something other
		     * than 'close' or 'error', then `false` is returned and no handlers
		     * are called.
		     *
		     * If the event is 'end', and has already been emitted, then the event
		     * is ignored. If the stream is in a paused or non-flowing state, then
		     * the event will be deferred until data flow resumes. If the stream is
		     * async, then handlers will be called on the next tick rather than
		     * immediately.
		     *
		     * If the event is 'close', and 'end' has not yet been emitted, then
		     * the event will be deferred until after 'end' is emitted.
		     *
		     * If the event is 'error', and an AbortSignal was provided for the stream,
		     * and there are no listeners, then the event is ignored, matching the
		     * behavior of node core streams in the presense of an AbortSignal.
		     *
		     * If the event is 'finish' or 'prefinish', then all listeners will be
		     * removed after emitting the event, to prevent double-firing.
		     */
		    emit(ev, ...args) {
		        const data = args[0];
		        // error and close are only events allowed after calling destroy()
		        if (ev !== 'error' &&
		            ev !== 'close' &&
		            ev !== DESTROYED &&
		            this[DESTROYED]) {
		            return false;
		        }
		        else if (ev === 'data') {
		            return !this[OBJECTMODE] && !data
		                ? false
		                : this[ASYNC]
		                    ? (defer(() => this[EMITDATA](data)), true)
		                    : this[EMITDATA](data);
		        }
		        else if (ev === 'end') {
		            return this[EMITEND]();
		        }
		        else if (ev === 'close') {
		            this[CLOSED] = true;
		            // don't emit close before 'end' and 'finish'
		            if (!this[EMITTED_END] && !this[DESTROYED])
		                return false;
		            const ret = super.emit('close');
		            this.removeAllListeners('close');
		            return ret;
		        }
		        else if (ev === 'error') {
		            this[EMITTED_ERROR] = data;
		            super.emit(ERROR, data);
		            const ret = !this[SIGNAL] || this.listeners('error').length
		                ? super.emit('error', data)
		                : false;
		            this[MAYBE_EMIT_END]();
		            return ret;
		        }
		        else if (ev === 'resume') {
		            const ret = super.emit('resume');
		            this[MAYBE_EMIT_END]();
		            return ret;
		        }
		        else if (ev === 'finish' || ev === 'prefinish') {
		            const ret = super.emit(ev);
		            this.removeAllListeners(ev);
		            return ret;
		        }
		        // Some other unknown event
		        const ret = super.emit(ev, ...args);
		        this[MAYBE_EMIT_END]();
		        return ret;
		    }
		    [EMITDATA](data) {
		        for (const p of this[PIPES]) {
		            if (p.dest.write(data) === false)
		                this.pause();
		        }
		        const ret = this[DISCARDED] ? false : super.emit('data', data);
		        this[MAYBE_EMIT_END]();
		        return ret;
		    }
		    [EMITEND]() {
		        if (this[EMITTED_END])
		            return false;
		        this[EMITTED_END] = true;
		        this.readable = false;
		        return this[ASYNC]
		            ? (defer(() => this[EMITEND2]()), true)
		            : this[EMITEND2]();
		    }
		    [EMITEND2]() {
		        if (this[DECODER]) {
		            const data = this[DECODER].end();
		            if (data) {
		                for (const p of this[PIPES]) {
		                    p.dest.write(data);
		                }
		                if (!this[DISCARDED])
		                    super.emit('data', data);
		            }
		        }
		        for (const p of this[PIPES]) {
		            p.end();
		        }
		        const ret = super.emit('end');
		        this.removeAllListeners('end');
		        return ret;
		    }
		    /**
		     * Return a Promise that resolves to an array of all emitted data once
		     * the stream ends.
		     */
		    async collect() {
		        const buf = Object.assign([], {
		            dataLength: 0,
		        });
		        if (!this[OBJECTMODE])
		            buf.dataLength = 0;
		        // set the promise first, in case an error is raised
		        // by triggering the flow here.
		        const p = this.promise();
		        this.on('data', c => {
		            buf.push(c);
		            if (!this[OBJECTMODE])
		                buf.dataLength += c.length;
		        });
		        await p;
		        return buf;
		    }
		    /**
		     * Return a Promise that resolves to the concatenation of all emitted data
		     * once the stream ends.
		     *
		     * Not allowed on objectMode streams.
		     */
		    async concat() {
		        if (this[OBJECTMODE]) {
		            throw new Error('cannot concat in objectMode');
		        }
		        const buf = await this.collect();
		        return (this[ENCODING]
		            ? buf.join('')
		            : Buffer.concat(buf, buf.dataLength));
		    }
		    /**
		     * Return a void Promise that resolves once the stream ends.
		     */
		    async promise() {
		        return new Promise((resolve, reject) => {
		            this.on(DESTROYED, () => reject(new Error('stream destroyed')));
		            this.on('error', er => reject(er));
		            this.on('end', () => resolve());
		        });
		    }
		    /**
		     * Asynchronous `for await of` iteration.
		     *
		     * This will continue emitting all chunks until the stream terminates.
		     */
		    [Symbol.asyncIterator]() {
		        // set this up front, in case the consumer doesn't call next()
		        // right away.
		        this[DISCARDED] = false;
		        let stopped = false;
		        const stop = async () => {
		            this.pause();
		            stopped = true;
		            return { value: undefined, done: true };
		        };
		        const next = () => {
		            if (stopped)
		                return stop();
		            const res = this.read();
		            if (res !== null)
		                return Promise.resolve({ done: false, value: res });
		            if (this[EOF])
		                return stop();
		            let resolve;
		            let reject;
		            const onerr = (er) => {
		                this.off('data', ondata);
		                this.off('end', onend);
		                this.off(DESTROYED, ondestroy);
		                stop();
		                reject(er);
		            };
		            const ondata = (value) => {
		                this.off('error', onerr);
		                this.off('end', onend);
		                this.off(DESTROYED, ondestroy);
		                this.pause();
		                resolve({ value, done: !!this[EOF] });
		            };
		            const onend = () => {
		                this.off('error', onerr);
		                this.off('data', ondata);
		                this.off(DESTROYED, ondestroy);
		                stop();
		                resolve({ done: true, value: undefined });
		            };
		            const ondestroy = () => onerr(new Error('stream destroyed'));
		            return new Promise((res, rej) => {
		                reject = rej;
		                resolve = res;
		                this.once(DESTROYED, ondestroy);
		                this.once('error', onerr);
		                this.once('end', onend);
		                this.once('data', ondata);
		            });
		        };
		        return {
		            next,
		            throw: stop,
		            return: stop,
		            [Symbol.asyncIterator]() {
		                return this;
		            },
		        };
		    }
		    /**
		     * Synchronous `for of` iteration.
		     *
		     * The iteration will terminate when the internal buffer runs out, even
		     * if the stream has not yet terminated.
		     */
		    [Symbol.iterator]() {
		        // set this up front, in case the consumer doesn't call next()
		        // right away.
		        this[DISCARDED] = false;
		        let stopped = false;
		        const stop = () => {
		            this.pause();
		            this.off(ERROR, stop);
		            this.off(DESTROYED, stop);
		            this.off('end', stop);
		            stopped = true;
		            return { done: true, value: undefined };
		        };
		        const next = () => {
		            if (stopped)
		                return stop();
		            const value = this.read();
		            return value === null ? stop() : { done: false, value };
		        };
		        this.once('end', stop);
		        this.once(ERROR, stop);
		        this.once(DESTROYED, stop);
		        return {
		            next,
		            throw: stop,
		            return: stop,
		            [Symbol.iterator]() {
		                return this;
		            },
		        };
		    }
		    /**
		     * Destroy a stream, preventing it from being used for any further purpose.
		     *
		     * If the stream has a `close()` method, then it will be called on
		     * destruction.
		     *
		     * After destruction, any attempt to write data, read data, or emit most
		     * events will be ignored.
		     *
		     * If an error argument is provided, then it will be emitted in an
		     * 'error' event.
		     */
		    destroy(er) {
		        if (this[DESTROYED]) {
		            if (er)
		                this.emit('error', er);
		            else
		                this.emit(DESTROYED);
		            return this;
		        }
		        this[DESTROYED] = true;
		        this[DISCARDED] = true;
		        // throw away all buffered data, it's never coming out
		        this[BUFFER].length = 0;
		        this[BUFFERLENGTH] = 0;
		        const wc = this;
		        if (typeof wc.close === 'function' && !this[CLOSED])
		            wc.close();
		        if (er)
		            this.emit('error', er);
		        // if no error to emit, still reject pending promises
		        else
		            this.emit(DESTROYED);
		        return this;
		    }
		    /**
		     * Alias for {@link isStream}
		     *
		     * Former export location, maintained for backwards compatibility.
		     *
		     * @deprecated
		     */
		    static get isStream() {
		        return exports.isStream;
		    }
		}
		exports.Minipass = Minipass;
		
	} (commonjs));
	return commonjs;
}

var hasRequiredCommonjs$1;

function requireCommonjs$1 () {
	if (hasRequiredCommonjs$1) return commonjs$2;
	hasRequiredCommonjs$1 = 1;
	var __createBinding = (commonjs$2 && commonjs$2.__createBinding) || (Object.create ? (function(o, m, k, k2) {
	    if (k2 === undefined) k2 = k;
	    var desc = Object.getOwnPropertyDescriptor(m, k);
	    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
	      desc = { enumerable: true, get: function() { return m[k]; } };
	    }
	    Object.defineProperty(o, k2, desc);
	}) : (function(o, m, k, k2) {
	    if (k2 === undefined) k2 = k;
	    o[k2] = m[k];
	}));
	var __setModuleDefault = (commonjs$2 && commonjs$2.__setModuleDefault) || (Object.create ? (function(o, v) {
	    Object.defineProperty(o, "default", { enumerable: true, value: v });
	}) : function(o, v) {
	    o["default"] = v;
	});
	var __importStar = (commonjs$2 && commonjs$2.__importStar) || function (mod) {
	    if (mod && mod.__esModule) return mod;
	    var result = {};
	    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
	    __setModuleDefault(result, mod);
	    return result;
	};
	Object.defineProperty(commonjs$2, "__esModule", { value: true });
	commonjs$2.PathScurry = commonjs$2.Path = commonjs$2.PathScurryDarwin = commonjs$2.PathScurryPosix = commonjs$2.PathScurryWin32 = commonjs$2.PathScurryBase = commonjs$2.PathPosix = commonjs$2.PathWin32 = commonjs$2.PathBase = commonjs$2.ChildrenCache = commonjs$2.ResolveCache = void 0;
	const lru_cache_1 = /*@__PURE__*/ requireCommonjs$3();
	const node_path_1 = require$$1$1;
	const node_url_1 = require$$2$1;
	const fs_1 = require$$0$1;
	const actualFS = __importStar(require$$4);
	const realpathSync = fs_1.realpathSync.native;
	// TODO: test perf of fs/promises realpath vs realpathCB,
	// since the promises one uses realpath.native
	const promises_1 = require$$5;
	const minipass_1 = requireCommonjs$2();
	const defaultFS = {
	    lstatSync: fs_1.lstatSync,
	    readdir: fs_1.readdir,
	    readdirSync: fs_1.readdirSync,
	    readlinkSync: fs_1.readlinkSync,
	    realpathSync,
	    promises: {
	        lstat: promises_1.lstat,
	        readdir: promises_1.readdir,
	        readlink: promises_1.readlink,
	        realpath: promises_1.realpath,
	    },
	};
	// if they just gave us require('fs') then use our default
	const fsFromOption = (fsOption) => !fsOption || fsOption === defaultFS || fsOption === actualFS ?
	    defaultFS
	    : {
	        ...defaultFS,
	        ...fsOption,
	        promises: {
	            ...defaultFS.promises,
	            ...(fsOption.promises || {}),
	        },
	    };
	// turn something like //?/c:/ into c:\
	const uncDriveRegexp = /^\\\\\?\\([a-z]:)\\?$/i;
	const uncToDrive = (rootPath) => rootPath.replace(/\//g, '\\').replace(uncDriveRegexp, '$1\\');
	// windows paths are separated by either / or \
	const eitherSep = /[\\\/]/;
	const UNKNOWN = 0; // may not even exist, for all we know
	const IFIFO = 0b0001;
	const IFCHR = 0b0010;
	const IFDIR = 0b0100;
	const IFBLK = 0b0110;
	const IFREG = 0b1000;
	const IFLNK = 0b1010;
	const IFSOCK = 0b1100;
	const IFMT = 0b1111;
	// mask to unset low 4 bits
	const IFMT_UNKNOWN = -16;
	// set after successfully calling readdir() and getting entries.
	const READDIR_CALLED = 0b0000_0001_0000;
	// set after a successful lstat()
	const LSTAT_CALLED = 0b0000_0010_0000;
	// set if an entry (or one of its parents) is definitely not a dir
	const ENOTDIR = 0b0000_0100_0000;
	// set if an entry (or one of its parents) does not exist
	// (can also be set on lstat errors like EACCES or ENAMETOOLONG)
	const ENOENT = 0b0000_1000_0000;
	// cannot have child entries -- also verify &IFMT is either IFDIR or IFLNK
	// set if we fail to readlink
	const ENOREADLINK = 0b0001_0000_0000;
	// set if we know realpath() will fail
	const ENOREALPATH = 0b0010_0000_0000;
	const ENOCHILD = ENOTDIR | ENOENT | ENOREALPATH;
	const TYPEMASK = 0b0011_1111_1111;
	const entToType = (s) => s.isFile() ? IFREG
	    : s.isDirectory() ? IFDIR
	        : s.isSymbolicLink() ? IFLNK
	            : s.isCharacterDevice() ? IFCHR
	                : s.isBlockDevice() ? IFBLK
	                    : s.isSocket() ? IFSOCK
	                        : s.isFIFO() ? IFIFO
	                            : UNKNOWN;
	// normalize unicode path names
	const normalizeCache = new Map();
	const normalize = (s) => {
	    const c = normalizeCache.get(s);
	    if (c)
	        return c;
	    const n = s.normalize('NFKD');
	    normalizeCache.set(s, n);
	    return n;
	};
	const normalizeNocaseCache = new Map();
	const normalizeNocase = (s) => {
	    const c = normalizeNocaseCache.get(s);
	    if (c)
	        return c;
	    const n = normalize(s.toLowerCase());
	    normalizeNocaseCache.set(s, n);
	    return n;
	};
	/**
	 * An LRUCache for storing resolved path strings or Path objects.
	 * @internal
	 */
	class ResolveCache extends lru_cache_1.LRUCache {
	    constructor() {
	        super({ max: 256 });
	    }
	}
	commonjs$2.ResolveCache = ResolveCache;
	// In order to prevent blowing out the js heap by allocating hundreds of
	// thousands of Path entries when walking extremely large trees, the "children"
	// in this tree are represented by storing an array of Path entries in an
	// LRUCache, indexed by the parent.  At any time, Path.children() may return an
	// empty array, indicating that it doesn't know about any of its children, and
	// thus has to rebuild that cache.  This is fine, it just means that we don't
	// benefit as much from having the cached entries, but huge directory walks
	// don't blow out the stack, and smaller ones are still as fast as possible.
	//
	//It does impose some complexity when building up the readdir data, because we
	//need to pass a reference to the children array that we started with.
	/**
	 * an LRUCache for storing child entries.
	 * @internal
	 */
	class ChildrenCache extends lru_cache_1.LRUCache {
	    constructor(maxSize = 16 * 1024) {
	        super({
	            maxSize,
	            // parent + children
	            sizeCalculation: a => a.length + 1,
	        });
	    }
	}
	commonjs$2.ChildrenCache = ChildrenCache;
	const setAsCwd = Symbol('PathScurry setAsCwd');
	/**
	 * Path objects are sort of like a super-powered
	 * {@link https://nodejs.org/docs/latest/api/fs.html#class-fsdirent fs.Dirent}
	 *
	 * Each one represents a single filesystem entry on disk, which may or may not
	 * exist. It includes methods for reading various types of information via
	 * lstat, readlink, and readdir, and caches all information to the greatest
	 * degree possible.
	 *
	 * Note that fs operations that would normally throw will instead return an
	 * "empty" value. This is in order to prevent excessive overhead from error
	 * stack traces.
	 */
	class PathBase {
	    /**
	     * the basename of this path
	     *
	     * **Important**: *always* test the path name against any test string
	     * usingthe {@link isNamed} method, and not by directly comparing this
	     * string. Otherwise, unicode path strings that the system sees as identical
	     * will not be properly treated as the same path, leading to incorrect
	     * behavior and possible security issues.
	     */
	    name;
	    /**
	     * the Path entry corresponding to the path root.
	     *
	     * @internal
	     */
	    root;
	    /**
	     * All roots found within the current PathScurry family
	     *
	     * @internal
	     */
	    roots;
	    /**
	     * a reference to the parent path, or undefined in the case of root entries
	     *
	     * @internal
	     */
	    parent;
	    /**
	     * boolean indicating whether paths are compared case-insensitively
	     * @internal
	     */
	    nocase;
	    /**
	     * boolean indicating that this path is the current working directory
	     * of the PathScurry collection that contains it.
	     */
	    isCWD = false;
	    // potential default fs override
	    #fs;
	    // Stats fields
	    #dev;
	    get dev() {
	        return this.#dev;
	    }
	    #mode;
	    get mode() {
	        return this.#mode;
	    }
	    #nlink;
	    get nlink() {
	        return this.#nlink;
	    }
	    #uid;
	    get uid() {
	        return this.#uid;
	    }
	    #gid;
	    get gid() {
	        return this.#gid;
	    }
	    #rdev;
	    get rdev() {
	        return this.#rdev;
	    }
	    #blksize;
	    get blksize() {
	        return this.#blksize;
	    }
	    #ino;
	    get ino() {
	        return this.#ino;
	    }
	    #size;
	    get size() {
	        return this.#size;
	    }
	    #blocks;
	    get blocks() {
	        return this.#blocks;
	    }
	    #atimeMs;
	    get atimeMs() {
	        return this.#atimeMs;
	    }
	    #mtimeMs;
	    get mtimeMs() {
	        return this.#mtimeMs;
	    }
	    #ctimeMs;
	    get ctimeMs() {
	        return this.#ctimeMs;
	    }
	    #birthtimeMs;
	    get birthtimeMs() {
	        return this.#birthtimeMs;
	    }
	    #atime;
	    get atime() {
	        return this.#atime;
	    }
	    #mtime;
	    get mtime() {
	        return this.#mtime;
	    }
	    #ctime;
	    get ctime() {
	        return this.#ctime;
	    }
	    #birthtime;
	    get birthtime() {
	        return this.#birthtime;
	    }
	    #matchName;
	    #depth;
	    #fullpath;
	    #fullpathPosix;
	    #relative;
	    #relativePosix;
	    #type;
	    #children;
	    #linkTarget;
	    #realpath;
	    /**
	     * This property is for compatibility with the Dirent class as of
	     * Node v20, where Dirent['parentPath'] refers to the path of the
	     * directory that was passed to readdir. For root entries, it's the path
	     * to the entry itself.
	     */
	    get parentPath() {
	        return (this.parent || this).fullpath();
	    }
	    /**
	     * Deprecated alias for Dirent['parentPath'] Somewhat counterintuitively,
	     * this property refers to the *parent* path, not the path object itself.
	     */
	    get path() {
	        return this.parentPath;
	    }
	    /**
	     * Do not create new Path objects directly.  They should always be accessed
	     * via the PathScurry class or other methods on the Path class.
	     *
	     * @internal
	     */
	    constructor(name, type = UNKNOWN, root, roots, nocase, children, opts) {
	        this.name = name;
	        this.#matchName = nocase ? normalizeNocase(name) : normalize(name);
	        this.#type = type & TYPEMASK;
	        this.nocase = nocase;
	        this.roots = roots;
	        this.root = root || this;
	        this.#children = children;
	        this.#fullpath = opts.fullpath;
	        this.#relative = opts.relative;
	        this.#relativePosix = opts.relativePosix;
	        this.parent = opts.parent;
	        if (this.parent) {
	            this.#fs = this.parent.#fs;
	        }
	        else {
	            this.#fs = fsFromOption(opts.fs);
	        }
	    }
	    /**
	     * Returns the depth of the Path object from its root.
	     *
	     * For example, a path at `/foo/bar` would have a depth of 2.
	     */
	    depth() {
	        if (this.#depth !== undefined)
	            return this.#depth;
	        if (!this.parent)
	            return (this.#depth = 0);
	        return (this.#depth = this.parent.depth() + 1);
	    }
	    /**
	     * @internal
	     */
	    childrenCache() {
	        return this.#children;
	    }
	    /**
	     * Get the Path object referenced by the string path, resolved from this Path
	     */
	    resolve(path) {
	        if (!path) {
	            return this;
	        }
	        const rootPath = this.getRootString(path);
	        const dir = path.substring(rootPath.length);
	        const dirParts = dir.split(this.splitSep);
	        const result = rootPath ?
	            this.getRoot(rootPath).#resolveParts(dirParts)
	            : this.#resolveParts(dirParts);
	        return result;
	    }
	    #resolveParts(dirParts) {
	        let p = this;
	        for (const part of dirParts) {
	            p = p.child(part);
	        }
	        return p;
	    }
	    /**
	     * Returns the cached children Path objects, if still available.  If they
	     * have fallen out of the cache, then returns an empty array, and resets the
	     * READDIR_CALLED bit, so that future calls to readdir() will require an fs
	     * lookup.
	     *
	     * @internal
	     */
	    children() {
	        const cached = this.#children.get(this);
	        if (cached) {
	            return cached;
	        }
	        const children = Object.assign([], { provisional: 0 });
	        this.#children.set(this, children);
	        this.#type &= -17;
	        return children;
	    }
	    /**
	     * Resolves a path portion and returns or creates the child Path.
	     *
	     * Returns `this` if pathPart is `''` or `'.'`, or `parent` if pathPart is
	     * `'..'`.
	     *
	     * This should not be called directly.  If `pathPart` contains any path
	     * separators, it will lead to unsafe undefined behavior.
	     *
	     * Use `Path.resolve()` instead.
	     *
	     * @internal
	     */
	    child(pathPart, opts) {
	        if (pathPart === '' || pathPart === '.') {
	            return this;
	        }
	        if (pathPart === '..') {
	            return this.parent || this;
	        }
	        // find the child
	        const children = this.children();
	        const name = this.nocase ? normalizeNocase(pathPart) : normalize(pathPart);
	        for (const p of children) {
	            if (p.#matchName === name) {
	                return p;
	            }
	        }
	        // didn't find it, create provisional child, since it might not
	        // actually exist.  If we know the parent isn't a dir, then
	        // in fact it CAN'T exist.
	        const s = this.parent ? this.sep : '';
	        const fullpath = this.#fullpath ? this.#fullpath + s + pathPart : undefined;
	        const pchild = this.newChild(pathPart, UNKNOWN, {
	            ...opts,
	            parent: this,
	            fullpath,
	        });
	        if (!this.canReaddir()) {
	            pchild.#type |= ENOENT;
	        }
	        // don't have to update provisional, because if we have real children,
	        // then provisional is set to children.length, otherwise a lower number
	        children.push(pchild);
	        return pchild;
	    }
	    /**
	     * The relative path from the cwd. If it does not share an ancestor with
	     * the cwd, then this ends up being equivalent to the fullpath()
	     */
	    relative() {
	        if (this.isCWD)
	            return '';
	        if (this.#relative !== undefined) {
	            return this.#relative;
	        }
	        const name = this.name;
	        const p = this.parent;
	        if (!p) {
	            return (this.#relative = this.name);
	        }
	        const pv = p.relative();
	        return pv + (!pv || !p.parent ? '' : this.sep) + name;
	    }
	    /**
	     * The relative path from the cwd, using / as the path separator.
	     * If it does not share an ancestor with
	     * the cwd, then this ends up being equivalent to the fullpathPosix()
	     * On posix systems, this is identical to relative().
	     */
	    relativePosix() {
	        if (this.sep === '/')
	            return this.relative();
	        if (this.isCWD)
	            return '';
	        if (this.#relativePosix !== undefined)
	            return this.#relativePosix;
	        const name = this.name;
	        const p = this.parent;
	        if (!p) {
	            return (this.#relativePosix = this.fullpathPosix());
	        }
	        const pv = p.relativePosix();
	        return pv + (!pv || !p.parent ? '' : '/') + name;
	    }
	    /**
	     * The fully resolved path string for this Path entry
	     */
	    fullpath() {
	        if (this.#fullpath !== undefined) {
	            return this.#fullpath;
	        }
	        const name = this.name;
	        const p = this.parent;
	        if (!p) {
	            return (this.#fullpath = this.name);
	        }
	        const pv = p.fullpath();
	        const fp = pv + (!p.parent ? '' : this.sep) + name;
	        return (this.#fullpath = fp);
	    }
	    /**
	     * On platforms other than windows, this is identical to fullpath.
	     *
	     * On windows, this is overridden to return the forward-slash form of the
	     * full UNC path.
	     */
	    fullpathPosix() {
	        if (this.#fullpathPosix !== undefined)
	            return this.#fullpathPosix;
	        if (this.sep === '/')
	            return (this.#fullpathPosix = this.fullpath());
	        if (!this.parent) {
	            const p = this.fullpath().replace(/\\/g, '/');
	            if (/^[a-z]:\//i.test(p)) {
	                return (this.#fullpathPosix = `//?/${p}`);
	            }
	            else {
	                return (this.#fullpathPosix = p);
	            }
	        }
	        const p = this.parent;
	        const pfpp = p.fullpathPosix();
	        const fpp = pfpp + (!pfpp || !p.parent ? '' : '/') + this.name;
	        return (this.#fullpathPosix = fpp);
	    }
	    /**
	     * Is the Path of an unknown type?
	     *
	     * Note that we might know *something* about it if there has been a previous
	     * filesystem operation, for example that it does not exist, or is not a
	     * link, or whether it has child entries.
	     */
	    isUnknown() {
	        return (this.#type & IFMT) === UNKNOWN;
	    }
	    isType(type) {
	        return this[`is${type}`]();
	    }
	    getType() {
	        return (this.isUnknown() ? 'Unknown'
	            : this.isDirectory() ? 'Directory'
	                : this.isFile() ? 'File'
	                    : this.isSymbolicLink() ? 'SymbolicLink'
	                        : this.isFIFO() ? 'FIFO'
	                            : this.isCharacterDevice() ? 'CharacterDevice'
	                                : this.isBlockDevice() ? 'BlockDevice'
	                                    : /* c8 ignore start */ this.isSocket() ? 'Socket'
	                                        : 'Unknown');
	        /* c8 ignore stop */
	    }
	    /**
	     * Is the Path a regular file?
	     */
	    isFile() {
	        return (this.#type & IFMT) === IFREG;
	    }
	    /**
	     * Is the Path a directory?
	     */
	    isDirectory() {
	        return (this.#type & IFMT) === IFDIR;
	    }
	    /**
	     * Is the path a character device?
	     */
	    isCharacterDevice() {
	        return (this.#type & IFMT) === IFCHR;
	    }
	    /**
	     * Is the path a block device?
	     */
	    isBlockDevice() {
	        return (this.#type & IFMT) === IFBLK;
	    }
	    /**
	     * Is the path a FIFO pipe?
	     */
	    isFIFO() {
	        return (this.#type & IFMT) === IFIFO;
	    }
	    /**
	     * Is the path a socket?
	     */
	    isSocket() {
	        return (this.#type & IFMT) === IFSOCK;
	    }
	    /**
	     * Is the path a symbolic link?
	     */
	    isSymbolicLink() {
	        return (this.#type & IFLNK) === IFLNK;
	    }
	    /**
	     * Return the entry if it has been subject of a successful lstat, or
	     * undefined otherwise.
	     *
	     * Does not read the filesystem, so an undefined result *could* simply
	     * mean that we haven't called lstat on it.
	     */
	    lstatCached() {
	        return this.#type & LSTAT_CALLED ? this : undefined;
	    }
	    /**
	     * Return the cached link target if the entry has been the subject of a
	     * successful readlink, or undefined otherwise.
	     *
	     * Does not read the filesystem, so an undefined result *could* just mean we
	     * don't have any cached data. Only use it if you are very sure that a
	     * readlink() has been called at some point.
	     */
	    readlinkCached() {
	        return this.#linkTarget;
	    }
	    /**
	     * Returns the cached realpath target if the entry has been the subject
	     * of a successful realpath, or undefined otherwise.
	     *
	     * Does not read the filesystem, so an undefined result *could* just mean we
	     * don't have any cached data. Only use it if you are very sure that a
	     * realpath() has been called at some point.
	     */
	    realpathCached() {
	        return this.#realpath;
	    }
	    /**
	     * Returns the cached child Path entries array if the entry has been the
	     * subject of a successful readdir(), or [] otherwise.
	     *
	     * Does not read the filesystem, so an empty array *could* just mean we
	     * don't have any cached data. Only use it if you are very sure that a
	     * readdir() has been called recently enough to still be valid.
	     */
	    readdirCached() {
	        const children = this.children();
	        return children.slice(0, children.provisional);
	    }
	    /**
	     * Return true if it's worth trying to readlink.  Ie, we don't (yet) have
	     * any indication that readlink will definitely fail.
	     *
	     * Returns false if the path is known to not be a symlink, if a previous
	     * readlink failed, or if the entry does not exist.
	     */
	    canReadlink() {
	        if (this.#linkTarget)
	            return true;
	        if (!this.parent)
	            return false;
	        // cases where it cannot possibly succeed
	        const ifmt = this.#type & IFMT;
	        return !((ifmt !== UNKNOWN && ifmt !== IFLNK) ||
	            this.#type & ENOREADLINK ||
	            this.#type & ENOENT);
	    }
	    /**
	     * Return true if readdir has previously been successfully called on this
	     * path, indicating that cachedReaddir() is likely valid.
	     */
	    calledReaddir() {
	        return !!(this.#type & READDIR_CALLED);
	    }
	    /**
	     * Returns true if the path is known to not exist. That is, a previous lstat
	     * or readdir failed to verify its existence when that would have been
	     * expected, or a parent entry was marked either enoent or enotdir.
	     */
	    isENOENT() {
	        return !!(this.#type & ENOENT);
	    }
	    /**
	     * Return true if the path is a match for the given path name.  This handles
	     * case sensitivity and unicode normalization.
	     *
	     * Note: even on case-sensitive systems, it is **not** safe to test the
	     * equality of the `.name` property to determine whether a given pathname
	     * matches, due to unicode normalization mismatches.
	     *
	     * Always use this method instead of testing the `path.name` property
	     * directly.
	     */
	    isNamed(n) {
	        return !this.nocase ?
	            this.#matchName === normalize(n)
	            : this.#matchName === normalizeNocase(n);
	    }
	    /**
	     * Return the Path object corresponding to the target of a symbolic link.
	     *
	     * If the Path is not a symbolic link, or if the readlink call fails for any
	     * reason, `undefined` is returned.
	     *
	     * Result is cached, and thus may be outdated if the filesystem is mutated.
	     */
	    async readlink() {
	        const target = this.#linkTarget;
	        if (target) {
	            return target;
	        }
	        if (!this.canReadlink()) {
	            return undefined;
	        }
	        /* c8 ignore start */
	        // already covered by the canReadlink test, here for ts grumples
	        if (!this.parent) {
	            return undefined;
	        }
	        /* c8 ignore stop */
	        try {
	            const read = await this.#fs.promises.readlink(this.fullpath());
	            const linkTarget = (await this.parent.realpath())?.resolve(read);
	            if (linkTarget) {
	                return (this.#linkTarget = linkTarget);
	            }
	        }
	        catch (er) {
	            this.#readlinkFail(er.code);
	            return undefined;
	        }
	    }
	    /**
	     * Synchronous {@link PathBase.readlink}
	     */
	    readlinkSync() {
	        const target = this.#linkTarget;
	        if (target) {
	            return target;
	        }
	        if (!this.canReadlink()) {
	            return undefined;
	        }
	        /* c8 ignore start */
	        // already covered by the canReadlink test, here for ts grumples
	        if (!this.parent) {
	            return undefined;
	        }
	        /* c8 ignore stop */
	        try {
	            const read = this.#fs.readlinkSync(this.fullpath());
	            const linkTarget = this.parent.realpathSync()?.resolve(read);
	            if (linkTarget) {
	                return (this.#linkTarget = linkTarget);
	            }
	        }
	        catch (er) {
	            this.#readlinkFail(er.code);
	            return undefined;
	        }
	    }
	    #readdirSuccess(children) {
	        // succeeded, mark readdir called bit
	        this.#type |= READDIR_CALLED;
	        // mark all remaining provisional children as ENOENT
	        for (let p = children.provisional; p < children.length; p++) {
	            const c = children[p];
	            if (c)
	                c.#markENOENT();
	        }
	    }
	    #markENOENT() {
	        // mark as UNKNOWN and ENOENT
	        if (this.#type & ENOENT)
	            return;
	        this.#type = (this.#type | ENOENT) & IFMT_UNKNOWN;
	        this.#markChildrenENOENT();
	    }
	    #markChildrenENOENT() {
	        // all children are provisional and do not exist
	        const children = this.children();
	        children.provisional = 0;
	        for (const p of children) {
	            p.#markENOENT();
	        }
	    }
	    #markENOREALPATH() {
	        this.#type |= ENOREALPATH;
	        this.#markENOTDIR();
	    }
	    // save the information when we know the entry is not a dir
	    #markENOTDIR() {
	        // entry is not a directory, so any children can't exist.
	        // this *should* be impossible, since any children created
	        // after it's been marked ENOTDIR should be marked ENOENT,
	        // so it won't even get to this point.
	        /* c8 ignore start */
	        if (this.#type & ENOTDIR)
	            return;
	        /* c8 ignore stop */
	        let t = this.#type;
	        // this could happen if we stat a dir, then delete it,
	        // then try to read it or one of its children.
	        if ((t & IFMT) === IFDIR)
	            t &= IFMT_UNKNOWN;
	        this.#type = t | ENOTDIR;
	        this.#markChildrenENOENT();
	    }
	    #readdirFail(code = '') {
	        // markENOTDIR and markENOENT also set provisional=0
	        if (code === 'ENOTDIR' || code === 'EPERM') {
	            this.#markENOTDIR();
	        }
	        else if (code === 'ENOENT') {
	            this.#markENOENT();
	        }
	        else {
	            this.children().provisional = 0;
	        }
	    }
	    #lstatFail(code = '') {
	        // Windows just raises ENOENT in this case, disable for win CI
	        /* c8 ignore start */
	        if (code === 'ENOTDIR') {
	            // already know it has a parent by this point
	            const p = this.parent;
	            p.#markENOTDIR();
	        }
	        else if (code === 'ENOENT') {
	            /* c8 ignore stop */
	            this.#markENOENT();
	        }
	    }
	    #readlinkFail(code = '') {
	        let ter = this.#type;
	        ter |= ENOREADLINK;
	        if (code === 'ENOENT')
	            ter |= ENOENT;
	        // windows gets a weird error when you try to readlink a file
	        if (code === 'EINVAL' || code === 'UNKNOWN') {
	            // exists, but not a symlink, we don't know WHAT it is, so remove
	            // all IFMT bits.
	            ter &= IFMT_UNKNOWN;
	        }
	        this.#type = ter;
	        // windows just gets ENOENT in this case.  We do cover the case,
	        // just disabled because it's impossible on Windows CI
	        /* c8 ignore start */
	        if (code === 'ENOTDIR' && this.parent) {
	            this.parent.#markENOTDIR();
	        }
	        /* c8 ignore stop */
	    }
	    #readdirAddChild(e, c) {
	        return (this.#readdirMaybePromoteChild(e, c) ||
	            this.#readdirAddNewChild(e, c));
	    }
	    #readdirAddNewChild(e, c) {
	        // alloc new entry at head, so it's never provisional
	        const type = entToType(e);
	        const child = this.newChild(e.name, type, { parent: this });
	        const ifmt = child.#type & IFMT;
	        if (ifmt !== IFDIR && ifmt !== IFLNK && ifmt !== UNKNOWN) {
	            child.#type |= ENOTDIR;
	        }
	        c.unshift(child);
	        c.provisional++;
	        return child;
	    }
	    #readdirMaybePromoteChild(e, c) {
	        for (let p = c.provisional; p < c.length; p++) {
	            const pchild = c[p];
	            const name = this.nocase ? normalizeNocase(e.name) : normalize(e.name);
	            if (name !== pchild.#matchName) {
	                continue;
	            }
	            return this.#readdirPromoteChild(e, pchild, p, c);
	        }
	    }
	    #readdirPromoteChild(e, p, index, c) {
	        const v = p.name;
	        // retain any other flags, but set ifmt from dirent
	        p.#type = (p.#type & IFMT_UNKNOWN) | entToType(e);
	        // case sensitivity fixing when we learn the true name.
	        if (v !== e.name)
	            p.name = e.name;
	        // just advance provisional index (potentially off the list),
	        // otherwise we have to splice/pop it out and re-insert at head
	        if (index !== c.provisional) {
	            if (index === c.length - 1)
	                c.pop();
	            else
	                c.splice(index, 1);
	            c.unshift(p);
	        }
	        c.provisional++;
	        return p;
	    }
	    /**
	     * Call lstat() on this Path, and update all known information that can be
	     * determined.
	     *
	     * Note that unlike `fs.lstat()`, the returned value does not contain some
	     * information, such as `mode`, `dev`, `nlink`, and `ino`.  If that
	     * information is required, you will need to call `fs.lstat` yourself.
	     *
	     * If the Path refers to a nonexistent file, or if the lstat call fails for
	     * any reason, `undefined` is returned.  Otherwise the updated Path object is
	     * returned.
	     *
	     * Results are cached, and thus may be out of date if the filesystem is
	     * mutated.
	     */
	    async lstat() {
	        if ((this.#type & ENOENT) === 0) {
	            try {
	                this.#applyStat(await this.#fs.promises.lstat(this.fullpath()));
	                return this;
	            }
	            catch (er) {
	                this.#lstatFail(er.code);
	            }
	        }
	    }
	    /**
	     * synchronous {@link PathBase.lstat}
	     */
	    lstatSync() {
	        if ((this.#type & ENOENT) === 0) {
	            try {
	                this.#applyStat(this.#fs.lstatSync(this.fullpath()));
	                return this;
	            }
	            catch (er) {
	                this.#lstatFail(er.code);
	            }
	        }
	    }
	    #applyStat(st) {
	        const { atime, atimeMs, birthtime, birthtimeMs, blksize, blocks, ctime, ctimeMs, dev, gid, ino, mode, mtime, mtimeMs, nlink, rdev, size, uid, } = st;
	        this.#atime = atime;
	        this.#atimeMs = atimeMs;
	        this.#birthtime = birthtime;
	        this.#birthtimeMs = birthtimeMs;
	        this.#blksize = blksize;
	        this.#blocks = blocks;
	        this.#ctime = ctime;
	        this.#ctimeMs = ctimeMs;
	        this.#dev = dev;
	        this.#gid = gid;
	        this.#ino = ino;
	        this.#mode = mode;
	        this.#mtime = mtime;
	        this.#mtimeMs = mtimeMs;
	        this.#nlink = nlink;
	        this.#rdev = rdev;
	        this.#size = size;
	        this.#uid = uid;
	        const ifmt = entToType(st);
	        // retain any other flags, but set the ifmt
	        this.#type = (this.#type & IFMT_UNKNOWN) | ifmt | LSTAT_CALLED;
	        if (ifmt !== UNKNOWN && ifmt !== IFDIR && ifmt !== IFLNK) {
	            this.#type |= ENOTDIR;
	        }
	    }
	    #onReaddirCB = [];
	    #readdirCBInFlight = false;
	    #callOnReaddirCB(children) {
	        this.#readdirCBInFlight = false;
	        const cbs = this.#onReaddirCB.slice();
	        this.#onReaddirCB.length = 0;
	        cbs.forEach(cb => cb(null, children));
	    }
	    /**
	     * Standard node-style callback interface to get list of directory entries.
	     *
	     * If the Path cannot or does not contain any children, then an empty array
	     * is returned.
	     *
	     * Results are cached, and thus may be out of date if the filesystem is
	     * mutated.
	     *
	     * @param cb The callback called with (er, entries).  Note that the `er`
	     * param is somewhat extraneous, as all readdir() errors are handled and
	     * simply result in an empty set of entries being returned.
	     * @param allowZalgo Boolean indicating that immediately known results should
	     * *not* be deferred with `queueMicrotask`. Defaults to `false`. Release
	     * zalgo at your peril, the dark pony lord is devious and unforgiving.
	     */
	    readdirCB(cb, allowZalgo = false) {
	        if (!this.canReaddir()) {
	            if (allowZalgo)
	                cb(null, []);
	            else
	                queueMicrotask(() => cb(null, []));
	            return;
	        }
	        const children = this.children();
	        if (this.calledReaddir()) {
	            const c = children.slice(0, children.provisional);
	            if (allowZalgo)
	                cb(null, c);
	            else
	                queueMicrotask(() => cb(null, c));
	            return;
	        }
	        // don't have to worry about zalgo at this point.
	        this.#onReaddirCB.push(cb);
	        if (this.#readdirCBInFlight) {
	            return;
	        }
	        this.#readdirCBInFlight = true;
	        // else read the directory, fill up children
	        // de-provisionalize any provisional children.
	        const fullpath = this.fullpath();
	        this.#fs.readdir(fullpath, { withFileTypes: true }, (er, entries) => {
	            if (er) {
	                this.#readdirFail(er.code);
	                children.provisional = 0;
	            }
	            else {
	                // if we didn't get an error, we always get entries.
	                //@ts-ignore
	                for (const e of entries) {
	                    this.#readdirAddChild(e, children);
	                }
	                this.#readdirSuccess(children);
	            }
	            this.#callOnReaddirCB(children.slice(0, children.provisional));
	            return;
	        });
	    }
	    #asyncReaddirInFlight;
	    /**
	     * Return an array of known child entries.
	     *
	     * If the Path cannot or does not contain any children, then an empty array
	     * is returned.
	     *
	     * Results are cached, and thus may be out of date if the filesystem is
	     * mutated.
	     */
	    async readdir() {
	        if (!this.canReaddir()) {
	            return [];
	        }
	        const children = this.children();
	        if (this.calledReaddir()) {
	            return children.slice(0, children.provisional);
	        }
	        // else read the directory, fill up children
	        // de-provisionalize any provisional children.
	        const fullpath = this.fullpath();
	        if (this.#asyncReaddirInFlight) {
	            await this.#asyncReaddirInFlight;
	        }
	        else {
	            /* c8 ignore start */
	            let resolve = () => { };
	            /* c8 ignore stop */
	            this.#asyncReaddirInFlight = new Promise(res => (resolve = res));
	            try {
	                for (const e of await this.#fs.promises.readdir(fullpath, {
	                    withFileTypes: true,
	                })) {
	                    this.#readdirAddChild(e, children);
	                }
	                this.#readdirSuccess(children);
	            }
	            catch (er) {
	                this.#readdirFail(er.code);
	                children.provisional = 0;
	            }
	            this.#asyncReaddirInFlight = undefined;
	            resolve();
	        }
	        return children.slice(0, children.provisional);
	    }
	    /**
	     * synchronous {@link PathBase.readdir}
	     */
	    readdirSync() {
	        if (!this.canReaddir()) {
	            return [];
	        }
	        const children = this.children();
	        if (this.calledReaddir()) {
	            return children.slice(0, children.provisional);
	        }
	        // else read the directory, fill up children
	        // de-provisionalize any provisional children.
	        const fullpath = this.fullpath();
	        try {
	            for (const e of this.#fs.readdirSync(fullpath, {
	                withFileTypes: true,
	            })) {
	                this.#readdirAddChild(e, children);
	            }
	            this.#readdirSuccess(children);
	        }
	        catch (er) {
	            this.#readdirFail(er.code);
	            children.provisional = 0;
	        }
	        return children.slice(0, children.provisional);
	    }
	    canReaddir() {
	        if (this.#type & ENOCHILD)
	            return false;
	        const ifmt = IFMT & this.#type;
	        // we always set ENOTDIR when setting IFMT, so should be impossible
	        /* c8 ignore start */
	        if (!(ifmt === UNKNOWN || ifmt === IFDIR || ifmt === IFLNK)) {
	            return false;
	        }
	        /* c8 ignore stop */
	        return true;
	    }
	    shouldWalk(dirs, walkFilter) {
	        return ((this.#type & IFDIR) === IFDIR &&
	            !(this.#type & ENOCHILD) &&
	            !dirs.has(this) &&
	            (!walkFilter || walkFilter(this)));
	    }
	    /**
	     * Return the Path object corresponding to path as resolved
	     * by realpath(3).
	     *
	     * If the realpath call fails for any reason, `undefined` is returned.
	     *
	     * Result is cached, and thus may be outdated if the filesystem is mutated.
	     * On success, returns a Path object.
	     */
	    async realpath() {
	        if (this.#realpath)
	            return this.#realpath;
	        if ((ENOREALPATH | ENOREADLINK | ENOENT) & this.#type)
	            return undefined;
	        try {
	            const rp = await this.#fs.promises.realpath(this.fullpath());
	            return (this.#realpath = this.resolve(rp));
	        }
	        catch (_) {
	            this.#markENOREALPATH();
	        }
	    }
	    /**
	     * Synchronous {@link realpath}
	     */
	    realpathSync() {
	        if (this.#realpath)
	            return this.#realpath;
	        if ((ENOREALPATH | ENOREADLINK | ENOENT) & this.#type)
	            return undefined;
	        try {
	            const rp = this.#fs.realpathSync(this.fullpath());
	            return (this.#realpath = this.resolve(rp));
	        }
	        catch (_) {
	            this.#markENOREALPATH();
	        }
	    }
	    /**
	     * Internal method to mark this Path object as the scurry cwd,
	     * called by {@link PathScurry#chdir}
	     *
	     * @internal
	     */
	    [setAsCwd](oldCwd) {
	        if (oldCwd === this)
	            return;
	        oldCwd.isCWD = false;
	        this.isCWD = true;
	        const changed = new Set([]);
	        let rp = [];
	        let p = this;
	        while (p && p.parent) {
	            changed.add(p);
	            p.#relative = rp.join(this.sep);
	            p.#relativePosix = rp.join('/');
	            p = p.parent;
	            rp.push('..');
	        }
	        // now un-memoize parents of old cwd
	        p = oldCwd;
	        while (p && p.parent && !changed.has(p)) {
	            p.#relative = undefined;
	            p.#relativePosix = undefined;
	            p = p.parent;
	        }
	    }
	}
	commonjs$2.PathBase = PathBase;
	/**
	 * Path class used on win32 systems
	 *
	 * Uses `'\\'` as the path separator for returned paths, either `'\\'` or `'/'`
	 * as the path separator for parsing paths.
	 */
	class PathWin32 extends PathBase {
	    /**
	     * Separator for generating path strings.
	     */
	    sep = '\\';
	    /**
	     * Separator for parsing path strings.
	     */
	    splitSep = eitherSep;
	    /**
	     * Do not create new Path objects directly.  They should always be accessed
	     * via the PathScurry class or other methods on the Path class.
	     *
	     * @internal
	     */
	    constructor(name, type = UNKNOWN, root, roots, nocase, children, opts) {
	        super(name, type, root, roots, nocase, children, opts);
	    }
	    /**
	     * @internal
	     */
	    newChild(name, type = UNKNOWN, opts = {}) {
	        return new PathWin32(name, type, this.root, this.roots, this.nocase, this.childrenCache(), opts);
	    }
	    /**
	     * @internal
	     */
	    getRootString(path) {
	        return node_path_1.win32.parse(path).root;
	    }
	    /**
	     * @internal
	     */
	    getRoot(rootPath) {
	        rootPath = uncToDrive(rootPath.toUpperCase());
	        if (rootPath === this.root.name) {
	            return this.root;
	        }
	        // ok, not that one, check if it matches another we know about
	        for (const [compare, root] of Object.entries(this.roots)) {
	            if (this.sameRoot(rootPath, compare)) {
	                return (this.roots[rootPath] = root);
	            }
	        }
	        // otherwise, have to create a new one.
	        return (this.roots[rootPath] = new PathScurryWin32(rootPath, this).root);
	    }
	    /**
	     * @internal
	     */
	    sameRoot(rootPath, compare = this.root.name) {
	        // windows can (rarely) have case-sensitive filesystem, but
	        // UNC and drive letters are always case-insensitive, and canonically
	        // represented uppercase.
	        rootPath = rootPath
	            .toUpperCase()
	            .replace(/\//g, '\\')
	            .replace(uncDriveRegexp, '$1\\');
	        return rootPath === compare;
	    }
	}
	commonjs$2.PathWin32 = PathWin32;
	/**
	 * Path class used on all posix systems.
	 *
	 * Uses `'/'` as the path separator.
	 */
	class PathPosix extends PathBase {
	    /**
	     * separator for parsing path strings
	     */
	    splitSep = '/';
	    /**
	     * separator for generating path strings
	     */
	    sep = '/';
	    /**
	     * Do not create new Path objects directly.  They should always be accessed
	     * via the PathScurry class or other methods on the Path class.
	     *
	     * @internal
	     */
	    constructor(name, type = UNKNOWN, root, roots, nocase, children, opts) {
	        super(name, type, root, roots, nocase, children, opts);
	    }
	    /**
	     * @internal
	     */
	    getRootString(path) {
	        return path.startsWith('/') ? '/' : '';
	    }
	    /**
	     * @internal
	     */
	    getRoot(_rootPath) {
	        return this.root;
	    }
	    /**
	     * @internal
	     */
	    newChild(name, type = UNKNOWN, opts = {}) {
	        return new PathPosix(name, type, this.root, this.roots, this.nocase, this.childrenCache(), opts);
	    }
	}
	commonjs$2.PathPosix = PathPosix;
	/**
	 * The base class for all PathScurry classes, providing the interface for path
	 * resolution and filesystem operations.
	 *
	 * Typically, you should *not* instantiate this class directly, but rather one
	 * of the platform-specific classes, or the exported {@link PathScurry} which
	 * defaults to the current platform.
	 */
	class PathScurryBase {
	    /**
	     * The root Path entry for the current working directory of this Scurry
	     */
	    root;
	    /**
	     * The string path for the root of this Scurry's current working directory
	     */
	    rootPath;
	    /**
	     * A collection of all roots encountered, referenced by rootPath
	     */
	    roots;
	    /**
	     * The Path entry corresponding to this PathScurry's current working directory.
	     */
	    cwd;
	    #resolveCache;
	    #resolvePosixCache;
	    #children;
	    /**
	     * Perform path comparisons case-insensitively.
	     *
	     * Defaults true on Darwin and Windows systems, false elsewhere.
	     */
	    nocase;
	    #fs;
	    /**
	     * This class should not be instantiated directly.
	     *
	     * Use PathScurryWin32, PathScurryDarwin, PathScurryPosix, or PathScurry
	     *
	     * @internal
	     */
	    constructor(cwd = process.cwd(), pathImpl, sep, { nocase, childrenCacheSize = 16 * 1024, fs = defaultFS, } = {}) {
	        this.#fs = fsFromOption(fs);
	        if (cwd instanceof URL || cwd.startsWith('file://')) {
	            cwd = (0, node_url_1.fileURLToPath)(cwd);
	        }
	        // resolve and split root, and then add to the store.
	        // this is the only time we call path.resolve()
	        const cwdPath = pathImpl.resolve(cwd);
	        this.roots = Object.create(null);
	        this.rootPath = this.parseRootPath(cwdPath);
	        this.#resolveCache = new ResolveCache();
	        this.#resolvePosixCache = new ResolveCache();
	        this.#children = new ChildrenCache(childrenCacheSize);
	        const split = cwdPath.substring(this.rootPath.length).split(sep);
	        // resolve('/') leaves '', splits to [''], we don't want that.
	        if (split.length === 1 && !split[0]) {
	            split.pop();
	        }
	        /* c8 ignore start */
	        if (nocase === undefined) {
	            throw new TypeError('must provide nocase setting to PathScurryBase ctor');
	        }
	        /* c8 ignore stop */
	        this.nocase = nocase;
	        this.root = this.newRoot(this.#fs);
	        this.roots[this.rootPath] = this.root;
	        let prev = this.root;
	        let len = split.length - 1;
	        const joinSep = pathImpl.sep;
	        let abs = this.rootPath;
	        let sawFirst = false;
	        for (const part of split) {
	            const l = len--;
	            prev = prev.child(part, {
	                relative: new Array(l).fill('..').join(joinSep),
	                relativePosix: new Array(l).fill('..').join('/'),
	                fullpath: (abs += (sawFirst ? '' : joinSep) + part),
	            });
	            sawFirst = true;
	        }
	        this.cwd = prev;
	    }
	    /**
	     * Get the depth of a provided path, string, or the cwd
	     */
	    depth(path = this.cwd) {
	        if (typeof path === 'string') {
	            path = this.cwd.resolve(path);
	        }
	        return path.depth();
	    }
	    /**
	     * Return the cache of child entries.  Exposed so subclasses can create
	     * child Path objects in a platform-specific way.
	     *
	     * @internal
	     */
	    childrenCache() {
	        return this.#children;
	    }
	    /**
	     * Resolve one or more path strings to a resolved string
	     *
	     * Same interface as require('path').resolve.
	     *
	     * Much faster than path.resolve() when called multiple times for the same
	     * path, because the resolved Path objects are cached.  Much slower
	     * otherwise.
	     */
	    resolve(...paths) {
	        // first figure out the minimum number of paths we have to test
	        // we always start at cwd, but any absolutes will bump the start
	        let r = '';
	        for (let i = paths.length - 1; i >= 0; i--) {
	            const p = paths[i];
	            if (!p || p === '.')
	                continue;
	            r = r ? `${p}/${r}` : p;
	            if (this.isAbsolute(p)) {
	                break;
	            }
	        }
	        const cached = this.#resolveCache.get(r);
	        if (cached !== undefined) {
	            return cached;
	        }
	        const result = this.cwd.resolve(r).fullpath();
	        this.#resolveCache.set(r, result);
	        return result;
	    }
	    /**
	     * Resolve one or more path strings to a resolved string, returning
	     * the posix path.  Identical to .resolve() on posix systems, but on
	     * windows will return a forward-slash separated UNC path.
	     *
	     * Same interface as require('path').resolve.
	     *
	     * Much faster than path.resolve() when called multiple times for the same
	     * path, because the resolved Path objects are cached.  Much slower
	     * otherwise.
	     */
	    resolvePosix(...paths) {
	        // first figure out the minimum number of paths we have to test
	        // we always start at cwd, but any absolutes will bump the start
	        let r = '';
	        for (let i = paths.length - 1; i >= 0; i--) {
	            const p = paths[i];
	            if (!p || p === '.')
	                continue;
	            r = r ? `${p}/${r}` : p;
	            if (this.isAbsolute(p)) {
	                break;
	            }
	        }
	        const cached = this.#resolvePosixCache.get(r);
	        if (cached !== undefined) {
	            return cached;
	        }
	        const result = this.cwd.resolve(r).fullpathPosix();
	        this.#resolvePosixCache.set(r, result);
	        return result;
	    }
	    /**
	     * find the relative path from the cwd to the supplied path string or entry
	     */
	    relative(entry = this.cwd) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        return entry.relative();
	    }
	    /**
	     * find the relative path from the cwd to the supplied path string or
	     * entry, using / as the path delimiter, even on Windows.
	     */
	    relativePosix(entry = this.cwd) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        return entry.relativePosix();
	    }
	    /**
	     * Return the basename for the provided string or Path object
	     */
	    basename(entry = this.cwd) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        return entry.name;
	    }
	    /**
	     * Return the dirname for the provided string or Path object
	     */
	    dirname(entry = this.cwd) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        return (entry.parent || entry).fullpath();
	    }
	    async readdir(entry = this.cwd, opts = {
	        withFileTypes: true,
	    }) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            opts = entry;
	            entry = this.cwd;
	        }
	        const { withFileTypes } = opts;
	        if (!entry.canReaddir()) {
	            return [];
	        }
	        else {
	            const p = await entry.readdir();
	            return withFileTypes ? p : p.map(e => e.name);
	        }
	    }
	    readdirSync(entry = this.cwd, opts = {
	        withFileTypes: true,
	    }) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            opts = entry;
	            entry = this.cwd;
	        }
	        const { withFileTypes = true } = opts;
	        if (!entry.canReaddir()) {
	            return [];
	        }
	        else if (withFileTypes) {
	            return entry.readdirSync();
	        }
	        else {
	            return entry.readdirSync().map(e => e.name);
	        }
	    }
	    /**
	     * Call lstat() on the string or Path object, and update all known
	     * information that can be determined.
	     *
	     * Note that unlike `fs.lstat()`, the returned value does not contain some
	     * information, such as `mode`, `dev`, `nlink`, and `ino`.  If that
	     * information is required, you will need to call `fs.lstat` yourself.
	     *
	     * If the Path refers to a nonexistent file, or if the lstat call fails for
	     * any reason, `undefined` is returned.  Otherwise the updated Path object is
	     * returned.
	     *
	     * Results are cached, and thus may be out of date if the filesystem is
	     * mutated.
	     */
	    async lstat(entry = this.cwd) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        return entry.lstat();
	    }
	    /**
	     * synchronous {@link PathScurryBase.lstat}
	     */
	    lstatSync(entry = this.cwd) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        return entry.lstatSync();
	    }
	    async readlink(entry = this.cwd, { withFileTypes } = {
	        withFileTypes: false,
	    }) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            withFileTypes = entry.withFileTypes;
	            entry = this.cwd;
	        }
	        const e = await entry.readlink();
	        return withFileTypes ? e : e?.fullpath();
	    }
	    readlinkSync(entry = this.cwd, { withFileTypes } = {
	        withFileTypes: false,
	    }) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            withFileTypes = entry.withFileTypes;
	            entry = this.cwd;
	        }
	        const e = entry.readlinkSync();
	        return withFileTypes ? e : e?.fullpath();
	    }
	    async realpath(entry = this.cwd, { withFileTypes } = {
	        withFileTypes: false,
	    }) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            withFileTypes = entry.withFileTypes;
	            entry = this.cwd;
	        }
	        const e = await entry.realpath();
	        return withFileTypes ? e : e?.fullpath();
	    }
	    realpathSync(entry = this.cwd, { withFileTypes } = {
	        withFileTypes: false,
	    }) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            withFileTypes = entry.withFileTypes;
	            entry = this.cwd;
	        }
	        const e = entry.realpathSync();
	        return withFileTypes ? e : e?.fullpath();
	    }
	    async walk(entry = this.cwd, opts = {}) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            opts = entry;
	            entry = this.cwd;
	        }
	        const { withFileTypes = true, follow = false, filter, walkFilter, } = opts;
	        const results = [];
	        if (!filter || filter(entry)) {
	            results.push(withFileTypes ? entry : entry.fullpath());
	        }
	        const dirs = new Set();
	        const walk = (dir, cb) => {
	            dirs.add(dir);
	            dir.readdirCB((er, entries) => {
	                /* c8 ignore start */
	                if (er) {
	                    return cb(er);
	                }
	                /* c8 ignore stop */
	                let len = entries.length;
	                if (!len)
	                    return cb();
	                const next = () => {
	                    if (--len === 0) {
	                        cb();
	                    }
	                };
	                for (const e of entries) {
	                    if (!filter || filter(e)) {
	                        results.push(withFileTypes ? e : e.fullpath());
	                    }
	                    if (follow && e.isSymbolicLink()) {
	                        e.realpath()
	                            .then(r => (r?.isUnknown() ? r.lstat() : r))
	                            .then(r => r?.shouldWalk(dirs, walkFilter) ? walk(r, next) : next());
	                    }
	                    else {
	                        if (e.shouldWalk(dirs, walkFilter)) {
	                            walk(e, next);
	                        }
	                        else {
	                            next();
	                        }
	                    }
	                }
	            }, true); // zalgooooooo
	        };
	        const start = entry;
	        return new Promise((res, rej) => {
	            walk(start, er => {
	                /* c8 ignore start */
	                if (er)
	                    return rej(er);
	                /* c8 ignore stop */
	                res(results);
	            });
	        });
	    }
	    walkSync(entry = this.cwd, opts = {}) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            opts = entry;
	            entry = this.cwd;
	        }
	        const { withFileTypes = true, follow = false, filter, walkFilter, } = opts;
	        const results = [];
	        if (!filter || filter(entry)) {
	            results.push(withFileTypes ? entry : entry.fullpath());
	        }
	        const dirs = new Set([entry]);
	        for (const dir of dirs) {
	            const entries = dir.readdirSync();
	            for (const e of entries) {
	                if (!filter || filter(e)) {
	                    results.push(withFileTypes ? e : e.fullpath());
	                }
	                let r = e;
	                if (e.isSymbolicLink()) {
	                    if (!(follow && (r = e.realpathSync())))
	                        continue;
	                    if (r.isUnknown())
	                        r.lstatSync();
	                }
	                if (r.shouldWalk(dirs, walkFilter)) {
	                    dirs.add(r);
	                }
	            }
	        }
	        return results;
	    }
	    /**
	     * Support for `for await`
	     *
	     * Alias for {@link PathScurryBase.iterate}
	     *
	     * Note: As of Node 19, this is very slow, compared to other methods of
	     * walking.  Consider using {@link PathScurryBase.stream} if memory overhead
	     * and backpressure are concerns, or {@link PathScurryBase.walk} if not.
	     */
	    [Symbol.asyncIterator]() {
	        return this.iterate();
	    }
	    iterate(entry = this.cwd, options = {}) {
	        // iterating async over the stream is significantly more performant,
	        // especially in the warm-cache scenario, because it buffers up directory
	        // entries in the background instead of waiting for a yield for each one.
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            options = entry;
	            entry = this.cwd;
	        }
	        return this.stream(entry, options)[Symbol.asyncIterator]();
	    }
	    /**
	     * Iterating over a PathScurry performs a synchronous walk.
	     *
	     * Alias for {@link PathScurryBase.iterateSync}
	     */
	    [Symbol.iterator]() {
	        return this.iterateSync();
	    }
	    *iterateSync(entry = this.cwd, opts = {}) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            opts = entry;
	            entry = this.cwd;
	        }
	        const { withFileTypes = true, follow = false, filter, walkFilter, } = opts;
	        if (!filter || filter(entry)) {
	            yield withFileTypes ? entry : entry.fullpath();
	        }
	        const dirs = new Set([entry]);
	        for (const dir of dirs) {
	            const entries = dir.readdirSync();
	            for (const e of entries) {
	                if (!filter || filter(e)) {
	                    yield withFileTypes ? e : e.fullpath();
	                }
	                let r = e;
	                if (e.isSymbolicLink()) {
	                    if (!(follow && (r = e.realpathSync())))
	                        continue;
	                    if (r.isUnknown())
	                        r.lstatSync();
	                }
	                if (r.shouldWalk(dirs, walkFilter)) {
	                    dirs.add(r);
	                }
	            }
	        }
	    }
	    stream(entry = this.cwd, opts = {}) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            opts = entry;
	            entry = this.cwd;
	        }
	        const { withFileTypes = true, follow = false, filter, walkFilter, } = opts;
	        const results = new minipass_1.Minipass({ objectMode: true });
	        if (!filter || filter(entry)) {
	            results.write(withFileTypes ? entry : entry.fullpath());
	        }
	        const dirs = new Set();
	        const queue = [entry];
	        let processing = 0;
	        const process = () => {
	            let paused = false;
	            while (!paused) {
	                const dir = queue.shift();
	                if (!dir) {
	                    if (processing === 0)
	                        results.end();
	                    return;
	                }
	                processing++;
	                dirs.add(dir);
	                const onReaddir = (er, entries, didRealpaths = false) => {
	                    /* c8 ignore start */
	                    if (er)
	                        return results.emit('error', er);
	                    /* c8 ignore stop */
	                    if (follow && !didRealpaths) {
	                        const promises = [];
	                        for (const e of entries) {
	                            if (e.isSymbolicLink()) {
	                                promises.push(e
	                                    .realpath()
	                                    .then((r) => r?.isUnknown() ? r.lstat() : r));
	                            }
	                        }
	                        if (promises.length) {
	                            Promise.all(promises).then(() => onReaddir(null, entries, true));
	                            return;
	                        }
	                    }
	                    for (const e of entries) {
	                        if (e && (!filter || filter(e))) {
	                            if (!results.write(withFileTypes ? e : e.fullpath())) {
	                                paused = true;
	                            }
	                        }
	                    }
	                    processing--;
	                    for (const e of entries) {
	                        const r = e.realpathCached() || e;
	                        if (r.shouldWalk(dirs, walkFilter)) {
	                            queue.push(r);
	                        }
	                    }
	                    if (paused && !results.flowing) {
	                        results.once('drain', process);
	                    }
	                    else if (!sync) {
	                        process();
	                    }
	                };
	                // zalgo containment
	                let sync = true;
	                dir.readdirCB(onReaddir, true);
	                sync = false;
	            }
	        };
	        process();
	        return results;
	    }
	    streamSync(entry = this.cwd, opts = {}) {
	        if (typeof entry === 'string') {
	            entry = this.cwd.resolve(entry);
	        }
	        else if (!(entry instanceof PathBase)) {
	            opts = entry;
	            entry = this.cwd;
	        }
	        const { withFileTypes = true, follow = false, filter, walkFilter, } = opts;
	        const results = new minipass_1.Minipass({ objectMode: true });
	        const dirs = new Set();
	        if (!filter || filter(entry)) {
	            results.write(withFileTypes ? entry : entry.fullpath());
	        }
	        const queue = [entry];
	        let processing = 0;
	        const process = () => {
	            let paused = false;
	            while (!paused) {
	                const dir = queue.shift();
	                if (!dir) {
	                    if (processing === 0)
	                        results.end();
	                    return;
	                }
	                processing++;
	                dirs.add(dir);
	                const entries = dir.readdirSync();
	                for (const e of entries) {
	                    if (!filter || filter(e)) {
	                        if (!results.write(withFileTypes ? e : e.fullpath())) {
	                            paused = true;
	                        }
	                    }
	                }
	                processing--;
	                for (const e of entries) {
	                    let r = e;
	                    if (e.isSymbolicLink()) {
	                        if (!(follow && (r = e.realpathSync())))
	                            continue;
	                        if (r.isUnknown())
	                            r.lstatSync();
	                    }
	                    if (r.shouldWalk(dirs, walkFilter)) {
	                        queue.push(r);
	                    }
	                }
	            }
	            if (paused && !results.flowing)
	                results.once('drain', process);
	        };
	        process();
	        return results;
	    }
	    chdir(path = this.cwd) {
	        const oldCwd = this.cwd;
	        this.cwd = typeof path === 'string' ? this.cwd.resolve(path) : path;
	        this.cwd[setAsCwd](oldCwd);
	    }
	}
	commonjs$2.PathScurryBase = PathScurryBase;
	/**
	 * Windows implementation of {@link PathScurryBase}
	 *
	 * Defaults to case insensitve, uses `'\\'` to generate path strings.  Uses
	 * {@link PathWin32} for Path objects.
	 */
	class PathScurryWin32 extends PathScurryBase {
	    /**
	     * separator for generating path strings
	     */
	    sep = '\\';
	    constructor(cwd = process.cwd(), opts = {}) {
	        const { nocase = true } = opts;
	        super(cwd, node_path_1.win32, '\\', { ...opts, nocase });
	        this.nocase = nocase;
	        for (let p = this.cwd; p; p = p.parent) {
	            p.nocase = this.nocase;
	        }
	    }
	    /**
	     * @internal
	     */
	    parseRootPath(dir) {
	        // if the path starts with a single separator, it's not a UNC, and we'll
	        // just get separator as the root, and driveFromUNC will return \
	        // In that case, mount \ on the root from the cwd.
	        return node_path_1.win32.parse(dir).root.toUpperCase();
	    }
	    /**
	     * @internal
	     */
	    newRoot(fs) {
	        return new PathWin32(this.rootPath, IFDIR, undefined, this.roots, this.nocase, this.childrenCache(), { fs });
	    }
	    /**
	     * Return true if the provided path string is an absolute path
	     */
	    isAbsolute(p) {
	        return (p.startsWith('/') || p.startsWith('\\') || /^[a-z]:(\/|\\)/i.test(p));
	    }
	}
	commonjs$2.PathScurryWin32 = PathScurryWin32;
	/**
	 * {@link PathScurryBase} implementation for all posix systems other than Darwin.
	 *
	 * Defaults to case-sensitive matching, uses `'/'` to generate path strings.
	 *
	 * Uses {@link PathPosix} for Path objects.
	 */
	class PathScurryPosix extends PathScurryBase {
	    /**
	     * separator for generating path strings
	     */
	    sep = '/';
	    constructor(cwd = process.cwd(), opts = {}) {
	        const { nocase = false } = opts;
	        super(cwd, node_path_1.posix, '/', { ...opts, nocase });
	        this.nocase = nocase;
	    }
	    /**
	     * @internal
	     */
	    parseRootPath(_dir) {
	        return '/';
	    }
	    /**
	     * @internal
	     */
	    newRoot(fs) {
	        return new PathPosix(this.rootPath, IFDIR, undefined, this.roots, this.nocase, this.childrenCache(), { fs });
	    }
	    /**
	     * Return true if the provided path string is an absolute path
	     */
	    isAbsolute(p) {
	        return p.startsWith('/');
	    }
	}
	commonjs$2.PathScurryPosix = PathScurryPosix;
	/**
	 * {@link PathScurryBase} implementation for Darwin (macOS) systems.
	 *
	 * Defaults to case-insensitive matching, uses `'/'` for generating path
	 * strings.
	 *
	 * Uses {@link PathPosix} for Path objects.
	 */
	class PathScurryDarwin extends PathScurryPosix {
	    constructor(cwd = process.cwd(), opts = {}) {
	        const { nocase = true } = opts;
	        super(cwd, { ...opts, nocase });
	    }
	}
	commonjs$2.PathScurryDarwin = PathScurryDarwin;
	/**
	 * Default {@link PathBase} implementation for the current platform.
	 *
	 * {@link PathWin32} on Windows systems, {@link PathPosix} on all others.
	 */
	commonjs$2.Path = process.platform === 'win32' ? PathWin32 : PathPosix;
	/**
	 * Default {@link PathScurryBase} implementation for the current platform.
	 *
	 * {@link PathScurryWin32} on Windows systems, {@link PathScurryDarwin} on
	 * Darwin (macOS) systems, {@link PathScurryPosix} on all others.
	 */
	commonjs$2.PathScurry = process.platform === 'win32' ? PathScurryWin32
	    : process.platform === 'darwin' ? PathScurryDarwin
	        : PathScurryPosix;
	
	return commonjs$2;
}

var pattern = {};

var hasRequiredPattern;

function requirePattern () {
	if (hasRequiredPattern) return pattern;
	hasRequiredPattern = 1;
	// this is just a very light wrapper around 2 arrays with an offset index
	Object.defineProperty(pattern, "__esModule", { value: true });
	pattern.Pattern = void 0;
	const minimatch_1 = requireCommonjs$4();
	const isPatternList = (pl) => pl.length >= 1;
	const isGlobList = (gl) => gl.length >= 1;
	/**
	 * An immutable-ish view on an array of glob parts and their parsed
	 * results
	 */
	class Pattern {
	    #patternList;
	    #globList;
	    #index;
	    length;
	    #platform;
	    #rest;
	    #globString;
	    #isDrive;
	    #isUNC;
	    #isAbsolute;
	    #followGlobstar = true;
	    constructor(patternList, globList, index, platform) {
	        if (!isPatternList(patternList)) {
	            throw new TypeError('empty pattern list');
	        }
	        if (!isGlobList(globList)) {
	            throw new TypeError('empty glob list');
	        }
	        if (globList.length !== patternList.length) {
	            throw new TypeError('mismatched pattern list and glob list lengths');
	        }
	        this.length = patternList.length;
	        if (index < 0 || index >= this.length) {
	            throw new TypeError('index out of range');
	        }
	        this.#patternList = patternList;
	        this.#globList = globList;
	        this.#index = index;
	        this.#platform = platform;
	        // normalize root entries of absolute patterns on initial creation.
	        if (this.#index === 0) {
	            // c: => ['c:/']
	            // C:/ => ['C:/']
	            // C:/x => ['C:/', 'x']
	            // //host/share => ['//host/share/']
	            // //host/share/ => ['//host/share/']
	            // //host/share/x => ['//host/share/', 'x']
	            // /etc => ['/', 'etc']
	            // / => ['/']
	            if (this.isUNC()) {
	                // '' / '' / 'host' / 'share'
	                const [p0, p1, p2, p3, ...prest] = this.#patternList;
	                const [g0, g1, g2, g3, ...grest] = this.#globList;
	                if (prest[0] === '') {
	                    // ends in /
	                    prest.shift();
	                    grest.shift();
	                }
	                const p = [p0, p1, p2, p3, ''].join('/');
	                const g = [g0, g1, g2, g3, ''].join('/');
	                this.#patternList = [p, ...prest];
	                this.#globList = [g, ...grest];
	                this.length = this.#patternList.length;
	            }
	            else if (this.isDrive() || this.isAbsolute()) {
	                const [p1, ...prest] = this.#patternList;
	                const [g1, ...grest] = this.#globList;
	                if (prest[0] === '') {
	                    // ends in /
	                    prest.shift();
	                    grest.shift();
	                }
	                const p = p1 + '/';
	                const g = g1 + '/';
	                this.#patternList = [p, ...prest];
	                this.#globList = [g, ...grest];
	                this.length = this.#patternList.length;
	            }
	        }
	    }
	    /**
	     * The first entry in the parsed list of patterns
	     */
	    pattern() {
	        return this.#patternList[this.#index];
	    }
	    /**
	     * true of if pattern() returns a string
	     */
	    isString() {
	        return typeof this.#patternList[this.#index] === 'string';
	    }
	    /**
	     * true of if pattern() returns GLOBSTAR
	     */
	    isGlobstar() {
	        return this.#patternList[this.#index] === minimatch_1.GLOBSTAR;
	    }
	    /**
	     * true if pattern() returns a regexp
	     */
	    isRegExp() {
	        return this.#patternList[this.#index] instanceof RegExp;
	    }
	    /**
	     * The /-joined set of glob parts that make up this pattern
	     */
	    globString() {
	        return (this.#globString =
	            this.#globString ||
	                (this.#index === 0 ?
	                    this.isAbsolute() ?
	                        this.#globList[0] + this.#globList.slice(1).join('/')
	                        : this.#globList.join('/')
	                    : this.#globList.slice(this.#index).join('/')));
	    }
	    /**
	     * true if there are more pattern parts after this one
	     */
	    hasMore() {
	        return this.length > this.#index + 1;
	    }
	    /**
	     * The rest of the pattern after this part, or null if this is the end
	     */
	    rest() {
	        if (this.#rest !== undefined)
	            return this.#rest;
	        if (!this.hasMore())
	            return (this.#rest = null);
	        this.#rest = new Pattern(this.#patternList, this.#globList, this.#index + 1, this.#platform);
	        this.#rest.#isAbsolute = this.#isAbsolute;
	        this.#rest.#isUNC = this.#isUNC;
	        this.#rest.#isDrive = this.#isDrive;
	        return this.#rest;
	    }
	    /**
	     * true if the pattern represents a //unc/path/ on windows
	     */
	    isUNC() {
	        const pl = this.#patternList;
	        return this.#isUNC !== undefined ?
	            this.#isUNC
	            : (this.#isUNC =
	                this.#platform === 'win32' &&
	                    this.#index === 0 &&
	                    pl[0] === '' &&
	                    pl[1] === '' &&
	                    typeof pl[2] === 'string' &&
	                    !!pl[2] &&
	                    typeof pl[3] === 'string' &&
	                    !!pl[3]);
	    }
	    // pattern like C:/...
	    // split = ['C:', ...]
	    // XXX: would be nice to handle patterns like `c:*` to test the cwd
	    // in c: for *, but I don't know of a way to even figure out what that
	    // cwd is without actually chdir'ing into it?
	    /**
	     * True if the pattern starts with a drive letter on Windows
	     */
	    isDrive() {
	        const pl = this.#patternList;
	        return this.#isDrive !== undefined ?
	            this.#isDrive
	            : (this.#isDrive =
	                this.#platform === 'win32' &&
	                    this.#index === 0 &&
	                    this.length > 1 &&
	                    typeof pl[0] === 'string' &&
	                    /^[a-z]:$/i.test(pl[0]));
	    }
	    // pattern = '/' or '/...' or '/x/...'
	    // split = ['', ''] or ['', ...] or ['', 'x', ...]
	    // Drive and UNC both considered absolute on windows
	    /**
	     * True if the pattern is rooted on an absolute path
	     */
	    isAbsolute() {
	        const pl = this.#patternList;
	        return this.#isAbsolute !== undefined ?
	            this.#isAbsolute
	            : (this.#isAbsolute =
	                (pl[0] === '' && pl.length > 1) ||
	                    this.isDrive() ||
	                    this.isUNC());
	    }
	    /**
	     * consume the root of the pattern, and return it
	     */
	    root() {
	        const p = this.#patternList[0];
	        return (typeof p === 'string' && this.isAbsolute() && this.#index === 0) ?
	            p
	            : '';
	    }
	    /**
	     * Check to see if the current globstar pattern is allowed to follow
	     * a symbolic link.
	     */
	    checkFollowGlobstar() {
	        return !(this.#index === 0 ||
	            !this.isGlobstar() ||
	            !this.#followGlobstar);
	    }
	    /**
	     * Mark that the current globstar pattern is following a symbolic link
	     */
	    markFollowGlobstar() {
	        if (this.#index === 0 || !this.isGlobstar() || !this.#followGlobstar)
	            return false;
	        this.#followGlobstar = false;
	        return true;
	    }
	}
	pattern.Pattern = Pattern;
	
	return pattern;
}

var walker = {};

var ignore = {};

var hasRequiredIgnore;

function requireIgnore () {
	if (hasRequiredIgnore) return ignore;
	hasRequiredIgnore = 1;
	// give it a pattern, and it'll be able to tell you if
	// a given path should be ignored.
	// Ignoring a path ignores its children if the pattern ends in /**
	// Ignores are always parsed in dot:true mode
	Object.defineProperty(ignore, "__esModule", { value: true });
	ignore.Ignore = void 0;
	const minimatch_1 = requireCommonjs$4();
	const pattern_js_1 = requirePattern();
	const defaultPlatform = (typeof process === 'object' &&
	    process &&
	    typeof process.platform === 'string') ?
	    process.platform
	    : 'linux';
	/**
	 * Class used to process ignored patterns
	 */
	class Ignore {
	    relative;
	    relativeChildren;
	    absolute;
	    absoluteChildren;
	    platform;
	    mmopts;
	    constructor(ignored, { nobrace, nocase, noext, noglobstar, platform = defaultPlatform, }) {
	        this.relative = [];
	        this.absolute = [];
	        this.relativeChildren = [];
	        this.absoluteChildren = [];
	        this.platform = platform;
	        this.mmopts = {
	            dot: true,
	            nobrace,
	            nocase,
	            noext,
	            noglobstar,
	            optimizationLevel: 2,
	            platform,
	            nocomment: true,
	            nonegate: true,
	        };
	        for (const ign of ignored)
	            this.add(ign);
	    }
	    add(ign) {
	        // this is a little weird, but it gives us a clean set of optimized
	        // minimatch matchers, without getting tripped up if one of them
	        // ends in /** inside a brace section, and it's only inefficient at
	        // the start of the walk, not along it.
	        // It'd be nice if the Pattern class just had a .test() method, but
	        // handling globstars is a bit of a pita, and that code already lives
	        // in minimatch anyway.
	        // Another way would be if maybe Minimatch could take its set/globParts
	        // as an option, and then we could at least just use Pattern to test
	        // for absolute-ness.
	        // Yet another way, Minimatch could take an array of glob strings, and
	        // a cwd option, and do the right thing.
	        const mm = new minimatch_1.Minimatch(ign, this.mmopts);
	        for (let i = 0; i < mm.set.length; i++) {
	            const parsed = mm.set[i];
	            const globParts = mm.globParts[i];
	            /* c8 ignore start */
	            if (!parsed || !globParts) {
	                throw new Error('invalid pattern object');
	            }
	            // strip off leading ./ portions
	            // https://github.com/isaacs/node-glob/issues/570
	            while (parsed[0] === '.' && globParts[0] === '.') {
	                parsed.shift();
	                globParts.shift();
	            }
	            /* c8 ignore stop */
	            const p = new pattern_js_1.Pattern(parsed, globParts, 0, this.platform);
	            const m = new minimatch_1.Minimatch(p.globString(), this.mmopts);
	            const children = globParts[globParts.length - 1] === '**';
	            const absolute = p.isAbsolute();
	            if (absolute)
	                this.absolute.push(m);
	            else
	                this.relative.push(m);
	            if (children) {
	                if (absolute)
	                    this.absoluteChildren.push(m);
	                else
	                    this.relativeChildren.push(m);
	            }
	        }
	    }
	    ignored(p) {
	        const fullpath = p.fullpath();
	        const fullpaths = `${fullpath}/`;
	        const relative = p.relative() || '.';
	        const relatives = `${relative}/`;
	        for (const m of this.relative) {
	            if (m.match(relative) || m.match(relatives))
	                return true;
	        }
	        for (const m of this.absolute) {
	            if (m.match(fullpath) || m.match(fullpaths))
	                return true;
	        }
	        return false;
	    }
	    childrenIgnored(p) {
	        const fullpath = p.fullpath() + '/';
	        const relative = (p.relative() || '.') + '/';
	        for (const m of this.relativeChildren) {
	            if (m.match(relative))
	                return true;
	        }
	        for (const m of this.absoluteChildren) {
	            if (m.match(fullpath))
	                return true;
	        }
	        return false;
	    }
	}
	ignore.Ignore = Ignore;
	
	return ignore;
}

var processor = {};

var hasRequiredProcessor;

function requireProcessor () {
	if (hasRequiredProcessor) return processor;
	hasRequiredProcessor = 1;
	// synchronous utility for filtering entries and calculating subwalks
	Object.defineProperty(processor, "__esModule", { value: true });
	processor.Processor = processor.SubWalks = processor.MatchRecord = processor.HasWalkedCache = void 0;
	const minimatch_1 = requireCommonjs$4();
	/**
	 * A cache of which patterns have been processed for a given Path
	 */
	class HasWalkedCache {
	    store;
	    constructor(store = new Map()) {
	        this.store = store;
	    }
	    copy() {
	        return new HasWalkedCache(new Map(this.store));
	    }
	    hasWalked(target, pattern) {
	        return this.store.get(target.fullpath())?.has(pattern.globString());
	    }
	    storeWalked(target, pattern) {
	        const fullpath = target.fullpath();
	        const cached = this.store.get(fullpath);
	        if (cached)
	            cached.add(pattern.globString());
	        else
	            this.store.set(fullpath, new Set([pattern.globString()]));
	    }
	}
	processor.HasWalkedCache = HasWalkedCache;
	/**
	 * A record of which paths have been matched in a given walk step,
	 * and whether they only are considered a match if they are a directory,
	 * and whether their absolute or relative path should be returned.
	 */
	class MatchRecord {
	    store = new Map();
	    add(target, absolute, ifDir) {
	        const n = (absolute ? 2 : 0) | (ifDir ? 1 : 0);
	        const current = this.store.get(target);
	        this.store.set(target, current === undefined ? n : n & current);
	    }
	    // match, absolute, ifdir
	    entries() {
	        return [...this.store.entries()].map(([path, n]) => [
	            path,
	            !!(n & 2),
	            !!(n & 1),
	        ]);
	    }
	}
	processor.MatchRecord = MatchRecord;
	/**
	 * A collection of patterns that must be processed in a subsequent step
	 * for a given path.
	 */
	class SubWalks {
	    store = new Map();
	    add(target, pattern) {
	        if (!target.canReaddir()) {
	            return;
	        }
	        const subs = this.store.get(target);
	        if (subs) {
	            if (!subs.find(p => p.globString() === pattern.globString())) {
	                subs.push(pattern);
	            }
	        }
	        else
	            this.store.set(target, [pattern]);
	    }
	    get(target) {
	        const subs = this.store.get(target);
	        /* c8 ignore start */
	        if (!subs) {
	            throw new Error('attempting to walk unknown path');
	        }
	        /* c8 ignore stop */
	        return subs;
	    }
	    entries() {
	        return this.keys().map(k => [k, this.store.get(k)]);
	    }
	    keys() {
	        return [...this.store.keys()].filter(t => t.canReaddir());
	    }
	}
	processor.SubWalks = SubWalks;
	/**
	 * The class that processes patterns for a given path.
	 *
	 * Handles child entry filtering, and determining whether a path's
	 * directory contents must be read.
	 */
	class Processor {
	    hasWalkedCache;
	    matches = new MatchRecord();
	    subwalks = new SubWalks();
	    patterns;
	    follow;
	    dot;
	    opts;
	    constructor(opts, hasWalkedCache) {
	        this.opts = opts;
	        this.follow = !!opts.follow;
	        this.dot = !!opts.dot;
	        this.hasWalkedCache =
	            hasWalkedCache ? hasWalkedCache.copy() : new HasWalkedCache();
	    }
	    processPatterns(target, patterns) {
	        this.patterns = patterns;
	        const processingSet = patterns.map(p => [target, p]);
	        // map of paths to the magic-starting subwalks they need to walk
	        // first item in patterns is the filter
	        for (let [t, pattern] of processingSet) {
	            this.hasWalkedCache.storeWalked(t, pattern);
	            const root = pattern.root();
	            const absolute = pattern.isAbsolute() && this.opts.absolute !== false;
	            // start absolute patterns at root
	            if (root) {
	                t = t.resolve(root === '/' && this.opts.root !== undefined ?
	                    this.opts.root
	                    : root);
	                const rest = pattern.rest();
	                if (!rest) {
	                    this.matches.add(t, true, false);
	                    continue;
	                }
	                else {
	                    pattern = rest;
	                }
	            }
	            if (t.isENOENT())
	                continue;
	            let p;
	            let rest;
	            let changed = false;
	            while (typeof (p = pattern.pattern()) === 'string' &&
	                (rest = pattern.rest())) {
	                const c = t.resolve(p);
	                t = c;
	                pattern = rest;
	                changed = true;
	            }
	            p = pattern.pattern();
	            rest = pattern.rest();
	            if (changed) {
	                if (this.hasWalkedCache.hasWalked(t, pattern))
	                    continue;
	                this.hasWalkedCache.storeWalked(t, pattern);
	            }
	            // now we have either a final string for a known entry,
	            // more strings for an unknown entry,
	            // or a pattern starting with magic, mounted on t.
	            if (typeof p === 'string') {
	                // must not be final entry, otherwise we would have
	                // concatenated it earlier.
	                const ifDir = p === '..' || p === '' || p === '.';
	                this.matches.add(t.resolve(p), absolute, ifDir);
	                continue;
	            }
	            else if (p === minimatch_1.GLOBSTAR) {
	                // if no rest, match and subwalk pattern
	                // if rest, process rest and subwalk pattern
	                // if it's a symlink, but we didn't get here by way of a
	                // globstar match (meaning it's the first time THIS globstar
	                // has traversed a symlink), then we follow it. Otherwise, stop.
	                if (!t.isSymbolicLink() ||
	                    this.follow ||
	                    pattern.checkFollowGlobstar()) {
	                    this.subwalks.add(t, pattern);
	                }
	                const rp = rest?.pattern();
	                const rrest = rest?.rest();
	                if (!rest || ((rp === '' || rp === '.') && !rrest)) {
	                    // only HAS to be a dir if it ends in **/ or **/.
	                    // but ending in ** will match files as well.
	                    this.matches.add(t, absolute, rp === '' || rp === '.');
	                }
	                else {
	                    if (rp === '..') {
	                        // this would mean you're matching **/.. at the fs root,
	                        // and no thanks, I'm not gonna test that specific case.
	                        /* c8 ignore start */
	                        const tp = t.parent || t;
	                        /* c8 ignore stop */
	                        if (!rrest)
	                            this.matches.add(tp, absolute, true);
	                        else if (!this.hasWalkedCache.hasWalked(tp, rrest)) {
	                            this.subwalks.add(tp, rrest);
	                        }
	                    }
	                }
	            }
	            else if (p instanceof RegExp) {
	                this.subwalks.add(t, pattern);
	            }
	        }
	        return this;
	    }
	    subwalkTargets() {
	        return this.subwalks.keys();
	    }
	    child() {
	        return new Processor(this.opts, this.hasWalkedCache);
	    }
	    // return a new Processor containing the subwalks for each
	    // child entry, and a set of matches, and
	    // a hasWalkedCache that's a copy of this one
	    // then we're going to call
	    filterEntries(parent, entries) {
	        const patterns = this.subwalks.get(parent);
	        // put matches and entry walks into the results processor
	        const results = this.child();
	        for (const e of entries) {
	            for (const pattern of patterns) {
	                const absolute = pattern.isAbsolute();
	                const p = pattern.pattern();
	                const rest = pattern.rest();
	                if (p === minimatch_1.GLOBSTAR) {
	                    results.testGlobstar(e, pattern, rest, absolute);
	                }
	                else if (p instanceof RegExp) {
	                    results.testRegExp(e, p, rest, absolute);
	                }
	                else {
	                    results.testString(e, p, rest, absolute);
	                }
	            }
	        }
	        return results;
	    }
	    testGlobstar(e, pattern, rest, absolute) {
	        if (this.dot || !e.name.startsWith('.')) {
	            if (!pattern.hasMore()) {
	                this.matches.add(e, absolute, false);
	            }
	            if (e.canReaddir()) {
	                // if we're in follow mode or it's not a symlink, just keep
	                // testing the same pattern. If there's more after the globstar,
	                // then this symlink consumes the globstar. If not, then we can
	                // follow at most ONE symlink along the way, so we mark it, which
	                // also checks to ensure that it wasn't already marked.
	                if (this.follow || !e.isSymbolicLink()) {
	                    this.subwalks.add(e, pattern);
	                }
	                else if (e.isSymbolicLink()) {
	                    if (rest && pattern.checkFollowGlobstar()) {
	                        this.subwalks.add(e, rest);
	                    }
	                    else if (pattern.markFollowGlobstar()) {
	                        this.subwalks.add(e, pattern);
	                    }
	                }
	            }
	        }
	        // if the NEXT thing matches this entry, then also add
	        // the rest.
	        if (rest) {
	            const rp = rest.pattern();
	            if (typeof rp === 'string' &&
	                // dots and empty were handled already
	                rp !== '..' &&
	                rp !== '' &&
	                rp !== '.') {
	                this.testString(e, rp, rest.rest(), absolute);
	            }
	            else if (rp === '..') {
	                /* c8 ignore start */
	                const ep = e.parent || e;
	                /* c8 ignore stop */
	                this.subwalks.add(ep, rest);
	            }
	            else if (rp instanceof RegExp) {
	                this.testRegExp(e, rp, rest.rest(), absolute);
	            }
	        }
	    }
	    testRegExp(e, p, rest, absolute) {
	        if (!p.test(e.name))
	            return;
	        if (!rest) {
	            this.matches.add(e, absolute, false);
	        }
	        else {
	            this.subwalks.add(e, rest);
	        }
	    }
	    testString(e, p, rest, absolute) {
	        // should never happen?
	        if (!e.isNamed(p))
	            return;
	        if (!rest) {
	            this.matches.add(e, absolute, false);
	        }
	        else {
	            this.subwalks.add(e, rest);
	        }
	    }
	}
	processor.Processor = Processor;
	
	return processor;
}

var hasRequiredWalker;

function requireWalker () {
	if (hasRequiredWalker) return walker;
	hasRequiredWalker = 1;
	Object.defineProperty(walker, "__esModule", { value: true });
	walker.GlobStream = walker.GlobWalker = walker.GlobUtil = void 0;
	/**
	 * Single-use utility classes to provide functionality to the {@link Glob}
	 * methods.
	 *
	 * @module
	 */
	const minipass_1 = requireCommonjs$2();
	const ignore_js_1 = requireIgnore();
	const processor_js_1 = requireProcessor();
	const makeIgnore = (ignore, opts) => typeof ignore === 'string' ? new ignore_js_1.Ignore([ignore], opts)
	    : Array.isArray(ignore) ? new ignore_js_1.Ignore(ignore, opts)
	        : ignore;
	/**
	 * basic walking utilities that all the glob walker types use
	 */
	class GlobUtil {
	    path;
	    patterns;
	    opts;
	    seen = new Set();
	    paused = false;
	    aborted = false;
	    #onResume = [];
	    #ignore;
	    #sep;
	    signal;
	    maxDepth;
	    includeChildMatches;
	    constructor(patterns, path, opts) {
	        this.patterns = patterns;
	        this.path = path;
	        this.opts = opts;
	        this.#sep = !opts.posix && opts.platform === 'win32' ? '\\' : '/';
	        this.includeChildMatches = opts.includeChildMatches !== false;
	        if (opts.ignore || !this.includeChildMatches) {
	            this.#ignore = makeIgnore(opts.ignore ?? [], opts);
	            if (!this.includeChildMatches &&
	                typeof this.#ignore.add !== 'function') {
	                const m = 'cannot ignore child matches, ignore lacks add() method.';
	                throw new Error(m);
	            }
	        }
	        // ignore, always set with maxDepth, but it's optional on the
	        // GlobOptions type
	        /* c8 ignore start */
	        this.maxDepth = opts.maxDepth || Infinity;
	        /* c8 ignore stop */
	        if (opts.signal) {
	            this.signal = opts.signal;
	            this.signal.addEventListener('abort', () => {
	                this.#onResume.length = 0;
	            });
	        }
	    }
	    #ignored(path) {
	        return this.seen.has(path) || !!this.#ignore?.ignored?.(path);
	    }
	    #childrenIgnored(path) {
	        return !!this.#ignore?.childrenIgnored?.(path);
	    }
	    // backpressure mechanism
	    pause() {
	        this.paused = true;
	    }
	    resume() {
	        /* c8 ignore start */
	        if (this.signal?.aborted)
	            return;
	        /* c8 ignore stop */
	        this.paused = false;
	        let fn = undefined;
	        while (!this.paused && (fn = this.#onResume.shift())) {
	            fn();
	        }
	    }
	    onResume(fn) {
	        if (this.signal?.aborted)
	            return;
	        /* c8 ignore start */
	        if (!this.paused) {
	            fn();
	        }
	        else {
	            /* c8 ignore stop */
	            this.#onResume.push(fn);
	        }
	    }
	    // do the requisite realpath/stat checking, and return the path
	    // to add or undefined to filter it out.
	    async matchCheck(e, ifDir) {
	        if (ifDir && this.opts.nodir)
	            return undefined;
	        let rpc;
	        if (this.opts.realpath) {
	            rpc = e.realpathCached() || (await e.realpath());
	            if (!rpc)
	                return undefined;
	            e = rpc;
	        }
	        const needStat = e.isUnknown() || this.opts.stat;
	        const s = needStat ? await e.lstat() : e;
	        if (this.opts.follow && this.opts.nodir && s?.isSymbolicLink()) {
	            const target = await s.realpath();
	            /* c8 ignore start */
	            if (target && (target.isUnknown() || this.opts.stat)) {
	                await target.lstat();
	            }
	            /* c8 ignore stop */
	        }
	        return this.matchCheckTest(s, ifDir);
	    }
	    matchCheckTest(e, ifDir) {
	        return (e &&
	            (this.maxDepth === Infinity || e.depth() <= this.maxDepth) &&
	            (!ifDir || e.canReaddir()) &&
	            (!this.opts.nodir || !e.isDirectory()) &&
	            (!this.opts.nodir ||
	                !this.opts.follow ||
	                !e.isSymbolicLink() ||
	                !e.realpathCached()?.isDirectory()) &&
	            !this.#ignored(e)) ?
	            e
	            : undefined;
	    }
	    matchCheckSync(e, ifDir) {
	        if (ifDir && this.opts.nodir)
	            return undefined;
	        let rpc;
	        if (this.opts.realpath) {
	            rpc = e.realpathCached() || e.realpathSync();
	            if (!rpc)
	                return undefined;
	            e = rpc;
	        }
	        const needStat = e.isUnknown() || this.opts.stat;
	        const s = needStat ? e.lstatSync() : e;
	        if (this.opts.follow && this.opts.nodir && s?.isSymbolicLink()) {
	            const target = s.realpathSync();
	            if (target && (target?.isUnknown() || this.opts.stat)) {
	                target.lstatSync();
	            }
	        }
	        return this.matchCheckTest(s, ifDir);
	    }
	    matchFinish(e, absolute) {
	        if (this.#ignored(e))
	            return;
	        // we know we have an ignore if this is false, but TS doesn't
	        if (!this.includeChildMatches && this.#ignore?.add) {
	            const ign = `${e.relativePosix()}/**`;
	            this.#ignore.add(ign);
	        }
	        const abs = this.opts.absolute === undefined ? absolute : this.opts.absolute;
	        this.seen.add(e);
	        const mark = this.opts.mark && e.isDirectory() ? this.#sep : '';
	        // ok, we have what we need!
	        if (this.opts.withFileTypes) {
	            this.matchEmit(e);
	        }
	        else if (abs) {
	            const abs = this.opts.posix ? e.fullpathPosix() : e.fullpath();
	            this.matchEmit(abs + mark);
	        }
	        else {
	            const rel = this.opts.posix ? e.relativePosix() : e.relative();
	            const pre = this.opts.dotRelative && !rel.startsWith('..' + this.#sep) ?
	                '.' + this.#sep
	                : '';
	            this.matchEmit(!rel ? '.' + mark : pre + rel + mark);
	        }
	    }
	    async match(e, absolute, ifDir) {
	        const p = await this.matchCheck(e, ifDir);
	        if (p)
	            this.matchFinish(p, absolute);
	    }
	    matchSync(e, absolute, ifDir) {
	        const p = this.matchCheckSync(e, ifDir);
	        if (p)
	            this.matchFinish(p, absolute);
	    }
	    walkCB(target, patterns, cb) {
	        /* c8 ignore start */
	        if (this.signal?.aborted)
	            cb();
	        /* c8 ignore stop */
	        this.walkCB2(target, patterns, new processor_js_1.Processor(this.opts), cb);
	    }
	    walkCB2(target, patterns, processor, cb) {
	        if (this.#childrenIgnored(target))
	            return cb();
	        if (this.signal?.aborted)
	            cb();
	        if (this.paused) {
	            this.onResume(() => this.walkCB2(target, patterns, processor, cb));
	            return;
	        }
	        processor.processPatterns(target, patterns);
	        // done processing.  all of the above is sync, can be abstracted out.
	        // subwalks is a map of paths to the entry filters they need
	        // matches is a map of paths to [absolute, ifDir] tuples.
	        let tasks = 1;
	        const next = () => {
	            if (--tasks === 0)
	                cb();
	        };
	        for (const [m, absolute, ifDir] of processor.matches.entries()) {
	            if (this.#ignored(m))
	                continue;
	            tasks++;
	            this.match(m, absolute, ifDir).then(() => next());
	        }
	        for (const t of processor.subwalkTargets()) {
	            if (this.maxDepth !== Infinity && t.depth() >= this.maxDepth) {
	                continue;
	            }
	            tasks++;
	            const childrenCached = t.readdirCached();
	            if (t.calledReaddir())
	                this.walkCB3(t, childrenCached, processor, next);
	            else {
	                t.readdirCB((_, entries) => this.walkCB3(t, entries, processor, next), true);
	            }
	        }
	        next();
	    }
	    walkCB3(target, entries, processor, cb) {
	        processor = processor.filterEntries(target, entries);
	        let tasks = 1;
	        const next = () => {
	            if (--tasks === 0)
	                cb();
	        };
	        for (const [m, absolute, ifDir] of processor.matches.entries()) {
	            if (this.#ignored(m))
	                continue;
	            tasks++;
	            this.match(m, absolute, ifDir).then(() => next());
	        }
	        for (const [target, patterns] of processor.subwalks.entries()) {
	            tasks++;
	            this.walkCB2(target, patterns, processor.child(), next);
	        }
	        next();
	    }
	    walkCBSync(target, patterns, cb) {
	        /* c8 ignore start */
	        if (this.signal?.aborted)
	            cb();
	        /* c8 ignore stop */
	        this.walkCB2Sync(target, patterns, new processor_js_1.Processor(this.opts), cb);
	    }
	    walkCB2Sync(target, patterns, processor, cb) {
	        if (this.#childrenIgnored(target))
	            return cb();
	        if (this.signal?.aborted)
	            cb();
	        if (this.paused) {
	            this.onResume(() => this.walkCB2Sync(target, patterns, processor, cb));
	            return;
	        }
	        processor.processPatterns(target, patterns);
	        // done processing.  all of the above is sync, can be abstracted out.
	        // subwalks is a map of paths to the entry filters they need
	        // matches is a map of paths to [absolute, ifDir] tuples.
	        let tasks = 1;
	        const next = () => {
	            if (--tasks === 0)
	                cb();
	        };
	        for (const [m, absolute, ifDir] of processor.matches.entries()) {
	            if (this.#ignored(m))
	                continue;
	            this.matchSync(m, absolute, ifDir);
	        }
	        for (const t of processor.subwalkTargets()) {
	            if (this.maxDepth !== Infinity && t.depth() >= this.maxDepth) {
	                continue;
	            }
	            tasks++;
	            const children = t.readdirSync();
	            this.walkCB3Sync(t, children, processor, next);
	        }
	        next();
	    }
	    walkCB3Sync(target, entries, processor, cb) {
	        processor = processor.filterEntries(target, entries);
	        let tasks = 1;
	        const next = () => {
	            if (--tasks === 0)
	                cb();
	        };
	        for (const [m, absolute, ifDir] of processor.matches.entries()) {
	            if (this.#ignored(m))
	                continue;
	            this.matchSync(m, absolute, ifDir);
	        }
	        for (const [target, patterns] of processor.subwalks.entries()) {
	            tasks++;
	            this.walkCB2Sync(target, patterns, processor.child(), next);
	        }
	        next();
	    }
	}
	walker.GlobUtil = GlobUtil;
	class GlobWalker extends GlobUtil {
	    matches = new Set();
	    constructor(patterns, path, opts) {
	        super(patterns, path, opts);
	    }
	    matchEmit(e) {
	        this.matches.add(e);
	    }
	    async walk() {
	        if (this.signal?.aborted)
	            throw this.signal.reason;
	        if (this.path.isUnknown()) {
	            await this.path.lstat();
	        }
	        await new Promise((res, rej) => {
	            this.walkCB(this.path, this.patterns, () => {
	                if (this.signal?.aborted) {
	                    rej(this.signal.reason);
	                }
	                else {
	                    res(this.matches);
	                }
	            });
	        });
	        return this.matches;
	    }
	    walkSync() {
	        if (this.signal?.aborted)
	            throw this.signal.reason;
	        if (this.path.isUnknown()) {
	            this.path.lstatSync();
	        }
	        // nothing for the callback to do, because this never pauses
	        this.walkCBSync(this.path, this.patterns, () => {
	            if (this.signal?.aborted)
	                throw this.signal.reason;
	        });
	        return this.matches;
	    }
	}
	walker.GlobWalker = GlobWalker;
	class GlobStream extends GlobUtil {
	    results;
	    constructor(patterns, path, opts) {
	        super(patterns, path, opts);
	        this.results = new minipass_1.Minipass({
	            signal: this.signal,
	            objectMode: true,
	        });
	        this.results.on('drain', () => this.resume());
	        this.results.on('resume', () => this.resume());
	    }
	    matchEmit(e) {
	        this.results.write(e);
	        if (!this.results.flowing)
	            this.pause();
	    }
	    stream() {
	        const target = this.path;
	        if (target.isUnknown()) {
	            target.lstat().then(() => {
	                this.walkCB(target, this.patterns, () => this.results.end());
	            });
	        }
	        else {
	            this.walkCB(target, this.patterns, () => this.results.end());
	        }
	        return this.results;
	    }
	    streamSync() {
	        if (this.path.isUnknown()) {
	            this.path.lstatSync();
	        }
	        this.walkCBSync(this.path, this.patterns, () => this.results.end());
	        return this.results;
	    }
	}
	walker.GlobStream = GlobStream;
	
	return walker;
}

var hasRequiredGlob;

function requireGlob () {
	if (hasRequiredGlob) return glob;
	hasRequiredGlob = 1;
	Object.defineProperty(glob, "__esModule", { value: true });
	glob.Glob = void 0;
	const minimatch_1 = requireCommonjs$4();
	const node_url_1 = require$$2$1;
	const path_scurry_1 = requireCommonjs$1();
	const pattern_js_1 = requirePattern();
	const walker_js_1 = requireWalker();
	// if no process global, just call it linux.
	// so we default to case-sensitive, / separators
	const defaultPlatform = (typeof process === 'object' &&
	    process &&
	    typeof process.platform === 'string') ?
	    process.platform
	    : 'linux';
	/**
	 * An object that can perform glob pattern traversals.
	 */
	class Glob {
	    absolute;
	    cwd;
	    root;
	    dot;
	    dotRelative;
	    follow;
	    ignore;
	    magicalBraces;
	    mark;
	    matchBase;
	    maxDepth;
	    nobrace;
	    nocase;
	    nodir;
	    noext;
	    noglobstar;
	    pattern;
	    platform;
	    realpath;
	    scurry;
	    stat;
	    signal;
	    windowsPathsNoEscape;
	    withFileTypes;
	    includeChildMatches;
	    /**
	     * The options provided to the constructor.
	     */
	    opts;
	    /**
	     * An array of parsed immutable {@link Pattern} objects.
	     */
	    patterns;
	    /**
	     * All options are stored as properties on the `Glob` object.
	     *
	     * See {@link GlobOptions} for full options descriptions.
	     *
	     * Note that a previous `Glob` object can be passed as the
	     * `GlobOptions` to another `Glob` instantiation to re-use settings
	     * and caches with a new pattern.
	     *
	     * Traversal functions can be called multiple times to run the walk
	     * again.
	     */
	    constructor(pattern, opts) {
	        /* c8 ignore start */
	        if (!opts)
	            throw new TypeError('glob options required');
	        /* c8 ignore stop */
	        this.withFileTypes = !!opts.withFileTypes;
	        this.signal = opts.signal;
	        this.follow = !!opts.follow;
	        this.dot = !!opts.dot;
	        this.dotRelative = !!opts.dotRelative;
	        this.nodir = !!opts.nodir;
	        this.mark = !!opts.mark;
	        if (!opts.cwd) {
	            this.cwd = '';
	        }
	        else if (opts.cwd instanceof URL || opts.cwd.startsWith('file://')) {
	            opts.cwd = (0, node_url_1.fileURLToPath)(opts.cwd);
	        }
	        this.cwd = opts.cwd || '';
	        this.root = opts.root;
	        this.magicalBraces = !!opts.magicalBraces;
	        this.nobrace = !!opts.nobrace;
	        this.noext = !!opts.noext;
	        this.realpath = !!opts.realpath;
	        this.absolute = opts.absolute;
	        this.includeChildMatches = opts.includeChildMatches !== false;
	        this.noglobstar = !!opts.noglobstar;
	        this.matchBase = !!opts.matchBase;
	        this.maxDepth =
	            typeof opts.maxDepth === 'number' ? opts.maxDepth : Infinity;
	        this.stat = !!opts.stat;
	        this.ignore = opts.ignore;
	        if (this.withFileTypes && this.absolute !== undefined) {
	            throw new Error('cannot set absolute and withFileTypes:true');
	        }
	        if (typeof pattern === 'string') {
	            pattern = [pattern];
	        }
	        this.windowsPathsNoEscape =
	            !!opts.windowsPathsNoEscape ||
	                opts.allowWindowsEscape ===
	                    false;
	        if (this.windowsPathsNoEscape) {
	            pattern = pattern.map(p => p.replace(/\\/g, '/'));
	        }
	        if (this.matchBase) {
	            if (opts.noglobstar) {
	                throw new TypeError('base matching requires globstar');
	            }
	            pattern = pattern.map(p => (p.includes('/') ? p : `./**/${p}`));
	        }
	        this.pattern = pattern;
	        this.platform = opts.platform || defaultPlatform;
	        this.opts = { ...opts, platform: this.platform };
	        if (opts.scurry) {
	            this.scurry = opts.scurry;
	            if (opts.nocase !== undefined &&
	                opts.nocase !== opts.scurry.nocase) {
	                throw new Error('nocase option contradicts provided scurry option');
	            }
	        }
	        else {
	            const Scurry = opts.platform === 'win32' ? path_scurry_1.PathScurryWin32
	                : opts.platform === 'darwin' ? path_scurry_1.PathScurryDarwin
	                    : opts.platform ? path_scurry_1.PathScurryPosix
	                        : path_scurry_1.PathScurry;
	            this.scurry = new Scurry(this.cwd, {
	                nocase: opts.nocase,
	                fs: opts.fs,
	            });
	        }
	        this.nocase = this.scurry.nocase;
	        // If you do nocase:true on a case-sensitive file system, then
	        // we need to use regexps instead of strings for non-magic
	        // path portions, because statting `aBc` won't return results
	        // for the file `AbC` for example.
	        const nocaseMagicOnly = this.platform === 'darwin' || this.platform === 'win32';
	        const mmo = {
	            // default nocase based on platform
	            ...opts,
	            dot: this.dot,
	            matchBase: this.matchBase,
	            nobrace: this.nobrace,
	            nocase: this.nocase,
	            nocaseMagicOnly,
	            nocomment: true,
	            noext: this.noext,
	            nonegate: true,
	            optimizationLevel: 2,
	            platform: this.platform,
	            windowsPathsNoEscape: this.windowsPathsNoEscape,
	            debug: !!this.opts.debug,
	        };
	        const mms = this.pattern.map(p => new minimatch_1.Minimatch(p, mmo));
	        const [matchSet, globParts] = mms.reduce((set, m) => {
	            set[0].push(...m.set);
	            set[1].push(...m.globParts);
	            return set;
	        }, [[], []]);
	        this.patterns = matchSet.map((set, i) => {
	            const g = globParts[i];
	            /* c8 ignore start */
	            if (!g)
	                throw new Error('invalid pattern object');
	            /* c8 ignore stop */
	            return new pattern_js_1.Pattern(set, g, 0, this.platform);
	        });
	    }
	    async walk() {
	        // Walkers always return array of Path objects, so we just have to
	        // coerce them into the right shape.  It will have already called
	        // realpath() if the option was set to do so, so we know that's cached.
	        // start out knowing the cwd, at least
	        return [
	            ...(await new walker_js_1.GlobWalker(this.patterns, this.scurry.cwd, {
	                ...this.opts,
	                maxDepth: this.maxDepth !== Infinity ?
	                    this.maxDepth + this.scurry.cwd.depth()
	                    : Infinity,
	                platform: this.platform,
	                nocase: this.nocase,
	                includeChildMatches: this.includeChildMatches,
	            }).walk()),
	        ];
	    }
	    walkSync() {
	        return [
	            ...new walker_js_1.GlobWalker(this.patterns, this.scurry.cwd, {
	                ...this.opts,
	                maxDepth: this.maxDepth !== Infinity ?
	                    this.maxDepth + this.scurry.cwd.depth()
	                    : Infinity,
	                platform: this.platform,
	                nocase: this.nocase,
	                includeChildMatches: this.includeChildMatches,
	            }).walkSync(),
	        ];
	    }
	    stream() {
	        return new walker_js_1.GlobStream(this.patterns, this.scurry.cwd, {
	            ...this.opts,
	            maxDepth: this.maxDepth !== Infinity ?
	                this.maxDepth + this.scurry.cwd.depth()
	                : Infinity,
	            platform: this.platform,
	            nocase: this.nocase,
	            includeChildMatches: this.includeChildMatches,
	        }).stream();
	    }
	    streamSync() {
	        return new walker_js_1.GlobStream(this.patterns, this.scurry.cwd, {
	            ...this.opts,
	            maxDepth: this.maxDepth !== Infinity ?
	                this.maxDepth + this.scurry.cwd.depth()
	                : Infinity,
	            platform: this.platform,
	            nocase: this.nocase,
	            includeChildMatches: this.includeChildMatches,
	        }).streamSync();
	    }
	    /**
	     * Default sync iteration function. Returns a Generator that
	     * iterates over the results.
	     */
	    iterateSync() {
	        return this.streamSync()[Symbol.iterator]();
	    }
	    [Symbol.iterator]() {
	        return this.iterateSync();
	    }
	    /**
	     * Default async iteration function. Returns an AsyncGenerator that
	     * iterates over the results.
	     */
	    iterate() {
	        return this.stream()[Symbol.asyncIterator]();
	    }
	    [Symbol.asyncIterator]() {
	        return this.iterate();
	    }
	}
	glob.Glob = Glob;
	
	return glob;
}

var hasMagic = {};

var hasRequiredHasMagic;

function requireHasMagic () {
	if (hasRequiredHasMagic) return hasMagic;
	hasRequiredHasMagic = 1;
	Object.defineProperty(hasMagic, "__esModule", { value: true });
	hasMagic.hasMagic = void 0;
	const minimatch_1 = requireCommonjs$4();
	/**
	 * Return true if the patterns provided contain any magic glob characters,
	 * given the options provided.
	 *
	 * Brace expansion is not considered "magic" unless the `magicalBraces` option
	 * is set, as brace expansion just turns one string into an array of strings.
	 * So a pattern like `'x{a,b}y'` would return `false`, because `'xay'` and
	 * `'xby'` both do not contain any magic glob characters, and it's treated the
	 * same as if you had called it on `['xay', 'xby']`. When `magicalBraces:true`
	 * is in the options, brace expansion _is_ treated as a pattern having magic.
	 */
	const hasMagic$1 = (pattern, options = {}) => {
	    if (!Array.isArray(pattern)) {
	        pattern = [pattern];
	    }
	    for (const p of pattern) {
	        if (new minimatch_1.Minimatch(p, options).hasMagic())
	            return true;
	    }
	    return false;
	};
	hasMagic.hasMagic = hasMagic$1;
	
	return hasMagic;
}

var hasRequiredCommonjs;

function requireCommonjs () {
	if (hasRequiredCommonjs) return commonjs$4;
	hasRequiredCommonjs = 1;
	(function (exports) {
		Object.defineProperty(exports, "__esModule", { value: true });
		exports.glob = exports.sync = exports.iterate = exports.iterateSync = exports.stream = exports.streamSync = exports.Ignore = exports.hasMagic = exports.Glob = exports.unescape = exports.escape = void 0;
		exports.globStreamSync = globStreamSync;
		exports.globStream = globStream;
		exports.globSync = globSync;
		exports.globIterateSync = globIterateSync;
		exports.globIterate = globIterate;
		const minimatch_1 = requireCommonjs$4();
		const glob_js_1 = requireGlob();
		const has_magic_js_1 = requireHasMagic();
		var minimatch_2 = requireCommonjs$4();
		Object.defineProperty(exports, "escape", { enumerable: true, get: function () { return minimatch_2.escape; } });
		Object.defineProperty(exports, "unescape", { enumerable: true, get: function () { return minimatch_2.unescape; } });
		var glob_js_2 = requireGlob();
		Object.defineProperty(exports, "Glob", { enumerable: true, get: function () { return glob_js_2.Glob; } });
		var has_magic_js_2 = requireHasMagic();
		Object.defineProperty(exports, "hasMagic", { enumerable: true, get: function () { return has_magic_js_2.hasMagic; } });
		var ignore_js_1 = requireIgnore();
		Object.defineProperty(exports, "Ignore", { enumerable: true, get: function () { return ignore_js_1.Ignore; } });
		function globStreamSync(pattern, options = {}) {
		    return new glob_js_1.Glob(pattern, options).streamSync();
		}
		function globStream(pattern, options = {}) {
		    return new glob_js_1.Glob(pattern, options).stream();
		}
		function globSync(pattern, options = {}) {
		    return new glob_js_1.Glob(pattern, options).walkSync();
		}
		async function glob_(pattern, options = {}) {
		    return new glob_js_1.Glob(pattern, options).walk();
		}
		function globIterateSync(pattern, options = {}) {
		    return new glob_js_1.Glob(pattern, options).iterateSync();
		}
		function globIterate(pattern, options = {}) {
		    return new glob_js_1.Glob(pattern, options).iterate();
		}
		// aliases: glob.sync.stream() glob.stream.sync() glob.sync() etc
		exports.streamSync = globStreamSync;
		exports.stream = Object.assign(globStream, { sync: globStreamSync });
		exports.iterateSync = globIterateSync;
		exports.iterate = Object.assign(globIterate, {
		    sync: globIterateSync,
		});
		exports.sync = Object.assign(globSync, {
		    stream: globStreamSync,
		    iterate: globIterateSync,
		});
		exports.glob = Object.assign(glob_, {
		    glob: glob_,
		    globSync,
		    sync: exports.sync,
		    globStream,
		    stream: exports.stream,
		    globStreamSync,
		    streamSync: exports.streamSync,
		    globIterate,
		    iterate: exports.iterate,
		    globIterateSync,
		    iterateSync: exports.iterateSync,
		    Glob: glob_js_1.Glob,
		    hasMagic: has_magic_js_1.hasMagic,
		    escape: minimatch_1.escape,
		    unescape: minimatch_1.unescape,
		});
		exports.glob.glob = exports.glob;
		
	} (commonjs$4));
	return commonjs$4;
}

var defaultExtension;
var hasRequiredDefaultExtension;

function requireDefaultExtension () {
	if (hasRequiredDefaultExtension) return defaultExtension;
	hasRequiredDefaultExtension = 1;

	defaultExtension = [
		'.js',
		'.cjs',
		'.mjs',
		'.ts',
		'.tsx',
		'.jsx'
	];
	return defaultExtension;
}

var defaultExclude;
var hasRequiredDefaultExclude;

function requireDefaultExclude () {
	if (hasRequiredDefaultExclude) return defaultExclude;
	hasRequiredDefaultExclude = 1;

	const defaultExtension = requireDefaultExtension();
	const testFileExtensions = defaultExtension
		.map(extension => extension.slice(1))
		.join(',');

	defaultExclude = [
		'coverage/**',
		'packages/*/test{,s}/**',
		'**/*.d.ts',
		'test{,s}/**',
		`test{,-*}.{${testFileExtensions}}`,
		`**/*{.,-}test.{${testFileExtensions}}`,
		'**/__tests__/**',

		/* Exclude common development tool configuration files */
		'**/{ava,babel,nyc}.config.{js,cjs,mjs}',
		'**/jest.config.{js,cjs,mjs,ts}',
		'**/{karma,rollup,webpack}.config.js',
		'**/.{eslint,mocha}rc.{js,cjs}'
	];
	return defaultExclude;
}

var schema;
var hasRequiredSchema;

function requireSchema () {
	if (hasRequiredSchema) return schema;
	hasRequiredSchema = 1;

	const defaultExclude = requireDefaultExclude();
	const defaultExtension = requireDefaultExtension();

	const nycCommands = {
		all: [null, 'check-coverage', 'instrument', 'merge', 'report'],
		testExclude: [null, 'instrument', 'report', 'check-coverage'],
		instrument: [null, 'instrument'],
		checkCoverage: [null, 'report', 'check-coverage'],
		report: [null, 'report'],
		main: [null],
		instrumentOnly: ['instrument']
	};

	const cwd = {
		description: 'working directory used when resolving paths',
		type: 'string',
		get default() {
			return process.cwd();
		},
		nycCommands: nycCommands.all
	};

	const nycrcPath = {
		description: 'specify an explicit path to find nyc configuration',
		nycCommands: nycCommands.all
	};

	const tempDir = {
		description: 'directory to output raw coverage information to',
		type: 'string',
		default: './.nyc_output',
		nycAlias: 't',
		nycHiddenAlias: 'temp-directory',
		nycCommands: [null, 'check-coverage', 'merge', 'report']
	};

	const testExclude = {
		exclude: {
			description: 'a list of specific files and directories that should be excluded from coverage, glob patterns are supported',
			type: 'array',
			items: {
				type: 'string'
			},
			default: defaultExclude,
			nycCommands: nycCommands.testExclude,
			nycAlias: 'x'
		},
		excludeNodeModules: {
			description: 'whether or not to exclude all node_module folders (i.e. **/node_modules/**) by default',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.testExclude
		},
		include: {
			description: 'a list of specific files that should be covered, glob patterns are supported',
			type: 'array',
			items: {
				type: 'string'
			},
			default: [],
			nycCommands: nycCommands.testExclude,
			nycAlias: 'n'
		},
		extension: {
			description: 'a list of extensions that nyc should handle in addition to .js',
			type: 'array',
			items: {
				type: 'string'
			},
			default: defaultExtension,
			nycCommands: nycCommands.testExclude,
			nycAlias: 'e'
		}
	};

	const instrumentVisitor = {
		coverageVariable: {
			description: 'variable to store coverage',
			type: 'string',
			default: '__coverage__',
			nycCommands: nycCommands.instrument
		},
		coverageGlobalScope: {
			description: 'scope to store the coverage variable',
			type: 'string',
			default: 'this',
			nycCommands: nycCommands.instrument
		},
		coverageGlobalScopeFunc: {
			description: 'avoid potentially replaced `Function` when finding global scope',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.instrument
		},
		ignoreClassMethods: {
			description: 'class method names to ignore for coverage',
			type: 'array',
			items: {
				type: 'string'
			},
			default: [],
			nycCommands: nycCommands.instrument
		}
	};

	const instrumentParseGen = {
		autoWrap: {
			description: 'allow `return` statements outside of functions',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.instrument
		},
		esModules: {
			description: 'should files be treated as ES Modules',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.instrument
		},
		parserPlugins: {
			description: 'babel parser plugins to use when parsing the source',
			type: 'array',
			items: {
				type: 'string'
			},
			/* Babel parser plugins are to be enabled when the feature is stage 3 and
			 * implemented in a released version of node.js. */
			default: [
				'asyncGenerators',
				'bigInt',
				'classProperties',
				'classPrivateProperties',
				'classPrivateMethods',
				'dynamicImport',
				'importMeta',
				'numericSeparator',
				'objectRestSpread',
				'optionalCatchBinding',
				'topLevelAwait'
			],
			nycCommands: nycCommands.instrument
		},
		compact: {
			description: 'should the output be compacted?',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.instrument
		},
		preserveComments: {
			description: 'should comments be preserved in the output?',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.instrument
		},
		produceSourceMap: {
			description: 'should source maps be produced?',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.instrument
		}
	};

	const checkCoverage = {
		excludeAfterRemap: {
			description: 'should exclude logic be performed after the source-map remaps filenames?',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.checkCoverage
		},
		branches: {
			description: 'what % of branches must be covered?',
			type: 'number',
			default: 0,
			minimum: 0,
			maximum: 100,
			nycCommands: nycCommands.checkCoverage
		},
		functions: {
			description: 'what % of functions must be covered?',
			type: 'number',
			default: 0,
			minimum: 0,
			maximum: 100,
			nycCommands: nycCommands.checkCoverage
		},
		lines: {
			description: 'what % of lines must be covered?',
			type: 'number',
			default: 90,
			minimum: 0,
			maximum: 100,
			nycCommands: nycCommands.checkCoverage
		},
		statements: {
			description: 'what % of statements must be covered?',
			type: 'number',
			default: 0,
			minimum: 0,
			maximum: 100,
			nycCommands: nycCommands.checkCoverage
		},
		perFile: {
			description: 'check thresholds per file',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.checkCoverage
		}
	};

	const report = {
		checkCoverage: {
			description: 'check whether coverage is within thresholds provided',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.report
		},
		reporter: {
			description: 'coverage reporter(s) to use',
			type: 'array',
			items: {
				type: 'string'
			},
			default: ['text'],
			nycCommands: nycCommands.report,
			nycAlias: 'r'
		},
		reportDir: {
			description: 'directory to output coverage reports in',
			type: 'string',
			default: 'coverage',
			nycCommands: nycCommands.report
		},
		showProcessTree: {
			description: 'display the tree of spawned processes',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.report
		},
		skipEmpty: {
			description: 'don\'t show empty files (no lines of code) in report',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.report
		},
		skipFull: {
			description: 'don\'t show files with 100% statement, branch, and function coverage',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.report
		}
	};

	const nycMain = {
		silent: {
			description: 'don\'t output a report after tests finish running',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.main,
			nycAlias: 's'
		},
		all: {
			description: 'whether or not to instrument all files of the project (not just the ones touched by your test suite)',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.main,
			nycAlias: 'a'
		},
		eager: {
			description: 'instantiate the instrumenter at startup (see https://git.io/vMKZ9)',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.main
		},
		cache: {
			description: 'cache instrumentation results for improved performance',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.main,
			nycAlias: 'c'
		},
		cacheDir: {
			description: 'explicitly set location for instrumentation cache',
			type: 'string',
			nycCommands: nycCommands.main
		},
		babelCache: {
			description: 'cache babel transpilation results for improved performance',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.main
		},
		useSpawnWrap: {
			description: 'use spawn-wrap instead of setting process.env.NODE_OPTIONS',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.main
		},
		hookRequire: {
			description: 'should nyc wrap require?',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.main
		},
		hookRunInContext: {
			description: 'should nyc wrap vm.runInContext?',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.main
		},
		hookRunInThisContext: {
			description: 'should nyc wrap vm.runInThisContext?',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.main
		},
		clean: {
			description: 'should the .nyc_output folder be cleaned before executing tests',
			type: 'boolean',
			default: true,
			nycCommands: nycCommands.main
		}
	};

	const instrumentOnly = {
		inPlace: {
			description: 'should nyc run the instrumentation in place?',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.instrumentOnly
		},
		exitOnError: {
			description: 'should nyc exit when an instrumentation failure occurs?',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.instrumentOnly
		},
		delete: {
			description: 'should the output folder be deleted before instrumenting files?',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.instrumentOnly
		},
		completeCopy: {
			description: 'should nyc copy all files from input to output as well as instrumented files?',
			type: 'boolean',
			default: false,
			nycCommands: nycCommands.instrumentOnly
		}
	};

	const nyc = {
		description: 'nyc configuration options',
		type: 'object',
		properties: {
			cwd,
			nycrcPath,
			tempDir,

			/* Test Exclude */
			...testExclude,

			/* Instrumentation settings */
			...instrumentVisitor,

			/* Instrumentation parser/generator settings */
			...instrumentParseGen,
			sourceMap: {
				description: 'should nyc detect and handle source maps?',
				type: 'boolean',
				default: true,
				nycCommands: nycCommands.instrument
			},
			require: {
				description: 'a list of additional modules that nyc should attempt to require in its subprocess, e.g., @babel/register, @babel/polyfill',
				type: 'array',
				items: {
					type: 'string'
				},
				default: [],
				nycCommands: nycCommands.instrument,
				nycAlias: 'i'
			},
			instrument: {
				description: 'should nyc handle instrumentation?',
				type: 'boolean',
				default: true,
				nycCommands: nycCommands.instrument
			},

			/* Check coverage */
			...checkCoverage,

			/* Report options */
			...report,

			/* Main command options */
			...nycMain,

			/* Instrument command options */
			...instrumentOnly
		}
	};

	const configs = {
		nyc,
		testExclude: {
			description: 'test-exclude options',
			type: 'object',
			properties: {
				cwd,
				...testExclude
			}
		},
		babelPluginIstanbul: {
			description: 'babel-plugin-istanbul options',
			type: 'object',
			properties: {
				cwd,
				...testExclude,
				...instrumentVisitor
			}
		},
		instrumentVisitor: {
			description: 'instrument visitor options',
			type: 'object',
			properties: instrumentVisitor
		},
		instrumenter: {
			description: 'stand-alone instrumenter options',
			type: 'object',
			properties: {
				...instrumentVisitor,
				...instrumentParseGen
			}
		}
	};

	function defaultsReducer(defaults, [name, {default: value}]) {
		/* Modifying arrays in defaults is safe, does not change schema. */
		if (Array.isArray(value)) {
			value = [...value];
		}

		return Object.assign(defaults, {[name]: value});
	}

	schema = {
		...configs,
		defaults: Object.keys(configs).reduce(
			(defaults, id) => {
				Object.defineProperty(defaults, id, {
					enumerable: true,
					get() {
						/* This defers `process.cwd()` until defaults are requested. */
						return Object.entries(configs[id].properties)
							.filter(([, info]) => 'default' in info)
							.reduce(defaultsReducer, {});
					}
				});

				return defaults;
			},
			{}
		)
	};
	return schema;
}

var isOutsideDir = {exports: {}};

var isOutsideDirWin32;
var hasRequiredIsOutsideDirWin32;

function requireIsOutsideDirWin32 () {
	if (hasRequiredIsOutsideDirWin32) return isOutsideDirWin32;
	hasRequiredIsOutsideDirWin32 = 1;

	const path = require$$0$2;
	const { minimatch } = requireCommonjs$4();

	const dot = { dot: true, windowsPathsNoEscape: true };

	isOutsideDirWin32 = function(dir, filename) {
	    return !minimatch(path.resolve(dir, filename), path.join(dir, '**'), dot);
	};
	return isOutsideDirWin32;
}

var isOutsideDirPosix;
var hasRequiredIsOutsideDirPosix;

function requireIsOutsideDirPosix () {
	if (hasRequiredIsOutsideDirPosix) return isOutsideDirPosix;
	hasRequiredIsOutsideDirPosix = 1;

	const path = require$$0$2;

	isOutsideDirPosix = function(dir, filename) {
	    return /^\.\./.test(path.relative(dir, filename));
	};
	return isOutsideDirPosix;
}

var hasRequiredIsOutsideDir;

function requireIsOutsideDir () {
	if (hasRequiredIsOutsideDir) return isOutsideDir.exports;
	hasRequiredIsOutsideDir = 1;

	if (process.platform === 'win32') {
	    isOutsideDir.exports = requireIsOutsideDirWin32();
	} else {
	    isOutsideDir.exports = requireIsOutsideDirPosix();
	}
	return isOutsideDir.exports;
}

var testExclude;
var hasRequiredTestExclude;

function requireTestExclude () {
	if (hasRequiredTestExclude) return testExclude;
	hasRequiredTestExclude = 1;

	const path = require$$0$2;
	const { glob } = requireCommonjs();
	const { minimatch } = requireCommonjs$4();
	const { defaults } = requireSchema();
	const isOutsideDir = requireIsOutsideDir();

	class TestExclude {
	    constructor(opts = {}) {
	        Object.assign(
	            this,
	            {relativePath: true},
	            defaults.testExclude
	        );

	        for (const [name, value] of Object.entries(opts)) {
	            if (value !== undefined) {
	                this[name] = value;
	            }
	        }

	        if (typeof this.include === 'string') {
	            this.include = [this.include];
	        }

	        if (typeof this.exclude === 'string') {
	            this.exclude = [this.exclude];
	        }

	        if (typeof this.extension === 'string') {
	            this.extension = [this.extension];
	        } else if (this.extension.length === 0) {
	            this.extension = false;
	        }

	        if (this.include && this.include.length > 0) {
	            this.include = prepGlobPatterns([].concat(this.include));
	        } else {
	            this.include = false;
	        }

	        if (
	            this.excludeNodeModules &&
	            !this.exclude.includes('**/node_modules/**')
	        ) {
	            this.exclude = this.exclude.concat('**/node_modules/**');
	        }

	        this.exclude = prepGlobPatterns([].concat(this.exclude));

	        this.handleNegation();
	    }

	    /* handle the special case of negative globs
	     * (!**foo/bar); we create a new this.excludeNegated set
	     * of rules, which is applied after excludes and we
	     * move excluded include rules into this.excludes.
	     */
	    handleNegation() {
	        const noNeg = e => e.charAt(0) !== '!';
	        const onlyNeg = e => e.charAt(0) === '!';
	        const stripNeg = e => e.slice(1);

	        if (Array.isArray(this.include)) {
	            const includeNegated = this.include.filter(onlyNeg).map(stripNeg);
	            this.exclude.push(...prepGlobPatterns(includeNegated));
	            this.include = this.include.filter(noNeg);
	        }

	        this.excludeNegated = this.exclude.filter(onlyNeg).map(stripNeg);
	        this.exclude = this.exclude.filter(noNeg);
	        this.excludeNegated = prepGlobPatterns(this.excludeNegated);
	    }

	    shouldInstrument(filename, relFile) {
	        if (
	            this.extension &&
	            !this.extension.some(ext => filename.endsWith(ext))
	        ) {
	            return false;
	        }

	        let pathToCheck = filename;

	        if (this.relativePath) {
	            relFile = relFile || path.relative(this.cwd, filename);

	            // Don't instrument files that are outside of the current working directory.
	            if (isOutsideDir(this.cwd, filename)) {
	                return false;
	            }

	            pathToCheck = relFile.replace(/^\.[\\/]/, ''); // remove leading './' or '.\'.
	        }

	        const dot = { dot: true };
	        const matches = pattern => minimatch(pathToCheck, pattern, dot);
	        return (
	            (!this.include || this.include.some(matches)) &&
	            (!this.exclude.some(matches) || this.excludeNegated.some(matches))
	        );
	    }

	    globSync(cwd = this.cwd) {
	        const globPatterns = getExtensionPattern(this.extension || []);
	        const globOptions = { cwd, nodir: true, dot: true, posix: true };
	        /* If we don't have any excludeNegated then we can optimize glob by telling
	         * it to not iterate into unwanted directory trees (like node_modules). */
	        if (this.excludeNegated.length === 0) {
	            globOptions.ignore = this.exclude;
	        }

	        return glob
	            .sync(globPatterns, globOptions)
	            .filter(file => this.shouldInstrument(path.resolve(cwd, file)));
	    }

	    async glob(cwd = this.cwd) {
	        const globPatterns = getExtensionPattern(this.extension || []);
	        const globOptions = { cwd, nodir: true, dot: true, posix: true };
	        /* If we don't have any excludeNegated then we can optimize glob by telling
	         * it to not iterate into unwanted directory trees (like node_modules). */
	        if (this.excludeNegated.length === 0) {
	            globOptions.ignore = this.exclude;
	        }

	        const list = await glob(globPatterns, globOptions);
	        return list.filter(file => this.shouldInstrument(path.resolve(cwd, file)));
	    }
	}

	function prepGlobPatterns(patterns) {
	    return patterns.reduce((result, pattern) => {
	        // Allow gitignore style of directory exclusion
	        if (!/\/\*\*$/.test(pattern)) {
	            result = result.concat(pattern.replace(/\/$/, '') + '/**');
	        }

	        // Any rules of the form **/foo.js, should also match foo.js.
	        if (/^\*\*\//.test(pattern)) {
	            result = result.concat(pattern.replace(/^\*\*\//, ''));
	        }

	        return result.concat(pattern);
	    }, []);
	}

	function getExtensionPattern(extension) {
	    switch (extension.length) {
	        case 0:
	            return '**';
	        case 1:
	            return `**/*${extension[0]}`;
	        default:
	            return `**/*{${extension.join()}}`;
	    }
	}

	testExclude = TestExclude;
	return testExclude;
}

var istanbulLibCoverage = {exports: {}};

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var percent;
var hasRequiredPercent;

function requirePercent () {
	if (hasRequiredPercent) return percent;
	hasRequiredPercent = 1;

	percent = function percent(covered, total) {
	    let tmp;
	    if (total > 0) {
	        tmp = (1000 * 100 * covered) / total;
	        return Math.floor(tmp / 10) / 100;
	    } else {
	        return 100.0;
	    }
	};
	return percent;
}

var dataProperties;
var hasRequiredDataProperties;

function requireDataProperties () {
	if (hasRequiredDataProperties) return dataProperties;
	hasRequiredDataProperties = 1;

	dataProperties = function dataProperties(klass, properties) {
	    properties.forEach(p => {
	        Object.defineProperty(klass.prototype, p, {
	            enumerable: true,
	            get() {
	                return this.data[p];
	            }
	        });
	    });
	};
	return dataProperties;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var coverageSummary;
var hasRequiredCoverageSummary;

function requireCoverageSummary () {
	if (hasRequiredCoverageSummary) return coverageSummary;
	hasRequiredCoverageSummary = 1;

	const percent = requirePercent();
	const dataProperties = requireDataProperties();

	function blankSummary() {
	    const empty = () => ({
	        total: 0,
	        covered: 0,
	        skipped: 0,
	        pct: 'Unknown'
	    });

	    return {
	        lines: empty(),
	        statements: empty(),
	        functions: empty(),
	        branches: empty(),
	        branchesTrue: empty()
	    };
	}

	// asserts that a data object "looks like" a summary coverage object
	function assertValidSummary(obj) {
	    const valid =
	        obj && obj.lines && obj.statements && obj.functions && obj.branches;
	    if (!valid) {
	        throw new Error(
	            'Invalid summary coverage object, missing keys, found:' +
	                Object.keys(obj).join(',')
	        );
	    }
	}

	/**
	 * CoverageSummary provides a summary of code coverage . It exposes 4 properties,
	 * `lines`, `statements`, `branches`, and `functions`. Each of these properties
	 * is an object that has 4 keys `total`, `covered`, `skipped` and `pct`.
	 * `pct` is a percentage number (0-100).
	 */
	class CoverageSummary {
	    /**
	     * @constructor
	     * @param {Object|CoverageSummary} [obj=undefined] an optional data object or
	     * another coverage summary to initialize this object with.
	     */
	    constructor(obj) {
	        if (!obj) {
	            this.data = blankSummary();
	        } else if (obj instanceof CoverageSummary) {
	            this.data = obj.data;
	        } else {
	            this.data = obj;
	        }
	        assertValidSummary(this.data);
	    }

	    /**
	     * merges a second summary coverage object into this one
	     * @param {CoverageSummary} obj - another coverage summary object
	     */
	    merge(obj) {
	        const keys = [
	            'lines',
	            'statements',
	            'branches',
	            'functions',
	            'branchesTrue'
	        ];
	        keys.forEach(key => {
	            if (obj[key]) {
	                this[key].total += obj[key].total;
	                this[key].covered += obj[key].covered;
	                this[key].skipped += obj[key].skipped;
	                this[key].pct = percent(this[key].covered, this[key].total);
	            }
	        });

	        return this;
	    }

	    /**
	     * returns a POJO that is JSON serializable. May be used to get the raw
	     * summary object.
	     */
	    toJSON() {
	        return this.data;
	    }

	    /**
	     * return true if summary has no lines of code
	     */
	    isEmpty() {
	        return this.lines.total === 0;
	    }
	}

	dataProperties(CoverageSummary, [
	    'lines',
	    'statements',
	    'functions',
	    'branches',
	    'branchesTrue'
	]);

	coverageSummary = {
	    CoverageSummary
	};
	return coverageSummary;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var fileCoverage;
var hasRequiredFileCoverage;

function requireFileCoverage () {
	if (hasRequiredFileCoverage) return fileCoverage;
	hasRequiredFileCoverage = 1;

	const percent = requirePercent();
	const dataProperties = requireDataProperties();
	const { CoverageSummary } = requireCoverageSummary();

	// returns a data object that represents empty coverage
	function emptyCoverage(filePath, reportLogic) {
	    const cov = {
	        path: filePath,
	        statementMap: {},
	        fnMap: {},
	        branchMap: {},
	        s: {},
	        f: {},
	        b: {}
	    };
	    if (reportLogic) cov.bT = {};
	    return cov;
	}

	// asserts that a data object "looks like" a coverage object
	function assertValidObject(obj) {
	    const valid =
	        obj &&
	        obj.path &&
	        obj.statementMap &&
	        obj.fnMap &&
	        obj.branchMap &&
	        obj.s &&
	        obj.f &&
	        obj.b;
	    if (!valid) {
	        throw new Error(
	            'Invalid file coverage object, missing keys, found:' +
	                Object.keys(obj).join(',')
	        );
	    }
	}

	const keyFromLoc = ({ start, end }) =>
	    `${start.line}|${start.column}|${end.line}|${end.column}`;

	const isObj = o => !!o && typeof o === 'object';
	const isLineCol = o =>
	    isObj(o) && typeof o.line === 'number' && typeof o.column === 'number';
	const isLoc = o => isObj(o) && isLineCol(o.start) && isLineCol(o.end);
	const getLoc = o => (isLoc(o) ? o : isLoc(o.loc) ? o.loc : null);

	// When merging, we can have a case where two ranges cover
	// the same block of code with `hits=1`, and each carve out a
	// different range with `hits=0` to indicate it's uncovered.
	// Find the nearest container so that we can properly indicate
	// that both sections are hit.
	// Returns null if no containing item is found.
	const findNearestContainer = (item, map) => {
	    const itemLoc = getLoc(item);
	    if (!itemLoc) return null;
	    // the B item is not an identified range in the A set, BUT
	    // it may be contained by an identified A range. If so, then
	    // any hit of that containing A range counts as a hit of this
	    // B range as well. We have to find the *narrowest* containing
	    // range to be accurate, since ranges can be hit and un-hit
	    // in a nested fashion.
	    let nearestContainingItem = null;
	    let containerDistance = null;
	    let containerKey = null;
	    for (const [i, mapItem] of Object.entries(map)) {
	        const mapLoc = getLoc(mapItem);
	        if (!mapLoc) continue;
	        // contained if all of line distances are > 0
	        // or line distance is 0 and col dist is >= 0
	        const distance = [
	            itemLoc.start.line - mapLoc.start.line,
	            itemLoc.start.column - mapLoc.start.column,
	            mapLoc.end.line - itemLoc.end.line,
	            mapLoc.end.column - itemLoc.end.column
	        ];
	        if (
	            distance[0] < 0 ||
	            distance[2] < 0 ||
	            (distance[0] === 0 && distance[1] < 0) ||
	            (distance[2] === 0 && distance[3] < 0)
	        ) {
	            continue;
	        }
	        if (nearestContainingItem === null) {
	            containerDistance = distance;
	            nearestContainingItem = mapItem;
	            containerKey = i;
	            continue;
	        }
	        // closer line more relevant than closer column
	        const closerBefore =
	            distance[0] < containerDistance[0] ||
	            (distance[0] === 0 && distance[1] < containerDistance[1]);
	        const closerAfter =
	            distance[2] < containerDistance[2] ||
	            (distance[2] === 0 && distance[3] < containerDistance[3]);
	        if (closerBefore || closerAfter) {
	            // closer
	            containerDistance = distance;
	            nearestContainingItem = mapItem;
	            containerKey = i;
	        }
	    }
	    return containerKey;
	};

	// either add two numbers, or all matching entries in a number[]
	const addHits = (aHits, bHits) => {
	    if (typeof aHits === 'number' && typeof bHits === 'number') {
	        return aHits + bHits;
	    } else if (Array.isArray(aHits) && Array.isArray(bHits)) {
	        return aHits.map((a, i) => (a || 0) + (bHits[i] || 0));
	    }
	    return null;
	};

	const addNearestContainerHits = (item, itemHits, map, mapHits) => {
	    const container = findNearestContainer(item, map);
	    if (container) {
	        return addHits(itemHits, mapHits[container]);
	    } else {
	        return itemHits;
	    }
	};

	const mergeProp = (aHits, aMap, bHits, bMap, itemKey = keyFromLoc) => {
	    const aItems = {};
	    for (const [key, itemHits] of Object.entries(aHits)) {
	        const item = aMap[key];
	        aItems[itemKey(item)] = [itemHits, item];
	    }
	    const bItems = {};
	    for (const [key, itemHits] of Object.entries(bHits)) {
	        const item = bMap[key];
	        bItems[itemKey(item)] = [itemHits, item];
	    }
	    const mergedItems = {};
	    for (const [key, aValue] of Object.entries(aItems)) {
	        let aItemHits = aValue[0];
	        const aItem = aValue[1];
	        const bValue = bItems[key];
	        if (!bValue) {
	            // not an identified range in b, but might be contained by one
	            aItemHits = addNearestContainerHits(aItem, aItemHits, bMap, bHits);
	        } else {
	            // is an identified range in b, so add the hits together
	            aItemHits = addHits(aItemHits, bValue[0]);
	        }
	        mergedItems[key] = [aItemHits, aItem];
	    }
	    // now find the items in b that are not in a. already added matches.
	    for (const [key, bValue] of Object.entries(bItems)) {
	        let bItemHits = bValue[0];
	        const bItem = bValue[1];
	        if (mergedItems[key]) continue;
	        // not an identified range in b, but might be contained by one
	        bItemHits = addNearestContainerHits(bItem, bItemHits, aMap, aHits);
	        mergedItems[key] = [bItemHits, bItem];
	    }

	    const hits = {};
	    const map = {};

	    Object.values(mergedItems).forEach(([itemHits, item], i) => {
	        hits[i] = itemHits;
	        map[i] = item;
	    });

	    return [hits, map];
	};

	/**
	 * provides a read-only view of coverage for a single file.
	 * The deep structure of this object is documented elsewhere. It has the following
	 * properties:
	 *
	 * * `path` - the file path for which coverage is being tracked
	 * * `statementMap` - map of statement locations keyed by statement index
	 * * `fnMap` - map of function metadata keyed by function index
	 * * `branchMap` - map of branch metadata keyed by branch index
	 * * `s` - hit counts for statements
	 * * `f` - hit count for functions
	 * * `b` - hit count for branches
	 */
	class FileCoverage {
	    /**
	     * @constructor
	     * @param {Object|FileCoverage|String} pathOrObj is a string that initializes
	     * and empty coverage object with the specified file path or a data object that
	     * has all the required properties for a file coverage object.
	     */
	    constructor(pathOrObj, reportLogic = false) {
	        if (!pathOrObj) {
	            throw new Error(
	                'Coverage must be initialized with a path or an object'
	            );
	        }
	        if (typeof pathOrObj === 'string') {
	            this.data = emptyCoverage(pathOrObj, reportLogic);
	        } else if (pathOrObj instanceof FileCoverage) {
	            this.data = pathOrObj.data;
	        } else if (typeof pathOrObj === 'object') {
	            this.data = pathOrObj;
	        } else {
	            throw new Error('Invalid argument to coverage constructor');
	        }
	        assertValidObject(this.data);
	    }

	    /**
	     * returns computed line coverage from statement coverage.
	     * This is a map of hits keyed by line number in the source.
	     */
	    getLineCoverage() {
	        const statementMap = this.data.statementMap;
	        const statements = this.data.s;
	        const lineMap = Object.create(null);

	        Object.entries(statements).forEach(([st, count]) => {
	            /* istanbul ignore if: is this even possible? */
	            if (!statementMap[st]) {
	                return;
	            }
	            const { line } = statementMap[st].start;
	            const prevVal = lineMap[line];
	            if (prevVal === undefined || prevVal < count) {
	                lineMap[line] = count;
	            }
	        });
	        return lineMap;
	    }

	    /**
	     * returns an array of uncovered line numbers.
	     * @returns {Array} an array of line numbers for which no hits have been
	     *  collected.
	     */
	    getUncoveredLines() {
	        const lc = this.getLineCoverage();
	        const ret = [];
	        Object.entries(lc).forEach(([l, hits]) => {
	            if (hits === 0) {
	                ret.push(l);
	            }
	        });
	        return ret;
	    }

	    /**
	     * returns a map of branch coverage by source line number.
	     * @returns {Object} an object keyed by line number. Each object
	     * has a `covered`, `total` and `coverage` (percentage) property.
	     */
	    getBranchCoverageByLine() {
	        const branchMap = this.branchMap;
	        const branches = this.b;
	        const ret = {};
	        Object.entries(branchMap).forEach(([k, map]) => {
	            const line = map.line || map.loc.start.line;
	            const branchData = branches[k];
	            ret[line] = ret[line] || [];
	            ret[line].push(...branchData);
	        });
	        Object.entries(ret).forEach(([k, dataArray]) => {
	            const covered = dataArray.filter(item => item > 0);
	            const coverage = (covered.length / dataArray.length) * 100;
	            ret[k] = {
	                covered: covered.length,
	                total: dataArray.length,
	                coverage
	            };
	        });
	        return ret;
	    }

	    /**
	     * return a JSON-serializable POJO for this file coverage object
	     */
	    toJSON() {
	        return this.data;
	    }

	    /**
	     * merges a second coverage object into this one, updating hit counts
	     * @param {FileCoverage} other - the coverage object to be merged into this one.
	     *  Note that the other object should have the same structure as this one (same file).
	     */
	    merge(other) {
	        if (other.all === true) {
	            return;
	        }

	        if (this.all === true) {
	            this.data = other.data;
	            return;
	        }

	        let [hits, map] = mergeProp(
	            this.s,
	            this.statementMap,
	            other.s,
	            other.statementMap
	        );
	        this.data.s = hits;
	        this.data.statementMap = map;

	        const keyFromLocProp = x => keyFromLoc(x.loc);
	        const keyFromLocationsProp = x => keyFromLoc(x.locations[0]);

	        [hits, map] = mergeProp(
	            this.f,
	            this.fnMap,
	            other.f,
	            other.fnMap,
	            keyFromLocProp
	        );
	        this.data.f = hits;
	        this.data.fnMap = map;

	        [hits, map] = mergeProp(
	            this.b,
	            this.branchMap,
	            other.b,
	            other.branchMap,
	            keyFromLocationsProp
	        );
	        this.data.b = hits;
	        this.data.branchMap = map;

	        // Tracking additional information about branch truthiness
	        // can be optionally enabled:
	        if (this.bT && other.bT) {
	            [hits, map] = mergeProp(
	                this.bT,
	                this.branchMap,
	                other.bT,
	                other.branchMap,
	                keyFromLocationsProp
	            );
	            this.data.bT = hits;
	        }
	    }

	    computeSimpleTotals(property) {
	        let stats = this[property];

	        if (typeof stats === 'function') {
	            stats = stats.call(this);
	        }

	        const ret = {
	            total: Object.keys(stats).length,
	            covered: Object.values(stats).filter(v => !!v).length,
	            skipped: 0
	        };
	        ret.pct = percent(ret.covered, ret.total);
	        return ret;
	    }

	    computeBranchTotals(property) {
	        const stats = this[property];
	        const ret = { total: 0, covered: 0, skipped: 0 };

	        Object.values(stats).forEach(branches => {
	            ret.covered += branches.filter(hits => hits > 0).length;
	            ret.total += branches.length;
	        });
	        ret.pct = percent(ret.covered, ret.total);
	        return ret;
	    }

	    /**
	     * resets hit counts for all statements, functions and branches
	     * in this coverage object resulting in zero coverage.
	     */
	    resetHits() {
	        const statements = this.s;
	        const functions = this.f;
	        const branches = this.b;
	        const branchesTrue = this.bT;
	        Object.keys(statements).forEach(s => {
	            statements[s] = 0;
	        });
	        Object.keys(functions).forEach(f => {
	            functions[f] = 0;
	        });
	        Object.keys(branches).forEach(b => {
	            branches[b].fill(0);
	        });
	        // Tracking additional information about branch truthiness
	        // can be optionally enabled:
	        if (branchesTrue) {
	            Object.keys(branchesTrue).forEach(bT => {
	                branchesTrue[bT].fill(0);
	            });
	        }
	    }

	    /**
	     * returns a CoverageSummary for this file coverage object
	     * @returns {CoverageSummary}
	     */
	    toSummary() {
	        const ret = {};
	        ret.lines = this.computeSimpleTotals('getLineCoverage');
	        ret.functions = this.computeSimpleTotals('f', 'fnMap');
	        ret.statements = this.computeSimpleTotals('s', 'statementMap');
	        ret.branches = this.computeBranchTotals('b');
	        // Tracking additional information about branch truthiness
	        // can be optionally enabled:
	        if (this.bT) {
	            ret.branchesTrue = this.computeBranchTotals('bT');
	        }
	        return new CoverageSummary(ret);
	    }
	}

	// expose coverage data attributes
	dataProperties(FileCoverage, [
	    'path',
	    'statementMap',
	    'fnMap',
	    'branchMap',
	    's',
	    'f',
	    'b',
	    'bT',
	    'all'
	]);

	fileCoverage = {
	    FileCoverage,
	    // exported for testing
	    findNearestContainer,
	    addHits,
	    addNearestContainerHits
	};
	return fileCoverage;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var coverageMap;
var hasRequiredCoverageMap;

function requireCoverageMap () {
	if (hasRequiredCoverageMap) return coverageMap;
	hasRequiredCoverageMap = 1;

	const { FileCoverage } = requireFileCoverage();
	const { CoverageSummary } = requireCoverageSummary();

	function maybeConstruct(obj, klass) {
	    if (obj instanceof klass) {
	        return obj;
	    }

	    return new klass(obj);
	}

	function loadMap(source) {
	    const data = Object.create(null);
	    if (!source) {
	        return data;
	    }

	    Object.entries(source).forEach(([k, cov]) => {
	        data[k] = maybeConstruct(cov, FileCoverage);
	    });

	    return data;
	}

	/** CoverageMap is a map of `FileCoverage` objects keyed by file paths. */
	class CoverageMap {
	    /**
	     * @constructor
	     * @param {Object} [obj=undefined] obj A coverage map from which to initialize this
	     * map's contents. This can be the raw global coverage object.
	     */
	    constructor(obj) {
	        if (obj instanceof CoverageMap) {
	            this.data = obj.data;
	        } else {
	            this.data = loadMap(obj);
	        }
	    }

	    /**
	     * merges a second coverage map into this one
	     * @param {CoverageMap} obj - a CoverageMap or its raw data. Coverage is merged
	     *  correctly for the same files and additional file coverage keys are created
	     *  as needed.
	     */
	    merge(obj) {
	        const other = maybeConstruct(obj, CoverageMap);
	        Object.values(other.data).forEach(fc => {
	            this.addFileCoverage(fc);
	        });
	    }

	    /**
	     * filter the coveragemap based on the callback provided
	     * @param {Function (filename)} callback - Returns true if the path
	     *  should be included in the coveragemap. False if it should be
	     *  removed.
	     */
	    filter(callback) {
	        Object.keys(this.data).forEach(k => {
	            if (!callback(k)) {
	                delete this.data[k];
	            }
	        });
	    }

	    /**
	     * returns a JSON-serializable POJO for this coverage map
	     * @returns {Object}
	     */
	    toJSON() {
	        return this.data;
	    }

	    /**
	     * returns an array for file paths for which this map has coverage
	     * @returns {Array{string}} - array of files
	     */
	    files() {
	        return Object.keys(this.data);
	    }

	    /**
	     * returns the file coverage for the specified file.
	     * @param {String} file
	     * @returns {FileCoverage}
	     */
	    fileCoverageFor(file) {
	        const fc = this.data[file];
	        if (!fc) {
	            throw new Error(`No file coverage available for: ${file}`);
	        }
	        return fc;
	    }

	    /**
	     * adds a file coverage object to this map. If the path for the object,
	     * already exists in the map, it is merged with the existing coverage
	     * otherwise a new key is added to the map.
	     * @param {FileCoverage} fc the file coverage to add
	     */
	    addFileCoverage(fc) {
	        const cov = new FileCoverage(fc);
	        const { path } = cov;
	        if (this.data[path]) {
	            this.data[path].merge(cov);
	        } else {
	            this.data[path] = cov;
	        }
	    }

	    /**
	     * returns the coverage summary for all the file coverage objects in this map.
	     * @returns {CoverageSummary}
	     */
	    getCoverageSummary() {
	        const ret = new CoverageSummary();
	        Object.values(this.data).forEach(fc => {
	            ret.merge(fc.toSummary());
	        });

	        return ret;
	    }
	}

	coverageMap = {
	    CoverageMap
	};
	return coverageMap;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var hasRequiredIstanbulLibCoverage;

function requireIstanbulLibCoverage () {
	if (hasRequiredIstanbulLibCoverage) return istanbulLibCoverage.exports;
	hasRequiredIstanbulLibCoverage = 1;

	/**
	 * istanbul-lib-coverage exports an API that allows you to create and manipulate
	 * file coverage, coverage maps (a set of file coverage objects) and summary
	 * coverage objects. File coverage for the same file can be merged as can
	 * entire coverage maps.
	 *
	 * @module Exports
	 */
	const { FileCoverage } = requireFileCoverage();
	const { CoverageMap } = requireCoverageMap();
	const { CoverageSummary } = requireCoverageSummary();

	istanbulLibCoverage.exports = {
	    /**
	     * creates a coverage summary object
	     * @param {Object} obj an argument with the same semantics
	     *  as the one passed to the `CoverageSummary` constructor
	     * @returns {CoverageSummary}
	     */
	    createCoverageSummary(obj) {
	        if (obj && obj instanceof CoverageSummary) {
	            return obj;
	        }
	        return new CoverageSummary(obj);
	    },
	    /**
	     * creates a CoverageMap object
	     * @param {Object} obj optional - an argument with the same semantics
	     *  as the one passed to the CoverageMap constructor.
	     * @returns {CoverageMap}
	     */
	    createCoverageMap(obj) {
	        if (obj && obj instanceof CoverageMap) {
	            return obj;
	        }
	        return new CoverageMap(obj);
	    },
	    /**
	     * creates a FileCoverage object
	     * @param {Object} obj optional - an argument with the same semantics
	     *  as the one passed to the FileCoverage constructor.
	     * @returns {FileCoverage}
	     */
	    createFileCoverage(obj) {
	        if (obj && obj instanceof FileCoverage) {
	            return obj;
	        }
	        return new FileCoverage(obj);
	    }
	};

	/** classes exported for reuse */
	istanbulLibCoverage.exports.classes = {
	    /**
	     * the file coverage constructor
	     */
	    FileCoverage
	};
	return istanbulLibCoverage.exports;
}

var makeDir = {exports: {}};

var debug_1;
var hasRequiredDebug;

function requireDebug () {
	if (hasRequiredDebug) return debug_1;
	hasRequiredDebug = 1;

	const debug = (
	  typeof process === 'object' &&
	  process.env &&
	  process.env.NODE_DEBUG &&
	  /\bsemver\b/i.test(process.env.NODE_DEBUG)
	) ? (...args) => console.error('SEMVER', ...args)
	  : () => {};

	debug_1 = debug;
	return debug_1;
}

var constants;
var hasRequiredConstants;

function requireConstants () {
	if (hasRequiredConstants) return constants;
	hasRequiredConstants = 1;

	// Note: this is the semver.org version of the spec that it implements
	// Not necessarily the package version of this code.
	const SEMVER_SPEC_VERSION = '2.0.0';

	const MAX_LENGTH = 256;
	const MAX_SAFE_INTEGER = Number.MAX_SAFE_INTEGER ||
	/* istanbul ignore next */ 9007199254740991;

	// Max safe segment length for coercion.
	const MAX_SAFE_COMPONENT_LENGTH = 16;

	// Max safe length for a build identifier. The max length minus 6 characters for
	// the shortest version with a build 0.0.0+BUILD.
	const MAX_SAFE_BUILD_LENGTH = MAX_LENGTH - 6;

	const RELEASE_TYPES = [
	  'major',
	  'premajor',
	  'minor',
	  'preminor',
	  'patch',
	  'prepatch',
	  'prerelease',
	];

	constants = {
	  MAX_LENGTH,
	  MAX_SAFE_COMPONENT_LENGTH,
	  MAX_SAFE_BUILD_LENGTH,
	  MAX_SAFE_INTEGER,
	  RELEASE_TYPES,
	  SEMVER_SPEC_VERSION,
	  FLAG_INCLUDE_PRERELEASE: 0b001,
	  FLAG_LOOSE: 0b010,
	};
	return constants;
}

var re = {exports: {}};

var hasRequiredRe;

function requireRe () {
	if (hasRequiredRe) return re.exports;
	hasRequiredRe = 1;
	(function (module, exports) {

		const {
		  MAX_SAFE_COMPONENT_LENGTH,
		  MAX_SAFE_BUILD_LENGTH,
		  MAX_LENGTH,
		} = requireConstants();
		const debug = requireDebug();
		exports = module.exports = {};

		// The actual regexps go on exports.re
		const re = exports.re = [];
		const safeRe = exports.safeRe = [];
		const src = exports.src = [];
		const safeSrc = exports.safeSrc = [];
		const t = exports.t = {};
		let R = 0;

		const LETTERDASHNUMBER = '[a-zA-Z0-9-]';

		// Replace some greedy regex tokens to prevent regex dos issues. These regex are
		// used internally via the safeRe object since all inputs in this library get
		// normalized first to trim and collapse all extra whitespace. The original
		// regexes are exported for userland consumption and lower level usage. A
		// future breaking change could export the safer regex only with a note that
		// all input should have extra whitespace removed.
		const safeRegexReplacements = [
		  ['\\s', 1],
		  ['\\d', MAX_LENGTH],
		  [LETTERDASHNUMBER, MAX_SAFE_BUILD_LENGTH],
		];

		const makeSafeRegex = (value) => {
		  for (const [token, max] of safeRegexReplacements) {
		    value = value
		      .split(`${token}*`).join(`${token}{0,${max}}`)
		      .split(`${token}+`).join(`${token}{1,${max}}`);
		  }
		  return value
		};

		const createToken = (name, value, isGlobal) => {
		  const safe = makeSafeRegex(value);
		  const index = R++;
		  debug(name, index, value);
		  t[name] = index;
		  src[index] = value;
		  safeSrc[index] = safe;
		  re[index] = new RegExp(value, isGlobal ? 'g' : undefined);
		  safeRe[index] = new RegExp(safe, isGlobal ? 'g' : undefined);
		};

		// The following Regular Expressions can be used for tokenizing,
		// validating, and parsing SemVer version strings.

		// ## Numeric Identifier
		// A single `0`, or a non-zero digit followed by zero or more digits.

		createToken('NUMERICIDENTIFIER', '0|[1-9]\\d*');
		createToken('NUMERICIDENTIFIERLOOSE', '\\d+');

		// ## Non-numeric Identifier
		// Zero or more digits, followed by a letter or hyphen, and then zero or
		// more letters, digits, or hyphens.

		createToken('NONNUMERICIDENTIFIER', `\\d*[a-zA-Z-]${LETTERDASHNUMBER}*`);

		// ## Main Version
		// Three dot-separated numeric identifiers.

		createToken('MAINVERSION', `(${src[t.NUMERICIDENTIFIER]})\\.` +
		                   `(${src[t.NUMERICIDENTIFIER]})\\.` +
		                   `(${src[t.NUMERICIDENTIFIER]})`);

		createToken('MAINVERSIONLOOSE', `(${src[t.NUMERICIDENTIFIERLOOSE]})\\.` +
		                        `(${src[t.NUMERICIDENTIFIERLOOSE]})\\.` +
		                        `(${src[t.NUMERICIDENTIFIERLOOSE]})`);

		// ## Pre-release Version Identifier
		// A numeric identifier, or a non-numeric identifier.
		// Non-numberic identifiers include numberic identifiers but can be longer.
		// Therefore non-numberic identifiers must go first.

		createToken('PRERELEASEIDENTIFIER', `(?:${src[t.NONNUMERICIDENTIFIER]
		}|${src[t.NUMERICIDENTIFIER]})`);

		createToken('PRERELEASEIDENTIFIERLOOSE', `(?:${src[t.NONNUMERICIDENTIFIER]
		}|${src[t.NUMERICIDENTIFIERLOOSE]})`);

		// ## Pre-release Version
		// Hyphen, followed by one or more dot-separated pre-release version
		// identifiers.

		createToken('PRERELEASE', `(?:-(${src[t.PRERELEASEIDENTIFIER]
		}(?:\\.${src[t.PRERELEASEIDENTIFIER]})*))`);

		createToken('PRERELEASELOOSE', `(?:-?(${src[t.PRERELEASEIDENTIFIERLOOSE]
		}(?:\\.${src[t.PRERELEASEIDENTIFIERLOOSE]})*))`);

		// ## Build Metadata Identifier
		// Any combination of digits, letters, or hyphens.

		createToken('BUILDIDENTIFIER', `${LETTERDASHNUMBER}+`);

		// ## Build Metadata
		// Plus sign, followed by one or more period-separated build metadata
		// identifiers.

		createToken('BUILD', `(?:\\+(${src[t.BUILDIDENTIFIER]
		}(?:\\.${src[t.BUILDIDENTIFIER]})*))`);

		// ## Full Version String
		// A main version, followed optionally by a pre-release version and
		// build metadata.

		// Note that the only major, minor, patch, and pre-release sections of
		// the version string are capturing groups.  The build metadata is not a
		// capturing group, because it should not ever be used in version
		// comparison.

		createToken('FULLPLAIN', `v?${src[t.MAINVERSION]
		}${src[t.PRERELEASE]}?${
		  src[t.BUILD]}?`);

		createToken('FULL', `^${src[t.FULLPLAIN]}$`);

		// like full, but allows v1.2.3 and =1.2.3, which people do sometimes.
		// also, 1.0.0alpha1 (prerelease without the hyphen) which is pretty
		// common in the npm registry.
		createToken('LOOSEPLAIN', `[v=\\s]*${src[t.MAINVERSIONLOOSE]
		}${src[t.PRERELEASELOOSE]}?${
		  src[t.BUILD]}?`);

		createToken('LOOSE', `^${src[t.LOOSEPLAIN]}$`);

		createToken('GTLT', '((?:<|>)?=?)');

		// Something like "2.*" or "1.2.x".
		// Note that "x.x" is a valid xRange identifer, meaning "any version"
		// Only the first item is strictly required.
		createToken('XRANGEIDENTIFIERLOOSE', `${src[t.NUMERICIDENTIFIERLOOSE]}|x|X|\\*`);
		createToken('XRANGEIDENTIFIER', `${src[t.NUMERICIDENTIFIER]}|x|X|\\*`);

		createToken('XRANGEPLAIN', `[v=\\s]*(${src[t.XRANGEIDENTIFIER]})` +
		                   `(?:\\.(${src[t.XRANGEIDENTIFIER]})` +
		                   `(?:\\.(${src[t.XRANGEIDENTIFIER]})` +
		                   `(?:${src[t.PRERELEASE]})?${
		                     src[t.BUILD]}?` +
		                   `)?)?`);

		createToken('XRANGEPLAINLOOSE', `[v=\\s]*(${src[t.XRANGEIDENTIFIERLOOSE]})` +
		                        `(?:\\.(${src[t.XRANGEIDENTIFIERLOOSE]})` +
		                        `(?:\\.(${src[t.XRANGEIDENTIFIERLOOSE]})` +
		                        `(?:${src[t.PRERELEASELOOSE]})?${
		                          src[t.BUILD]}?` +
		                        `)?)?`);

		createToken('XRANGE', `^${src[t.GTLT]}\\s*${src[t.XRANGEPLAIN]}$`);
		createToken('XRANGELOOSE', `^${src[t.GTLT]}\\s*${src[t.XRANGEPLAINLOOSE]}$`);

		// Coercion.
		// Extract anything that could conceivably be a part of a valid semver
		createToken('COERCEPLAIN', `${'(^|[^\\d])' +
		              '(\\d{1,'}${MAX_SAFE_COMPONENT_LENGTH}})` +
		              `(?:\\.(\\d{1,${MAX_SAFE_COMPONENT_LENGTH}}))?` +
		              `(?:\\.(\\d{1,${MAX_SAFE_COMPONENT_LENGTH}}))?`);
		createToken('COERCE', `${src[t.COERCEPLAIN]}(?:$|[^\\d])`);
		createToken('COERCEFULL', src[t.COERCEPLAIN] +
		              `(?:${src[t.PRERELEASE]})?` +
		              `(?:${src[t.BUILD]})?` +
		              `(?:$|[^\\d])`);
		createToken('COERCERTL', src[t.COERCE], true);
		createToken('COERCERTLFULL', src[t.COERCEFULL], true);

		// Tilde ranges.
		// Meaning is "reasonably at or greater than"
		createToken('LONETILDE', '(?:~>?)');

		createToken('TILDETRIM', `(\\s*)${src[t.LONETILDE]}\\s+`, true);
		exports.tildeTrimReplace = '$1~';

		createToken('TILDE', `^${src[t.LONETILDE]}${src[t.XRANGEPLAIN]}$`);
		createToken('TILDELOOSE', `^${src[t.LONETILDE]}${src[t.XRANGEPLAINLOOSE]}$`);

		// Caret ranges.
		// Meaning is "at least and backwards compatible with"
		createToken('LONECARET', '(?:\\^)');

		createToken('CARETTRIM', `(\\s*)${src[t.LONECARET]}\\s+`, true);
		exports.caretTrimReplace = '$1^';

		createToken('CARET', `^${src[t.LONECARET]}${src[t.XRANGEPLAIN]}$`);
		createToken('CARETLOOSE', `^${src[t.LONECARET]}${src[t.XRANGEPLAINLOOSE]}$`);

		// A simple gt/lt/eq thing, or just "" to indicate "any version"
		createToken('COMPARATORLOOSE', `^${src[t.GTLT]}\\s*(${src[t.LOOSEPLAIN]})$|^$`);
		createToken('COMPARATOR', `^${src[t.GTLT]}\\s*(${src[t.FULLPLAIN]})$|^$`);

		// An expression to strip any whitespace between the gtlt and the thing
		// it modifies, so that `> 1.2.3` ==> `>1.2.3`
		createToken('COMPARATORTRIM', `(\\s*)${src[t.GTLT]
		}\\s*(${src[t.LOOSEPLAIN]}|${src[t.XRANGEPLAIN]})`, true);
		exports.comparatorTrimReplace = '$1$2$3';

		// Something like `1.2.3 - 1.2.4`
		// Note that these all use the loose form, because they'll be
		// checked against either the strict or loose comparator form
		// later.
		createToken('HYPHENRANGE', `^\\s*(${src[t.XRANGEPLAIN]})` +
		                   `\\s+-\\s+` +
		                   `(${src[t.XRANGEPLAIN]})` +
		                   `\\s*$`);

		createToken('HYPHENRANGELOOSE', `^\\s*(${src[t.XRANGEPLAINLOOSE]})` +
		                        `\\s+-\\s+` +
		                        `(${src[t.XRANGEPLAINLOOSE]})` +
		                        `\\s*$`);

		// Star ranges basically just allow anything at all.
		createToken('STAR', '(<|>)?=?\\s*\\*');
		// >=0.0.0 is like a star
		createToken('GTE0', '^\\s*>=\\s*0\\.0\\.0\\s*$');
		createToken('GTE0PRE', '^\\s*>=\\s*0\\.0\\.0-0\\s*$'); 
	} (re, re.exports));
	return re.exports;
}

var parseOptions_1;
var hasRequiredParseOptions;

function requireParseOptions () {
	if (hasRequiredParseOptions) return parseOptions_1;
	hasRequiredParseOptions = 1;

	// parse out just the options we care about
	const looseOption = Object.freeze({ loose: true });
	const emptyOpts = Object.freeze({ });
	const parseOptions = options => {
	  if (!options) {
	    return emptyOpts
	  }

	  if (typeof options !== 'object') {
	    return looseOption
	  }

	  return options
	};
	parseOptions_1 = parseOptions;
	return parseOptions_1;
}

var identifiers;
var hasRequiredIdentifiers;

function requireIdentifiers () {
	if (hasRequiredIdentifiers) return identifiers;
	hasRequiredIdentifiers = 1;

	const numeric = /^[0-9]+$/;
	const compareIdentifiers = (a, b) => {
	  if (typeof a === 'number' && typeof b === 'number') {
	    return a === b ? 0 : a < b ? -1 : 1
	  }

	  const anum = numeric.test(a);
	  const bnum = numeric.test(b);

	  if (anum && bnum) {
	    a = +a;
	    b = +b;
	  }

	  return a === b ? 0
	    : (anum && !bnum) ? -1
	    : (bnum && !anum) ? 1
	    : a < b ? -1
	    : 1
	};

	const rcompareIdentifiers = (a, b) => compareIdentifiers(b, a);

	identifiers = {
	  compareIdentifiers,
	  rcompareIdentifiers,
	};
	return identifiers;
}

var semver;
var hasRequiredSemver;

function requireSemver () {
	if (hasRequiredSemver) return semver;
	hasRequiredSemver = 1;

	const debug = requireDebug();
	const { MAX_LENGTH, MAX_SAFE_INTEGER } = requireConstants();
	const { safeRe: re, t } = requireRe();

	const parseOptions = requireParseOptions();
	const { compareIdentifiers } = requireIdentifiers();
	class SemVer {
	  constructor (version, options) {
	    options = parseOptions(options);

	    if (version instanceof SemVer) {
	      if (version.loose === !!options.loose &&
	        version.includePrerelease === !!options.includePrerelease) {
	        return version
	      } else {
	        version = version.version;
	      }
	    } else if (typeof version !== 'string') {
	      throw new TypeError(`Invalid version. Must be a string. Got type "${typeof version}".`)
	    }

	    if (version.length > MAX_LENGTH) {
	      throw new TypeError(
	        `version is longer than ${MAX_LENGTH} characters`
	      )
	    }

	    debug('SemVer', version, options);
	    this.options = options;
	    this.loose = !!options.loose;
	    // this isn't actually relevant for versions, but keep it so that we
	    // don't run into trouble passing this.options around.
	    this.includePrerelease = !!options.includePrerelease;

	    const m = version.trim().match(options.loose ? re[t.LOOSE] : re[t.FULL]);

	    if (!m) {
	      throw new TypeError(`Invalid Version: ${version}`)
	    }

	    this.raw = version;

	    // these are actually numbers
	    this.major = +m[1];
	    this.minor = +m[2];
	    this.patch = +m[3];

	    if (this.major > MAX_SAFE_INTEGER || this.major < 0) {
	      throw new TypeError('Invalid major version')
	    }

	    if (this.minor > MAX_SAFE_INTEGER || this.minor < 0) {
	      throw new TypeError('Invalid minor version')
	    }

	    if (this.patch > MAX_SAFE_INTEGER || this.patch < 0) {
	      throw new TypeError('Invalid patch version')
	    }

	    // numberify any prerelease numeric ids
	    if (!m[4]) {
	      this.prerelease = [];
	    } else {
	      this.prerelease = m[4].split('.').map((id) => {
	        if (/^[0-9]+$/.test(id)) {
	          const num = +id;
	          if (num >= 0 && num < MAX_SAFE_INTEGER) {
	            return num
	          }
	        }
	        return id
	      });
	    }

	    this.build = m[5] ? m[5].split('.') : [];
	    this.format();
	  }

	  format () {
	    this.version = `${this.major}.${this.minor}.${this.patch}`;
	    if (this.prerelease.length) {
	      this.version += `-${this.prerelease.join('.')}`;
	    }
	    return this.version
	  }

	  toString () {
	    return this.version
	  }

	  compare (other) {
	    debug('SemVer.compare', this.version, this.options, other);
	    if (!(other instanceof SemVer)) {
	      if (typeof other === 'string' && other === this.version) {
	        return 0
	      }
	      other = new SemVer(other, this.options);
	    }

	    if (other.version === this.version) {
	      return 0
	    }

	    return this.compareMain(other) || this.comparePre(other)
	  }

	  compareMain (other) {
	    if (!(other instanceof SemVer)) {
	      other = new SemVer(other, this.options);
	    }

	    if (this.major < other.major) {
	      return -1
	    }
	    if (this.major > other.major) {
	      return 1
	    }
	    if (this.minor < other.minor) {
	      return -1
	    }
	    if (this.minor > other.minor) {
	      return 1
	    }
	    if (this.patch < other.patch) {
	      return -1
	    }
	    if (this.patch > other.patch) {
	      return 1
	    }
	    return 0
	  }

	  comparePre (other) {
	    if (!(other instanceof SemVer)) {
	      other = new SemVer(other, this.options);
	    }

	    // NOT having a prerelease is > having one
	    if (this.prerelease.length && !other.prerelease.length) {
	      return -1
	    } else if (!this.prerelease.length && other.prerelease.length) {
	      return 1
	    } else if (!this.prerelease.length && !other.prerelease.length) {
	      return 0
	    }

	    let i = 0;
	    do {
	      const a = this.prerelease[i];
	      const b = other.prerelease[i];
	      debug('prerelease compare', i, a, b);
	      if (a === undefined && b === undefined) {
	        return 0
	      } else if (b === undefined) {
	        return 1
	      } else if (a === undefined) {
	        return -1
	      } else if (a === b) {
	        continue
	      } else {
	        return compareIdentifiers(a, b)
	      }
	    } while (++i)
	  }

	  compareBuild (other) {
	    if (!(other instanceof SemVer)) {
	      other = new SemVer(other, this.options);
	    }

	    let i = 0;
	    do {
	      const a = this.build[i];
	      const b = other.build[i];
	      debug('build compare', i, a, b);
	      if (a === undefined && b === undefined) {
	        return 0
	      } else if (b === undefined) {
	        return 1
	      } else if (a === undefined) {
	        return -1
	      } else if (a === b) {
	        continue
	      } else {
	        return compareIdentifiers(a, b)
	      }
	    } while (++i)
	  }

	  // preminor will bump the version up to the next minor release, and immediately
	  // down to pre-release. premajor and prepatch work the same way.
	  inc (release, identifier, identifierBase) {
	    if (release.startsWith('pre')) {
	      if (!identifier && identifierBase === false) {
	        throw new Error('invalid increment argument: identifier is empty')
	      }
	      // Avoid an invalid semver results
	      if (identifier) {
	        const match = `-${identifier}`.match(this.options.loose ? re[t.PRERELEASELOOSE] : re[t.PRERELEASE]);
	        if (!match || match[1] !== identifier) {
	          throw new Error(`invalid identifier: ${identifier}`)
	        }
	      }
	    }

	    switch (release) {
	      case 'premajor':
	        this.prerelease.length = 0;
	        this.patch = 0;
	        this.minor = 0;
	        this.major++;
	        this.inc('pre', identifier, identifierBase);
	        break
	      case 'preminor':
	        this.prerelease.length = 0;
	        this.patch = 0;
	        this.minor++;
	        this.inc('pre', identifier, identifierBase);
	        break
	      case 'prepatch':
	        // If this is already a prerelease, it will bump to the next version
	        // drop any prereleases that might already exist, since they are not
	        // relevant at this point.
	        this.prerelease.length = 0;
	        this.inc('patch', identifier, identifierBase);
	        this.inc('pre', identifier, identifierBase);
	        break
	      // If the input is a non-prerelease version, this acts the same as
	      // prepatch.
	      case 'prerelease':
	        if (this.prerelease.length === 0) {
	          this.inc('patch', identifier, identifierBase);
	        }
	        this.inc('pre', identifier, identifierBase);
	        break
	      case 'release':
	        if (this.prerelease.length === 0) {
	          throw new Error(`version ${this.raw} is not a prerelease`)
	        }
	        this.prerelease.length = 0;
	        break

	      case 'major':
	        // If this is a pre-major version, bump up to the same major version.
	        // Otherwise increment major.
	        // 1.0.0-5 bumps to 1.0.0
	        // 1.1.0 bumps to 2.0.0
	        if (
	          this.minor !== 0 ||
	          this.patch !== 0 ||
	          this.prerelease.length === 0
	        ) {
	          this.major++;
	        }
	        this.minor = 0;
	        this.patch = 0;
	        this.prerelease = [];
	        break
	      case 'minor':
	        // If this is a pre-minor version, bump up to the same minor version.
	        // Otherwise increment minor.
	        // 1.2.0-5 bumps to 1.2.0
	        // 1.2.1 bumps to 1.3.0
	        if (this.patch !== 0 || this.prerelease.length === 0) {
	          this.minor++;
	        }
	        this.patch = 0;
	        this.prerelease = [];
	        break
	      case 'patch':
	        // If this is not a pre-release version, it will increment the patch.
	        // If it is a pre-release it will bump up to the same patch version.
	        // 1.2.0-5 patches to 1.2.0
	        // 1.2.0 patches to 1.2.1
	        if (this.prerelease.length === 0) {
	          this.patch++;
	        }
	        this.prerelease = [];
	        break
	      // This probably shouldn't be used publicly.
	      // 1.0.0 'pre' would become 1.0.0-0 which is the wrong direction.
	      case 'pre': {
	        const base = Number(identifierBase) ? 1 : 0;

	        if (this.prerelease.length === 0) {
	          this.prerelease = [base];
	        } else {
	          let i = this.prerelease.length;
	          while (--i >= 0) {
	            if (typeof this.prerelease[i] === 'number') {
	              this.prerelease[i]++;
	              i = -2;
	            }
	          }
	          if (i === -1) {
	            // didn't increment anything
	            if (identifier === this.prerelease.join('.') && identifierBase === false) {
	              throw new Error('invalid increment argument: identifier already exists')
	            }
	            this.prerelease.push(base);
	          }
	        }
	        if (identifier) {
	          // 1.2.0-beta.1 bumps to 1.2.0-beta.2,
	          // 1.2.0-beta.fooblz or 1.2.0-beta bumps to 1.2.0-beta.0
	          let prerelease = [identifier, base];
	          if (identifierBase === false) {
	            prerelease = [identifier];
	          }
	          if (compareIdentifiers(this.prerelease[0], identifier) === 0) {
	            if (isNaN(this.prerelease[1])) {
	              this.prerelease = prerelease;
	            }
	          } else {
	            this.prerelease = prerelease;
	          }
	        }
	        break
	      }
	      default:
	        throw new Error(`invalid increment argument: ${release}`)
	    }
	    this.raw = this.format();
	    if (this.build.length) {
	      this.raw += `+${this.build.join('.')}`;
	    }
	    return this
	  }
	}

	semver = SemVer;
	return semver;
}

var compare_1;
var hasRequiredCompare$1;

function requireCompare$1 () {
	if (hasRequiredCompare$1) return compare_1;
	hasRequiredCompare$1 = 1;

	const SemVer = requireSemver();
	const compare = (a, b, loose) =>
	  new SemVer(a, loose).compare(new SemVer(b, loose));

	compare_1 = compare;
	return compare_1;
}

var gte_1;
var hasRequiredGte;

function requireGte () {
	if (hasRequiredGte) return gte_1;
	hasRequiredGte = 1;

	const compare = requireCompare$1();
	const gte = (a, b, loose) => compare(a, b, loose) >= 0;
	gte_1 = gte;
	return gte_1;
}

var hasRequiredMakeDir;

function requireMakeDir () {
	if (hasRequiredMakeDir) return makeDir.exports;
	hasRequiredMakeDir = 1;
	const fs = require$$0$1;
	const path = require$$0$2;
	const {promisify} = require$$2$2;
	const semverGte = requireGte();

	const useNativeRecursiveOption = semverGte(process.version, '10.12.0');

	// https://github.com/nodejs/node/issues/8987
	// https://github.com/libuv/libuv/pull/1088
	const checkPath = pth => {
		if (process.platform === 'win32') {
			const pathHasInvalidWinCharacters = /[<>:"|?*]/.test(pth.replace(path.parse(pth).root, ''));

			if (pathHasInvalidWinCharacters) {
				const error = new Error(`Path contains invalid characters: ${pth}`);
				error.code = 'EINVAL';
				throw error;
			}
		}
	};

	const processOptions = options => {
		const defaults = {
			mode: 0o777,
			fs
		};

		return {
			...defaults,
			...options
		};
	};

	const permissionError = pth => {
		// This replicates the exception of `fs.mkdir` with native the
		// `recusive` option when run on an invalid drive under Windows.
		const error = new Error(`operation not permitted, mkdir '${pth}'`);
		error.code = 'EPERM';
		error.errno = -4048;
		error.path = pth;
		error.syscall = 'mkdir';
		return error;
	};

	const makeDir$1 = async (input, options) => {
		checkPath(input);
		options = processOptions(options);

		const mkdir = promisify(options.fs.mkdir);
		const stat = promisify(options.fs.stat);

		if (useNativeRecursiveOption && options.fs.mkdir === fs.mkdir) {
			const pth = path.resolve(input);

			await mkdir(pth, {
				mode: options.mode,
				recursive: true
			});

			return pth;
		}

		const make = async pth => {
			try {
				await mkdir(pth, options.mode);

				return pth;
			} catch (error) {
				if (error.code === 'EPERM') {
					throw error;
				}

				if (error.code === 'ENOENT') {
					if (path.dirname(pth) === pth) {
						throw permissionError(pth);
					}

					if (error.message.includes('null bytes')) {
						throw error;
					}

					await make(path.dirname(pth));

					return make(pth);
				}

				try {
					const stats = await stat(pth);
					if (!stats.isDirectory()) {
						throw new Error('The path is not a directory');
					}
				} catch {
					throw error;
				}

				return pth;
			}
		};

		return make(path.resolve(input));
	};

	makeDir.exports = makeDir$1;

	makeDir.exports.sync = (input, options) => {
		checkPath(input);
		options = processOptions(options);

		if (useNativeRecursiveOption && options.fs.mkdirSync === fs.mkdirSync) {
			const pth = path.resolve(input);

			fs.mkdirSync(pth, {
				mode: options.mode,
				recursive: true
			});

			return pth;
		}

		const make = pth => {
			try {
				options.fs.mkdirSync(pth, options.mode);
			} catch (error) {
				if (error.code === 'EPERM') {
					throw error;
				}

				if (error.code === 'ENOENT') {
					if (path.dirname(pth) === pth) {
						throw permissionError(pth);
					}

					if (error.message.includes('null bytes')) {
						throw error;
					}

					make(path.dirname(pth));
					return make(pth);
				}

				try {
					if (!options.fs.statSync(pth).isDirectory()) {
						throw new Error('The path is not a directory');
					}
				} catch {
					throw error;
				}
			}

			return pth;
		};

		return make(path.resolve(input));
	};
	return makeDir.exports;
}

var hasFlag;
var hasRequiredHasFlag;

function requireHasFlag () {
	if (hasRequiredHasFlag) return hasFlag;
	hasRequiredHasFlag = 1;

	hasFlag = (flag, argv = process.argv) => {
		const prefix = flag.startsWith('-') ? '' : (flag.length === 1 ? '-' : '--');
		const position = argv.indexOf(prefix + flag);
		const terminatorPosition = argv.indexOf('--');
		return position !== -1 && (terminatorPosition === -1 || position < terminatorPosition);
	};
	return hasFlag;
}

var supportsColor_1;
var hasRequiredSupportsColor;

function requireSupportsColor () {
	if (hasRequiredSupportsColor) return supportsColor_1;
	hasRequiredSupportsColor = 1;
	const os = require$$0$3;
	const tty = require$$1$2;
	const hasFlag = requireHasFlag();

	const {env} = process;

	let forceColor;
	if (hasFlag('no-color') ||
		hasFlag('no-colors') ||
		hasFlag('color=false') ||
		hasFlag('color=never')) {
		forceColor = 0;
	} else if (hasFlag('color') ||
		hasFlag('colors') ||
		hasFlag('color=true') ||
		hasFlag('color=always')) {
		forceColor = 1;
	}

	if ('FORCE_COLOR' in env) {
		if (env.FORCE_COLOR === 'true') {
			forceColor = 1;
		} else if (env.FORCE_COLOR === 'false') {
			forceColor = 0;
		} else {
			forceColor = env.FORCE_COLOR.length === 0 ? 1 : Math.min(parseInt(env.FORCE_COLOR, 10), 3);
		}
	}

	function translateLevel(level) {
		if (level === 0) {
			return false;
		}

		return {
			level,
			hasBasic: true,
			has256: level >= 2,
			has16m: level >= 3
		};
	}

	function supportsColor(haveStream, streamIsTTY) {
		if (forceColor === 0) {
			return 0;
		}

		if (hasFlag('color=16m') ||
			hasFlag('color=full') ||
			hasFlag('color=truecolor')) {
			return 3;
		}

		if (hasFlag('color=256')) {
			return 2;
		}

		if (haveStream && !streamIsTTY && forceColor === undefined) {
			return 0;
		}

		const min = forceColor || 0;

		if (env.TERM === 'dumb') {
			return min;
		}

		if (process.platform === 'win32') {
			// Windows 10 build 10586 is the first Windows release that supports 256 colors.
			// Windows 10 build 14931 is the first release that supports 16m/TrueColor.
			const osRelease = os.release().split('.');
			if (
				Number(osRelease[0]) >= 10 &&
				Number(osRelease[2]) >= 10586
			) {
				return Number(osRelease[2]) >= 14931 ? 3 : 2;
			}

			return 1;
		}

		if ('CI' in env) {
			if (['TRAVIS', 'CIRCLECI', 'APPVEYOR', 'GITLAB_CI', 'GITHUB_ACTIONS', 'BUILDKITE'].some(sign => sign in env) || env.CI_NAME === 'codeship') {
				return 1;
			}

			return min;
		}

		if ('TEAMCITY_VERSION' in env) {
			return /^(9\.(0*[1-9]\d*)\.|\d{2,}\.)/.test(env.TEAMCITY_VERSION) ? 1 : 0;
		}

		if (env.COLORTERM === 'truecolor') {
			return 3;
		}

		if ('TERM_PROGRAM' in env) {
			const version = parseInt((env.TERM_PROGRAM_VERSION || '').split('.')[0], 10);

			switch (env.TERM_PROGRAM) {
				case 'iTerm.app':
					return version >= 3 ? 3 : 2;
				case 'Apple_Terminal':
					return 2;
				// No default
			}
		}

		if (/-256(color)?$/i.test(env.TERM)) {
			return 2;
		}

		if (/^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/i.test(env.TERM)) {
			return 1;
		}

		if ('COLORTERM' in env) {
			return 1;
		}

		return min;
	}

	function getSupportLevel(stream) {
		const level = supportsColor(stream, stream && stream.isTTY);
		return translateLevel(level);
	}

	supportsColor_1 = {
		supportsColor: getSupportLevel,
		stdout: translateLevel(supportsColor(true, tty.isatty(1))),
		stderr: translateLevel(supportsColor(true, tty.isatty(2)))
	};
	return supportsColor_1;
}

var fileWriter;
var hasRequiredFileWriter;

function requireFileWriter () {
	if (hasRequiredFileWriter) return fileWriter;
	hasRequiredFileWriter = 1;
	/*
	 Copyright 2012-2015, Yahoo Inc.
	 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
	 */
	const path = require$$0$2;
	const fs = require$$0$1;
	const mkdirp = requireMakeDir();
	const supportsColor = requireSupportsColor();

	/**
	 * Base class for writing content
	 * @class ContentWriter
	 * @constructor
	 */
	class ContentWriter {
	    /**
	     * returns the colorized version of a string. Typically,
	     * content writers that write to files will return the
	     * same string and ones writing to a tty will wrap it in
	     * appropriate escape sequences.
	     * @param {String} str the string to colorize
	     * @param {String} clazz one of `high`, `medium` or `low`
	     * @returns {String} the colorized form of the string
	     */
	    colorize(str /*, clazz*/) {
	        return str;
	    }

	    /**
	     * writes a string appended with a newline to the destination
	     * @param {String} str the string to write
	     */
	    println(str) {
	        this.write(`${str}\n`);
	    }

	    /**
	     * closes this content writer. Should be called after all writes are complete.
	     */
	    close() {}
	}

	/**
	 * a content writer that writes to a file
	 * @param {Number} fd - the file descriptor
	 * @extends ContentWriter
	 * @constructor
	 */
	class FileContentWriter extends ContentWriter {
	    constructor(fd) {
	        super();

	        this.fd = fd;
	    }

	    write(str) {
	        fs.writeSync(this.fd, str);
	    }

	    close() {
	        fs.closeSync(this.fd);
	    }
	}

	// allow stdout to be captured for tests.
	let capture = false;
	let output = '';

	/**
	 * a content writer that writes to the console
	 * @extends ContentWriter
	 * @constructor
	 */
	class ConsoleWriter extends ContentWriter {
	    write(str) {
	        if (capture) {
	            output += str;
	        } else {
	            process.stdout.write(str);
	        }
	    }

	    colorize(str, clazz) {
	        const colors = {
	            low: '31;1',
	            medium: '33;1',
	            high: '32;1'
	        };

	        /* istanbul ignore next: different modes for CI and local */
	        if (supportsColor.stdout && colors[clazz]) {
	            return `\u001b[${colors[clazz]}m${str}\u001b[0m`;
	        }
	        return str;
	    }
	}

	/**
	 * utility for writing files under a specific directory
	 * @class FileWriter
	 * @param {String} baseDir the base directory under which files should be written
	 * @constructor
	 */
	class FileWriter {
	    constructor(baseDir) {
	        if (!baseDir) {
	            throw new Error('baseDir must be specified');
	        }
	        this.baseDir = baseDir;
	    }

	    /**
	     * static helpers for capturing stdout report output;
	     * super useful for tests!
	     */
	    static startCapture() {
	        capture = true;
	    }

	    static stopCapture() {
	        capture = false;
	    }

	    static getOutput() {
	        return output;
	    }

	    static resetOutput() {
	        output = '';
	    }

	    /**
	     * returns a FileWriter that is rooted at the supplied subdirectory
	     * @param {String} subdir the subdirectory under which to root the
	     *  returned FileWriter
	     * @returns {FileWriter}
	     */
	    writerForDir(subdir) {
	        if (path.isAbsolute(subdir)) {
	            throw new Error(
	                `Cannot create subdir writer for absolute path: ${subdir}`
	            );
	        }
	        return new FileWriter(`${this.baseDir}/${subdir}`);
	    }

	    /**
	     * copies a file from a source directory to a destination name
	     * @param {String} source path to source file
	     * @param {String} dest relative path to destination file
	     * @param {String} [header=undefined] optional text to prepend to destination
	     *  (e.g., an "this file is autogenerated" comment, copyright notice, etc.)
	     */
	    copyFile(source, dest, header) {
	        if (path.isAbsolute(dest)) {
	            throw new Error(`Cannot write to absolute path: ${dest}`);
	        }
	        dest = path.resolve(this.baseDir, dest);
	        mkdirp.sync(path.dirname(dest));
	        let contents;
	        if (header) {
	            contents = header + fs.readFileSync(source, 'utf8');
	        } else {
	            contents = fs.readFileSync(source);
	        }
	        fs.writeFileSync(dest, contents);
	    }

	    /**
	     * returns a content writer for writing content to the supplied file.
	     * @param {String|null} file the relative path to the file or the special
	     *  values `"-"` or `null` for writing to the console
	     * @returns {ContentWriter}
	     */
	    writeFile(file) {
	        if (file === null || file === '-') {
	            return new ConsoleWriter();
	        }
	        if (path.isAbsolute(file)) {
	            throw new Error(`Cannot write to absolute path: ${file}`);
	        }
	        file = path.resolve(this.baseDir, file);
	        mkdirp.sync(path.dirname(file));
	        return new FileContentWriter(fs.openSync(file, 'w'));
	    }
	}

	fileWriter = FileWriter;
	return fileWriter;
}

var xmlWriter;
var hasRequiredXmlWriter;

function requireXmlWriter () {
	if (hasRequiredXmlWriter) return xmlWriter;
	hasRequiredXmlWriter = 1;
	/*
	 Copyright 2012-2015, Yahoo Inc.
	 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
	 */
	const INDENT = '  ';

	function attrString(attrs) {
	    return Object.entries(attrs || {})
	        .map(([k, v]) => ` ${k}="${v}"`)
	        .join('');
	}

	/**
	 * a utility class to produce well-formed, indented XML
	 * @param {ContentWriter} contentWriter the content writer that this utility wraps
	 * @constructor
	 */
	class XMLWriter {
	    constructor(contentWriter) {
	        this.cw = contentWriter;
	        this.stack = [];
	    }

	    indent(str) {
	        return this.stack.map(() => INDENT).join('') + str;
	    }

	    /**
	     * writes the opening XML tag with the supplied attributes
	     * @param {String} name tag name
	     * @param {Object} [attrs=null] attrs attributes for the tag
	     */
	    openTag(name, attrs) {
	        const str = this.indent(`<${name + attrString(attrs)}>`);
	        this.cw.println(str);
	        this.stack.push(name);
	    }

	    /**
	     * closes an open XML tag.
	     * @param {String} name - tag name to close. This must match the writer's
	     *  notion of the tag that is currently open.
	     */
	    closeTag(name) {
	        if (this.stack.length === 0) {
	            throw new Error(`Attempt to close tag ${name} when not opened`);
	        }
	        const stashed = this.stack.pop();
	        const str = `</${name}>`;

	        if (stashed !== name) {
	            throw new Error(
	                `Attempt to close tag ${name} when ${stashed} was the one open`
	            );
	        }
	        this.cw.println(this.indent(str));
	    }

	    /**
	     * writes a tag and its value opening and closing it at the same time
	     * @param {String} name tag name
	     * @param {Object} [attrs=null] attrs tag attributes
	     * @param {String} [content=null] content optional tag content
	     */
	    inlineTag(name, attrs, content) {
	        let str = '<' + name + attrString(attrs);
	        if (content) {
	            str += `>${content}</${name}>`;
	        } else {
	            str += '/>';
	        }
	        str = this.indent(str);
	        this.cw.println(str);
	    }

	    /**
	     * closes all open tags and ends the document
	     */
	    closeAll() {
	        this.stack
	            .slice()
	            .reverse()
	            .forEach(name => {
	                this.closeTag(name);
	            });
	    }
	}

	xmlWriter = XMLWriter;
	return xmlWriter;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var tree;
var hasRequiredTree;

function requireTree () {
	if (hasRequiredTree) return tree;
	hasRequiredTree = 1;

	/**
	 * An object with methods that are called during the traversal of the coverage tree.
	 * A visitor has the following methods that are called during tree traversal.
	 *
	 *   * `onStart(root, state)` - called before traversal begins
	 *   * `onSummary(node, state)` - called for every summary node
	 *   * `onDetail(node, state)` - called for every detail node
	 *   * `onSummaryEnd(node, state)` - called after all children have been visited for
	 *      a summary node.
	 *   * `onEnd(root, state)` - called after traversal ends
	 *
	 * @param delegate - a partial visitor that only implements the methods of interest
	 *  The visitor object supplies the missing methods as noops. For example, reports
	 *  that only need the final coverage summary need implement `onStart` and nothing
	 *  else. Reports that use only detailed coverage information need implement `onDetail`
	 *  and nothing else.
	 * @constructor
	 */
	class Visitor {
	    constructor(delegate) {
	        this.delegate = delegate;
	    }
	}

	['Start', 'End', 'Summary', 'SummaryEnd', 'Detail']
	    .map(k => `on${k}`)
	    .forEach(fn => {
	        Object.defineProperty(Visitor.prototype, fn, {
	            writable: true,
	            value(node, state) {
	                if (typeof this.delegate[fn] === 'function') {
	                    this.delegate[fn](node, state);
	                }
	            }
	        });
	    });

	class CompositeVisitor extends Visitor {
	    constructor(visitors) {
	        super();

	        if (!Array.isArray(visitors)) {
	            visitors = [visitors];
	        }
	        this.visitors = visitors.map(v => {
	            if (v instanceof Visitor) {
	                return v;
	            }
	            return new Visitor(v);
	        });
	    }
	}

	['Start', 'Summary', 'SummaryEnd', 'Detail', 'End']
	    .map(k => `on${k}`)
	    .forEach(fn => {
	        Object.defineProperty(CompositeVisitor.prototype, fn, {
	            value(node, state) {
	                this.visitors.forEach(v => {
	                    v[fn](node, state);
	                });
	            }
	        });
	    });

	class BaseNode {
	    isRoot() {
	        return !this.getParent();
	    }

	    /**
	     * visit all nodes depth-first from this node down. Note that `onStart`
	     * and `onEnd` are never called on the visitor even if the current
	     * node is the root of the tree.
	     * @param visitor a full visitor that is called during tree traversal
	     * @param state optional state that is passed around
	     */
	    visit(visitor, state) {
	        if (this.isSummary()) {
	            visitor.onSummary(this, state);
	        } else {
	            visitor.onDetail(this, state);
	        }

	        this.getChildren().forEach(child => {
	            child.visit(visitor, state);
	        });

	        if (this.isSummary()) {
	            visitor.onSummaryEnd(this, state);
	        }
	    }
	}

	/**
	 * abstract base class for a coverage tree.
	 * @constructor
	 */
	class BaseTree {
	    constructor(root) {
	        this.root = root;
	    }

	    /**
	     * returns the root node of the tree
	     */
	    getRoot() {
	        return this.root;
	    }

	    /**
	     * visits the tree depth-first with the supplied partial visitor
	     * @param visitor - a potentially partial visitor
	     * @param state - the state to be passed around during tree traversal
	     */
	    visit(visitor, state) {
	        if (!(visitor instanceof Visitor)) {
	            visitor = new Visitor(visitor);
	        }
	        visitor.onStart(this.getRoot(), state);
	        this.getRoot().visit(visitor, state);
	        visitor.onEnd(this.getRoot(), state);
	    }
	}

	tree = {
	    BaseTree,
	    BaseNode,
	    Visitor,
	    CompositeVisitor
	};
	return tree;
}

var watermarks;
var hasRequiredWatermarks;

function requireWatermarks () {
	if (hasRequiredWatermarks) return watermarks;
	hasRequiredWatermarks = 1;
	/*
	 Copyright 2012-2015, Yahoo Inc.
	 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
	 */
	watermarks = {
	    getDefault() {
	        return {
	            statements: [50, 80],
	            functions: [50, 80],
	            branches: [50, 80],
	            lines: [50, 80]
	        };
	    }
	};
	return watermarks;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var path_1;
var hasRequiredPath;

function requirePath () {
	if (hasRequiredPath) return path_1;
	hasRequiredPath = 1;

	const path = require$$0$2;
	let parsePath = path.parse;
	let SEP = path.sep;
	const origParser = parsePath;
	const origSep = SEP;

	function makeRelativeNormalizedPath(str, sep) {
	    const parsed = parsePath(str);
	    let root = parsed.root;
	    let dir;
	    let file = parsed.base;
	    let quoted;
	    let pos;

	    // handle a weird windows case separately
	    if (sep === '\\') {
	        pos = root.indexOf(':\\');
	        if (pos >= 0) {
	            root = root.substring(0, pos + 2);
	        }
	    }
	    dir = parsed.dir.substring(root.length);

	    if (str === '') {
	        return [];
	    }

	    if (sep !== '/') {
	        quoted = new RegExp(sep.replace(/\W/g, '\\$&'), 'g');
	        dir = dir.replace(quoted, '/');
	        file = file.replace(quoted, '/'); // excessively paranoid?
	    }

	    if (dir !== '') {
	        dir = `${dir}/${file}`;
	    } else {
	        dir = file;
	    }
	    if (dir.substring(0, 1) === '/') {
	        dir = dir.substring(1);
	    }
	    dir = dir.split(/\/+/);
	    return dir;
	}

	class Path {
	    constructor(strOrArray) {
	        if (Array.isArray(strOrArray)) {
	            this.v = strOrArray;
	        } else if (typeof strOrArray === 'string') {
	            this.v = makeRelativeNormalizedPath(strOrArray, SEP);
	        } else {
	            throw new Error(
	                `Invalid Path argument must be string or array:${strOrArray}`
	            );
	        }
	    }

	    toString() {
	        return this.v.join('/');
	    }

	    hasParent() {
	        return this.v.length > 0;
	    }

	    parent() {
	        if (!this.hasParent()) {
	            throw new Error('Unable to get parent for 0 elem path');
	        }
	        const p = this.v.slice();
	        p.pop();
	        return new Path(p);
	    }

	    elements() {
	        return this.v.slice();
	    }

	    name() {
	        return this.v.slice(-1)[0];
	    }

	    contains(other) {
	        let i;
	        if (other.length > this.length) {
	            return false;
	        }
	        for (i = 0; i < other.length; i += 1) {
	            if (this.v[i] !== other.v[i]) {
	                return false;
	            }
	        }
	        return true;
	    }

	    ancestorOf(other) {
	        return other.contains(this) && other.length !== this.length;
	    }

	    descendantOf(other) {
	        return this.contains(other) && other.length !== this.length;
	    }

	    commonPrefixPath(other) {
	        const len = this.length > other.length ? other.length : this.length;
	        let i;
	        const ret = [];

	        for (i = 0; i < len; i += 1) {
	            if (this.v[i] === other.v[i]) {
	                ret.push(this.v[i]);
	            } else {
	                break;
	            }
	        }
	        return new Path(ret);
	    }

	    static compare(a, b) {
	        const al = a.length;
	        const bl = b.length;

	        if (al < bl) {
	            return -1;
	        }

	        if (al > bl) {
	            return 1;
	        }

	        const astr = a.toString();
	        const bstr = b.toString();
	        return astr < bstr ? -1 : astr > bstr ? 1 : 0;
	    }
	}

	['push', 'pop', 'shift', 'unshift', 'splice'].forEach(fn => {
	    Object.defineProperty(Path.prototype, fn, {
	        value(...args) {
	            return this.v[fn](...args);
	        }
	    });
	});

	Object.defineProperty(Path.prototype, 'length', {
	    enumerable: true,
	    get() {
	        return this.v.length;
	    }
	});

	path_1 = Path;
	Path.tester = {
	    setParserAndSep(p, sep) {
	        parsePath = p;
	        SEP = sep;
	    },
	    reset() {
	        parsePath = origParser;
	        SEP = origSep;
	    }
	};
	return path_1;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var summarizerFactory;
var hasRequiredSummarizerFactory;

function requireSummarizerFactory () {
	if (hasRequiredSummarizerFactory) return summarizerFactory;
	hasRequiredSummarizerFactory = 1;

	const coverage = requireIstanbulLibCoverage();
	const Path = requirePath();
	const { BaseNode, BaseTree } = requireTree();

	class ReportNode extends BaseNode {
	    constructor(path, fileCoverage) {
	        super();

	        this.path = path;
	        this.parent = null;
	        this.fileCoverage = fileCoverage;
	        this.children = [];
	    }

	    static createRoot(children) {
	        const root = new ReportNode(new Path([]));

	        children.forEach(child => {
	            root.addChild(child);
	        });

	        return root;
	    }

	    addChild(child) {
	        child.parent = this;
	        this.children.push(child);
	    }

	    asRelative(p) {
	        if (p.substring(0, 1) === '/') {
	            return p.substring(1);
	        }
	        return p;
	    }

	    getQualifiedName() {
	        return this.asRelative(this.path.toString());
	    }

	    getRelativeName() {
	        const parent = this.getParent();
	        const myPath = this.path;
	        let relPath;
	        let i;
	        const parentPath = parent ? parent.path : new Path([]);
	        if (parentPath.ancestorOf(myPath)) {
	            relPath = new Path(myPath.elements());
	            for (i = 0; i < parentPath.length; i += 1) {
	                relPath.shift();
	            }
	            return this.asRelative(relPath.toString());
	        }
	        return this.asRelative(this.path.toString());
	    }

	    getParent() {
	        return this.parent;
	    }

	    getChildren() {
	        return this.children;
	    }

	    isSummary() {
	        return !this.fileCoverage;
	    }

	    getFileCoverage() {
	        return this.fileCoverage;
	    }

	    getCoverageSummary(filesOnly) {
	        const cacheProp = `c_${filesOnly ? 'files' : 'full'}`;
	        let summary;

	        if (Object.prototype.hasOwnProperty.call(this, cacheProp)) {
	            return this[cacheProp];
	        }

	        if (!this.isSummary()) {
	            summary = this.getFileCoverage().toSummary();
	        } else {
	            let count = 0;
	            summary = coverage.createCoverageSummary();
	            this.getChildren().forEach(child => {
	                if (filesOnly && child.isSummary()) {
	                    return;
	                }
	                count += 1;
	                summary.merge(child.getCoverageSummary(filesOnly));
	            });
	            if (count === 0 && filesOnly) {
	                summary = null;
	            }
	        }
	        this[cacheProp] = summary;
	        return summary;
	    }
	}

	class ReportTree extends BaseTree {
	    constructor(root, childPrefix) {
	        super(root);

	        const maybePrefix = node => {
	            if (childPrefix && !node.isRoot()) {
	                node.path.unshift(childPrefix);
	            }
	        };
	        this.visit({
	            onDetail: maybePrefix,
	            onSummary(node) {
	                maybePrefix(node);
	                node.children.sort((a, b) => {
	                    const astr = a.path.toString();
	                    const bstr = b.path.toString();
	                    return astr < bstr
	                        ? -1
	                        : astr > bstr
	                        ? 1
	                        : /* istanbul ignore next */ 0;
	                });
	            }
	        });
	    }
	}

	function findCommonParent(paths) {
	    return paths.reduce(
	        (common, path) => common.commonPrefixPath(path),
	        paths[0] || new Path([])
	    );
	}

	function findOrCreateParent(parentPath, nodeMap, created = () => {}) {
	    let parent = nodeMap[parentPath.toString()];

	    if (!parent) {
	        parent = new ReportNode(parentPath);
	        nodeMap[parentPath.toString()] = parent;
	        created(parentPath, parent);
	    }

	    return parent;
	}

	function toDirParents(list) {
	    const nodeMap = Object.create(null);
	    list.forEach(o => {
	        const parent = findOrCreateParent(o.path.parent(), nodeMap);
	        parent.addChild(new ReportNode(o.path, o.fileCoverage));
	    });

	    return Object.values(nodeMap);
	}

	function addAllPaths(topPaths, nodeMap, path, node) {
	    const parent = findOrCreateParent(
	        path.parent(),
	        nodeMap,
	        (parentPath, parent) => {
	            if (parentPath.hasParent()) {
	                addAllPaths(topPaths, nodeMap, parentPath, parent);
	            } else {
	                topPaths.push(parent);
	            }
	        }
	    );

	    parent.addChild(node);
	}

	function foldIntoOneDir(node, parent) {
	    const { children } = node;
	    if (children.length === 1 && !children[0].fileCoverage) {
	        children[0].parent = parent;
	        return foldIntoOneDir(children[0], parent);
	    }
	    node.children = children.map(child => foldIntoOneDir(child, node));
	    return node;
	}

	function pkgSummaryPrefix(dirParents, commonParent) {
	    if (!dirParents.some(dp => dp.path.length === 0)) {
	        return;
	    }

	    if (commonParent.length === 0) {
	        return 'root';
	    }

	    return commonParent.name();
	}

	class SummarizerFactory {
	    constructor(coverageMap, defaultSummarizer = 'pkg') {
	        this._coverageMap = coverageMap;
	        this._defaultSummarizer = defaultSummarizer;
	        this._initialList = coverageMap.files().map(filePath => ({
	            filePath,
	            path: new Path(filePath),
	            fileCoverage: coverageMap.fileCoverageFor(filePath)
	        }));
	        this._commonParent = findCommonParent(
	            this._initialList.map(o => o.path.parent())
	        );
	        if (this._commonParent.length > 0) {
	            this._initialList.forEach(o => {
	                o.path.splice(0, this._commonParent.length);
	            });
	        }
	    }

	    get defaultSummarizer() {
	        return this[this._defaultSummarizer];
	    }

	    get flat() {
	        if (!this._flat) {
	            this._flat = new ReportTree(
	                ReportNode.createRoot(
	                    this._initialList.map(
	                        node => new ReportNode(node.path, node.fileCoverage)
	                    )
	                )
	            );
	        }

	        return this._flat;
	    }

	    _createPkg() {
	        const dirParents = toDirParents(this._initialList);
	        if (dirParents.length === 1) {
	            return new ReportTree(dirParents[0]);
	        }

	        return new ReportTree(
	            ReportNode.createRoot(dirParents),
	            pkgSummaryPrefix(dirParents, this._commonParent)
	        );
	    }

	    get pkg() {
	        if (!this._pkg) {
	            this._pkg = this._createPkg();
	        }

	        return this._pkg;
	    }

	    _createNested() {
	        const nodeMap = Object.create(null);
	        const topPaths = [];
	        this._initialList.forEach(o => {
	            const node = new ReportNode(o.path, o.fileCoverage);
	            addAllPaths(topPaths, nodeMap, o.path, node);
	        });

	        const topNodes = topPaths.map(node => foldIntoOneDir(node));
	        if (topNodes.length === 1) {
	            return new ReportTree(topNodes[0]);
	        }

	        return new ReportTree(ReportNode.createRoot(topNodes));
	    }

	    get nested() {
	        if (!this._nested) {
	            this._nested = this._createNested();
	        }

	        return this._nested;
	    }
	}

	summarizerFactory = SummarizerFactory;
	return summarizerFactory;
}

var context;
var hasRequiredContext;

function requireContext () {
	if (hasRequiredContext) return context;
	hasRequiredContext = 1;
	/*
	 Copyright 2012-2015, Yahoo Inc.
	 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
	 */
	const fs = require$$0$1;
	const FileWriter = requireFileWriter();
	const XMLWriter = requireXmlWriter();
	const tree = requireTree();
	const watermarks = requireWatermarks();
	const SummarizerFactory = requireSummarizerFactory();

	function defaultSourceLookup(path) {
	    try {
	        return fs.readFileSync(path, 'utf8');
	    } catch (ex) {
	        throw new Error(`Unable to lookup source: ${path} (${ex.message})`);
	    }
	}

	function normalizeWatermarks(specified = {}) {
	    Object.entries(watermarks.getDefault()).forEach(([k, value]) => {
	        const specValue = specified[k];
	        if (!Array.isArray(specValue) || specValue.length !== 2) {
	            specified[k] = value;
	        }
	    });

	    return specified;
	}

	/**
	 * A reporting context that is passed to report implementations
	 * @param {Object} [opts=null] opts options
	 * @param {String} [opts.dir='coverage'] opts.dir the reporting directory
	 * @param {Object} [opts.watermarks=null] opts.watermarks watermarks for
	 *  statements, lines, branches and functions
	 * @param {Function} [opts.sourceFinder=fsLookup] opts.sourceFinder a
	 *  function that returns source code given a file path. Defaults to
	 *  filesystem lookups based on path.
	 * @constructor
	 */
	class Context {
	    constructor(opts) {
	        this.dir = opts.dir || 'coverage';
	        this.watermarks = normalizeWatermarks(opts.watermarks);
	        this.sourceFinder = opts.sourceFinder || defaultSourceLookup;
	        this._summarizerFactory = new SummarizerFactory(
	            opts.coverageMap,
	            opts.defaultSummarizer
	        );
	        this.data = {};
	    }

	    /**
	     * returns a FileWriter implementation for reporting use. Also available
	     * as the `writer` property on the context.
	     * @returns {Writer}
	     */
	    getWriter() {
	        return this.writer;
	    }

	    /**
	     * returns the source code for the specified file path or throws if
	     * the source could not be found.
	     * @param {String} filePath the file path as found in a file coverage object
	     * @returns {String} the source code
	     */
	    getSource(filePath) {
	        return this.sourceFinder(filePath);
	    }

	    /**
	     * returns the coverage class given a coverage
	     * types and a percentage value.
	     * @param {String} type - the coverage type, one of `statements`, `functions`,
	     *  `branches`, or `lines`
	     * @param {Number} value - the percentage value
	     * @returns {String} one of `high`, `medium` or `low`
	     */
	    classForPercent(type, value) {
	        const watermarks = this.watermarks[type];
	        if (!watermarks) {
	            return 'unknown';
	        }
	        if (value < watermarks[0]) {
	            return 'low';
	        }
	        if (value >= watermarks[1]) {
	            return 'high';
	        }
	        return 'medium';
	    }

	    /**
	     * returns an XML writer for the supplied content writer
	     * @param {ContentWriter} contentWriter the content writer to which the returned XML writer
	     *  writes data
	     * @returns {XMLWriter}
	     */
	    getXMLWriter(contentWriter) {
	        return new XMLWriter(contentWriter);
	    }

	    /**
	     * returns a full visitor given a partial one.
	     * @param {Object} partialVisitor a partial visitor only having the functions of
	     *  interest to the caller. These functions are called with a scope that is the
	     *  supplied object.
	     * @returns {Visitor}
	     */
	    getVisitor(partialVisitor) {
	        return new tree.Visitor(partialVisitor);
	    }

	    getTree(name = 'defaultSummarizer') {
	        return this._summarizerFactory[name];
	    }
	}

	Object.defineProperty(Context.prototype, 'writer', {
	    enumerable: true,
	    get() {
	        if (!this.data.writer) {
	            this.data.writer = new FileWriter(this.dir);
	        }
	        return this.data.writer;
	    }
	});

	context = Context;
	return context;
}

var reportBase;
var hasRequiredReportBase;

function requireReportBase () {
	if (hasRequiredReportBase) return reportBase;
	hasRequiredReportBase = 1;

	// TODO: switch to class private field when targetting node.js 12
	const _summarizer = Symbol('ReportBase.#summarizer');

	class ReportBase {
	    constructor(opts = {}) {
	        this[_summarizer] = opts.summarizer;
	    }

	    execute(context) {
	        context.getTree(this[_summarizer]).visit(this, context);
	    }
	}

	reportBase = ReportBase;
	return reportBase;
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var istanbulLibReport;
var hasRequiredIstanbulLibReport;

function requireIstanbulLibReport () {
	if (hasRequiredIstanbulLibReport) return istanbulLibReport;
	hasRequiredIstanbulLibReport = 1;

	/**
	 * @module Exports
	 */

	const Context = requireContext();
	const watermarks = requireWatermarks();
	const ReportBase = requireReportBase();

	istanbulLibReport = {
	    /**
	     * returns a reporting context for the supplied options
	     * @param {Object} [opts=null] opts
	     * @returns {Context}
	     */
	    createContext(opts) {
	        return new Context(opts);
	    },

	    /**
	     * returns the default watermarks that would be used when not
	     * overridden
	     * @returns {Object} an object with `statements`, `functions`, `branches`,
	     *  and `line` keys. Each value is a 2 element array that has the low and
	     *  high watermark as percentages.
	     */
	    getDefaultWatermarks() {
	        return watermarks.getDefault();
	    },

	    /**
	     * Base class for all reports
	     */
	    ReportBase
	};
	return istanbulLibReport;
}

function commonjsRequire(path) {
	throw new Error('Could not dynamically require "' + path + '". Please configure the dynamicRequireTargets or/and ignoreDynamicRequires option of @rollup/plugin-commonjs appropriately for this require call to work.');
}

/*
 Copyright 2012-2015, Yahoo Inc.
 Copyrights licensed under the New BSD License. See the accompanying LICENSE file for terms.
 */

var lcovonly;
var hasRequiredLcovonly;

function requireLcovonly () {
	if (hasRequiredLcovonly) return lcovonly;
	hasRequiredLcovonly = 1;
	const { ReportBase } = requireIstanbulLibReport();

	class LcovOnlyReport extends ReportBase {
	    constructor(opts) {
	        super();
	        opts = opts || {};
	        this.file = opts.file || 'lcov.info';
	        this.projectRoot = opts.projectRoot || process.cwd();
	        this.contentWriter = null;
	    }

	    onStart(root, context) {
	        this.contentWriter = context.writer.writeFile(this.file);
	    }

	    onDetail(node) {
	        const fc = node.getFileCoverage();
	        const writer = this.contentWriter;
	        const functions = fc.f;
	        const functionMap = fc.fnMap;
	        const lines = fc.getLineCoverage();
	        const branches = fc.b;
	        const branchMap = fc.branchMap;
	        const summary = node.getCoverageSummary();
	        const path = require$$0$2;

	        writer.println('TN:');
	        const fileName = path.relative(this.projectRoot, fc.path);
	        writer.println('SF:' + fileName);

	        Object.values(functionMap).forEach(meta => {
	            // Some versions of the instrumenter in the wild populate 'loc'
	            // but not 'decl':
	            const decl = meta.decl || meta.loc;
	            writer.println('FN:' + [decl.start.line, meta.name].join(','));
	        });
	        writer.println('FNF:' + summary.functions.total);
	        writer.println('FNH:' + summary.functions.covered);

	        Object.entries(functionMap).forEach(([key, meta]) => {
	            const stats = functions[key];
	            writer.println('FNDA:' + [stats, meta.name].join(','));
	        });

	        Object.entries(lines).forEach(entry => {
	            writer.println('DA:' + entry.join(','));
	        });
	        writer.println('LF:' + summary.lines.total);
	        writer.println('LH:' + summary.lines.covered);

	        Object.entries(branches).forEach(([key, branchArray]) => {
	            const meta = branchMap[key];
	            if (meta) {
	                const { line } = meta.loc.start;
	                branchArray.forEach((b, i) => {
	                    writer.println('BRDA:' + [line, key, i, b].join(','));
	                });
	            } else {
	                console.warn('Missing coverage entries in', fileName, key);
	            }
	        });
	        writer.println('BRF:' + summary.branches.total);
	        writer.println('BRH:' + summary.branches.covered);
	        writer.println('end_of_record');
	    }

	    onEnd() {
	        this.contentWriter.close();
	    }
	}

	lcovonly = LcovOnlyReport;
	return lcovonly;
}

var istanbulReports;
var hasRequiredIstanbulReports;

function requireIstanbulReports () {
	if (hasRequiredIstanbulReports) return istanbulReports;
	hasRequiredIstanbulReports = 1;

	istanbulReports = {
	    create(name, cfg) {
	        cfg = cfg || {};
	        let Cons;
	        try {
	            Cons = requireLcovonly();
	        } catch (e) {
	            if (e.code !== 'MODULE_NOT_FOUND') {
	                throw e;
	            }

	            Cons = commonjsRequire(name);
	        }

	        return new Cons(cfg);
	    }
	};
	return istanbulReports;
}

/*
* Copyright Node.js contributors. All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to
* deal in the Software without restriction, including without limitation the
* rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
* sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
* IN THE SOFTWARE.
*/

var sourceMapFromFile_1;
var hasRequiredSourceMapFromFile;

function requireSourceMapFromFile () {
	if (hasRequiredSourceMapFromFile) return sourceMapFromFile_1;
	hasRequiredSourceMapFromFile = 1;
	// TODO(bcoe): this logic is ported from Node.js' internal source map
	// helpers:
	// https://github.com/nodejs/node/blob/master/lib/internal/source_map/source_map_cache.js
	// we should to upstream and downstream fixes.

	const { readFileSync } = require$$0$1;
	const { fileURLToPath, pathToFileURL } = require$$1$3;
	const util = require$$2$2;
	const debuglog = util.debuglog('c8');

	/**
	 * Extract the sourcemap url from a source file
	 * reference: https://sourcemaps.info/spec.html
	 * @param {String} file - compilation target file
	 * @returns {String} full path to source map file
	 * @private
	 */
	function getSourceMapFromFile (filename) {
	  const fileBody = readFileSync(filename).toString();
	  const sourceMapLineRE = /\/[*/]#\s+sourceMappingURL=(?<sourceMappingURL>[^\s]+)/;
	  const results = fileBody.match(sourceMapLineRE);
	  if (results !== null) {
	    const sourceMappingURL = results.groups.sourceMappingURL;
	    const sourceMap = dataFromUrl(pathToFileURL(filename), sourceMappingURL);
	    return sourceMap
	  } else {
	    return null
	  }
	}

	function dataFromUrl (sourceURL, sourceMappingURL) {
	  try {
	    const url = new URL(sourceMappingURL);
	    switch (url.protocol) {
	      case 'data:':
	        return sourceMapFromDataUrl(url.pathname)
	      default:
	        return null
	    }
	  } catch (err) {
	    debuglog(err);
	    // If no scheme is present, we assume we are dealing with a file path.
	    const mapURL = new URL(sourceMappingURL, sourceURL).href;
	    return sourceMapFromFile(mapURL)
	  }
	}

	function sourceMapFromFile (mapURL) {
	  try {
	    const content = readFileSync(fileURLToPath(mapURL), 'utf8');
	    return JSON.parse(content)
	  } catch (err) {
	    debuglog(err);
	    return null
	  }
	}

	// data:[<mediatype>][;base64],<data> see:
	// https://tools.ietf.org/html/rfc2397#section-2
	function sourceMapFromDataUrl (url) {
	  const { 0: format, 1: data } = url.split(',');
	  const splitFormat = format.split(';');
	  const contentType = splitFormat[0];
	  const base64 = splitFormat[splitFormat.length - 1] === 'base64';
	  if (contentType === 'application/json') {
	    const decodedData = base64 ? Buffer.from(data, 'base64').toString('utf8') : data;
	    try {
	      return JSON.parse(decodedData)
	    } catch (err) {
	      debuglog(err);
	      return null
	    }
	  } else {
	    debuglog(`unexpected content-type ${contentType}`);
	    return null
	  }
	}

	sourceMapFromFile_1 = getSourceMapFromFile;
	return sourceMapFromFile_1;
}

var convertSourceMap = {};

var hasRequiredConvertSourceMap;

function requireConvertSourceMap () {
	if (hasRequiredConvertSourceMap) return convertSourceMap;
	hasRequiredConvertSourceMap = 1;
	(function (exports) {

		Object.defineProperty(exports, 'commentRegex', {
		  get: function getCommentRegex () {
		    // Groups: 1: media type, 2: MIME type, 3: charset, 4: encoding, 5: data.
		    return /^\s*?\/[\/\*][@#]\s+?sourceMappingURL=data:(((?:application|text)\/json)(?:;charset=([^;,]+?)?)?)?(?:;(base64))?,(.*?)$/mg;
		  }
		});


		Object.defineProperty(exports, 'mapFileCommentRegex', {
		  get: function getMapFileCommentRegex () {
		    // Matches sourceMappingURL in either // or /* comment styles.
		    return /(?:\/\/[@#][ \t]+?sourceMappingURL=([^\s'"`]+?)[ \t]*?$)|(?:\/\*[@#][ \t]+sourceMappingURL=([^*]+?)[ \t]*?(?:\*\/){1}[ \t]*?$)/mg;
		  }
		});

		var decodeBase64;
		if (typeof Buffer !== 'undefined') {
		  if (typeof Buffer.from === 'function') {
		    decodeBase64 = decodeBase64WithBufferFrom;
		  } else {
		    decodeBase64 = decodeBase64WithNewBuffer;
		  }
		} else {
		  decodeBase64 = decodeBase64WithAtob;
		}

		function decodeBase64WithBufferFrom(base64) {
		  return Buffer.from(base64, 'base64').toString();
		}

		function decodeBase64WithNewBuffer(base64) {
		  if (typeof value === 'number') {
		    throw new TypeError('The value to decode must not be of type number.');
		  }
		  return new Buffer(base64, 'base64').toString();
		}

		function decodeBase64WithAtob(base64) {
		  return decodeURIComponent(escape(atob(base64)));
		}

		function stripComment(sm) {
		  return sm.split(',').pop();
		}

		function readFromFileMap(sm, read) {
		  var r = exports.mapFileCommentRegex.exec(sm);
		  // for some odd reason //# .. captures in 1 and /* .. */ in 2
		  var filename = r[1] || r[2];

		  try {
		    var sm = read(filename);
		    if (sm != null && typeof sm.catch === 'function') {
		      return sm.catch(throwError);
		    } else {
		      return sm;
		    }
		  } catch (e) {
		    throwError(e);
		  }

		  function throwError(e) {
		    throw new Error('An error occurred while trying to read the map file at ' + filename + '\n' + e.stack);
		  }
		}

		function Converter (sm, opts) {
		  opts = opts || {};

		  if (opts.hasComment) {
		    sm = stripComment(sm);
		  }

		  if (opts.encoding === 'base64') {
		    sm = decodeBase64(sm);
		  } else if (opts.encoding === 'uri') {
		    sm = decodeURIComponent(sm);
		  }

		  if (opts.isJSON || opts.encoding) {
		    sm = JSON.parse(sm);
		  }

		  this.sourcemap = sm;
		}

		Converter.prototype.toJSON = function (space) {
		  return JSON.stringify(this.sourcemap, null, space);
		};

		if (typeof Buffer !== 'undefined') {
		  if (typeof Buffer.from === 'function') {
		    Converter.prototype.toBase64 = encodeBase64WithBufferFrom;
		  } else {
		    Converter.prototype.toBase64 = encodeBase64WithNewBuffer;
		  }
		} else {
		  Converter.prototype.toBase64 = encodeBase64WithBtoa;
		}

		function encodeBase64WithBufferFrom() {
		  var json = this.toJSON();
		  return Buffer.from(json, 'utf8').toString('base64');
		}

		function encodeBase64WithNewBuffer() {
		  var json = this.toJSON();
		  if (typeof json === 'number') {
		    throw new TypeError('The json to encode must not be of type number.');
		  }
		  return new Buffer(json, 'utf8').toString('base64');
		}

		function encodeBase64WithBtoa() {
		  var json = this.toJSON();
		  return btoa(unescape(encodeURIComponent(json)));
		}

		Converter.prototype.toURI = function () {
		  var json = this.toJSON();
		  return encodeURIComponent(json);
		};

		Converter.prototype.toComment = function (options) {
		  var encoding, content, data;
		  if (options != null && options.encoding === 'uri') {
		    encoding = '';
		    content = this.toURI();
		  } else {
		    encoding = ';base64';
		    content = this.toBase64();
		  }
		  data = 'sourceMappingURL=data:application/json;charset=utf-8' + encoding + ',' + content;
		  return options != null && options.multiline ? '/*# ' + data + ' */' : '//# ' + data;
		};

		// returns copy instead of original
		Converter.prototype.toObject = function () {
		  return JSON.parse(this.toJSON());
		};

		Converter.prototype.addProperty = function (key, value) {
		  if (this.sourcemap.hasOwnProperty(key)) throw new Error('property "' + key + '" already exists on the sourcemap, use set property instead');
		  return this.setProperty(key, value);
		};

		Converter.prototype.setProperty = function (key, value) {
		  this.sourcemap[key] = value;
		  return this;
		};

		Converter.prototype.getProperty = function (key) {
		  return this.sourcemap[key];
		};

		exports.fromObject = function (obj) {
		  return new Converter(obj);
		};

		exports.fromJSON = function (json) {
		  return new Converter(json, { isJSON: true });
		};

		exports.fromURI = function (uri) {
		  return new Converter(uri, { encoding: 'uri' });
		};

		exports.fromBase64 = function (base64) {
		  return new Converter(base64, { encoding: 'base64' });
		};

		exports.fromComment = function (comment) {
		  var m, encoding;
		  comment = comment
		    .replace(/^\/\*/g, '//')
		    .replace(/\*\/$/g, '');
		  m = exports.commentRegex.exec(comment);
		  encoding = m && m[4] || 'uri';
		  return new Converter(comment, { encoding: encoding, hasComment: true });
		};

		function makeConverter(sm) {
		  return new Converter(sm, { isJSON: true });
		}

		exports.fromMapFileComment = function (comment, read) {
		  if (typeof read === 'string') {
		    throw new Error(
		      'String directory paths are no longer supported with `fromMapFileComment`\n' +
		      'Please review the Upgrading documentation at https://github.com/thlorenz/convert-source-map#upgrading'
		    )
		  }

		  var sm = readFromFileMap(comment, read);
		  if (sm != null && typeof sm.then === 'function') {
		    return sm.then(makeConverter);
		  } else {
		    return makeConverter(sm);
		  }
		};

		// Finds last sourcemap comment in file or returns null if none was found
		exports.fromSource = function (content) {
		  var m = content.match(exports.commentRegex);
		  return m ? exports.fromComment(m.pop()) : null;
		};

		// Finds last sourcemap comment in file or returns null if none was found
		exports.fromMapFileSource = function (content, read) {
		  if (typeof read === 'string') {
		    throw new Error(
		      'String directory paths are no longer supported with `fromMapFileSource`\n' +
		      'Please review the Upgrading documentation at https://github.com/thlorenz/convert-source-map#upgrading'
		    )
		  }
		  var m = content.match(exports.mapFileCommentRegex);
		  return m ? exports.fromMapFileComment(m.pop(), read) : null;
		};

		exports.removeComments = function (src) {
		  return src.replace(exports.commentRegex, '');
		};

		exports.removeMapFileComments = function (src) {
		  return src.replace(exports.mapFileCommentRegex, '');
		};

		exports.generateMapFileComment = function (file, options) {
		  var data = 'sourceMappingURL=' + file;
		  return options && options.multiline ? '/*# ' + data + ' */' : '//# ' + data;
		}; 
	} (convertSourceMap));
	return convertSourceMap;
}

var branch;
var hasRequiredBranch;

function requireBranch () {
	if (hasRequiredBranch) return branch;
	hasRequiredBranch = 1;
	branch = class CovBranch {
	  constructor (startLine, startCol, endLine, endCol, count) {
	    this.startLine = startLine;
	    this.startCol = startCol;
	    this.endLine = endLine;
	    this.endCol = endCol;
	    this.count = count;
	  }

	  toIstanbul () {
	    const location = {
	      start: {
	        line: this.startLine,
	        column: this.startCol
	      },
	      end: {
	        line: this.endLine,
	        column: this.endCol
	      }
	    };
	    return {
	      type: 'branch',
	      line: this.startLine,
	      loc: location,
	      locations: [Object.assign({}, location)]
	    }
	  }
	};
	return branch;
}

var _function;
var hasRequired_function;

function require_function () {
	if (hasRequired_function) return _function;
	hasRequired_function = 1;
	_function = class CovFunction {
	  constructor (name, startLine, startCol, endLine, endCol, count) {
	    this.name = name;
	    this.startLine = startLine;
	    this.startCol = startCol;
	    this.endLine = endLine;
	    this.endCol = endCol;
	    this.count = count;
	  }

	  toIstanbul () {
	    const loc = {
	      start: {
	        line: this.startLine,
	        column: this.startCol
	      },
	      end: {
	        line: this.endLine,
	        column: this.endCol
	      }
	    };
	    return {
	      name: this.name,
	      decl: loc,
	      loc,
	      line: this.startLine
	    }
	  }
	};
	return _function;
}

var line;
var hasRequiredLine;

function requireLine () {
	if (hasRequiredLine) return line;
	hasRequiredLine = 1;
	line = class CovLine {
	  constructor (line, startCol, lineStr) {
	    this.line = line;
	    // note that startCol and endCol are absolute positions
	    // within a file, not relative to the line.
	    this.startCol = startCol;

	    // the line length itself does not include the newline characters,
	    // these are however taken into account when enumerating absolute offset.
	    const matchedNewLineChar = lineStr.match(/\r?\n$/u);
	    const newLineLength = matchedNewLineChar ? matchedNewLineChar[0].length : 0;
	    this.endCol = startCol + lineStr.length - newLineLength;

	    // we start with all lines having been executed, and work
	    // backwards zeroing out lines based on V8 output.
	    this.count = 1;

	    // set by source.js during parsing, if /* c8 ignore next */ is found.
	    this.ignore = false;
	  }

	  toIstanbul () {
	    return {
	      start: {
	        line: this.line,
	        column: 0
	      },
	      end: {
	        line: this.line,
	        column: this.endCol - this.startCol
	      }
	    }
	  }
	};
	return line;
}

var range = {};

/**
 * ...something resembling a binary search, to find the lowest line within the range.
 * And then you could break as soon as the line is longer than the range...
 */

var hasRequiredRange;

function requireRange () {
	if (hasRequiredRange) return range;
	hasRequiredRange = 1;
	range.sliceRange = (lines, startCol, endCol, inclusive = false) => {
	  let start = 0;
	  let end = lines.length;

	  if (inclusive) {
	    // I consider this a temporary solution until I find an alternaive way to fix the "off by one issue"
	    --startCol;
	  }

	  while (start < end) {
	    let mid = (start + end) >> 1;
	    if (startCol >= lines[mid].endCol) {
	      start = mid + 1;
	    } else if (endCol < lines[mid].startCol) {
	      end = mid - 1;
	    } else {
	      end = mid;
	      while (mid >= 0 && startCol < lines[mid].endCol && endCol >= lines[mid].startCol) {
	        --mid;
	      }
	      start = mid + 1;
	      break
	    }
	  }

	  while (end < lines.length && startCol < lines[end].endCol && endCol >= lines[end].startCol) {
	    ++end;
	  }

	  return lines.slice(start, end)
	};
	return range;
}

var traceMapping_umd$1 = {exports: {}};

var resolveUri_umd$1 = {exports: {}};

var resolveUri_umd = resolveUri_umd$1.exports;

var hasRequiredResolveUri_umd;

function requireResolveUri_umd () {
	if (hasRequiredResolveUri_umd) return resolveUri_umd$1.exports;
	hasRequiredResolveUri_umd = 1;
	(function (module, exports) {
		(function (global, factory) {
		    module.exports = factory() ;
		})(resolveUri_umd, (function () {
		    // Matches the scheme of a URL, eg "http://"
		    const schemeRegex = /^[\w+.-]+:\/\//;
		    /**
		     * Matches the parts of a URL:
		     * 1. Scheme, including ":", guaranteed.
		     * 2. User/password, including "@", optional.
		     * 3. Host, guaranteed.
		     * 4. Port, including ":", optional.
		     * 5. Path, including "/", optional.
		     * 6. Query, including "?", optional.
		     * 7. Hash, including "#", optional.
		     */
		    const urlRegex = /^([\w+.-]+:)\/\/([^@/#?]*@)?([^:/#?]*)(:\d+)?(\/[^#?]*)?(\?[^#]*)?(#.*)?/;
		    /**
		     * File URLs are weird. They dont' need the regular `//` in the scheme, they may or may not start
		     * with a leading `/`, they can have a domain (but only if they don't start with a Windows drive).
		     *
		     * 1. Host, optional.
		     * 2. Path, which may include "/", guaranteed.
		     * 3. Query, including "?", optional.
		     * 4. Hash, including "#", optional.
		     */
		    const fileRegex = /^file:(?:\/\/((?![a-z]:)[^/#?]*)?)?(\/?[^#?]*)(\?[^#]*)?(#.*)?/i;
		    function isAbsoluteUrl(input) {
		        return schemeRegex.test(input);
		    }
		    function isSchemeRelativeUrl(input) {
		        return input.startsWith('//');
		    }
		    function isAbsolutePath(input) {
		        return input.startsWith('/');
		    }
		    function isFileUrl(input) {
		        return input.startsWith('file:');
		    }
		    function isRelative(input) {
		        return /^[.?#]/.test(input);
		    }
		    function parseAbsoluteUrl(input) {
		        const match = urlRegex.exec(input);
		        return makeUrl(match[1], match[2] || '', match[3], match[4] || '', match[5] || '/', match[6] || '', match[7] || '');
		    }
		    function parseFileUrl(input) {
		        const match = fileRegex.exec(input);
		        const path = match[2];
		        return makeUrl('file:', '', match[1] || '', '', isAbsolutePath(path) ? path : '/' + path, match[3] || '', match[4] || '');
		    }
		    function makeUrl(scheme, user, host, port, path, query, hash) {
		        return {
		            scheme,
		            user,
		            host,
		            port,
		            path,
		            query,
		            hash,
		            type: 7 /* Absolute */,
		        };
		    }
		    function parseUrl(input) {
		        if (isSchemeRelativeUrl(input)) {
		            const url = parseAbsoluteUrl('http:' + input);
		            url.scheme = '';
		            url.type = 6 /* SchemeRelative */;
		            return url;
		        }
		        if (isAbsolutePath(input)) {
		            const url = parseAbsoluteUrl('http://foo.com' + input);
		            url.scheme = '';
		            url.host = '';
		            url.type = 5 /* AbsolutePath */;
		            return url;
		        }
		        if (isFileUrl(input))
		            return parseFileUrl(input);
		        if (isAbsoluteUrl(input))
		            return parseAbsoluteUrl(input);
		        const url = parseAbsoluteUrl('http://foo.com/' + input);
		        url.scheme = '';
		        url.host = '';
		        url.type = input
		            ? input.startsWith('?')
		                ? 3 /* Query */
		                : input.startsWith('#')
		                    ? 2 /* Hash */
		                    : 4 /* RelativePath */
		            : 1 /* Empty */;
		        return url;
		    }
		    function stripPathFilename(path) {
		        // If a path ends with a parent directory "..", then it's a relative path with excess parent
		        // paths. It's not a file, so we can't strip it.
		        if (path.endsWith('/..'))
		            return path;
		        const index = path.lastIndexOf('/');
		        return path.slice(0, index + 1);
		    }
		    function mergePaths(url, base) {
		        normalizePath(base, base.type);
		        // If the path is just a "/", then it was an empty path to begin with (remember, we're a relative
		        // path).
		        if (url.path === '/') {
		            url.path = base.path;
		        }
		        else {
		            // Resolution happens relative to the base path's directory, not the file.
		            url.path = stripPathFilename(base.path) + url.path;
		        }
		    }
		    /**
		     * The path can have empty directories "//", unneeded parents "foo/..", or current directory
		     * "foo/.". We need to normalize to a standard representation.
		     */
		    function normalizePath(url, type) {
		        const rel = type <= 4 /* RelativePath */;
		        const pieces = url.path.split('/');
		        // We need to preserve the first piece always, so that we output a leading slash. The item at
		        // pieces[0] is an empty string.
		        let pointer = 1;
		        // Positive is the number of real directories we've output, used for popping a parent directory.
		        // Eg, "foo/bar/.." will have a positive 2, and we can decrement to be left with just "foo".
		        let positive = 0;
		        // We need to keep a trailing slash if we encounter an empty directory (eg, splitting "foo/" will
		        // generate `["foo", ""]` pieces). And, if we pop a parent directory. But once we encounter a
		        // real directory, we won't need to append, unless the other conditions happen again.
		        let addTrailingSlash = false;
		        for (let i = 1; i < pieces.length; i++) {
		            const piece = pieces[i];
		            // An empty directory, could be a trailing slash, or just a double "//" in the path.
		            if (!piece) {
		                addTrailingSlash = true;
		                continue;
		            }
		            // If we encounter a real directory, then we don't need to append anymore.
		            addTrailingSlash = false;
		            // A current directory, which we can always drop.
		            if (piece === '.')
		                continue;
		            // A parent directory, we need to see if there are any real directories we can pop. Else, we
		            // have an excess of parents, and we'll need to keep the "..".
		            if (piece === '..') {
		                if (positive) {
		                    addTrailingSlash = true;
		                    positive--;
		                    pointer--;
		                }
		                else if (rel) {
		                    // If we're in a relativePath, then we need to keep the excess parents. Else, in an absolute
		                    // URL, protocol relative URL, or an absolute path, we don't need to keep excess.
		                    pieces[pointer++] = piece;
		                }
		                continue;
		            }
		            // We've encountered a real directory. Move it to the next insertion pointer, which accounts for
		            // any popped or dropped directories.
		            pieces[pointer++] = piece;
		            positive++;
		        }
		        let path = '';
		        for (let i = 1; i < pointer; i++) {
		            path += '/' + pieces[i];
		        }
		        if (!path || (addTrailingSlash && !path.endsWith('/..'))) {
		            path += '/';
		        }
		        url.path = path;
		    }
		    /**
		     * Attempts to resolve `input` URL/path relative to `base`.
		     */
		    function resolve(input, base) {
		        if (!input && !base)
		            return '';
		        const url = parseUrl(input);
		        let inputType = url.type;
		        if (base && inputType !== 7 /* Absolute */) {
		            const baseUrl = parseUrl(base);
		            const baseType = baseUrl.type;
		            switch (inputType) {
		                case 1 /* Empty */:
		                    url.hash = baseUrl.hash;
		                // fall through
		                case 2 /* Hash */:
		                    url.query = baseUrl.query;
		                // fall through
		                case 3 /* Query */:
		                case 4 /* RelativePath */:
		                    mergePaths(url, baseUrl);
		                // fall through
		                case 5 /* AbsolutePath */:
		                    // The host, user, and port are joined, you can't copy one without the others.
		                    url.user = baseUrl.user;
		                    url.host = baseUrl.host;
		                    url.port = baseUrl.port;
		                // fall through
		                case 6 /* SchemeRelative */:
		                    // The input doesn't have a schema at least, so we need to copy at least that over.
		                    url.scheme = baseUrl.scheme;
		            }
		            if (baseType > inputType)
		                inputType = baseType;
		        }
		        normalizePath(url, inputType);
		        const queryHash = url.query + url.hash;
		        switch (inputType) {
		            // This is impossible, because of the empty checks at the start of the function.
		            // case UrlType.Empty:
		            case 2 /* Hash */:
		            case 3 /* Query */:
		                return queryHash;
		            case 4 /* RelativePath */: {
		                // The first char is always a "/", and we need it to be relative.
		                const path = url.path.slice(1);
		                if (!path)
		                    return queryHash || '.';
		                if (isRelative(base || input) && !isRelative(path)) {
		                    // If base started with a leading ".", or there is no base and input started with a ".",
		                    // then we need to ensure that the relative path starts with a ".". We don't know if
		                    // relative starts with a "..", though, so check before prepending.
		                    return './' + path + queryHash;
		                }
		                return path + queryHash;
		            }
		            case 5 /* AbsolutePath */:
		                return url.path + queryHash;
		            default:
		                return url.scheme + '//' + url.user + url.host + url.port + url.path + queryHash;
		        }
		    }

		    return resolve;

		}));
		
	} (resolveUri_umd$1));
	return resolveUri_umd$1.exports;
}

var sourcemapCodec_umd$1 = {exports: {}};

var sourcemapCodec_umd = sourcemapCodec_umd$1.exports;

var hasRequiredSourcemapCodec_umd;

function requireSourcemapCodec_umd () {
	if (hasRequiredSourcemapCodec_umd) return sourcemapCodec_umd$1.exports;
	hasRequiredSourcemapCodec_umd = 1;
	(function (module, exports) {
		(function (global, factory) {
		  {
		    factory(module);
		    module.exports = def(module);
		  }
		  function def(m) { return 'default' in m.exports ? m.exports.default : m.exports; }
		})(sourcemapCodec_umd, (function (module) {
		var __defProp = Object.defineProperty;
		var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
		var __getOwnPropNames = Object.getOwnPropertyNames;
		var __hasOwnProp = Object.prototype.hasOwnProperty;
		var __export = (target, all) => {
		  for (var name in all)
		    __defProp(target, name, { get: all[name], enumerable: true });
		};
		var __copyProps = (to, from, except, desc) => {
		  if (from && typeof from === "object" || typeof from === "function") {
		    for (let key of __getOwnPropNames(from))
		      if (!__hasOwnProp.call(to, key) && key !== except)
		        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
		  }
		  return to;
		};
		var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

		// src/sourcemap-codec.ts
		var sourcemap_codec_exports = {};
		__export(sourcemap_codec_exports, {
		  decode: () => decode,
		  decodeGeneratedRanges: () => decodeGeneratedRanges,
		  decodeOriginalScopes: () => decodeOriginalScopes,
		  encode: () => encode,
		  encodeGeneratedRanges: () => encodeGeneratedRanges,
		  encodeOriginalScopes: () => encodeOriginalScopes
		});
		module.exports = __toCommonJS(sourcemap_codec_exports);

		// src/vlq.ts
		var comma = ",".charCodeAt(0);
		var semicolon = ";".charCodeAt(0);
		var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
		var intToChar = new Uint8Array(64);
		var charToInt = new Uint8Array(128);
		for (let i = 0; i < chars.length; i++) {
		  const c = chars.charCodeAt(i);
		  intToChar[i] = c;
		  charToInt[c] = i;
		}
		function decodeInteger(reader, relative) {
		  let value = 0;
		  let shift = 0;
		  let integer = 0;
		  do {
		    const c = reader.next();
		    integer = charToInt[c];
		    value |= (integer & 31) << shift;
		    shift += 5;
		  } while (integer & 32);
		  const shouldNegate = value & 1;
		  value >>>= 1;
		  if (shouldNegate) {
		    value = -2147483648 | -value;
		  }
		  return relative + value;
		}
		function encodeInteger(builder, num, relative) {
		  let delta = num - relative;
		  delta = delta < 0 ? -delta << 1 | 1 : delta << 1;
		  do {
		    let clamped = delta & 31;
		    delta >>>= 5;
		    if (delta > 0) clamped |= 32;
		    builder.write(intToChar[clamped]);
		  } while (delta > 0);
		  return num;
		}
		function hasMoreVlq(reader, max) {
		  if (reader.pos >= max) return false;
		  return reader.peek() !== comma;
		}

		// src/strings.ts
		var bufLength = 1024 * 16;
		var td = typeof TextDecoder !== "undefined" ? /* @__PURE__ */ new TextDecoder() : typeof Buffer !== "undefined" ? {
		  decode(buf) {
		    const out = Buffer.from(buf.buffer, buf.byteOffset, buf.byteLength);
		    return out.toString();
		  }
		} : {
		  decode(buf) {
		    let out = "";
		    for (let i = 0; i < buf.length; i++) {
		      out += String.fromCharCode(buf[i]);
		    }
		    return out;
		  }
		};
		var StringWriter = class {
		  constructor() {
		    this.pos = 0;
		    this.out = "";
		    this.buffer = new Uint8Array(bufLength);
		  }
		  write(v) {
		    const { buffer } = this;
		    buffer[this.pos++] = v;
		    if (this.pos === bufLength) {
		      this.out += td.decode(buffer);
		      this.pos = 0;
		    }
		  }
		  flush() {
		    const { buffer, out, pos } = this;
		    return pos > 0 ? out + td.decode(buffer.subarray(0, pos)) : out;
		  }
		};
		var StringReader = class {
		  constructor(buffer) {
		    this.pos = 0;
		    this.buffer = buffer;
		  }
		  next() {
		    return this.buffer.charCodeAt(this.pos++);
		  }
		  peek() {
		    return this.buffer.charCodeAt(this.pos);
		  }
		  indexOf(char) {
		    const { buffer, pos } = this;
		    const idx = buffer.indexOf(char, pos);
		    return idx === -1 ? buffer.length : idx;
		  }
		};

		// src/scopes.ts
		var EMPTY = [];
		function decodeOriginalScopes(input) {
		  const { length } = input;
		  const reader = new StringReader(input);
		  const scopes = [];
		  const stack = [];
		  let line = 0;
		  for (; reader.pos < length; reader.pos++) {
		    line = decodeInteger(reader, line);
		    const column = decodeInteger(reader, 0);
		    if (!hasMoreVlq(reader, length)) {
		      const last = stack.pop();
		      last[2] = line;
		      last[3] = column;
		      continue;
		    }
		    const kind = decodeInteger(reader, 0);
		    const fields = decodeInteger(reader, 0);
		    const hasName = fields & 1;
		    const scope = hasName ? [line, column, 0, 0, kind, decodeInteger(reader, 0)] : [line, column, 0, 0, kind];
		    let vars = EMPTY;
		    if (hasMoreVlq(reader, length)) {
		      vars = [];
		      do {
		        const varsIndex = decodeInteger(reader, 0);
		        vars.push(varsIndex);
		      } while (hasMoreVlq(reader, length));
		    }
		    scope.vars = vars;
		    scopes.push(scope);
		    stack.push(scope);
		  }
		  return scopes;
		}
		function encodeOriginalScopes(scopes) {
		  const writer = new StringWriter();
		  for (let i = 0; i < scopes.length; ) {
		    i = _encodeOriginalScopes(scopes, i, writer, [0]);
		  }
		  return writer.flush();
		}
		function _encodeOriginalScopes(scopes, index, writer, state) {
		  const scope = scopes[index];
		  const { 0: startLine, 1: startColumn, 2: endLine, 3: endColumn, 4: kind, vars } = scope;
		  if (index > 0) writer.write(comma);
		  state[0] = encodeInteger(writer, startLine, state[0]);
		  encodeInteger(writer, startColumn, 0);
		  encodeInteger(writer, kind, 0);
		  const fields = scope.length === 6 ? 1 : 0;
		  encodeInteger(writer, fields, 0);
		  if (scope.length === 6) encodeInteger(writer, scope[5], 0);
		  for (const v of vars) {
		    encodeInteger(writer, v, 0);
		  }
		  for (index++; index < scopes.length; ) {
		    const next = scopes[index];
		    const { 0: l, 1: c } = next;
		    if (l > endLine || l === endLine && c >= endColumn) {
		      break;
		    }
		    index = _encodeOriginalScopes(scopes, index, writer, state);
		  }
		  writer.write(comma);
		  state[0] = encodeInteger(writer, endLine, state[0]);
		  encodeInteger(writer, endColumn, 0);
		  return index;
		}
		function decodeGeneratedRanges(input) {
		  const { length } = input;
		  const reader = new StringReader(input);
		  const ranges = [];
		  const stack = [];
		  let genLine = 0;
		  let definitionSourcesIndex = 0;
		  let definitionScopeIndex = 0;
		  let callsiteSourcesIndex = 0;
		  let callsiteLine = 0;
		  let callsiteColumn = 0;
		  let bindingLine = 0;
		  let bindingColumn = 0;
		  do {
		    const semi = reader.indexOf(";");
		    let genColumn = 0;
		    for (; reader.pos < semi; reader.pos++) {
		      genColumn = decodeInteger(reader, genColumn);
		      if (!hasMoreVlq(reader, semi)) {
		        const last = stack.pop();
		        last[2] = genLine;
		        last[3] = genColumn;
		        continue;
		      }
		      const fields = decodeInteger(reader, 0);
		      const hasDefinition = fields & 1;
		      const hasCallsite = fields & 2;
		      const hasScope = fields & 4;
		      let callsite = null;
		      let bindings = EMPTY;
		      let range;
		      if (hasDefinition) {
		        const defSourcesIndex = decodeInteger(reader, definitionSourcesIndex);
		        definitionScopeIndex = decodeInteger(
		          reader,
		          definitionSourcesIndex === defSourcesIndex ? definitionScopeIndex : 0
		        );
		        definitionSourcesIndex = defSourcesIndex;
		        range = [genLine, genColumn, 0, 0, defSourcesIndex, definitionScopeIndex];
		      } else {
		        range = [genLine, genColumn, 0, 0];
		      }
		      range.isScope = !!hasScope;
		      if (hasCallsite) {
		        const prevCsi = callsiteSourcesIndex;
		        const prevLine = callsiteLine;
		        callsiteSourcesIndex = decodeInteger(reader, callsiteSourcesIndex);
		        const sameSource = prevCsi === callsiteSourcesIndex;
		        callsiteLine = decodeInteger(reader, sameSource ? callsiteLine : 0);
		        callsiteColumn = decodeInteger(
		          reader,
		          sameSource && prevLine === callsiteLine ? callsiteColumn : 0
		        );
		        callsite = [callsiteSourcesIndex, callsiteLine, callsiteColumn];
		      }
		      range.callsite = callsite;
		      if (hasMoreVlq(reader, semi)) {
		        bindings = [];
		        do {
		          bindingLine = genLine;
		          bindingColumn = genColumn;
		          const expressionsCount = decodeInteger(reader, 0);
		          let expressionRanges;
		          if (expressionsCount < -1) {
		            expressionRanges = [[decodeInteger(reader, 0)]];
		            for (let i = -1; i > expressionsCount; i--) {
		              const prevBl = bindingLine;
		              bindingLine = decodeInteger(reader, bindingLine);
		              bindingColumn = decodeInteger(reader, bindingLine === prevBl ? bindingColumn : 0);
		              const expression = decodeInteger(reader, 0);
		              expressionRanges.push([expression, bindingLine, bindingColumn]);
		            }
		          } else {
		            expressionRanges = [[expressionsCount]];
		          }
		          bindings.push(expressionRanges);
		        } while (hasMoreVlq(reader, semi));
		      }
		      range.bindings = bindings;
		      ranges.push(range);
		      stack.push(range);
		    }
		    genLine++;
		    reader.pos = semi + 1;
		  } while (reader.pos < length);
		  return ranges;
		}
		function encodeGeneratedRanges(ranges) {
		  if (ranges.length === 0) return "";
		  const writer = new StringWriter();
		  for (let i = 0; i < ranges.length; ) {
		    i = _encodeGeneratedRanges(ranges, i, writer, [0, 0, 0, 0, 0, 0, 0]);
		  }
		  return writer.flush();
		}
		function _encodeGeneratedRanges(ranges, index, writer, state) {
		  const range = ranges[index];
		  const {
		    0: startLine,
		    1: startColumn,
		    2: endLine,
		    3: endColumn,
		    isScope,
		    callsite,
		    bindings
		  } = range;
		  if (state[0] < startLine) {
		    catchupLine(writer, state[0], startLine);
		    state[0] = startLine;
		    state[1] = 0;
		  } else if (index > 0) {
		    writer.write(comma);
		  }
		  state[1] = encodeInteger(writer, range[1], state[1]);
		  const fields = (range.length === 6 ? 1 : 0) | (callsite ? 2 : 0) | (isScope ? 4 : 0);
		  encodeInteger(writer, fields, 0);
		  if (range.length === 6) {
		    const { 4: sourcesIndex, 5: scopesIndex } = range;
		    if (sourcesIndex !== state[2]) {
		      state[3] = 0;
		    }
		    state[2] = encodeInteger(writer, sourcesIndex, state[2]);
		    state[3] = encodeInteger(writer, scopesIndex, state[3]);
		  }
		  if (callsite) {
		    const { 0: sourcesIndex, 1: callLine, 2: callColumn } = range.callsite;
		    if (sourcesIndex !== state[4]) {
		      state[5] = 0;
		      state[6] = 0;
		    } else if (callLine !== state[5]) {
		      state[6] = 0;
		    }
		    state[4] = encodeInteger(writer, sourcesIndex, state[4]);
		    state[5] = encodeInteger(writer, callLine, state[5]);
		    state[6] = encodeInteger(writer, callColumn, state[6]);
		  }
		  if (bindings) {
		    for (const binding of bindings) {
		      if (binding.length > 1) encodeInteger(writer, -binding.length, 0);
		      const expression = binding[0][0];
		      encodeInteger(writer, expression, 0);
		      let bindingStartLine = startLine;
		      let bindingStartColumn = startColumn;
		      for (let i = 1; i < binding.length; i++) {
		        const expRange = binding[i];
		        bindingStartLine = encodeInteger(writer, expRange[1], bindingStartLine);
		        bindingStartColumn = encodeInteger(writer, expRange[2], bindingStartColumn);
		        encodeInteger(writer, expRange[0], 0);
		      }
		    }
		  }
		  for (index++; index < ranges.length; ) {
		    const next = ranges[index];
		    const { 0: l, 1: c } = next;
		    if (l > endLine || l === endLine && c >= endColumn) {
		      break;
		    }
		    index = _encodeGeneratedRanges(ranges, index, writer, state);
		  }
		  if (state[0] < endLine) {
		    catchupLine(writer, state[0], endLine);
		    state[0] = endLine;
		    state[1] = 0;
		  } else {
		    writer.write(comma);
		  }
		  state[1] = encodeInteger(writer, endColumn, state[1]);
		  return index;
		}
		function catchupLine(writer, lastLine, line) {
		  do {
		    writer.write(semicolon);
		  } while (++lastLine < line);
		}

		// src/sourcemap-codec.ts
		function decode(mappings) {
		  const { length } = mappings;
		  const reader = new StringReader(mappings);
		  const decoded = [];
		  let genColumn = 0;
		  let sourcesIndex = 0;
		  let sourceLine = 0;
		  let sourceColumn = 0;
		  let namesIndex = 0;
		  do {
		    const semi = reader.indexOf(";");
		    const line = [];
		    let sorted = true;
		    let lastCol = 0;
		    genColumn = 0;
		    while (reader.pos < semi) {
		      let seg;
		      genColumn = decodeInteger(reader, genColumn);
		      if (genColumn < lastCol) sorted = false;
		      lastCol = genColumn;
		      if (hasMoreVlq(reader, semi)) {
		        sourcesIndex = decodeInteger(reader, sourcesIndex);
		        sourceLine = decodeInteger(reader, sourceLine);
		        sourceColumn = decodeInteger(reader, sourceColumn);
		        if (hasMoreVlq(reader, semi)) {
		          namesIndex = decodeInteger(reader, namesIndex);
		          seg = [genColumn, sourcesIndex, sourceLine, sourceColumn, namesIndex];
		        } else {
		          seg = [genColumn, sourcesIndex, sourceLine, sourceColumn];
		        }
		      } else {
		        seg = [genColumn];
		      }
		      line.push(seg);
		      reader.pos++;
		    }
		    if (!sorted) sort(line);
		    decoded.push(line);
		    reader.pos = semi + 1;
		  } while (reader.pos <= length);
		  return decoded;
		}
		function sort(line) {
		  line.sort(sortComparator);
		}
		function sortComparator(a, b) {
		  return a[0] - b[0];
		}
		function encode(decoded) {
		  const writer = new StringWriter();
		  let sourcesIndex = 0;
		  let sourceLine = 0;
		  let sourceColumn = 0;
		  let namesIndex = 0;
		  for (let i = 0; i < decoded.length; i++) {
		    const line = decoded[i];
		    if (i > 0) writer.write(semicolon);
		    if (line.length === 0) continue;
		    let genColumn = 0;
		    for (let j = 0; j < line.length; j++) {
		      const segment = line[j];
		      if (j > 0) writer.write(comma);
		      genColumn = encodeInteger(writer, segment[0], genColumn);
		      if (segment.length === 1) continue;
		      sourcesIndex = encodeInteger(writer, segment[1], sourcesIndex);
		      sourceLine = encodeInteger(writer, segment[2], sourceLine);
		      sourceColumn = encodeInteger(writer, segment[3], sourceColumn);
		      if (segment.length === 4) continue;
		      namesIndex = encodeInteger(writer, segment[4], namesIndex);
		    }
		  }
		  return writer.flush();
		}
		}));
		
	} (sourcemapCodec_umd$1));
	return sourcemapCodec_umd$1.exports;
}

var traceMapping_umd = traceMapping_umd$1.exports;

var hasRequiredTraceMapping_umd;

function requireTraceMapping_umd () {
	if (hasRequiredTraceMapping_umd) return traceMapping_umd$1.exports;
	hasRequiredTraceMapping_umd = 1;
	(function (module, exports) {
		(function (global, factory) {
		  {
		    factory(module, requireResolveUri_umd(), requireSourcemapCodec_umd());
		    module.exports = def(module);
		  }
		  function def(m) { return 'default' in m.exports ? m.exports.default : m.exports; }
		})(traceMapping_umd, (function (module, require_resolveURI, require_sourcemapCodec) {
		var __create = Object.create;
		var __defProp = Object.defineProperty;
		var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
		var __getOwnPropNames = Object.getOwnPropertyNames;
		var __getProtoOf = Object.getPrototypeOf;
		var __hasOwnProp = Object.prototype.hasOwnProperty;
		var __commonJS = (cb, mod) => function __require() {
		  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
		};
		var __export = (target, all) => {
		  for (var name in all)
		    __defProp(target, name, { get: all[name], enumerable: true });
		};
		var __copyProps = (to, from, except, desc) => {
		  if (from && typeof from === "object" || typeof from === "function") {
		    for (let key of __getOwnPropNames(from))
		      if (!__hasOwnProp.call(to, key) && key !== except)
		        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
		  }
		  return to;
		};
		var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
		  // If the importer is in node compatibility mode or this is not an ESM
		  // file that has been converted to a CommonJS file using a Babel-
		  // compatible transform (i.e. "__esModule" has not been set), then set
		  // "default" to the CommonJS "module.exports" for node compatibility.
		  !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
		  mod
		));
		var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

		// umd:@jridgewell/sourcemap-codec
		var require_sourcemap_codec = __commonJS({
		  "umd:@jridgewell/sourcemap-codec"(exports, module2) {
		    module2.exports = require_sourcemapCodec;
		  }
		});

		// umd:@jridgewell/resolve-uri
		var require_resolve_uri = __commonJS({
		  "umd:@jridgewell/resolve-uri"(exports, module2) {
		    module2.exports = require_resolveURI;
		  }
		});

		// src/trace-mapping.ts
		var trace_mapping_exports = {};
		__export(trace_mapping_exports, {
		  AnyMap: () => FlattenMap,
		  FlattenMap: () => FlattenMap,
		  GREATEST_LOWER_BOUND: () => GREATEST_LOWER_BOUND,
		  LEAST_UPPER_BOUND: () => LEAST_UPPER_BOUND,
		  TraceMap: () => TraceMap,
		  allGeneratedPositionsFor: () => allGeneratedPositionsFor,
		  decodedMap: () => decodedMap,
		  decodedMappings: () => decodedMappings,
		  eachMapping: () => eachMapping,
		  encodedMap: () => encodedMap,
		  encodedMappings: () => encodedMappings,
		  generatedPositionFor: () => generatedPositionFor,
		  isIgnored: () => isIgnored,
		  originalPositionFor: () => originalPositionFor,
		  presortedDecodedMap: () => presortedDecodedMap,
		  sourceContentFor: () => sourceContentFor,
		  traceSegment: () => traceSegment
		});
		module.exports = __toCommonJS(trace_mapping_exports);
		var import_sourcemap_codec = __toESM(require_sourcemap_codec());

		// src/resolve.ts
		var import_resolve_uri = __toESM(require_resolve_uri());

		// src/strip-filename.ts
		function stripFilename(path) {
		  if (!path) return "";
		  const index = path.lastIndexOf("/");
		  return path.slice(0, index + 1);
		}

		// src/resolve.ts
		function resolver(mapUrl, sourceRoot) {
		  const from = stripFilename(mapUrl);
		  const prefix = sourceRoot ? sourceRoot + "/" : "";
		  return (source) => (0, import_resolve_uri.default)(prefix + (source || ""), from);
		}

		// src/sourcemap-segment.ts
		var COLUMN = 0;
		var SOURCES_INDEX = 1;
		var SOURCE_LINE = 2;
		var SOURCE_COLUMN = 3;
		var NAMES_INDEX = 4;
		var REV_GENERATED_LINE = 1;
		var REV_GENERATED_COLUMN = 2;

		// src/sort.ts
		function maybeSort(mappings, owned) {
		  const unsortedIndex = nextUnsortedSegmentLine(mappings, 0);
		  if (unsortedIndex === mappings.length) return mappings;
		  if (!owned) mappings = mappings.slice();
		  for (let i = unsortedIndex; i < mappings.length; i = nextUnsortedSegmentLine(mappings, i + 1)) {
		    mappings[i] = sortSegments(mappings[i], owned);
		  }
		  return mappings;
		}
		function nextUnsortedSegmentLine(mappings, start) {
		  for (let i = start; i < mappings.length; i++) {
		    if (!isSorted(mappings[i])) return i;
		  }
		  return mappings.length;
		}
		function isSorted(line) {
		  for (let j = 1; j < line.length; j++) {
		    if (line[j][COLUMN] < line[j - 1][COLUMN]) {
		      return false;
		    }
		  }
		  return true;
		}
		function sortSegments(line, owned) {
		  if (!owned) line = line.slice();
		  return line.sort(sortComparator);
		}
		function sortComparator(a, b) {
		  return a[COLUMN] - b[COLUMN];
		}

		// src/by-source.ts
		function buildBySources(decoded, memos) {
		  const sources = memos.map(() => []);
		  for (let i = 0; i < decoded.length; i++) {
		    const line = decoded[i];
		    for (let j = 0; j < line.length; j++) {
		      const seg = line[j];
		      if (seg.length === 1) continue;
		      const sourceIndex2 = seg[SOURCES_INDEX];
		      const sourceLine = seg[SOURCE_LINE];
		      const sourceColumn = seg[SOURCE_COLUMN];
		      const source = sources[sourceIndex2];
		      const segs = source[sourceLine] || (source[sourceLine] = []);
		      segs.push([sourceColumn, i, seg[COLUMN]]);
		    }
		  }
		  for (let i = 0; i < sources.length; i++) {
		    const source = sources[i];
		    for (let j = 0; j < source.length; j++) {
		      const line = source[j];
		      if (line) line.sort(sortComparator);
		    }
		  }
		  return sources;
		}

		// src/binary-search.ts
		var found = false;
		function binarySearch(haystack, needle, low, high) {
		  while (low <= high) {
		    const mid = low + (high - low >> 1);
		    const cmp = haystack[mid][COLUMN] - needle;
		    if (cmp === 0) {
		      found = true;
		      return mid;
		    }
		    if (cmp < 0) {
		      low = mid + 1;
		    } else {
		      high = mid - 1;
		    }
		  }
		  found = false;
		  return low - 1;
		}
		function upperBound(haystack, needle, index) {
		  for (let i = index + 1; i < haystack.length; index = i++) {
		    if (haystack[i][COLUMN] !== needle) break;
		  }
		  return index;
		}
		function lowerBound(haystack, needle, index) {
		  for (let i = index - 1; i >= 0; index = i--) {
		    if (haystack[i][COLUMN] !== needle) break;
		  }
		  return index;
		}
		function memoizedState() {
		  return {
		    lastKey: -1,
		    lastNeedle: -1,
		    lastIndex: -1
		  };
		}
		function memoizedBinarySearch(haystack, needle, state, key) {
		  const { lastKey, lastNeedle, lastIndex } = state;
		  let low = 0;
		  let high = haystack.length - 1;
		  if (key === lastKey) {
		    if (needle === lastNeedle) {
		      found = lastIndex !== -1 && haystack[lastIndex][COLUMN] === needle;
		      return lastIndex;
		    }
		    if (needle >= lastNeedle) {
		      low = lastIndex === -1 ? 0 : lastIndex;
		    } else {
		      high = lastIndex;
		    }
		  }
		  state.lastKey = key;
		  state.lastNeedle = needle;
		  return state.lastIndex = binarySearch(haystack, needle, low, high);
		}

		// src/types.ts
		function parse(map) {
		  return typeof map === "string" ? JSON.parse(map) : map;
		}

		// src/flatten-map.ts
		var FlattenMap = function(map, mapUrl) {
		  const parsed = parse(map);
		  if (!("sections" in parsed)) {
		    return new TraceMap(parsed, mapUrl);
		  }
		  const mappings = [];
		  const sources = [];
		  const sourcesContent = [];
		  const names = [];
		  const ignoreList = [];
		  recurse(
		    parsed,
		    mapUrl,
		    mappings,
		    sources,
		    sourcesContent,
		    names,
		    ignoreList,
		    0,
		    0,
		    Infinity,
		    Infinity
		  );
		  const joined = {
		    version: 3,
		    file: parsed.file,
		    names,
		    sources,
		    sourcesContent,
		    mappings,
		    ignoreList
		  };
		  return presortedDecodedMap(joined);
		};
		function recurse(input, mapUrl, mappings, sources, sourcesContent, names, ignoreList, lineOffset, columnOffset, stopLine, stopColumn) {
		  const { sections } = input;
		  for (let i = 0; i < sections.length; i++) {
		    const { map, offset } = sections[i];
		    let sl = stopLine;
		    let sc = stopColumn;
		    if (i + 1 < sections.length) {
		      const nextOffset = sections[i + 1].offset;
		      sl = Math.min(stopLine, lineOffset + nextOffset.line);
		      if (sl === stopLine) {
		        sc = Math.min(stopColumn, columnOffset + nextOffset.column);
		      } else if (sl < stopLine) {
		        sc = columnOffset + nextOffset.column;
		      }
		    }
		    addSection(
		      map,
		      mapUrl,
		      mappings,
		      sources,
		      sourcesContent,
		      names,
		      ignoreList,
		      lineOffset + offset.line,
		      columnOffset + offset.column,
		      sl,
		      sc
		    );
		  }
		}
		function addSection(input, mapUrl, mappings, sources, sourcesContent, names, ignoreList, lineOffset, columnOffset, stopLine, stopColumn) {
		  const parsed = parse(input);
		  if ("sections" in parsed) return recurse(...arguments);
		  const map = new TraceMap(parsed, mapUrl);
		  const sourcesOffset = sources.length;
		  const namesOffset = names.length;
		  const decoded = decodedMappings(map);
		  const { resolvedSources, sourcesContent: contents, ignoreList: ignores } = map;
		  append(sources, resolvedSources);
		  append(names, map.names);
		  if (contents) append(sourcesContent, contents);
		  else for (let i = 0; i < resolvedSources.length; i++) sourcesContent.push(null);
		  if (ignores) for (let i = 0; i < ignores.length; i++) ignoreList.push(ignores[i] + sourcesOffset);
		  for (let i = 0; i < decoded.length; i++) {
		    const lineI = lineOffset + i;
		    if (lineI > stopLine) return;
		    const out = getLine(mappings, lineI);
		    const cOffset = i === 0 ? columnOffset : 0;
		    const line = decoded[i];
		    for (let j = 0; j < line.length; j++) {
		      const seg = line[j];
		      const column = cOffset + seg[COLUMN];
		      if (lineI === stopLine && column >= stopColumn) return;
		      if (seg.length === 1) {
		        out.push([column]);
		        continue;
		      }
		      const sourcesIndex = sourcesOffset + seg[SOURCES_INDEX];
		      const sourceLine = seg[SOURCE_LINE];
		      const sourceColumn = seg[SOURCE_COLUMN];
		      out.push(
		        seg.length === 4 ? [column, sourcesIndex, sourceLine, sourceColumn] : [column, sourcesIndex, sourceLine, sourceColumn, namesOffset + seg[NAMES_INDEX]]
		      );
		    }
		  }
		}
		function append(arr, other) {
		  for (let i = 0; i < other.length; i++) arr.push(other[i]);
		}
		function getLine(arr, index) {
		  for (let i = arr.length; i <= index; i++) arr[i] = [];
		  return arr[index];
		}

		// src/trace-mapping.ts
		var LINE_GTR_ZERO = "`line` must be greater than 0 (lines start at line 1)";
		var COL_GTR_EQ_ZERO = "`column` must be greater than or equal to 0 (columns start at column 0)";
		var LEAST_UPPER_BOUND = -1;
		var GREATEST_LOWER_BOUND = 1;
		var TraceMap = class {
		  constructor(map, mapUrl) {
		    const isString = typeof map === "string";
		    if (!isString && map._decodedMemo) return map;
		    const parsed = parse(map);
		    const { version, file, names, sourceRoot, sources, sourcesContent } = parsed;
		    this.version = version;
		    this.file = file;
		    this.names = names || [];
		    this.sourceRoot = sourceRoot;
		    this.sources = sources;
		    this.sourcesContent = sourcesContent;
		    this.ignoreList = parsed.ignoreList || parsed.x_google_ignoreList || void 0;
		    const resolve = resolver(mapUrl, sourceRoot);
		    this.resolvedSources = sources.map(resolve);
		    const { mappings } = parsed;
		    if (typeof mappings === "string") {
		      this._encoded = mappings;
		      this._decoded = void 0;
		    } else if (Array.isArray(mappings)) {
		      this._encoded = void 0;
		      this._decoded = maybeSort(mappings, isString);
		    } else if (parsed.sections) {
		      throw new Error(`TraceMap passed sectioned source map, please use FlattenMap export instead`);
		    } else {
		      throw new Error(`invalid source map: ${JSON.stringify(parsed)}`);
		    }
		    this._decodedMemo = memoizedState();
		    this._bySources = void 0;
		    this._bySourceMemos = void 0;
		  }
		};
		function cast(map) {
		  return map;
		}
		function encodedMappings(map) {
		  var _a, _b;
		  return (_b = (_a = cast(map))._encoded) != null ? _b : _a._encoded = (0, import_sourcemap_codec.encode)(cast(map)._decoded);
		}
		function decodedMappings(map) {
		  var _a;
		  return (_a = cast(map))._decoded || (_a._decoded = (0, import_sourcemap_codec.decode)(cast(map)._encoded));
		}
		function traceSegment(map, line, column) {
		  const decoded = decodedMappings(map);
		  if (line >= decoded.length) return null;
		  const segments = decoded[line];
		  const index = traceSegmentInternal(
		    segments,
		    cast(map)._decodedMemo,
		    line,
		    column,
		    GREATEST_LOWER_BOUND
		  );
		  return index === -1 ? null : segments[index];
		}
		function originalPositionFor(map, needle) {
		  let { line, column, bias } = needle;
		  line--;
		  if (line < 0) throw new Error(LINE_GTR_ZERO);
		  if (column < 0) throw new Error(COL_GTR_EQ_ZERO);
		  const decoded = decodedMappings(map);
		  if (line >= decoded.length) return OMapping(null, null, null, null);
		  const segments = decoded[line];
		  const index = traceSegmentInternal(
		    segments,
		    cast(map)._decodedMemo,
		    line,
		    column,
		    bias || GREATEST_LOWER_BOUND
		  );
		  if (index === -1) return OMapping(null, null, null, null);
		  const segment = segments[index];
		  if (segment.length === 1) return OMapping(null, null, null, null);
		  const { names, resolvedSources } = map;
		  return OMapping(
		    resolvedSources[segment[SOURCES_INDEX]],
		    segment[SOURCE_LINE] + 1,
		    segment[SOURCE_COLUMN],
		    segment.length === 5 ? names[segment[NAMES_INDEX]] : null
		  );
		}
		function generatedPositionFor(map, needle) {
		  const { source, line, column, bias } = needle;
		  return generatedPosition(map, source, line, column, bias || GREATEST_LOWER_BOUND, false);
		}
		function allGeneratedPositionsFor(map, needle) {
		  const { source, line, column, bias } = needle;
		  return generatedPosition(map, source, line, column, bias || LEAST_UPPER_BOUND, true);
		}
		function eachMapping(map, cb) {
		  const decoded = decodedMappings(map);
		  const { names, resolvedSources } = map;
		  for (let i = 0; i < decoded.length; i++) {
		    const line = decoded[i];
		    for (let j = 0; j < line.length; j++) {
		      const seg = line[j];
		      const generatedLine = i + 1;
		      const generatedColumn = seg[0];
		      let source = null;
		      let originalLine = null;
		      let originalColumn = null;
		      let name = null;
		      if (seg.length !== 1) {
		        source = resolvedSources[seg[1]];
		        originalLine = seg[2] + 1;
		        originalColumn = seg[3];
		      }
		      if (seg.length === 5) name = names[seg[4]];
		      cb({
		        generatedLine,
		        generatedColumn,
		        source,
		        originalLine,
		        originalColumn,
		        name
		      });
		    }
		  }
		}
		function sourceIndex(map, source) {
		  const { sources, resolvedSources } = map;
		  let index = sources.indexOf(source);
		  if (index === -1) index = resolvedSources.indexOf(source);
		  return index;
		}
		function sourceContentFor(map, source) {
		  const { sourcesContent } = map;
		  if (sourcesContent == null) return null;
		  const index = sourceIndex(map, source);
		  return index === -1 ? null : sourcesContent[index];
		}
		function isIgnored(map, source) {
		  const { ignoreList } = map;
		  if (ignoreList == null) return false;
		  const index = sourceIndex(map, source);
		  return index === -1 ? false : ignoreList.includes(index);
		}
		function presortedDecodedMap(map, mapUrl) {
		  const tracer = new TraceMap(clone(map, []), mapUrl);
		  cast(tracer)._decoded = map.mappings;
		  return tracer;
		}
		function decodedMap(map) {
		  return clone(map, decodedMappings(map));
		}
		function encodedMap(map) {
		  return clone(map, encodedMappings(map));
		}
		function clone(map, mappings) {
		  return {
		    version: map.version,
		    file: map.file,
		    names: map.names,
		    sourceRoot: map.sourceRoot,
		    sources: map.sources,
		    sourcesContent: map.sourcesContent,
		    mappings,
		    ignoreList: map.ignoreList || map.x_google_ignoreList
		  };
		}
		function OMapping(source, line, column, name) {
		  return { source, line, column, name };
		}
		function GMapping(line, column) {
		  return { line, column };
		}
		function traceSegmentInternal(segments, memo, line, column, bias) {
		  let index = memoizedBinarySearch(segments, column, memo, line);
		  if (found) {
		    index = (bias === LEAST_UPPER_BOUND ? upperBound : lowerBound)(segments, column, index);
		  } else if (bias === LEAST_UPPER_BOUND) index++;
		  if (index === -1 || index === segments.length) return -1;
		  return index;
		}
		function sliceGeneratedPositions(segments, memo, line, column, bias) {
		  let min = traceSegmentInternal(segments, memo, line, column, GREATEST_LOWER_BOUND);
		  if (!found && bias === LEAST_UPPER_BOUND) min++;
		  if (min === -1 || min === segments.length) return [];
		  const matchedColumn = found ? column : segments[min][COLUMN];
		  if (!found) min = lowerBound(segments, matchedColumn, min);
		  const max = upperBound(segments, matchedColumn, min);
		  const result = [];
		  for (; min <= max; min++) {
		    const segment = segments[min];
		    result.push(GMapping(segment[REV_GENERATED_LINE] + 1, segment[REV_GENERATED_COLUMN]));
		  }
		  return result;
		}
		function generatedPosition(map, source, line, column, bias, all) {
		  var _a, _b;
		  line--;
		  if (line < 0) throw new Error(LINE_GTR_ZERO);
		  if (column < 0) throw new Error(COL_GTR_EQ_ZERO);
		  const { sources, resolvedSources } = map;
		  let sourceIndex2 = sources.indexOf(source);
		  if (sourceIndex2 === -1) sourceIndex2 = resolvedSources.indexOf(source);
		  if (sourceIndex2 === -1) return all ? [] : GMapping(null, null);
		  const bySourceMemos = (_a = cast(map))._bySourceMemos || (_a._bySourceMemos = sources.map(memoizedState));
		  const generated = (_b = cast(map))._bySources || (_b._bySources = buildBySources(decodedMappings(map), bySourceMemos));
		  const segments = generated[sourceIndex2][line];
		  if (segments == null) return all ? [] : GMapping(null, null);
		  const memo = bySourceMemos[sourceIndex2];
		  if (all) return sliceGeneratedPositions(segments, memo, line, column, bias);
		  const index = traceSegmentInternal(segments, memo, line, column, bias);
		  if (index === -1) return GMapping(null, null);
		  const segment = segments[index];
		  return GMapping(segment[REV_GENERATED_LINE] + 1, segment[REV_GENERATED_COLUMN]);
		}
		}));
		
	} (traceMapping_umd$1));
	return traceMapping_umd$1.exports;
}

var source;
var hasRequiredSource;

function requireSource () {
	if (hasRequiredSource) return source;
	hasRequiredSource = 1;
	const CovLine = requireLine();
	const { sliceRange } = requireRange();
	const { originalPositionFor, generatedPositionFor, GREATEST_LOWER_BOUND, LEAST_UPPER_BOUND } = requireTraceMapping_umd();

	source = class CovSource {
	  constructor (sourceRaw, wrapperLength) {
	    sourceRaw = sourceRaw ? sourceRaw.trimEnd() : '';
	    this.lines = [];
	    this.eof = sourceRaw.length;
	    this.shebangLength = getShebangLength(sourceRaw);
	    this.wrapperLength = wrapperLength - this.shebangLength;
	    this._buildLines(sourceRaw);
	  }

	  _buildLines (source) {
	    let position = 0;
	    let ignoreCount = 0;
	    let ignoreAll = false;
	    for (const [i, lineStr] of source.split(/(?<=\r?\n)/u).entries()) {
	      const line = new CovLine(i + 1, position, lineStr);
	      if (ignoreCount > 0) {
	        line.ignore = true;
	        ignoreCount--;
	      } else if (ignoreAll) {
	        line.ignore = true;
	      }
	      this.lines.push(line);
	      position += lineStr.length;

	      const ignoreToken = this._parseIgnore(lineStr);
	      if (!ignoreToken) continue

	      line.ignore = true;
	      if (ignoreToken.count !== undefined) {
	        ignoreCount = ignoreToken.count;
	      }
	      if (ignoreToken.start || ignoreToken.stop) {
	        ignoreAll = ignoreToken.start;
	        ignoreCount = 0;
	      }
	    }
	  }

	  /**
	   * Parses for comments:
	   *    c8 ignore next
	   *    c8 ignore next 3
	   *    c8 ignore start
	   *    c8 ignore stop
	   * And equivalent ones for v8, e.g. v8 ignore next.
	   * @param {string} lineStr
	   * @return {{count?: number, start?: boolean, stop?: boolean}|undefined}
	   */
	  _parseIgnore (lineStr) {
	    const testIgnoreNextLines = lineStr.match(/^\W*\/\* (?:[cv]8|node:coverage) ignore next (?<count>[0-9]+)/);
	    if (testIgnoreNextLines) {
	      return { count: Number(testIgnoreNextLines.groups.count) }
	    }

	    // Check if comment is on its own line.
	    if (lineStr.match(/^\W*\/\* (?:[cv]8|node:coverage) ignore next/)) {
	      return { count: 1 }
	    }

	    if (lineStr.match(/\/\* ([cv]8|node:coverage) ignore next/)) {
	      // Won't ignore successive lines, but the current line will be ignored.
	      return { count: 0 }
	    }

	    const testIgnoreStartStop = lineStr.match(/\/\* [c|v]8 ignore (?<mode>start|stop)/);
	    if (testIgnoreStartStop) {
	      if (testIgnoreStartStop.groups.mode === 'start') return { start: true }
	      if (testIgnoreStartStop.groups.mode === 'stop') return { stop: true }
	    }

	    const testNodeIgnoreStartStop = lineStr.match(/\/\* node:coverage (?<mode>enable|disable)/);
	    if (testNodeIgnoreStartStop) {
	      if (testNodeIgnoreStartStop.groups.mode === 'disable') return { start: true }
	      if (testNodeIgnoreStartStop.groups.mode === 'enable') return { stop: true }
	    }
	  }

	  // given a start column and end column in absolute offsets within
	  // a source file (0 - EOF), returns the relative line column positions.
	  offsetToOriginalRelative (sourceMap, startCol, endCol) {
	    const lines = sliceRange(this.lines, startCol, endCol, true);
	    if (!lines.length) return {}

	    const start = originalPositionTryBoth(
	      sourceMap,
	      lines[0].line,
	      Math.max(0, startCol - lines[0].startCol)
	    );
	    if (!(start && start.source)) {
	      return {}
	    }

	    let end = originalEndPositionFor(
	      sourceMap,
	      lines[lines.length - 1].line,
	      endCol - lines[lines.length - 1].startCol
	    );
	    if (!(end && end.source)) {
	      return {}
	    }

	    if (start.source !== end.source) {
	      return {}
	    }

	    if (start.line === end.line && start.column === end.column) {
	      end = originalPositionFor(sourceMap, {
	        line: lines[lines.length - 1].line,
	        column: endCol - lines[lines.length - 1].startCol,
	        bias: LEAST_UPPER_BOUND
	      });
	      end.column -= 1;
	    }

	    return {
	      source: start.source,
	      startLine: start.line,
	      relStartCol: start.column,
	      endLine: end.line,
	      relEndCol: end.column
	    }
	  }

	  relativeToOffset (line, relCol) {
	    line = Math.max(line, 1);
	    if (this.lines[line - 1] === undefined) return this.eof
	    return Math.min(this.lines[line - 1].startCol + relCol, this.lines[line - 1].endCol)
	  }
	};

	// this implementation is pulled over from istanbul-lib-sourcemap:
	// https://github.com/istanbuljs/istanbuljs/blob/master/packages/istanbul-lib-source-maps/lib/get-mapping.js
	//
	/**
	 * AST ranges are inclusive for start positions and exclusive for end positions.
	 * Source maps are also logically ranges over text, though interacting with
	 * them is generally achieved by working with explicit positions.
	 *
	 * When finding the _end_ location of an AST item, the range behavior is
	 * important because what we're asking for is the _end_ of whatever range
	 * corresponds to the end location we seek.
	 *
	 * This boils down to the following steps, conceptually, though the source-map
	 * library doesn't expose primitives to do this nicely:
	 *
	 * 1. Find the range on the generated file that ends at, or exclusively
	 *    contains the end position of the AST node.
	 * 2. Find the range on the original file that corresponds to
	 *    that generated range.
	 * 3. Find the _end_ location of that original range.
	 */
	function originalEndPositionFor (sourceMap, line, column) {
	  // Given the generated location, find the original location of the mapping
	  // that corresponds to a range on the generated file that overlaps the
	  // generated file end location. Note however that this position on its
	  // own is not useful because it is the position of the _start_ of the range
	  // on the original file, and we want the _end_ of the range.
	  const beforeEndMapping = originalPositionTryBoth(
	    sourceMap,
	    line,
	    Math.max(column - 1, 1)
	  );

	  if (beforeEndMapping.source === null) {
	    return null
	  }

	  // Convert that original position back to a generated one, with a bump
	  // to the right, and a rightward bias. Since 'generatedPositionFor' searches
	  // for mappings in the original-order sorted list, this will find the
	  // mapping that corresponds to the one immediately after the
	  // beforeEndMapping mapping.
	  const afterEndMapping = generatedPositionFor(sourceMap, {
	    source: beforeEndMapping.source,
	    line: beforeEndMapping.line,
	    column: beforeEndMapping.column + 1,
	    bias: LEAST_UPPER_BOUND
	  });
	  if (
	  // If this is null, it means that we've hit the end of the file,
	  // so we can use Infinity as the end column.
	    afterEndMapping.line === null ||
	      // If these don't match, it means that the call to
	      // 'generatedPositionFor' didn't find any other original mappings on
	      // the line we gave, so consider the binding to extend to infinity.
	      originalPositionFor(sourceMap, afterEndMapping).line !==
	          beforeEndMapping.line
	  ) {
	    return {
	      source: beforeEndMapping.source,
	      line: beforeEndMapping.line,
	      column: Infinity
	    }
	  }

	  // Convert the end mapping into the real original position.
	  return originalPositionFor(sourceMap, afterEndMapping)
	}

	function originalPositionTryBoth (sourceMap, line, column) {
	  let original = originalPositionFor(sourceMap, {
	    line,
	    column,
	    bias: GREATEST_LOWER_BOUND
	  });
	  if (original.line === null) {
	    original = originalPositionFor(sourceMap, {
	      line,
	      column,
	      bias: LEAST_UPPER_BOUND
	    });
	  }
	  // The source maps generated by https://github.com/istanbuljs/istanbuljs
	  // (using @babel/core 7.7.5) have behavior, such that a mapping
	  // mid-way through a line maps to an earlier line than a mapping
	  // at position 0. Using the line at positon 0 seems to provide better reports:
	  //
	  //     if (true) {
	  //        cov_y5divc6zu().b[1][0]++;
	  //        cov_y5divc6zu().s[3]++;
	  //        console.info('reachable');
	  //     }  else { ... }
	  //  ^  ^
	  // l5  l3
	  const min = originalPositionFor(sourceMap, {
	    line,
	    column: 0,
	    bias: GREATEST_LOWER_BOUND
	  });
	  if (min.line > original.line) {
	    original = min;
	  }
	  return original
	}

	// Not required since Node 12, see: https://github.com/nodejs/node/pull/27375
	const isPreNode12 = /^v1[0-1]\./u.test(process.version);
	function getShebangLength (source) {
	  /* c8 ignore start - platform-specific */
	  if (isPreNode12 && source.indexOf('#!') === 0) {
	    const match = source.match(/(?<shebang>#!.*)/);
	    if (match) {
	      return match.groups.shebang.length
	    }
	  } else {
	  /* c8 ignore stop - platform-specific */
	    return 0
	  }
	}
	return source;
}

var engines = {
	node: ">=10.12.0"
};
var require$$9 = {
	engines: engines};

var v8ToIstanbul$1;
var hasRequiredV8ToIstanbul$1;

function requireV8ToIstanbul$1 () {
	if (hasRequiredV8ToIstanbul$1) return v8ToIstanbul$1;
	hasRequiredV8ToIstanbul$1 = 1;
	const assert = require$$0$4;
	const convertSourceMap = requireConvertSourceMap();
	const util = require$$2$2;
	const debuglog = util.debuglog('c8');
	const { dirname, isAbsolute, join, resolve } = require$$0$2;
	const { fileURLToPath } = require$$1$3;
	const CovBranch = requireBranch();
	const CovFunction = require_function();
	const CovSource = requireSource();
	const { sliceRange } = requireRange();
	const compatError = Error(`requires Node.js ${require$$9.engines.node}`);
	const { readFileSync } = require$$0$1;
	let readFile = () => { throw compatError };
	try {
	  readFile = require('fs').promises.readFile;
	} catch (_err) {
	  // most likely we're on an older version of Node.js.
	}
	const { TraceMap } = requireTraceMapping_umd();
	const isOlderNode10 = /^v10\.(([0-9]\.)|(1[0-5]\.))/u.test(process.version);
	const isNode8 = /^v8\./.test(process.version);

	// Injected when Node.js is loading script into isolate pre Node 10.16.x.
	// see: https://github.com/nodejs/node/pull/21573.
	const cjsWrapperLength = isOlderNode10 ? require$$12.wrapper[0].length : 0;

	v8ToIstanbul$1 = class V8ToIstanbul {
	  constructor (scriptPath, wrapperLength, sources, excludePath) {
	    assert(typeof scriptPath === 'string', 'scriptPath must be a string');
	    assert(!isNode8, 'This module does not support node 8 or lower, please upgrade to node 10');
	    this.path = parsePath(scriptPath);
	    this.wrapperLength = wrapperLength === undefined ? cjsWrapperLength : wrapperLength;
	    this.excludePath = excludePath || (() => false);
	    this.sources = sources || {};
	    this.generatedLines = [];
	    this.branches = {};
	    this.functions = {};
	    this.covSources = [];
	    this.rawSourceMap = undefined;
	    this.sourceMap = undefined;
	    this.sourceTranspiled = undefined;
	    // Indicate that this report was generated with placeholder data from
	    // running --all:
	    this.all = false;
	  }

	  async load () {
	    const rawSource = this.sources.source || await readFile(this.path, 'utf8');
	    this.rawSourceMap = this.sources.sourceMap ||
	      // if we find a source-map (either inline, or a .map file) we load
	      // both the transpiled and original source, both of which are used during
	      // the backflips we perform to remap absolute to relative positions.
	      convertSourceMap.fromSource(rawSource) || convertSourceMap.fromMapFileSource(rawSource, this._readFileFromDir.bind(this));

	    if (this.rawSourceMap) {
	      if (this.rawSourceMap.sourcemap.sources.length > 1) {
	        this.sourceMap = new TraceMap(this.rawSourceMap.sourcemap);
	        if (!this.sourceMap.sourcesContent) {
	          this.sourceMap.sourcesContent = await this.sourcesContentFromSources();
	        }
	        this.covSources = this.sourceMap.sourcesContent.map((rawSource, i) => ({ source: new CovSource(rawSource, this.wrapperLength), path: this.sourceMap.sources[i] }));
	        this.sourceTranspiled = new CovSource(rawSource, this.wrapperLength);
	      } else {
	        const candidatePath = this.rawSourceMap.sourcemap.sources.length >= 1 ? this.rawSourceMap.sourcemap.sources[0] : this.rawSourceMap.sourcemap.file;
	        this.path = this._resolveSource(this.rawSourceMap, candidatePath || this.path);
	        this.sourceMap = new TraceMap(this.rawSourceMap.sourcemap);

	        let originalRawSource;
	        if (this.sources.sourceMap && this.sources.sourceMap.sourcemap && this.sources.sourceMap.sourcemap.sourcesContent && this.sources.sourceMap.sourcemap.sourcesContent.length === 1) {
	          // If the sourcesContent field has been provided, return it rather than attempting
	          // to load the original source from disk.
	          // TODO: investigate whether there's ever a case where we hit this logic with 1:many sources.
	          originalRawSource = this.sources.sourceMap.sourcemap.sourcesContent[0];
	        } else if (this.sources.originalSource) {
	          // Original source may be populated on the sources object.
	          originalRawSource = this.sources.originalSource;
	        } else if (this.sourceMap.sourcesContent && this.sourceMap.sourcesContent[0]) {
	          // perhaps we loaded sourcesContent was populated by an inline source map, or .map file?
	          // TODO: investigate whether there's ever a case where we hit this logic with 1:many sources.
	          originalRawSource = this.sourceMap.sourcesContent[0];
	        } else {
	          // We fallback to reading the original source from disk.
	          originalRawSource = await readFile(this.path, 'utf8');
	        }
	        this.covSources = [{ source: new CovSource(originalRawSource, this.wrapperLength), path: this.path }];
	        this.sourceTranspiled = new CovSource(rawSource, this.wrapperLength);
	      }
	    } else {
	      this.covSources = [{ source: new CovSource(rawSource, this.wrapperLength), path: this.path }];
	    }
	  }

	  _readFileFromDir (filename) {
	    return readFileSync(resolve(dirname(this.path), filename), 'utf-8')
	  }

	  async sourcesContentFromSources () {
	    const fileList = this.sourceMap.sources.map(relativePath => {
	      const realPath = this._resolveSource(this.rawSourceMap, relativePath);
	      return readFile(realPath, 'utf-8')
	        .then(result => result)
	        .catch(err => {
	          debuglog(`failed to load ${realPath}: ${err.message}`);
	        })
	    });
	    return await Promise.all(fileList)
	  }

	  destroy () {
	    // no longer necessary, but preserved for backwards compatibility.
	  }

	  _resolveSource (rawSourceMap, sourcePath) {
	    if (sourcePath.startsWith('file://')) {
	      return fileURLToPath(sourcePath)
	    }
	    sourcePath = sourcePath.replace(/^webpack:\/\//, '');
	    const sourceRoot = rawSourceMap.sourcemap.sourceRoot ? rawSourceMap.sourcemap.sourceRoot.replace('file://', '') : '';
	    const candidatePath = join(sourceRoot, sourcePath);

	    if (isAbsolute(candidatePath)) {
	      return candidatePath
	    } else {
	      return resolve(dirname(this.path), candidatePath)
	    }
	  }

	  applyCoverage (blocks) {
	    blocks.forEach(block => {
	      block.ranges.forEach((range, i) => {
	        const isEmptyCoverage = block.functionName === '(empty-report)';
	        const { startCol, endCol, path, covSource } = this._maybeRemapStartColEndCol(range, isEmptyCoverage);
	        if (this.excludePath(path)) {
	          return
	        }
	        let lines;
	        if (isEmptyCoverage) {
	          // (empty-report), this will result in a report that has all lines zeroed out.
	          lines = covSource.lines.filter((line) => {
	            line.count = 0;
	            return true
	          });
	          this.all = lines.length > 0;
	        } else {
	          lines = sliceRange(covSource.lines, startCol, endCol);
	        }
	        if (!lines.length) {
	          return
	        }

	        const startLineInstance = lines[0];
	        const endLineInstance = lines[lines.length - 1];

	        if (block.isBlockCoverage) {
	          this.branches[path] = this.branches[path] || [];
	          // record branches.
	          this.branches[path].push(new CovBranch(
	            startLineInstance.line,
	            startCol - startLineInstance.startCol,
	            endLineInstance.line,
	            endCol - endLineInstance.startCol,
	            range.count
	          ));

	          // if block-level granularity is enabled, we still create a single
	          // CovFunction tracking object for each set of ranges.
	          if (block.functionName && i === 0) {
	            this.functions[path] = this.functions[path] || [];
	            this.functions[path].push(new CovFunction(
	              block.functionName,
	              startLineInstance.line,
	              startCol - startLineInstance.startCol,
	              endLineInstance.line,
	              endCol - endLineInstance.startCol,
	              range.count
	            ));
	          }
	        } else if (block.functionName) {
	          this.functions[path] = this.functions[path] || [];
	          // record functions.
	          this.functions[path].push(new CovFunction(
	            block.functionName,
	            startLineInstance.line,
	            startCol - startLineInstance.startCol,
	            endLineInstance.line,
	            endCol - endLineInstance.startCol,
	            range.count
	          ));
	        }

	        // record the lines (we record these as statements, such that we're
	        // compatible with Istanbul 2.0).
	        lines.forEach(line => {
	          // make sure branch spans entire line; don't record 'goodbye'
	          // branch in `const foo = true ? 'hello' : 'goodbye'` as a
	          // 0 for line coverage.
	          //
	          // All lines start out with coverage of 1, and are later set to 0
	          // if they are not invoked; line.ignore prevents a line from being
	          // set to 0, and is set if the special comment /* c8 ignore next */
	          // is used.

	          if (startCol <= line.startCol && endCol >= line.endCol && !line.ignore) {
	            line.count = range.count;
	          }
	        });
	      });
	    });
	  }

	  _maybeRemapStartColEndCol (range, isEmptyCoverage) {
	    let covSource = this.covSources[0].source;
	    const covSourceWrapperLength = isEmptyCoverage ? 0 : covSource.wrapperLength;
	    let startCol = Math.max(0, range.startOffset - covSourceWrapperLength);
	    let endCol = Math.min(covSource.eof, range.endOffset - covSourceWrapperLength);
	    let path = this.path;

	    if (this.sourceMap) {
	      const sourceTranspiledWrapperLength = isEmptyCoverage ? 0 : this.sourceTranspiled.wrapperLength;
	      startCol = Math.max(0, range.startOffset - sourceTranspiledWrapperLength);
	      endCol = Math.min(this.sourceTranspiled.eof, range.endOffset - sourceTranspiledWrapperLength);

	      const { startLine, relStartCol, endLine, relEndCol, source } = this.sourceTranspiled.offsetToOriginalRelative(
	        this.sourceMap,
	        startCol,
	        endCol
	      );

	      const matchingSource = this.covSources.find(covSource => covSource.path === source);
	      covSource = matchingSource ? matchingSource.source : this.covSources[0].source;
	      path = matchingSource ? matchingSource.path : this.covSources[0].path;

	      // next we convert these relative positions back to absolute positions
	      // in the original source (which is the format expected in the next step).
	      startCol = covSource.relativeToOffset(startLine, relStartCol);
	      endCol = covSource.relativeToOffset(endLine, relEndCol);
	    }

	    return {
	      path,
	      covSource,
	      startCol,
	      endCol
	    }
	  }

	  getInnerIstanbul (source, path) {
	    // We apply the "Resolving Sources" logic (as defined in
	    // sourcemaps.info/spec.html) as a final step for 1:many source maps.
	    // for 1:1 source maps, the resolve logic is applied while loading.
	    //
	    // TODO: could we move the resolving logic for 1:1 source maps to the final
	    // step as well? currently this breaks some tests in c8.
	    let resolvedPath = path;
	    if (this.rawSourceMap && this.rawSourceMap.sourcemap.sources.length > 1) {
	      resolvedPath = this._resolveSource(this.rawSourceMap, path);
	    }

	    if (this.excludePath(resolvedPath)) {
	      return
	    }

	    return {
	      [resolvedPath]: {
	        path: resolvedPath,
	        all: this.all,
	        ...this._statementsToIstanbul(source, path),
	        ...this._branchesToIstanbul(source, path),
	        ...this._functionsToIstanbul(source, path)
	      }
	    }
	  }

	  toIstanbul () {
	    return this.covSources.reduce((istanbulOuter, { source, path }) => Object.assign(istanbulOuter, this.getInnerIstanbul(source, path)), {})
	  }

	  _statementsToIstanbul (source, path) {
	    const statements = {
	      statementMap: {},
	      s: {}
	    };
	    source.lines.forEach((line, index) => {
	      statements.statementMap[`${index}`] = line.toIstanbul();
	      statements.s[`${index}`] = line.ignore ? 1 : line.count;
	    });
	    return statements
	  }

	  _branchesToIstanbul (source, path) {
	    const branches = {
	      branchMap: {},
	      b: {}
	    };
	    this.branches[path] = this.branches[path] || [];
	    this.branches[path].forEach((branch, index) => {
	      const srcLine = source.lines[branch.startLine - 1];
	      const ignore = srcLine === undefined ? true : srcLine.ignore;
	      branches.branchMap[`${index}`] = branch.toIstanbul();
	      branches.b[`${index}`] = [ignore ? 1 : branch.count];
	    });
	    return branches
	  }

	  _functionsToIstanbul (source, path) {
	    const functions = {
	      fnMap: {},
	      f: {}
	    };
	    this.functions[path] = this.functions[path] || [];
	    this.functions[path].forEach((fn, index) => {
	      const srcLine = source.lines[fn.startLine - 1];
	      const ignore = srcLine === undefined ? true : srcLine.ignore;
	      functions.fnMap[`${index}`] = fn.toIstanbul();
	      functions.f[`${index}`] = ignore ? 1 : fn.count;
	    });
	    return functions
	  }
	};

	function parsePath (scriptPath) {
	  return scriptPath.startsWith('file://') ? fileURLToPath(scriptPath) : scriptPath
	}
	return v8ToIstanbul$1;
}

var v8ToIstanbul;
var hasRequiredV8ToIstanbul;

function requireV8ToIstanbul () {
	if (hasRequiredV8ToIstanbul) return v8ToIstanbul;
	hasRequiredV8ToIstanbul = 1;
	const V8ToIstanbul = requireV8ToIstanbul$1();

	v8ToIstanbul = function (path, wrapperLength, sources, excludePath) {
	  return new V8ToIstanbul(path, wrapperLength, sources, excludePath)
	};
	return v8ToIstanbul;
}

/**
 * Compares two script coverages.
 *
 * The result corresponds to the comparison of their `url` value (alphabetical sort).
 */

var compare;
var hasRequiredCompare;

function requireCompare () {
	if (hasRequiredCompare) return compare;
	hasRequiredCompare = 1;
	function compareScriptCovs(a, b) {
	  if (a.url === b.url) {
	    return 0;
	  } else if (a.url < b.url) {
	    return -1;
	  } else {
	    return 1;
	  }
	}

	/**
	 * Compares two function coverages.
	 *
	 * The result corresponds to the comparison of the root ranges.
	 */
	function compareFunctionCovs(a, b) {
	  return compareRangeCovs(a.ranges[0], b.ranges[0]);
	}

	/**
	 * Compares two range coverages.
	 *
	 * The ranges are first ordered by ascending `startOffset` and then by
	 * descending `endOffset`.
	 * This corresponds to a pre-order tree traversal.
	 */
	function compareRangeCovs(a, b) {
	  if (a.startOffset !== b.startOffset) {
	    return a.startOffset - b.startOffset;
	  } else {
	    return b.endOffset - a.endOffset;
	  }
	}

	compare = {
	  compareScriptCovs,
	  compareFunctionCovs,
	  compareRangeCovs,
	};
	return compare;
}

var ascii;
var hasRequiredAscii;

function requireAscii () {
	if (hasRequiredAscii) return ascii;
	hasRequiredAscii = 1;
	const { compareRangeCovs } = requireCompare();

	function emitForest(trees) {
	  return emitForestLines(trees).join("\n");
	}

	function emitForestLines(trees) {
	  const colMap = getColMap(trees);
	  const header = emitOffsets(colMap);
	  return [header, ...trees.map((tree) => emitTree(tree, colMap).join("\n"))];
	}

	function getColMap(trees) {
	  const eventSet = new Set();
	  for (const tree of trees) {
	    const stack = [tree];
	    while (stack.length > 0) {
	      const cur = stack.pop();
	      eventSet.add(cur.start);
	      eventSet.add(cur.end);
	      for (const child of cur.children) {
	        stack.push(child);
	      }
	    }
	  }
	  const events = [...eventSet];
	  events.sort((a, b) => a - b);
	  let maxDigits = 1;
	  for (const event of events) {
	    maxDigits = Math.max(maxDigits, event.toString(10).length);
	  }
	  const colWidth = maxDigits + 3;
	  const colMap = new Map();
	  for (const [i, event] of events.entries()) {
	    colMap.set(event, i * colWidth);
	  }
	  return colMap;
	}

	function emitTree(tree, colMap) {
	  const layers = [];
	  let nextLayer = [tree];
	  while (nextLayer.length > 0) {
	    const layer = nextLayer;
	    layers.push(layer);
	    nextLayer = [];
	    for (const node of layer) {
	      for (const child of node.children) {
	        nextLayer.push(child);
	      }
	    }
	  }
	  return layers.map((layer) => emitTreeLayer(layer, colMap));
	}

	function parseFunctionRanges(text, offsetMap) {
	  const result = [];
	  for (const line of text.split("\n")) {
	    for (const range of parseTreeLayer(line, offsetMap)) {
	      result.push(range);
	    }
	  }
	  result.sort(compareRangeCovs);
	  return result;
	}

	/**
	 *
	 * @param layer Sorted list of disjoint trees.
	 * @param colMap
	 */
	function emitTreeLayer(layer, colMap) {
	  const line = [];
	  let curIdx = 0;
	  for (const { start, end, count } of layer) {
	    const startIdx = colMap.get(start);
	    const endIdx = colMap.get(end);
	    if (startIdx > curIdx) {
	      line.push(" ".repeat(startIdx - curIdx));
	    }
	    line.push(emitRange(count, endIdx - startIdx));
	    curIdx = endIdx;
	  }
	  return line.join("");
	}

	function parseTreeLayer(text, offsetMap) {
	  const result = [];
	  const regex = /\[(\d+)-*\)/gs;
	  while (true) {
	    const match = regex.exec(text);
	    if (match === null) {
	      break;
	    }
	    const startIdx = match.index;
	    const endIdx = startIdx + match[0].length;
	    const count = parseInt(match[1], 10);
	    const startOffset = offsetMap.get(startIdx);
	    const endOffset = offsetMap.get(endIdx);
	    if (startOffset === undefined || endOffset === undefined) {
	      throw new Error(`Invalid offsets for: ${JSON.stringify(text)}`);
	    }
	    result.push({ startOffset, endOffset, count });
	  }
	  return result;
	}

	function emitRange(count, len) {
	  const rangeStart = `[${count.toString(10)}`;
	  const rangeEnd = ")";
	  const hyphensLen = len - (rangeStart.length + rangeEnd.length);
	  const hyphens = "-".repeat(Math.max(0, hyphensLen));
	  return `${rangeStart}${hyphens}${rangeEnd}`;
	}

	function emitOffsets(colMap) {
	  let line = "";
	  for (const [event, col] of colMap) {
	    if (line.length < col) {
	      line += " ".repeat(col - line.length);
	    }
	    line += event.toString(10);
	  }
	  return line;
	}

	function parseOffsets(text) {
	  const result = new Map();
	  const regex = /\d+/gs;
	  while (true) {
	    const match = regex.exec(text);
	    if (match === null) {
	      break;
	    }
	    result.set(match.index, parseInt(match[0], 10));
	  }
	  return result;
	}

	ascii = {
	  emitForest,
	  emitForestLines,
	  parseFunctionRanges,
	  parseOffsets,
	};
	return ascii;
}

/**
 * Creates a deep copy of a process coverage.
 *
 * @param processCov Process coverage to clone.
 * @return Cloned process coverage.
 */

var clone;
var hasRequiredClone;

function requireClone () {
	if (hasRequiredClone) return clone;
	hasRequiredClone = 1;
	function cloneProcessCov(processCov) {
	  const result = [];
	  for (const scriptCov of processCov.result) {
	    result.push(cloneScriptCov(scriptCov));
	  }

	  return {
	    result,
	  };
	}

	/**
	 * Creates a deep copy of a script coverage.
	 *
	 * @param scriptCov Script coverage to clone.
	 * @return Cloned script coverage.
	 */
	function cloneScriptCov(scriptCov) {
	  const functions = [];
	  for (const functionCov of scriptCov.functions) {
	    functions.push(cloneFunctionCov(functionCov));
	  }

	  return {
	    scriptId: scriptCov.scriptId,
	    url: scriptCov.url,
	    functions,
	  };
	}

	/**
	 * Creates a deep copy of a function coverage.
	 *
	 * @param functionCov Function coverage to clone.
	 * @return Cloned function coverage.
	 */
	function cloneFunctionCov(functionCov) {
	  const ranges = [];
	  for (const rangeCov of functionCov.ranges) {
	    ranges.push(cloneRangeCov(rangeCov));
	  }

	  return {
	    functionName: functionCov.functionName,
	    ranges,
	    isBlockCoverage: functionCov.isBlockCoverage,
	  };
	}

	/**
	 * Creates a deep copy of a function coverage.
	 *
	 * @param rangeCov Range coverage to clone.
	 * @return Cloned range coverage.
	 */
	function cloneRangeCov(rangeCov) {
	  return {
	    startOffset: rangeCov.startOffset,
	    endOffset: rangeCov.endOffset,
	    count: rangeCov.count,
	  };
	}

	clone = {
	  cloneProcessCov,
	  cloneScriptCov,
	  cloneFunctionCov,
	  cloneRangeCov,
	};
	return clone;
}

var rangeTree;
var hasRequiredRangeTree;

function requireRangeTree () {
	if (hasRequiredRangeTree) return rangeTree;
	hasRequiredRangeTree = 1;
	class RangeTree {
	  start;
	  end;
	  delta;
	  children;

	  constructor(start, end, delta, children) {
	    this.start = start;
	    this.end = end;
	    this.delta = delta;
	    this.children = children;
	  }

	  /**
	   * @precodition `ranges` are well-formed and pre-order sorted
	   */
	  static fromSortedRanges(ranges) {
	    let root;
	    // Stack of parent trees and parent counts.
	    const stack = [];
	    for (const range of ranges) {
	      const node = new RangeTree(
	        range.startOffset,
	        range.endOffset,
	        range.count,
	        [],
	      );
	      if (root === undefined) {
	        root = node;
	        stack.push([node, range.count]);
	        continue;
	      }
	      let parent;
	      let parentCount;
	      while (true) {
	        [parent, parentCount] = stack[stack.length - 1];
	        // assert: `top !== undefined` (the ranges are sorted)
	        if (range.startOffset < parent.end) {
	          break;
	        } else {
	          stack.pop();
	        }

	        if (stack.length === 0) {
	          break;
	        }
	      }
	      node.delta -= parentCount;
	      parent.children.push(node);
	      stack.push([node, range.count]);
	    }
	    return root;
	  }

	  normalize() {
	    const children = [];
	    let curEnd;
	    let head;
	    const tail = [];
	    for (const child of this.children) {
	      if (head === undefined) {
	        head = child;
	      } else if (child.delta === head.delta && child.start === curEnd) {
	        tail.push(child);
	      } else {
	        endChain();
	        head = child;
	      }
	      curEnd = child.end;
	    }
	    if (head !== undefined) {
	      endChain();
	    }

	    if (children.length === 1) {
	      const child = children[0];
	      if (child.start === this.start && child.end === this.end) {
	        this.delta += child.delta;
	        this.children = child.children;
	        // `.lazyCount` is zero for both (both are after normalization)
	        return;
	      }
	    }

	    this.children = children;

	    function endChain() {
	      if (tail.length !== 0) {
	        head.end = tail[tail.length - 1].end;
	        for (const tailTree of tail) {
	          for (const subChild of tailTree.children) {
	            subChild.delta += tailTree.delta - head.delta;
	            head.children.push(subChild);
	          }
	        }
	        tail.length = 0;
	      }
	      head.normalize();
	      children.push(head);
	    }
	  }

	  /**
	   * @precondition `tree.start < value && value < tree.end`
	   * @return RangeTree Right part
	   */
	  split(value) {
	    let leftChildLen = this.children.length;
	    let mid;

	    // TODO(perf): Binary search (check overhead)
	    for (let i = 0; i < this.children.length; i++) {
	      const child = this.children[i];
	      if (child.start < value && value < child.end) {
	        mid = child.split(value);
	        leftChildLen = i + 1;
	        break;
	      } else if (child.start >= value) {
	        leftChildLen = i;
	        break;
	      }
	    }

	    const rightLen = this.children.length - leftChildLen;
	    const rightChildren = this.children.splice(leftChildLen, rightLen);
	    if (mid !== undefined) {
	      rightChildren.unshift(mid);
	    }
	    const result = new RangeTree(value, this.end, this.delta, rightChildren);
	    this.end = value;
	    return result;
	  }

	  /**
	   * Get the range coverages corresponding to the tree.
	   *
	   * The ranges are pre-order sorted.
	   */
	  toRanges() {
	    const ranges = [];
	    // Stack of parent trees and counts.
	    const stack = [[this, 0]];
	    while (stack.length > 0) {
	      const [cur, parentCount] = stack.pop();
	      const count = parentCount + cur.delta;
	      ranges.push({ startOffset: cur.start, endOffset: cur.end, count });
	      for (let i = cur.children.length - 1; i >= 0; i--) {
	        stack.push([cur.children[i], count]);
	      }
	    }
	    return ranges;
	  }
	}

	rangeTree = {
	  RangeTree,
	};
	return rangeTree;
}

var normalize;
var hasRequiredNormalize;

function requireNormalize () {
	if (hasRequiredNormalize) return normalize;
	hasRequiredNormalize = 1;
	const {
	  compareFunctionCovs,
	  compareRangeCovs,
	  compareScriptCovs,
	} = requireCompare();
	const { RangeTree } = requireRangeTree();

	/**
	 * Normalizes a process coverage.
	 *
	 * Sorts the scripts alphabetically by `url`.
	 * Reassigns script ids: the script at index `0` receives `"0"`, the script at
	 * index `1` receives `"1"` etc.
	 * This does not normalize the script coverages.
	 *
	 * @param processCov Process coverage to normalize.
	 */
	function normalizeProcessCov(processCov) {
	  processCov.result.sort(compareScriptCovs);
	  for (const [scriptId, scriptCov] of processCov.result.entries()) {
	    scriptCov.scriptId = scriptId.toString(10);
	  }
	}

	/**
	 * Normalizes a process coverage deeply.
	 *
	 * Normalizes the script coverages deeply, then normalizes the process coverage
	 * itself.
	 *
	 * @param processCov Process coverage to normalize.
	 */
	function deepNormalizeProcessCov(processCov) {
	  for (const scriptCov of processCov.result) {
	    deepNormalizeScriptCov(scriptCov);
	  }
	  normalizeProcessCov(processCov);
	}

	/**
	 * Normalizes a script coverage.
	 *
	 * Sorts the function by root range (pre-order sort).
	 * This does not normalize the function coverages.
	 *
	 * @param scriptCov Script coverage to normalize.
	 */
	function normalizeScriptCov(scriptCov) {
	  scriptCov.functions.sort(compareFunctionCovs);
	}

	/**
	 * Normalizes a script coverage deeply.
	 *
	 * Normalizes the function coverages deeply, then normalizes the script coverage
	 * itself.
	 *
	 * @param scriptCov Script coverage to normalize.
	 */
	function deepNormalizeScriptCov(scriptCov) {
	  for (const funcCov of scriptCov.functions) {
	    normalizeFunctionCov(funcCov);
	  }
	  normalizeScriptCov(scriptCov);
	}

	/**
	 * Normalizes a function coverage.
	 *
	 * Sorts the ranges (pre-order sort).
	 * TODO: Tree-based normalization of the ranges.
	 *
	 * @param funcCov Function coverage to normalize.
	 */
	function normalizeFunctionCov(funcCov) {
	  funcCov.ranges.sort(compareRangeCovs);
	  const tree = RangeTree.fromSortedRanges(funcCov.ranges);
	  normalizeRangeTree(tree);
	  funcCov.ranges = tree.toRanges();
	}

	/**
	 * @internal
	 */
	function normalizeRangeTree(tree) {
	  tree.normalize();
	}

	normalize = {
	  normalizeProcessCov,
	  deepNormalizeProcessCov,
	  normalizeScriptCov,
	  deepNormalizeScriptCov,
	  normalizeFunctionCov,
	  normalizeRangeTree,
	};
	return normalize;
}

var merge;
var hasRequiredMerge;

function requireMerge () {
	if (hasRequiredMerge) return merge;
	hasRequiredMerge = 1;
	const {
	  deepNormalizeScriptCov,
	  normalizeFunctionCov,
	  normalizeProcessCov,
	  normalizeRangeTree,
	  normalizeScriptCov,
	} = requireNormalize();
	const { RangeTree } = requireRangeTree();

	/**
	 * Merges a list of process coverages.
	 *
	 * The result is normalized.
	 * The input values may be mutated, it is not safe to use them after passing
	 * them to this function.
	 * The computation is synchronous.
	 *
	 * @param processCovs Process coverages to merge.
	 * @return Merged process coverage.
	 */
	function mergeProcessCovs(processCovs) {
	  if (processCovs.length === 0) {
	    return { result: [] };
	  }

	  const urlToScripts = new Map();
	  for (const processCov of processCovs) {
	    for (const scriptCov of processCov.result) {
	      let scriptCovs = urlToScripts.get(scriptCov.url);
	      if (scriptCovs === undefined) {
	        scriptCovs = [];
	        urlToScripts.set(scriptCov.url, scriptCovs);
	      }
	      scriptCovs.push(scriptCov);
	    }
	  }

	  const result = [];
	  for (const scripts of urlToScripts.values()) {
	    // assert: `scripts.length > 0`
	    result.push(mergeScriptCovs(scripts));
	  }
	  const merged = { result };

	  normalizeProcessCov(merged);
	  return merged;
	}

	/**
	 * Merges a list of matching script coverages.
	 *
	 * Scripts are matching if they have the same `url`.
	 * The result is normalized.
	 * The input values may be mutated, it is not safe to use them after passing
	 * them to this function.
	 * The computation is synchronous.
	 *
	 * @param scriptCovs Process coverages to merge.
	 * @return Merged script coverage, or `undefined` if the input list was empty.
	 */
	function mergeScriptCovs(scriptCovs) {
	  if (scriptCovs.length === 0) {
	    return undefined;
	  } else if (scriptCovs.length === 1) {
	    const merged = scriptCovs[0];
	    deepNormalizeScriptCov(merged);
	    return merged;
	  }

	  const first = scriptCovs[0];
	  const scriptId = first.scriptId;
	  const url = first.url;

	  const rangeToFuncs = new Map();
	  for (const scriptCov of scriptCovs) {
	    for (const funcCov of scriptCov.functions) {
	      const rootRange = stringifyFunctionRootRange(funcCov);
	      let funcCovs = rangeToFuncs.get(rootRange);

	      if (
	        funcCovs === undefined ||
	        // if the entry in rangeToFuncs is function-level granularity and
	        // the new coverage is block-level, prefer block-level.
	        (!funcCovs[0].isBlockCoverage && funcCov.isBlockCoverage)
	      ) {
	        funcCovs = [];
	        rangeToFuncs.set(rootRange, funcCovs);
	      } else if (funcCovs[0].isBlockCoverage && !funcCov.isBlockCoverage) {
	        // if the entry in rangeToFuncs is block-level granularity, we should
	        // not append function level granularity.
	        continue;
	      }
	      funcCovs.push(funcCov);
	    }
	  }

	  const functions = [];
	  for (const funcCovs of rangeToFuncs.values()) {
	    // assert: `funcCovs.length > 0`
	    functions.push(mergeFunctionCovs(funcCovs));
	  }

	  const merged = { scriptId, url, functions };
	  normalizeScriptCov(merged);
	  return merged;
	}

	/**
	 * Returns a string representation of the root range of the function.
	 *
	 * This string can be used to match function with same root range.
	 * The string is derived from the start and end offsets of the root range of
	 * the function.
	 * This assumes that `ranges` is non-empty (true for valid function coverages).
	 *
	 * @param funcCov Function coverage with the range to stringify
	 * @internal
	 */
	function stringifyFunctionRootRange(funcCov) {
	  const rootRange = funcCov.ranges[0];
	  return `${rootRange.startOffset.toString(10)};${rootRange.endOffset.toString(10)}`;
	}

	/**
	 * Merges a list of matching function coverages.
	 *
	 * Functions are matching if their root ranges have the same span.
	 * The result is normalized.
	 * The input values may be mutated, it is not safe to use them after passing
	 * them to this function.
	 * The computation is synchronous.
	 *
	 * @param funcCovs Function coverages to merge.
	 * @return Merged function coverage, or `undefined` if the input list was empty.
	 */
	function mergeFunctionCovs(funcCovs) {
	  if (funcCovs.length === 0) {
	    return undefined;
	  } else if (funcCovs.length === 1) {
	    const merged = funcCovs[0];
	    normalizeFunctionCov(merged);
	    return merged;
	  }

	  const functionName = funcCovs[0].functionName;

	  const trees = [];
	  for (const funcCov of funcCovs) {
	    // assert: `fn.ranges.length > 0`
	    // assert: `fn.ranges` is sorted
	    trees.push(RangeTree.fromSortedRanges(funcCov.ranges));
	  }

	  // assert: `trees.length > 0`
	  const mergedTree = mergeRangeTrees(trees);
	  normalizeRangeTree(mergedTree);
	  const ranges = mergedTree.toRanges();
	  const isBlockCoverage = !(ranges.length === 1 && ranges[0].count === 0);

	  const merged = { functionName, ranges, isBlockCoverage };
	  // assert: `merged` is normalized
	  return merged;
	}

	/**
	 * @precondition Same `start` and `end` for all the trees
	 */
	function mergeRangeTrees(trees) {
	  if (trees.length <= 1) {
	    return trees[0];
	  }
	  const first = trees[0];
	  let delta = 0;
	  for (const tree of trees) {
	    delta += tree.delta;
	  }
	  const children = mergeRangeTreeChildren(trees);
	  return new RangeTree(first.start, first.end, delta, children);
	}

	class RangeTreeWithParent {
	  parentIndex;
	  tree;

	  constructor(parentIndex, tree) {
	    this.parentIndex = parentIndex;
	    this.tree = tree;
	  }
	}

	class StartEvent {
	  offset;
	  trees;

	  constructor(offset, trees) {
	    this.offset = offset;
	    this.trees = trees;
	  }

	  static compare(a, b) {
	    return a.offset - b.offset;
	  }
	}

	class StartEventQueue {
	  queue;
	  nextIndex;
	  pendingOffset;
	  pendingTrees;

	  constructor(queue) {
	    this.queue = queue;
	    this.nextIndex = 0;
	    this.pendingOffset = 0;
	    this.pendingTrees = undefined;
	  }

	  static fromParentTrees(parentTrees) {
	    const startToTrees = new Map();
	    for (const [parentIndex, parentTree] of parentTrees.entries()) {
	      for (const child of parentTree.children) {
	        let trees = startToTrees.get(child.start);
	        if (trees === undefined) {
	          trees = [];
	          startToTrees.set(child.start, trees);
	        }
	        trees.push(new RangeTreeWithParent(parentIndex, child));
	      }
	    }
	    const queue = [];
	    for (const [startOffset, trees] of startToTrees) {
	      queue.push(new StartEvent(startOffset, trees));
	    }
	    queue.sort(StartEvent.compare);
	    return new StartEventQueue(queue);
	  }

	  setPendingOffset(offset) {
	    this.pendingOffset = offset;
	  }

	  pushPendingTree(tree) {
	    if (this.pendingTrees === undefined) {
	      this.pendingTrees = [];
	    }
	    this.pendingTrees.push(tree);
	  }

	  next() {
	    const pendingTrees = this.pendingTrees;
	    const nextEvent = this.queue[this.nextIndex];
	    if (pendingTrees === undefined) {
	      this.nextIndex++;
	      return nextEvent;
	    } else if (nextEvent === undefined) {
	      this.pendingTrees = undefined;
	      return new StartEvent(this.pendingOffset, pendingTrees);
	    } else {
	      if (this.pendingOffset < nextEvent.offset) {
	        this.pendingTrees = undefined;
	        return new StartEvent(this.pendingOffset, pendingTrees);
	      } else {
	        if (this.pendingOffset === nextEvent.offset) {
	          this.pendingTrees = undefined;
	          for (const tree of pendingTrees) {
	            nextEvent.trees.push(tree);
	          }
	        }
	        this.nextIndex++;
	        return nextEvent;
	      }
	    }
	  }
	}

	function mergeRangeTreeChildren(parentTrees) {
	  const result = [];
	  const startEventQueue = StartEventQueue.fromParentTrees(parentTrees);
	  const parentToNested = new Map();
	  let openRange;

	  while (true) {
	    const event = startEventQueue.next();
	    if (event === undefined) {
	      break;
	    }

	    if (openRange !== undefined && openRange.end <= event.offset) {
	      result.push(nextChild(openRange, parentToNested));
	      openRange = undefined;
	    }

	    if (openRange === undefined) {
	      let openRangeEnd = event.offset + 1;
	      for (const { parentIndex, tree } of event.trees) {
	        openRangeEnd = Math.max(openRangeEnd, tree.end);
	        insertChild(parentToNested, parentIndex, tree);
	      }
	      startEventQueue.setPendingOffset(openRangeEnd);
	      openRange = { start: event.offset, end: openRangeEnd };
	    } else {
	      for (const { parentIndex, tree } of event.trees) {
	        if (tree.end > openRange.end) {
	          const right = tree.split(openRange.end);
	          startEventQueue.pushPendingTree(
	            new RangeTreeWithParent(parentIndex, right),
	          );
	        }
	        insertChild(parentToNested, parentIndex, tree);
	      }
	    }
	  }
	  if (openRange !== undefined) {
	    result.push(nextChild(openRange, parentToNested));
	  }

	  return result;
	}

	function insertChild(parentToNested, parentIndex, tree) {
	  let nested = parentToNested.get(parentIndex);
	  if (nested === undefined) {
	    nested = [];
	    parentToNested.set(parentIndex, nested);
	  }
	  nested.push(tree);
	}

	function nextChild(openRange, parentToNested) {
	  const matchingTrees = [];

	  for (const nested of parentToNested.values()) {
	    if (
	      nested.length === 1 &&
	      nested[0].start === openRange.start &&
	      nested[0].end === openRange.end
	    ) {
	      matchingTrees.push(nested[0]);
	    } else {
	      matchingTrees.push(
	        new RangeTree(openRange.start, openRange.end, 0, nested),
	      );
	    }
	  }
	  parentToNested.clear();
	  return mergeRangeTrees(matchingTrees);
	}

	merge = {
	  mergeProcessCovs,
	  mergeScriptCovs,
	  mergeFunctionCovs,
	};
	return merge;
}

var lib;
var hasRequiredLib;

function requireLib () {
	if (hasRequiredLib) return lib;
	hasRequiredLib = 1;
	const {
	  emitForest,
	  emitForestLines,
	  parseFunctionRanges,
	  parseOffsets,
	} = requireAscii();
	const {
	  cloneFunctionCov,
	  cloneProcessCov,
	  cloneScriptCov,
	  cloneRangeCov,
	} = requireClone();
	const {
	  compareScriptCovs,
	  compareFunctionCovs,
	  compareRangeCovs,
	} = requireCompare();
	const {
	  mergeFunctionCovs,
	  mergeProcessCovs,
	  mergeScriptCovs,
	} = requireMerge();
	const { RangeTree } = requireRangeTree();

	lib = {
	  emitForest,
	  emitForestLines,
	  parseFunctionRanges,
	  parseOffsets,
	  cloneFunctionCov,
	  cloneProcessCov,
	  cloneScriptCov,
	  cloneRangeCov,
	  compareScriptCovs,
	  compareFunctionCovs,
	  compareRangeCovs,
	  mergeFunctionCovs,
	  mergeProcessCovs,
	  mergeScriptCovs,
	  RangeTree,
	};
	return lib;
}

var report;
var hasRequiredReport;

function requireReport () {
	if (hasRequiredReport) return report;
	hasRequiredReport = 1;
	const Exclude = requireTestExclude();
	const libCoverage = requireIstanbulLibCoverage();
	const libReport = requireIstanbulLibReport();
	const reports = requireIstanbulReports();
	let readFile;
	try {
	  ;({ readFile } = require('fs/promises'));
	} catch (err) {
({ readFile } = require$$0$1.promises);
	}
	const { readdirSync, readFileSync, statSync } = require$$0$1;
	const { isAbsolute, resolve, extname } = require$$0$2;
	const { pathToFileURL, fileURLToPath } = require$$1$3;
	const getSourceMapFromFile = requireSourceMapFromFile();
	// TODO: switch back to @c88/v8-coverage once patch is landed.
	const v8toIstanbul = requireV8ToIstanbul();
	const util = require$$2$2;
	const debuglog = util.debuglog('c8');

	class Report {
	  constructor ({
	    exclude,
	    extension,
	    excludeAfterRemap,
	    include,
	    reporter,
	    reporterOptions,
	    reportsDirectory,
	    tempDirectory,
	    watermarks,
	    omitRelative,
	    wrapperLength,
	    resolve: resolvePaths,
	    all,
	    src,
	    allowExternal = false,
	    skipFull,
	    excludeNodeModules,
	    mergeAsync,
	    monocartArgv
	  }) {
	    this.reporter = reporter;
	    this.reporterOptions = reporterOptions || {};
	    this.reportsDirectory = reportsDirectory;
	    this.tempDirectory = tempDirectory;
	    this.watermarks = watermarks;
	    this.resolve = resolvePaths;
	    this.exclude = new Exclude({
	      exclude: exclude,
	      include: include,
	      extension: extension,
	      relativePath: !allowExternal,
	      excludeNodeModules: excludeNodeModules
	    });
	    this.excludeAfterRemap = excludeAfterRemap;
	    this.shouldInstrumentCache = new Map();
	    this.omitRelative = omitRelative;
	    this.sourceMapCache = {};
	    this.wrapperLength = wrapperLength;
	    this.all = all;
	    this.src = this._getSrc(src);
	    this.skipFull = skipFull;
	    this.mergeAsync = mergeAsync;
	    this.monocartArgv = monocartArgv;
	  }

	  _getSrc (src) {
	    if (typeof src === 'string') {
	      return [src]
	    } else if (Array.isArray(src)) {
	      return src
	    } else {
	      return [process.cwd()]
	    }
	  }

	  async run () {
	    if (this.monocartArgv) {
	      return this.runMonocart()
	    }
	    const context = libReport.createContext({
	      dir: this.reportsDirectory,
	      watermarks: this.watermarks,
	      coverageMap: await this.getCoverageMapFromAllCoverageFiles()
	    });

	    for (const _reporter of this.reporter) {
	      reports.create(_reporter, {
	        skipEmpty: false,
	        skipFull: this.skipFull,
	        maxCols: process.stdout.columns || 100,
	        ...this.reporterOptions[_reporter]
	      }).execute(context);
	    }
	  }

	  async importMonocart () {
	    return import('monocart-coverage-reports')
	  }

	  async getMonocart () {
	    let MCR;
	    try {
	      MCR = await this.importMonocart();
	    } catch (e) {
	      console.error('--experimental-monocart requires the plugin monocart-coverage-reports. Run: "npm i monocart-coverage-reports@2 --save-dev"');
	      process.exit(1);
	    }
	    return MCR
	  }

	  async runMonocart () {
	    const MCR = await this.getMonocart();
	    if (!MCR) {
	      return
	    }

	    const argv = this.monocartArgv;
	    const exclude = this.exclude;

	    function getEntryFilter () {
	      return argv.entryFilter || argv.filter || function (entry) {
	        return exclude.shouldInstrument(fileURLToPath(entry.url))
	      }
	    }

	    function getSourceFilter () {
	      return argv.sourceFilter || argv.filter || function (sourcePath) {
	        if (argv.excludeAfterRemap) {
	          // console.log(sourcePath)
	          return exclude.shouldInstrument(sourcePath)
	        }
	        return true
	      }
	    }

	    function getReports () {
	      const reports = Array.isArray(argv.reporter) ? argv.reporter : [argv.reporter];
	      const reporterOptions = argv.reporterOptions || {};

	      return reports.map((reportName) => {
	        const reportOptions = {
	          ...reporterOptions[reportName]
	        };
	        if (reportName === 'text') {
	          reportOptions.skipEmpty = false;
	          reportOptions.skipFull = argv.skipFull;
	          reportOptions.maxCols = process.stdout.columns || 100;
	        }
	        return [reportName, reportOptions]
	      })
	    }

	    // --all: add empty coverage for all files
	    function getAllOptions () {
	      if (!argv.all) {
	        return
	      }

	      const src = argv.src;
	      const workingDirs = Array.isArray(src) ? src : (typeof src === 'string' ? [src] : [process.cwd()]);
	      return {
	        dir: workingDirs,
	        filter: (filePath) => {
	          return exclude.shouldInstrument(filePath)
	        }
	      }
	    }

	    function initPct (summary) {
	      Object.keys(summary).forEach(k => {
	        if (summary[k].pct === '') {
	          summary[k].pct = 100;
	        }
	      });
	      return summary
	    }

	    // adapt coverage options
	    const coverageOptions = {
	      logging: argv.logging,
	      name: argv.name,

	      reports: getReports(),

	      outputDir: argv.reportsDir,
	      baseDir: argv.baseDir,

	      entryFilter: getEntryFilter(),
	      sourceFilter: getSourceFilter(),

	      inline: argv.inline,
	      lcov: argv.lcov,

	      all: getAllOptions(),

	      clean: argv.clean,

	      // use default value for istanbul
	      defaultSummarizer: 'pkg',

	      onEnd: (coverageResults) => {
	        // for check coverage
	        this._allCoverageFiles = {
	          files: () => {
	            return coverageResults.files.map(it => it.sourcePath)
	          },
	          fileCoverageFor: (file) => {
	            const fileCoverage = coverageResults.files.find(it => it.sourcePath === file);
	            return {
	              toSummary: () => {
	                return initPct(fileCoverage.summary)
	              }
	            }
	          },
	          getCoverageSummary: () => {
	            return initPct(coverageResults.summary)
	          }
	        };
	      }
	    };
	    const coverageReport = new MCR.CoverageReport(coverageOptions);
	    coverageReport.cleanCache();

	    // read v8 coverage data from tempDirectory
	    await coverageReport.addFromDir(argv.tempDirectory);

	    // generate report
	    await coverageReport.generate();
	  }

	  async getCoverageMapFromAllCoverageFiles () {
	    // the merge process can be very expensive, and it's often the case that
	    // check-coverage is called immediately after a report. We memoize the
	    // result from getCoverageMapFromAllCoverageFiles() to address this
	    // use-case.
	    if (this._allCoverageFiles) return this._allCoverageFiles

	    const map = libCoverage.createCoverageMap();
	    let v8ProcessCov;

	    if (this.mergeAsync) {
	      v8ProcessCov = await this._getMergedProcessCovAsync();
	    } else {
	      v8ProcessCov = this._getMergedProcessCov();
	    }
	    const resultCountPerPath = new Map();

	    for (const v8ScriptCov of v8ProcessCov.result) {
	      try {
	        const sources = this._getSourceMap(v8ScriptCov);
	        const path = resolve(this.resolve, v8ScriptCov.url);
	        const converter = v8toIstanbul(path, this.wrapperLength, sources, (path) => {
	          if (this.excludeAfterRemap) {
	            return !this._shouldInstrument(path)
	          }
	        });
	        await converter.load();

	        if (resultCountPerPath.has(path)) {
	          resultCountPerPath.set(path, resultCountPerPath.get(path) + 1);
	        } else {
	          resultCountPerPath.set(path, 0);
	        }

	        converter.applyCoverage(v8ScriptCov.functions);
	        map.merge(converter.toIstanbul());
	      } catch (err) {
	        debuglog(`file: ${v8ScriptCov.url} error: ${err.stack}`);
	      }
	    }

	    this._allCoverageFiles = map;
	    return this._allCoverageFiles
	  }

	  /**
	   * Returns source-map and fake source file, if cached during Node.js'
	   * execution. This is used to support tools like ts-node, which transpile
	   * using runtime hooks.
	   *
	   * Note: requires Node.js 13+
	   *
	   * @return {Object} sourceMap and fake source file (created from line #s).
	   * @private
	   */
	  _getSourceMap (v8ScriptCov) {
	    const sources = {};
	    const sourceMapAndLineLengths = this.sourceMapCache[pathToFileURL(v8ScriptCov.url).href];
	    if (sourceMapAndLineLengths) {
	      // See: https://github.com/nodejs/node/pull/34305
	      if (!sourceMapAndLineLengths.data) return
	      sources.sourceMap = {
	        sourcemap: sourceMapAndLineLengths.data
	      };
	      if (sourceMapAndLineLengths.lineLengths) {
	        let source = '';
	        sourceMapAndLineLengths.lineLengths.forEach(length => {
	          source += `${''.padEnd(length, '.')}\n`;
	        });
	        sources.source = source;
	      }
	    }
	    return sources
	  }

	  /**
	   * Returns the merged V8 process coverage.
	   *
	   * The result is computed from the individual process coverages generated
	   * by Node. It represents the sum of their counts.
	   *
	   * @return {ProcessCov} Merged V8 process coverage.
	   * @private
	   */
	  _getMergedProcessCov () {
	    const { mergeProcessCovs } = requireLib();
	    const v8ProcessCovs = [];
	    const fileIndex = new Set(); // Set<string>
	    for (const v8ProcessCov of this._loadReports()) {
	      if (this._isCoverageObject(v8ProcessCov)) {
	        if (v8ProcessCov['source-map-cache']) {
	          Object.assign(this.sourceMapCache, this._normalizeSourceMapCache(v8ProcessCov['source-map-cache']));
	        }
	        v8ProcessCovs.push(this._normalizeProcessCov(v8ProcessCov, fileIndex));
	      }
	    }

	    if (this.all) {
	      const emptyReports = this._includeUncoveredFiles(fileIndex);
	      v8ProcessCovs.unshift({
	        result: emptyReports
	      });
	    }

	    return mergeProcessCovs(v8ProcessCovs)
	  }

	  /**
	   * Returns the merged V8 process coverage.
	   *
	   * It asynchronously and incrementally reads and merges individual process coverages
	   * generated by Node. This can be used via the `--merge-async` CLI arg.  It's intended
	   * to be used across a large multi-process test run.
	   *
	   * @return {ProcessCov} Merged V8 process coverage.
	   * @private
	   */
	  async _getMergedProcessCovAsync () {
	    const { mergeProcessCovs } = requireLib();
	    const fileIndex = new Set(); // Set<string>
	    let mergedCov = null;
	    for (const file of readdirSync(this.tempDirectory)) {
	      try {
	        const rawFile = await readFile(
	          resolve(this.tempDirectory, file),
	          'utf8'
	        );
	        let report = JSON.parse(rawFile);

	        if (this._isCoverageObject(report)) {
	          if (report['source-map-cache']) {
	            Object.assign(this.sourceMapCache, this._normalizeSourceMapCache(report['source-map-cache']));
	          }
	          report = this._normalizeProcessCov(report, fileIndex);
	          if (mergedCov) {
	            mergedCov = mergeProcessCovs([mergedCov, report]);
	          } else {
	            mergedCov = mergeProcessCovs([report]);
	          }
	        }
	      } catch (err) {
	        debuglog(`${err.stack}`);
	      }
	    }

	    if (this.all) {
	      const emptyReports = this._includeUncoveredFiles(fileIndex);
	      const emptyReport = {
	        result: emptyReports
	      };

	      mergedCov = mergeProcessCovs([emptyReport, mergedCov]);
	    }

	    return mergedCov
	  }

	  /**
	   * Adds empty coverage reports to account for uncovered/untested code.
	   * This is only done when the `--all` flag is present.
	   *
	   * @param {Set} fileIndex list of files that have coverage
	   * @returns {Array} list of empty coverage reports
	   */
	  _includeUncoveredFiles (fileIndex) {
	    const emptyReports = [];
	    const workingDirs = this.src;
	    const { extension } = this.exclude;
	    for (const workingDir of workingDirs) {
	      this.exclude.globSync(workingDir).forEach((f) => {
	        const fullPath = resolve(workingDir, f);
	        if (!fileIndex.has(fullPath)) {
	          const ext = extname(fullPath);
	          if (extension.includes(ext)) {
	            const stat = statSync(fullPath);
	            const sourceMap = getSourceMapFromFile(fullPath);
	            if (sourceMap) {
	              this.sourceMapCache[pathToFileURL(fullPath)] = { data: sourceMap };
	            }
	            emptyReports.push({
	              scriptId: 0,
	              url: resolve(fullPath),
	              functions: [{
	                functionName: '(empty-report)',
	                ranges: [{
	                  startOffset: 0,
	                  endOffset: stat.size,
	                  count: 0
	                }],
	                isBlockCoverage: true
	              }]
	            });
	          }
	        }
	      });
	    }

	    return emptyReports
	  }

	  /**
	   * Make sure v8ProcessCov actually contains coverage information.
	   *
	   * @return {boolean} does it look like v8ProcessCov?
	   * @private
	   */
	  _isCoverageObject (maybeV8ProcessCov) {
	    return maybeV8ProcessCov && Array.isArray(maybeV8ProcessCov.result)
	  }

	  /**
	   * Returns the list of V8 process coverages generated by Node.
	   *
	   * @return {ProcessCov[]} Process coverages generated by Node.
	   * @private
	   */
	  _loadReports () {
	    const reports = [];
	    for (const file of readdirSync(this.tempDirectory)) {
	      try {
	        reports.push(JSON.parse(readFileSync(
	          resolve(this.tempDirectory, file),
	          'utf8'
	        )));
	      } catch (err) {
	        debuglog(`${err.stack}`);
	      }
	    }
	    return reports
	  }

	  /**
	   * Normalizes a process coverage.
	   *
	   * This function replaces file URLs (`url` property) by their corresponding
	   * system-dependent path and applies the current inclusion rules to filter out
	   * the excluded script coverages.
	   *
	   * The result is a copy of the input, with script coverages filtered based
	   * on their `url` and the current inclusion rules.
	   * There is no deep cloning.
	   *
	   * @param v8ProcessCov V8 process coverage to normalize.
	   * @param fileIndex a Set<string> of paths discovered in coverage
	   * @return {v8ProcessCov} Normalized V8 process coverage.
	   * @private
	   */
	  _normalizeProcessCov (v8ProcessCov, fileIndex) {
	    const result = [];
	    for (const v8ScriptCov of v8ProcessCov.result) {
	      // https://github.com/nodejs/node/pull/35498 updates Node.js'
	      // builtin module filenames:
	      if (/^node:/.test(v8ScriptCov.url)) {
	        v8ScriptCov.url = `${v8ScriptCov.url.replace(/^node:/, '')}.js`;
	      }
	      if (/^file:\/\//.test(v8ScriptCov.url)) {
	        try {
	          v8ScriptCov.url = fileURLToPath(v8ScriptCov.url);
	          fileIndex.add(v8ScriptCov.url);
	        } catch (err) {
	          debuglog(`${err.stack}`);
	          continue
	        }
	      }
	      if ((!this.omitRelative || isAbsolute(v8ScriptCov.url))) {
	        if (this.excludeAfterRemap || this._shouldInstrument(v8ScriptCov.url)) {
	          result.push(v8ScriptCov);
	        }
	      }
	    }
	    return { result }
	  }

	  /**
	   * Normalizes a V8 source map cache.
	   *
	   * This function normalizes file URLs to a system-independent format.
	   *
	   * @param v8SourceMapCache V8 source map cache to normalize.
	   * @return {v8SourceMapCache} Normalized V8 source map cache.
	   * @private
	   */
	  _normalizeSourceMapCache (v8SourceMapCache) {
	    const cache = {};
	    for (const fileURL of Object.keys(v8SourceMapCache)) {
	      cache[pathToFileURL(fileURLToPath(fileURL)).href] = v8SourceMapCache[fileURL];
	    }
	    return cache
	  }

	  /**
	   * this.exclude.shouldInstrument with cache
	   *
	   * @private
	   * @return {boolean}
	   */
	  _shouldInstrument (filename) {
	    const cacheResult = this.shouldInstrumentCache.get(filename);
	    if (cacheResult !== undefined) {
	      return cacheResult
	    }

	    const result = this.exclude.shouldInstrument(filename);
	    this.shouldInstrumentCache.set(filename, result);
	    return result
	  }
	}

	report = function (opts) {
	  return new Report(opts)
	};
	return report;
}

var hasRequiredC8;

function requireC8 () {
	if (hasRequiredC8) return c8;
	hasRequiredC8 = 1;
	c8.Report = requireReport();
	return c8;
}

var c8Exports = requireC8();

// bazel will create the COVERAGE_OUTPUT_FILE whilst setting up the sandbox.
// therefore, should be doing a file size check rather than presence.
try {
    const stats = require$$0$1.statSync(process.env.COVERAGE_OUTPUT_FILE);
    if (stats.size != 0) {
        // early exit here does not affect the outcome of the tests.
        // bazel will only execute _lcov_merger when tests pass.
        process.exit(0);
    }
    // in case file doesn't exist or some other error is thrown, just ignore it.
} catch {}

const include = require$$0$1
    .readFileSync(process.env.COVERAGE_MANIFEST)
    .toString('utf8')
    .split('\n')
    .filter((f) => f != '');

// TODO: can or should we instrument files from other repositories as well?
// if so then the path.join call below will yield invalid paths since files will have external/wksp as their prefix.
const pwd = require$$0$2.join(
    process.env.JS_COVERAGE__RUNFILES,
    process.env.TEST_WORKSPACE
);
process.chdir(pwd);

new c8Exports.Report({
    include: include,
    exclude: include.length === 0 ? ['**'] : [],
    reportsDirectory: process.env.COVERAGE_DIR,
    tempDirectory: process.env.COVERAGE_DIR,
    resolve: '',
    src: pwd,
    all: true,
    reporter: ['lcovonly'],
})
    .run()
    .then(() => {
        require$$0$1.renameSync(
            require$$0$2.join(process.env.COVERAGE_DIR, 'lcov.info'),
            process.env.COVERAGE_OUTPUT_FILE
        );
    })
    .catch((err) => {
        console.error(err);
        process.exit(1);
    });
