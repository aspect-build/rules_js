// The name of this file is the test: it contains an apostrophe, which is legal in a
// Bazel label and which the JavaScript launcher used to splice unescaped into a
// single-quoted string literal, making the generated launcher a syntax error. A space
// is in there too, since the same substitution also lands inside a template literal.
console.log('entry point with an apostrophe ran')
