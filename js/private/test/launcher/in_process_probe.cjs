// Reports what the launcher was responsible for. Shared by every probe target below, so the
// detection has to be target-independent.
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

// What the targets below configure through node_options, env NODE_OPTIONS, env NODE_ENV and
// env TZ. Each is asserted by one target only; the rest print an unasserted value.
console.log('TITLE=' + process.title)
console.log('NODE_ENV=' + process.env.NODE_ENV)
console.log('TZ_OFFSET=' + new Date(0).getTimezoneOffset())
