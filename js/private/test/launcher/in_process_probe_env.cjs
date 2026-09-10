// The same probe for a target whose env carries NODE_OPTIONS. Node parses that variable once, as
// it starts, so a launcher that ran the program in its own process would silently drop the option
// -- the launcher sets the target's env long after node booted. Reports both the path taken and
// whether the option actually reached node.
const launcherLoaded = Object.keys(require.cache).some((id) =>
    id.endsWith('/in_process_probe_env_bin_/in_process_probe_env_bin.cjs')
)
console.log('IN_LAUNCHER_PROCESS=' + (launcherLoaded ? 'yes' : 'no'))
console.log('TITLE=' + process.title)
