#!/usr/bin/env node
// A naughty version of a simple devserver that modifies files before serving them.
// See https://github.com/aspect-build/rules_js/issues/935 for more context.
const http = require('http')
const url = require('url')
const fs = require('fs')
const chalk = require('chalk')

http.createServer(function (req, res) {
    const q = url.parse(req.url, true)
    const filename = q.pathname == '/' ? './index.html' : '.' + q.pathname
    console.log(`Serving ${chalk.italic.bgBlue(filename)}`)
    fs.readFile(filename, function (err, data) {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/html' })
            return res.end('404 Not Found')
        }
        fs.writeFileSync(filename, data + '<div>naughty devserver</div>') // Write back the file being served!
        res.writeHead(200, { 'Content-Type': 'text/html' })
        res.write(data)
        console.log(require.resolve('chalk'))
        return res.end()
    })
}).listen(8080)
