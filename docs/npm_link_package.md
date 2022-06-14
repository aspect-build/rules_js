<!-- Generated with Stardoc: http://skydoc.bazel.build -->

npm_link_package rule

<a id="#npm_link_package_direct"></a>

## npm_link_package_direct

<pre>
npm_link_package_direct(<a href="#npm_link_package_direct-name">name</a>, <a href="#npm_link_package_direct-package">package</a>, <a href="#npm_link_package_direct-src">src</a>)
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
| <a id="npm_link_package_direct-package"></a>package |  The package name to link to.<br><br>If unset, the package name of the src npm_link_package_store is used. If set, takes precendance over the package name in the src npm_link_package_store.   | String | optional | "" |
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
| <a id="npm_link_package_store-deps"></a>deps |  Other node packages store link targets one depends on mapped to the name to link them under in this packages deps.<br><br>        This should include *all* modules the program may need at runtime.<br><br>        You can find all the package store link targets in your repository with<br><br>        <pre><code>         bazel query ... | grep //:.aspect_rules_js | grep -v /dir | grep -v /pkg | grep -v /ref         </code></pre><br><br>        1st party deps will typically be versioned 0.0.0 (unless set to another version explicitly in         npm_link_package). For example,<br><br>        <pre><code>         //:.aspect_rules_js/node_modules/@mycorp/mylib/0.0.0         </code></pre><br><br>        3rd party package store link targets will include the version. For example,<br><br>        <pre><code>         //:.aspect_rules_js/node_modules/cliui/7.0.4         </code></pre><br><br>        If imported via npm_translate_lock, the version may include peer dep(s),<br><br>        <pre><code>         //:.aspect_rules_js/node_modules/debug/4.3.4_supports-color@8.1.1         </code></pre><br><br>        It could be also be a <code>github.com</code> url based version,<br><br>        <pre><code>         //:.aspect_rules_js/node_modules/debug/github.com/ngokevin/debug/9742c5f383a6f8046241920156236ade8ec30d53         </code></pre><br><br>        In general, package store link targets names for 3rd party packages that come from         <code>npm_translate_lock</code> start with <code>.aspect_rules_js/</code> then name passed to the <code>npm_link_all_packages</code> macro         (typically 'node_modules') followed by <code>/&lt;package&gt;/&lt;version&gt;</code> where <code>package</code> is the         package name (including @scope segment if any) and <code>version</code> is the specific version of         the package that comes from the pnpm-lock.yaml file.<br><br>        Package store link targets names for 3rd party package that come directly from an         <code>npm_import</code> start with <code>.aspect_rules_js/</code> then name passed to the <code>npm_import</code>'s <code>npm_link_imported_package</code>         macro (typically 'node_modules') followed by <code>/&lt;package&gt;/&lt;version&gt;</code> where <code>package</code>         matches the <code>package</code> attribute in the npm_import of the package and <code>version</code> matches the         <code>version</code> attribute.<br><br>        &gt; In typical usage, a node.js program sometimes requires modules which were         &gt; never declared as dependencies.         &gt; This pattern is typically used when the program has conditional behavior         &gt; that is enabled when the module is found (like a plugin) but the program         &gt; also runs without the dependency.         &gt;          &gt; This is possible because node.js doesn't enforce the dependencies are sound.         &gt; All files under <code>node_modules</code> are available to any program.         &gt; In contrast, Bazel makes it possible to make builds hermetic, which means that         &gt; all dependencies of a program must be declared when running in Bazel's sandbox.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: Label -> String</a> | optional | {} |
| <a id="npm_link_package_store-package"></a>package |  The package name to link to.<br><br>If unset, the package name in the NpmPackageInfo src must be set. If set, takes precendance over the package name in the NpmPackageInfo src.   | String | optional | "" |
| <a id="npm_link_package_store-src"></a>src |  A npm_package target or or any other target that provides a NpmPackageInfo.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="npm_link_package_store-version"></a>version |  The package version being linked.<br><br>If unset, the package version in the NpmPackageInfo src must be set. If set, takes precendance over the package version in the NpmPackageInfo src.   | String | optional | "" |


<a id="#npm_link_package"></a>

## npm_link_package

<pre>
npm_link_package(<a href="#npm_link_package-name">name</a>, <a href="#npm_link_package-version">version</a>, <a href="#npm_link_package-root_package">root_package</a>, <a href="#npm_link_package-direct">direct</a>, <a href="#npm_link_package-src">src</a>, <a href="#npm_link_package-deps">deps</a>, <a href="#npm_link_package-fail_if_no_link">fail_if_no_link</a>, <a href="#npm_link_package-auto_manual">auto_manual</a>,
                 <a href="#npm_link_package-visibility">visibility</a>, <a href="#npm_link_package-kwargs">kwargs</a>)
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
| <a id="npm_link_package-name"></a>name |  The name of the direct link target to create (if linked directly). For first-party deps linked across a workspace, the name must match in all packages being linked as it is used to derive the virtual store link target name.   |  none |
| <a id="npm_link_package-version"></a>version |  version used to identify the package in the virtual store   |  <code>"0.0.0"</code> |
| <a id="npm_link_package-root_package"></a>root_package |  the root package where the node_modules virtual store is linked to   |  <code>""</code> |
| <a id="npm_link_package-direct"></a>direct |  whether or not to link a direct dependency in this package For 3rd party deps fetched with an npm_import, direct may not be specified if link_packages is set on the npm_import.   |  <code>True</code> |
| <a id="npm_link_package-src"></a>src |  the npm_package target to link; may only to be specified when linking in the root package   |  <code>None</code> |
| <a id="npm_link_package-deps"></a>deps |  list of npm_link_package_store; may only to be specified when linking in the root package   |  <code>{}</code> |
| <a id="npm_link_package-fail_if_no_link"></a>fail_if_no_link |  whether or not to fail if this is called in a package that is not the root package and with direct false   |  <code>True</code> |
| <a id="npm_link_package-auto_manual"></a>auto_manual |  whether or not to automatically add a manual tag to the generated targets Links tagged "manual" dy default is desirable so that they are not built by <code>bazel build ...</code> if they are unused downstream. For 3rd party deps, this is particularly important so that 3rd party deps are not fetched at all unless they are used.   |  <code>True</code> |
| <a id="npm_link_package-visibility"></a>visibility |  the visibility of the generated targets   |  <code>["//visibility:public"]</code> |
| <a id="npm_link_package-kwargs"></a>kwargs |  see attributes of npm_link_package_store rule   |  none |

**RETURNS**

Label of the npm_link_package_direct if created, else None


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


