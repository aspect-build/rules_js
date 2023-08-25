<!-- Manually created. -->

npm_link_all_packages repository rule


<a id="npm_link_all_packages"></a>

## npm_link_all_packages

<pre>
npm_link_all_packages(name, imported_links, visibility, kwargs)
</pre>

Generated list of `npm_link_package()` target generators and first-party linked packages corresponding to the packages in the pnpm-lock.yaml file.

**PARAMETERS**

| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| name | name of catch all target to generate for all packages linked |  none |
| imported_links | optional list link functions from manually imported packages that were fetched with npm_import rules |  none |

For example,

```
load("@npm//:defs.bzl", "npm_link_all_packages")
load("@npm_meaning-of-life__links//:defs.bzl", npm_link_meaning_of_life = "npm_link_imported_package")

npm_link_all_packages(
    name = "node_modules",
    imported_links = [
        npm_link_meaning_of_life,
    ],
)```
