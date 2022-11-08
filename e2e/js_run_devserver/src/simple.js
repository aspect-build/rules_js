#!/usr/bin/env node
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
        res.writeHead(200, { 'Content-Type': 'text/html' })
        res.write(data)
        console.log(require.resolve('chalk'))
        return res.end()
    })
}).listen(8080)
