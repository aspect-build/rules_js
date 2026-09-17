// Reports the details of the environment that the launcher influences.
//
// The hermetic launcher's generated `.cjs` sits at `<name>_/<name>.cjs` beside the binary, so the
// shape identifies it whichever target loaded us. It is in this process's require.cache only when
// the launcher ran this program in its own node process rather than starting a second node on it.
const launcherLoaded = Object.keys(require.cache).some((id) =>
    /\/([^/]+)_\/\1\.cjs$/.test(id)
)
console.log('IN_LAUNCHER_PROCESS=' + (launcherLoaded ? 'yes' : 'no'))
console.log('IS_MAIN_MODULE=' + (require.main === module ? 'yes' : 'no'))
console.log('TITLE=' + process.title)
console.log('NODE_ENV=' + process.env.NODE_ENV)
console.log('TZ_OFFSET=' + new Date(0).getTimezoneOffset())
