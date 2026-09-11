// The same probe for a target whose env sets NODE_ENV. Node reads nothing from that variable --
// it is a userland convention -- so setting it after node started is no different from setting it
// before, and the program has to keep the launcher's own process.
const launcherLoaded = Object.keys(require.cache).some((id) =>
    id.endsWith(
        '/in_process_probe_node_env_bin_/in_process_probe_node_env_bin.cjs'
    )
)
console.log('IN_LAUNCHER_PROCESS=' + (launcherLoaded ? 'yes' : 'no'))
console.log('NODE_ENV=' + process.env.NODE_ENV)
