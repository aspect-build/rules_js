// Entry point of a js_binary that is only ever built as the tool of an action, so that its copy in
// the bin directory exists in the exec configuration alone. See case 8 in BUILD.bazel.
process.stdout.write('NO_RUNFILES_ENTRY_POINT\n')
