# WIP

## Test packages

In this folder, we have a `package.json` with some test packages from our `@aspect-test` npm scope.

```
package.json
  └─ dependencies
     ├── @aspect-test/bar@2.0.0
     │   └── @aspect-test/qar@1.0.0
     ├── @aspect-test/foo@2.0.0
     │   └── @aspect-test/qar@2.0.0
     └── @aspect-test/qar@2.0.0
```

The flattened transitive closer of this dependency tree is:

```
@aspect-test/bar@2.0.0
@aspect-test/foo@2.0.0
@aspect-test/qar@1.0.0
@aspect-test/qar@2.0.0
```

## With pnpm

Lets examine how pnpm handles this `package.json` since the aim is to mimic the pnpm node_modules tree in the bazel-out tree.

Running pnpm install in this folder yields,

```
$ pnpm install
Lockfile is up-to-date, resolution step is skipped
Packages: +4
++++
Packages are hard linked from the content-addressable store to the virtual store.
  Content-addressable store is at: /Users/greg/Library/pnpm/store/v3
  Virtual store is at:             node_modules/.pnpm

dependencies:
+ @aspect-test/bar 2.0.0
+ @aspect-test/foo 2.0.0
+ @aspect-test/qar 2.0.0

Progress: resolved 4, reused 4, downloaded 0, added 4, done
```

The `node_modules` folder houses the symlinked node_modules structure with a `.pnpm` virtual store directory.

```
$ ls -la node_modules
drwxr-xr-x   5 greg  staff  160  7 Apr 22:42 .bin
drwxr-xr-x   7 greg  staff  224  7 Apr 22:42 .pnpm
drwxr-xr-x   5 greg  staff  160  7 Apr 22:42 @aspect-test
```

The `@aspect-test/bar`, `@aspect-test/foo` & `@aspect-test/qar` are symlinks into the `.pnpm` virtual store:

```
$ ls -la node_modules/@aspect-test
lrwxr-xr-x  1 greg  staff   73  7 Apr 22:42 bar -> ../.pnpm/@aspect-test+bar@2.0.0/node_modules/@aspect-test/bar
lrwxr-xr-x  1 greg  staff   73  7 Apr 22:42 foo -> ../.pnpm/@aspect-test+foo@2.0.0/node_modules/@aspect-test/foo
lrwxr-xr-x  1 greg  staff   73  7 Apr 22:42 qar -> ../.pnpm/@aspect-test+qar@2.0.0/node_modules/@aspect-test/qar
```

The `node_modules/.pnpm` virtual store has a flat list of the complete transitive closure of packages at all versions

```
$ ls -la node_modules/.pnpm
drwxr-xr-x  3 greg  staff    96  7 Apr 22:42 @aspect-test+bar@2.0.0
drwxr-xr-x  3 greg  staff    96  7 Apr 22:42 @aspect-test+foo@2.0.0
drwxr-xr-x  3 greg  staff    96  7 Apr 22:42 @aspect-test+qar@1.0.0
drwxr-xr-x  3 greg  staff    96  7 Apr 22:42 @aspect-test+qar@2.0.0
```

The overall structure looks like this:

```
node_modules
  ├── .bin
  |  ├── bar
  |  ├── foo
  |  └── qar
  |
  ├── .pnpm (virtual store)
  |   ├── @aspect-test+bar@2.0.0
  |   |   └── node_modules
  |   |       └── @aspect-test
  |   |           ├── bar
  |   |           |   └── ... hard-links to <store>/bar@2.0.0
  |   |           └── qar -> ../../../@aspect-test+qar@1.0.0/node_modules/@aspect-test/qar
  |   |
  |   ├── @aspect-test+foo@2.0.0
  |   |   └── node_modules
  |   |       └── @aspect-test
  |   |           ├── foo
  |   |           |   └── ... hard-links to <store>/foo@2.0.0
  |   |           └── qar -> ../../../@aspect-test+qar@2.0.0/node_modules/@aspect-test/qar
  |   |
  |   ├── @aspect-test+qar@1.0.0
  |   |   └── node_modules
  |   |       └── @aspect-test
  |   |           └── qar
  |   |              └── ... hard-links to <store>/qar@1.0.0
  |   |
  |   └── @aspect-test+qar@2.0.0
  |       └── node_modules
  |           └── @aspect-test
  |               └── qar
  |                   └── ... hard-links to <store>/qar@2.0.0
  |
  └─ @aspect-test
     ├── bar -> ../.pnpm/@aspect-test+bar@2.0.0/node_modules/@aspect-test/bar
     ├── foo -> ../.pnpm/@aspect-test+foo@2.0.0/node_modules/@aspect-test/foo
     └── qar -> ../.pnpm/@aspect-test+qar@2.0.0/node_modules/@aspect-test/qar
```

More documentation and reasoning on this structure here https://pnpm.io/symlinked-node-modules-structure.

## With bazel

