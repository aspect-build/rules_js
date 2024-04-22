<!-- Generated with Stardoc: http://skydoc.bazel.build -->

npm_link_package rule

<a id="npm_link_package"></a>

## npm_link_package

<pre>
npm_link_package(<a href="#npm_link_package-name">name</a>, <a href="#npm_link_package-root_package">root_package</a>, <a href="#npm_link_package-link">link</a>, <a href="#npm_link_package-src">src</a>, <a href="#npm_link_package-deps">deps</a>, <a href="#npm_link_package-fail_if_no_link">fail_if_no_link</a>, <a href="#npm_link_package-auto_manual">auto_manual</a>, <a href="#npm_link_package-visibility">visibility</a>,
                 <a href="#npm_link_package-kwargs">kwargs</a>)
</pre>

"Links an npm package to node_modules if link is True.

When called at the root_package, a package store target is generated named `link__{bazelified_name}__store`.

When linking, a `{name}` target is generated which consists of the `node_modules/<package>` symlink and transitively
its package store link and the package store links of the transitive closure of deps.

When linking, `{name}/dir` filegroup is also generated that refers to a directory artifact can be used to access
the package directory for creating entry points or accessing files in the package.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="npm_link_package-name"></a>name |  The name of the link target to create if `link` is True. For first-party deps linked across a workspace, the name must match in all packages being linked as it is used to derive the package store link target name.   |  none |
| <a id="npm_link_package-root_package"></a>root_package |  the root package where the node_modules package store is linked to   |  `""` |
| <a id="npm_link_package-link"></a>link |  whether or not to link in this package If false, only the npm_package_store target will be created _if_ this is called in the `root_package`.   |  `True` |
| <a id="npm_link_package-src"></a>src |  the npm_package target to link; may only to be specified when linking in the root package   |  `None` |
| <a id="npm_link_package-deps"></a>deps |  list of npm_package_store; may only to be specified when linking in the root package   |  `{}` |
| <a id="npm_link_package-fail_if_no_link"></a>fail_if_no_link |  whether or not to fail if this is called in a package that is not the root package and `link` is False   |  `True` |
| <a id="npm_link_package-auto_manual"></a>auto_manual |  whether or not to automatically add a manual tag to the generated targets Links tagged "manual" dy default is desirable so that they are not built by `bazel build ...` if they are unused downstream. For 3rd party deps, this is particularly important so that 3rd party deps are not fetched at all unless they are used.   |  `True` |
| <a id="npm_link_package-visibility"></a>visibility |  the visibility of the link target   |  `["//visibility:public"]` |
| <a id="npm_link_package-kwargs"></a>kwargs |  see attributes of npm_package_store rule   |  none |

**RETURNS**

Label of the npm_link_package_store if created, else None


