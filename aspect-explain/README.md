# Execlog Creation Instructions
From rules_js
```
mkdir aspect-explain/out1

bazel --output_base $(pwd)/aspect-explain/out1 build //... --disk_cache= --experimental_execution_log_compact_file=compact.1.log

sudo rm -rf aspect-explain/out1

mkdir aspect-explain/out2

bazel --output_base $(pwd)/aspect-explain/out2 build //... --disk_cache= --experimental_execution_log_compact_file=compact.2.log

sudo rm -rf aspect-explain/out2
```

# Demo Instructions

From silo
```
git checkout ferret-poc-v2
bazel build //cli/pro
```

From rules_js
```
../silo/bazel-bin/cli/pro/pro_/pro explain --cache-misses ./aspect-explain/compact.1.log ./aspect-explain/compact.2.log
```

# Talking Points
If you build the following
```
bazel build //:.aspect_rules_js/node_modules/segfault-handler@1.3.0/lc
```

and look at the file it creates
```
bazel-out/darwin_arm64-fastbuild/bin/node_modules/.aspect_rules_js/segfault-handler@1.3.0/node_modules/segfault-handler/build/Makefile
```

You can see that it contains the bazel `execroot` / `output_base` paths within it. This path is non-hermetic and can be different based on the machine it is being run on. 


Docs: https://bazel.build/docs/user-manual#output-base
> By default, the output base is derived from the user's login name, and the name of the workspace directory (actually, its MD5 digest), so a typical value looks like: /var/tmp/google/_bazel_johndoe/d41d8cd98f00b204e9800998ecf8427e.
