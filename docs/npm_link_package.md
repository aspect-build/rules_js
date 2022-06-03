<!-- Generated with Stardoc: http://skydoc.bazel.build -->

npm_link_package rule

<a id="#npm_link_package_direct"></a>

## npm_link_package_direct

<pre>
npm_link_package_direct(<a href="#npm_link_package_direct-name">name</a>, <a href="#npm_link_package_direct-src">src</a>)
</pre>

Defines a node package that is linked into a node_modules tree as a direct dependency.

This is used in co-ordination with the npm_link_package_store rule that links into the
node_modules/.apsect_rules_js virtual store with a pnpm style symlinked node_modules output tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="npm_link_package_direct-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="npm_link_package_direct-src"></a>src |  The npm_link_package target to link as a direct dependency.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#npm_link_package_store"></a>

## npm_link_package_store

<pre>
npm_link_package_store(<a href="#npm_link_package_store-name">name</a>, <a href="#npm_link_package_store-deps">deps</a>, <a href="#npm_link_package_store-package">package</a>, <a href="#npm_link_package_store-src">src</a>, <a href="#npm_link_package_store-version">version</a>)
</pre>

Defines a node package that is linked into a node_modules tree.

The node package is linked with a pnpm style symlinked node_modules output tree.

The term "package" is defined at
<https://nodejs.org/docs/latest-v16.x/api/packages.html>

See https://pnpm.io/symlinked-node-modules-structure for more information on
the symlinked node_modules structure.
Npm may also support a symlinked node_modules structure called
"Isolated mode" in the future:
https://github.com/npm/rfcs/blob/main/accepted/0042-isolated-mode.md.


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="npm_link_package_store-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="npm_link_package_store-deps"></a>deps |  Other node packages this one depends on.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="npm_link_package_store-package"></a>package |  The package name to link to.<br><br>If unset, the package name in the NpmPackageInfo src must be set. If set, takes precendance over the package name in the NpmPackageInfo src.   | String | optional | "" |
| <a id="npm_link_package_store-src"></a>src |  A npm_package target or or any other target that provides a NpmPackageInfo.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="npm_link_package_store-version"></a>version |  The package version being linked.<br><br>If unset, the package version in the NpmPackageInfo src must be set. If set, takes precendance over the package version in the NpmPackageInfo src.   | String | optional | "" |


<a id="#npm_link_package"></a>

## npm_link_package

<pre>
npm_link_package(<a href="#npm_link_package-name">name</a>, <a href="#npm_link_package-root_package">root_package</a>, <a href="#npm_link_package-direct">direct</a>, <a href="#npm_link_package-src">src</a>, <a href="#npm_link_package-deps">deps</a>, <a href="#npm_link_package-fail_if_no_link">fail_if_no_link</a>, <a href="#npm_link_package-auto_manual">auto_manual</a>, <a href="#npm_link_package-visibility">visibility</a>,
                 <a href="#npm_link_package-kwargs">kwargs</a>)
</pre>

"Links an npm package to the virtual store if in the root package and directly to node_modules if direct is True.

When called at the root_package, a virtual store target is generated named "link__{bazelified_name}__store".

When linking direct, a "{name}" target is generated which consists of the direct node_modules link and transitively
its virtual store link and the virtual store links of the transitive closure of deps.

