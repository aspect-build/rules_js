## Making the editor happy

Editors (and the language services they host) expect a couple of things:

-   third-party tooling like the TypeScript SDK under `<project root>/node_modules`
-   types for your first-party imports

Since rules_js puts the outputs under Bazel's `bazel-out` tree, the editor doesn't find them by default.

To get local tooling installed, you can continue to run `pnpm install` (or use whatever package manager your lockfile is for)
to get a `node_modules` tree in your project.
If there are many packages to install, you could reduce this by only installing the tooling
actually needed for non-Bazel workflows, like the `@types/*` packages and `typescript`.

To resolve first-party imports like `import '@myorg/my_lib'` to resolve in TypeScript, use the
`paths` key in the `tsconfig.json` file to list additional search locations.
This is the same thing you'd do outside of Bazel.
See [example](https://github.com/aspect-build/rules_ts/blob/74d54bda208695d7e8992520e560166875cfbce7/examples/simple/tsconfig.json#L4-L10).

## Bazel isn't seeing my changes to package.json

rules_js relies on what's in the `pnpm-lock.yaml` file.
Make sure your changes are reflected there.

Want a Bazel test to assert the lockfile isn't stale? See our `examples/assert_lockfile_to_to_date`.

## Can I edit files in `node_modules` for debugging?

Try running Bazel with `--experimental_check_output_files=false` so that your edits inside the `bazel-out/node_modules` tree are preserved.

## Can I use bazel-managed pnpm?

Yes, but it's a bit clumsy right now.

First, make sure you fetched it: `bazel fetch @pnpm//:*`

Then run `bazel run @nodejs_host//:node $(bazel info output_base)/external/pnpm/package/bin/pnpm.cjs`

You can use this recipe to make sure your developers run the exact same pnpm and node versions.

## Why can't Bazel fetch an npm package?

If the error looks like this: `failed to fetch. no such package '@npm__foo__1.2.3//': at offset 773, object has duplicate key`
then you are hitting https://github.com/bazelbuild/bazel/issues/15605

The workaround is to patch the package.json of any offending packages in npm_translate_lock, see https://github.com/aspect-build/rules_js/issues/148#issuecomment-1144378565.
Or, if a newer version of the package has fixed the duplicate keys, you could upgrade.

## In my monorepo, can Bazel output multiple packages under one dist/ folder?

Many projects have a structure like the following:

```
my-workspace/
├─ packages/
│  ├─ lib1/
│  └─ lib2/
└─ dist/
   ├─ lib1/
   └─ lib2/
```

However, Bazel has a constraint that outputs for a given Bazel package (a directory containing a `BUILD` file) must be written under the corresponding output folder. This means that you have two choices:

1. **Keep your output structure the same.** This implies there must be a single `BUILD` file under `my-workspace`, since this is the only Bazel package which can output to paths beneath `my-workspace/dist`. The downside is that this `BUILD` file may get long, accumulate a lot of `load` statements, and the paths inside will be longer.

The result looks like this:

```
my-workspace/
├─ BUILD.bazel
├─ packages/
│  ├─ lib1/
│  └─ lib2/
└─ bazel-bin/packages/
   ├─ lib1/
   └─ lib2/
```

2. **Change your output structure** to distribute `dist` folders beneath `lib1` and `lib2`. Now you can have `BUILD` files underneath each library, which is more Bazel-idiomatic.

The result looks like this:

```
my-workspace/
├─ packages/
│  ├─ lib1/
│  |  └─ BUILD.bazel
│  ├─ lib2/
│  |  └─ BUILD.bazel
└─ bazel-bin/packages/
   ├─ lib1/
   |  └─ dist/
   └─ lib2/
      └─ dist/
```

Note that when following option 2, it might require updating some configuration files which refer to the original output locations. For example, your `tsconfig.json` file might have a `paths` section which points to the `../../dist` folder.

To keep your legacy build system working during the migration, you might want to avoid changing those configuration files in-place. For this purpose, you can use [the `jq` rule](https://docs.aspect.build/aspect-build/bazel-lib/v1.0.0/docs/jq-docgen.html#jq) in place of `copy_to_bin`, using a `filter` expression so the copy of the configuration file in `bazel-bin` that's used by the Bazel build can have a different path than the configuration file in the source tree.
