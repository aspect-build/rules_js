// Reports various details about the environment that are influenced by the launcher.
//
// The hermetic launcher's generated `.cjs` sits at `<name>_/<name>.cjs` beside the binary, so the
// shape identifies it whichever target loaded us. It is in this process's require.cache only when
// the launcher ran this program in its own node process rather than starting a second node on it.
const launcherLoaded = Object.keys(require.cache).some((id) =>
    /\/([^/]+)_\/\1\.cjs$/.test(id)
)
console.log('IN_LAUNCHER_PROCESS=' + (launcherLoaded ? 'yes' : 'no'))

// A CommonJS program guarded by this check does nothing at all if the launcher loads it as an
// ordinary dependency instead of as the main module.
console.log('IS_MAIN_MODULE=' + (require.main === module ? 'yes' : 'no'))

// What the test targets configure through node_options and the environment variables
// NODE_OPTIONS, NODE_ENV, and TZ.
console.log('TITLE=' + process.title)
console.log('NODE_ENV=' + process.env.NODE_ENV)
console.log('TZ_OFFSET=' + new Date(0).getTimezoneOffset())
