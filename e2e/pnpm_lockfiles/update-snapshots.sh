#!/usr/bin/env bash

bazel run @@//v54:repos
bazel run @@//v60:repos
bazel run @@//v61:repos
bazel run @@//v90:repos
bazel run @@//v101:repos

bazel run --enable_bzlmod=false @@//v54:wksp-repos
bazel run --enable_bzlmod=false @@//v60:wksp-repos
bazel run --enable_bzlmod=false @@//v61:wksp-repos
bazel run --enable_bzlmod=false @@//v90:wksp-repos
bazel run --enable_bzlmod=false @@//v101:wksp-repos
