This e2e tests that an imported git dependency has it's .git metadata folder removed. The git
dependency is fetched via npm_import rather than npm_translate_lock because pnpm will automatically
convert `git+ssh` protocols to `https` in the lockfile when the repository is public, preventing us
from exercising the ssh logic specifically.
