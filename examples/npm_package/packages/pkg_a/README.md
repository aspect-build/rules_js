# @mycorp/pkg-a package

'@mycorp/pkg-a' is an example of a package that is depended on in `package.json` file(s) through the workspace with,

``
"@mycorp/pkg-a": "workspace:\*"

```

which results it it being linked automatically via `npm_link_all_packages`.
```
