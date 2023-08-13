import fs from 'fs'
import { createServer } from 'http-server'
import { createHttpTerminator } from 'http-terminator';
import path from 'path'
import puppeteer from 'puppeteer'
import webpack from 'webpack'
import HtmlWebpackPlugin from 'html-webpack-plugin'

// No test should take anywhere near 60s, but increase from 5s just in case 
// there is a delay when compiling the webpack app / launching Chrome when the 
// machine is under load
jasmine.DEFAULT_TIMEOUT_INTERVAL = 60000

describe('node_modules symlinks >', () => {
    const execRoot = process.env.JS_BINARY__EXECROOT
    const runfilesRoot = process.env.JS_BINARY__RUNFILES

    beforeAll(() => {
        // first ensure that the environment variables are strings with some 
        // length
        if (typeof execRoot !== 'string' || execRoot.length === 0) {
            throw new Error(`process.env.JS_BINARY__EXECROOT was empty`)
        }
        if (typeof runfilesRoot !== 'string' || runfilesRoot.length === 0) {
            throw new Error(`process.env.JS_BINARY__RUNFILES was empty`)
        }
    })

    it(`symlinks non-scoped node_modules to the exec root instead of runfiles to ensure bundlers see a single node_modules tree`, () => {
        const reactSymlink = fs.readlinkSync('./node_modules/react')

        expect(reactSymlink).toContain(execRoot)
        expect(reactSymlink).not.toContain(runfilesRoot)
    })

    it(`symlinks scoped (i.e. '@scope/package') node_modules to the exec root instead of runfiles to ensure bundlers see a single node_modules tree (https://github.com/aspect-build/rules_js/issues/1204)`, () => {
        const testComponentSymlink = fs.readlinkSync('./node_modules/@my-org/test-component')

        expect(testComponentSymlink).toContain(execRoot)
        expect(testComponentSymlink).not.toContain(runfilesRoot)
    })
})

describe('Webpack integration test >', () => {
    /*
     * Performs a test to make sure only a single node_modules tree is made
     * available in the js_run_devserver sandbox, as reported in
     * https://github.com/aspect-build/rules_js/issues/1204
     * 
     * This test is done as the following:
     * 
     * 1. Uses Webpack to compile a very basic React app that simply displays a 
     *    single <button> on the page. 
     * 2. Uses http-server to serve the generated index.html file.
     * 3. Uses puppeteer to launch Chrome and check for the <button> on the page.
     * 
     * If the button doesn't exist on the page, it's because multiple copies of 
     * React have entered the bundle and are causing an error to be thrown.
     */
    const port = 19000
    let browser
    let server

    beforeEach(async () => {
        // 1. Compile the webpack app - outputs to './dist'
        await compileApp('./app')

        // 2. Start http server
        server = await startServer('./dist', port)

        // 3. Launch Chrome for testing
        browser = await puppeteer.launch({ headless: 'new' })
    })

    afterEach(async () => {
        if (browser) await browser.close()
        if (server) await server.terminate()
    })

    it('displays the test component on the page (this confirms there is a single node_modules tree - should not get any React hooks errors)', async () => {
        const page = await browser.newPage()
        await page.goto(`http://localhost:${port}`)

        try {
            await page.waitForSelector('button', { timeout: 10000 })
        } catch (error) {
            console.error(
                `Could not find the <button> element that would be displayed on the ` +
                `page if there was no React error from multiple copies being present`
            )
            throw error;
        }
    })

    /**
     * Compiles the webpack app and outputs its index.html and js file(s) to 
     * './dist'
     */
    async function compileApp(entry) {
        return new Promise((resolve, reject) => {
            const config = {
                mode: 'development',
                entry,
                output: {
                    path: path.join(process.cwd(), 'dist'),
                },
                resolve: {
                    extensions: ['.jsx', '.js'],
                    symlinks: true,
                },
                plugins: [new HtmlWebpackPlugin()],
            }
    
            webpack(config, (err, stats) => {
                if (err) {
                    console.error(err.stack || err)
                    if (err.details) {
                        console.error(err.details)
                    }
                    reject(err)
                } else {
                    if (stats.hasErrors()) {
                        console.error(stats.toJson().errors)
                        reject('An error occurred during compilation - see above')
                    } else {
                        resolve()
                    }
                }
            })
        })
    }
    
    /**
     * Starts an http-server instance
     * 
     * @param root The root directory to serve
     * @param port The port to serve on
     */
    async function startServer(root, port) {
        const httpServer = createServer({
            root,
            cache: -1,
        })
        const server = httpServer.server;

        // Use http-terminator to make sure there are no hanging connections
        // when the test completes
        const httpTerminator = createHttpTerminator({ server })

        return new Promise((resolve, reject) => {
            server.on('listening', () => resolve(httpTerminator))
            server.on('error', reject)

            server.listen(port)
        })
    }
})