When linking direct, "{name}/dir" filegroup is also generated that refers to a directory artifact can be used to access
the package directory for creating entry points or accessing files in the package.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_link_package-name"></a>name |  The name of the direct alias target to create if linked directly.   |  none |
| <a id="npm_link_package-root_package"></a>root_package |  the root package where the node_modules virtual store is linked to   |  <code>""</code> |
| <a id="npm_link_package-direct"></a>direct |  whether or not to link a direct dependency in this package For 3rd party deps fetched with an npm_import, direct may not be specified if link_packages is set on the npm_import.   |  <code>True</code> |
| <a id="npm_link_package-src"></a>src |  the npm_package target to link; may only to be specified when linking in the root package   |  <code>None</code> |
| <a id="npm_link_package-deps"></a>deps |  list of npm_link_package_store; may only to be specified when linking in the root package   |  <code>[]</code> |
| <a id="npm_link_package-fail_if_no_link"></a>fail_if_no_link |  whether or not to fail if this is called in a package that is not the root package and with direct false   |  <code>True</code> |
| <a id="npm_link_package-auto_manual"></a>auto_manual |  whether or not to automatically add a manual tag to the generated targets Links tagged "manual" dy default is desirable so that they are not built by <code>bazel build ...</code> if they are unused downstream. For 3rd party deps, this is particularly important so that 3rd party deps are not fetched at all unless they are used.   |  <code>True</code> |
| <a id="npm_link_package-visibility"></a>visibility |  the visibility of the generated targets   |  <code>["//visibility:public"]</code> |
| <a id="npm_link_package-kwargs"></a>kwargs |  see attributes of npm_link_package_store rule   |  none |

**RETURNS**

Label of the npm_link_package_direct if created, else None


<a id="#npm_link_package_dep"></a>

## npm_link_package_dep

<pre>
npm_link_package_dep(<a href="#npm_link_package_dep-name">name</a>, <a href="#npm_link_package_dep-version">version</a>, <a href="#npm_link_package_dep-root_package">root_package</a>)
</pre>

Returns the label to the npm_link_package store for a package.

This can be used to generate virtual store target names for the deps list
of a npm_link_package.

Example root BUILD.file where the virtual store is linked by default,

```
load("@npm//:defs.bzl", "npm_link_all_packages")
load("@aspect_rules_js//:defs.bzl", "npm_link_package")

# Links all packages from the `translate_pnpm_lock(name = "npm", pnpm_lock = "//:pnpm-lock.yaml")`
# repository rule.
npm_link_all_packages(name = "node_modules")

# Link a first party `@lib/foo` defined by the `npm_package` `//lib/foo:foo` target.
npm_link_package(
    name = "node_modules/@lib/foo",
    src = "//lib/foo",
)

# Link a first party `@lib/bar` defined by the `npm_package` `//lib/bar:bar` target
# that depends on `@lib/foo` and on `acorn` specified in `package.json` and fetched
# with `translate_pnpm_lock`
npm_link_package(
    name = "link_lib_bar",
    src = "//lib/bar",
    deps = [
        npm_link_package_dep("node_modules/@lib/foo"),
        npm_link_package_dep("acorn", version = "8.4.0"),
    ],
)
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_link_package_dep-name"></a>name |  The name of the link target. For first-party packages, this must match the <code>name</code> passed to npm_link_package for the package in the root package when not linking at the root package.<br><br>For 3rd party deps fetched with an npm_import or via a translate_pnpm_lock repository rule, the name must match the <code>package</code> attribute of the corresponding <code>npm_import</code>. This is typically the npm package name.   |  none |
| <a id="npm_link_package_dep-version"></a>version |  The version of the package This should be left unset for first-party packages linked manually with npm_link_package.<br><br>For 3rd party deps fetched with an npm_import or via a translate_pnpm_lock repository rule, the package version is required to qualify the dependency. It must the <code>version</code> attribute of the corresponding <code>npm_import</code>.   |  <code>None</code> |
| <a id="npm_link_package_dep-root_package"></a>root_package |  The bazel package of the virtual store. Defaults to the current package   |  <code>""</code> |

**RETURNS**

The label of the direct link for the given package at the given link package,


<a id="#npm_link_package_direct_lib.implementation"></a>

## npm_link_package_direct_lib.implementation

<pre>
npm_link_package_direct_lib.implementation(<a href="#npm_link_package_direct_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_link_package_direct_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


<a id="#npm_link_package_store_lib.implementation"></a>

## npm_link_package_store_lib.implementation

<pre>
npm_link_package_store_lib.implementation(<a href="#npm_link_package_store_lib.implementation-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_link_package_store_lib.implementation-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


