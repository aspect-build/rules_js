// Reports two things the launcher is responsible for.
//
// The hermetic launcher's generated `.cjs` sits in a `<name>_/` directory beside the binary. It
// is in this process's require.cache only when the launcher loaded this program into its own
// node process rather than starting a second node on it.
const launcherLoaded = Object.keys(require.cache).some((id) =>
    id.endsWith('/in_process_probe_bin_/in_process_probe_bin.cjs')
)
console.log('IN_LAUNCHER_PROCESS=' + (launcherLoaded ? 'yes' : 'no'))

// A CommonJS program guarded by this check does nothing at all if the launcher loads it as an
// ordinary dependency instead of as the main module.
console.log('IS_MAIN_MODULE=' + (require.main === module ? 'yes' : 'no'))
