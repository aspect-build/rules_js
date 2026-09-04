"""Shared normalization for checked-in golden files."""

# Canonical bzlmod repo separators changed from ~~/~ (Bazel 7) to ++/+ (Bazel 8+), so a
# golden that names one has to be rewritten to match whichever Bazel is running.
REPO_SEPARATOR_NORMALIZE = (
    "sed -E -e 's/~~/++/g'" +
    " -e 's|([+][+][^/~]+)~([^/~]+)~([^/~]+)|\\1+\\2+\\3|g'" +
    " -e 's|([+][+][^/~]+)~([^/~]+)|\\1+\\2|g'"
)
