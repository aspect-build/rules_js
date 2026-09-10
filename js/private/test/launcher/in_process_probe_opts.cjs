// The same probe for a target carrying node_options, whose launcher name differs. node_options
// can only be applied by starting node again, so this must report the exec path.
const launcherLoaded = Object.keys(require.cache).some((id) =>
    id.endsWith('/in_process_probe_opts_bin_/in_process_probe_opts_bin.cjs')
)
console.log('IN_LAUNCHER_PROCESS=' + (launcherLoaded ? 'yes' : 'no'))
