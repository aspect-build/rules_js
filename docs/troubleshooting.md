# Common troubleshooting tips

## Module not found errors

This is the most common error rules_js users encounter.
These problems generally stem from a runtime `require` call of some library which was not declared as a dependency.

Fortunately, these problems are not unique to Bazel.
As described in https://github.com/aspect-build/rules_js/blob/main/docs/pnpm.md#hoisting, rules_js
should behave the same way `pnpm` does with `hoist=false`.
These problems are also reproducible under [Yarn PnP](https://yarnpkg.com/features/pnp) because it
also relies on correct dependencies.

The Node.js documentation describes the algorithm used:
https://nodejs.org/api/modules.html#loading-from-node_modules-folders

Since the resolution starts from the callsite, the remedy depends on where the `require` statement appears.

### require appears in your code

This is the case when you write a `config.js` file and pass it to a tool.

> This is the "ideal" way for JavaScript libraries to be configured, because it allows an easy
> "symmetry" where you `require` a library and declare your dependency on it in the same place.

In this case you should add the runtime dependency to your BUILD file where the `config.js` is a source.

For example,

```starlark
js_library(
    name = "requires_foo",
    srcs = ["config.js"],                  # contains "require('foo')"
    data = ["//my/pkg:node_modules/foo"],  # satisfies that require
)
```

### require appears in third-party code

This case itself breaks down into three possible remedies, depending on whether you can move the
require to your own code, the missing dependency can be considered a "bug",
or the third-party package uses the "plugin pattern" to discover its
plugins dynamically at runtime based on finding them based on a string you provided.

#### The `require` can move to first-party

This is the most principled solution. In many cases, a library that accepts the name of a package as
a string will also accept it as an object, so you can refactor `config: ['some-package']` to
`config: [require('some-package')]`. You may need to change from json or yaml config to a JavaScript
config file to allow the `require` syntax.

Once you've done this, it's handled like the "require appears in your code" case above.

#### It's a bug

This is the case when a package has a `require` statement in its runtime code for some package, but
it doesn't list that package in its `package.json`, or lists it only as a `devDependency`.

pnpm and Yarn PnP will hit the same bug. Conveniently, there's already a shared database used by
both projects to list these, along with the missing dependency edge:
https://github.com/yarnpkg/berry/blob/master/packages/yarnpkg-extensions/sources/index.ts

> We should use this database under Bazel as well. Follow
> https://github.com/aspect-build/rules_js/issues/1215.

The recommended fix for both pnpm and rules_js is to use
[pnpm.packageExtensions](https://pnpm.io/package_json#pnpmpackageextensions)
in your `package.json` to add the missing `dependencies` or `peerDependencies`.

Example,

https://github.com/aspect-build/rules_js/blob/a8c192eed0e553acb7000beee00c60d60a32ed82/package.json#L12

Make sure you run `pnpm install` after changing `package.json`, as rules_js only reads the
`pnpm-lock.yaml` file to gather dependency information.

#### It's a plugin

Sometimes the package intentionally doesn't list dependencies, because it discovers them at runtime.
`eslint` and `prettier` are common typical examples.

The solution is based on pnpm's [public-hoist-pattern](https://pnpm.io/npmrc#public-hoist-pattern).
Use the [`public_hoist_packages` attribute of `npm_translate_lock`](./npm_translate_lock.md#npm_translate_lock-public_hoist_packages). This makes the `require` statement appear in the
"public" root of the `node_modules` tree, so the resolution algorithm will search sibling packages.

Example:

https://github.com/aspect-build/bazel-examples/blob/75bbf7b5f4ed9c9c0e4901e52c8fe610ea680621/react-cra/MODULE.bazel#L20-L23

> NB: We plan to add support for the `.npmrc` `public-hoist-pattern` setting to `rules_js` in a future release.
> For now, you must emulate public-hoist-pattern in `rules_js` using the `public_hoist_packages` attribute shown above.