Under bazel, we can leverage the external repository cache (download cache) to locally cache all archives downloaded from the npm registry.
This differs from the pnpm CAS storage as that storage is per file from extract archives. Under bazel the package archives are extracted
when the `npm_import` repository rule is executed.

The external repositories that `npm_import` creates (one per package in the transitive closure) are a flat list of all packages at all versions.

For the set of packages here. these are:

```
npm__aspect-test_bar-2.0.0
npm__aspect-test_foo-2.0.0
npm__aspect-test_qar-1.0.0
npm__aspect-test_qar-2.0.0
```

In each of these external repositories, there is a `copy_directory` target to create a TreeArtifact for each package which can be used as an input to rules.
If a package has postinstall or preinstall scripts, these will be handled by a postinstall rule and the TreeArtifact produced by that target
will be used downstream instead of the pristine downloaded, extracted and copied artifact.

The desired node_modules structure in bazel-out should look very similar to the pnpm node_modules symlink structure:

```
bazel-out/<platform>/bin/path/to/package
  ├── package.json
  ├── pnpm-lock.yaml
  └── node_modules
      ├── .bin
      |   ├── bar
      |   ├── foo
      |   └── qar
      |
      ├── .bazel (virtual store)
      |   ├── @aspect-test+bar@2.0.0
      |   |   └── node_modules
      |   |       └── @aspect-test
      |   |           ├── bar
      |   |           |   └── ... TreeArtifact
      |   |           └── qar -> ../../../@aspect-test+qar@1.0.0/node_modules/@aspect-test/qar
      |   |
      |   ├── @aspect-test+foo@2.0.0
      |   |   └── node_modules
      |   |       └── @aspect-test
      |   |           ├── foo
      |   |           |   └── ... TreeArtifact
      |   |           └── qar -> ../../../@aspect-test+qar@2.0.0/node_modules/@aspect-test/qar
      |   |
      |   ├── @aspect-test+qar@1.0.0
      |   |   └── node_modules
      |   |       └── @aspect-test
      |   |           └── qar
      |   |               └── ... TreeArtifact
      |   |
      |   └── @aspect-test+qar@2.0.0
      |       └── node_modules
      |           └── @aspect-test
      |               └── qar
      |                   └── ... TreeArtifact
      |
      └── @aspect-test
          ├── bar -> ../.bazel/@aspect-test+bar@2.0.0/node_modules/@aspect-test/bar
          ├── foo -> ../.bazel/@aspect-test+foo@2.0.0/node_modules/@aspect-test/foo
          └── qar -> ../.bazel/@aspect-test+qar@2.0.0/node_modules/@aspect-test/qar
```

We can determine the above structure from pnpm lock file alone.

For a given package such as `@aspect-test/bar@2.0.0` we would need the following output artifacts:

* `//path/to/package:node_modules/.bin/bar`: output file
* `//path/to/package:node_modules/.bazel/@aspect-test+bar@2.0.0/node_modules/@aspect-test/bar`: output tree artifact
* `//path/to/package:node_modules/.bazel/@aspect-test+bar@2.0.0/node_modules/@aspect-test/qar`: output symlink -> `../../../@aspect-test+qar@1.0.0/node_modules/@aspect-test/qar`
* `//path/to/package:node_modules/@aspect-test/bar`: output symlink -> `../.bazel/@aspect-test+bar@2.0.0/node_modules/@aspect-test/bar`

Key to this approach is that these output artifacts are in the same package as the `package.json` file.

This would likely mean that the convenience target `@npm//@aspect-test/bar` would be an alias to the target that generates all of these such as `@//path/to/package:npm__@aspect-test__bar`.

This way, when you add a data dependency on `@npm//@aspect-test/bar`, you are simply adding these outputs and the outputs of its transitive deps to your sandbox and your runfiles tree that are already in the correct node_modules structure.

TODO: figure out how first party deps come in to play

# You've got the output tree covered. What about resolving from the source tree?

In the legacy linker, we symlink a node_modules tree into the execroot source tree. For example,

`execroot/path/to/package/node_modules` is a symlink to `execroot/bazel-out/<platform>/bin/path/to/package/node_modules`.

This means that you can use node_modules resolution from a source file in the execroot to resolve packages. Although this works, it comes with a major flaw: outside of the sandbox `execroot/path/to/package/node_modules` collides with the user managed `node_modules` folder in the `path/to/package` directory of the workspace.

This means that outside of the sandbox, bazel will create symlinks into the source tree which is undesirable. If the user has already created a `node_modules` folder then a require from a source file can end up resolving into the user managed node_modules which is non-hermetic.

The proposed approach for rules_js is to always copy source files to the output tree behind the scenes in rules. This avoids bazel managed node_modules from getting conflated with user managed node_modules. It also means that we won't have to teach tools such as `tsc` to resolve out of multiple trees as we currently have to do with `rootDirs` pointing to every possible bazel-out variant or with the `resolveFromOutputDir` feature we drafted that is currently up for review (https://github.com/microsoft/TypeScript/pull/48190).