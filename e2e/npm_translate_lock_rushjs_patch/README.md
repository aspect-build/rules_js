# RushJS pnpm patch example

## Steps to reproduce

1.  Install RushJS
    ```bash
    npm install -g @microsoft/rush@5.97.1
    ```

1.  Create rush repository
    ```bash
    rush init
    ```

1.  Update `pnpnVersion` in `rush.json` to `7.33.6`

1.  Add subdir project to `rush.json`
    ```json
    cd subdir
    rush add --package debug@4.3.4
    ```

1.  Add `debug` package to `subdir` project.

1.  Check RushJS setup
    ```bash
    rush update
    ```

1.  Copy Bazel project setup from `../npm_translate_lock_subdir_patch`.
    -   pnpm_lock location is `//:common/config/rush/pnpm-lock.yaml`

1.  Patch `debug` package.
    ```bash
    cd subdir
    rush-pnpm patch --edit-dir .rush/debug@4.3.4 debug@4.3.4
    # update src/index.js
    echo "module.exports.patched = true;" >> .rush/debug@4.3.4/src/index.js
    pnpm patch-commit .rush/debug@4.3.4
    ```

1. Create package with layout suitable for npm_translate_lock under `common/bazel` directory.
    ```bash
    # remap ../pnpm-patches/ under patches adjacent to pnpm-lock.yaml file
    cd common/bazel
    ln -s ../pnpm-patches/ patches
    ln -s ../config/rush/pnpm-lock.yaml pnpm-lock.yaml
    ```
