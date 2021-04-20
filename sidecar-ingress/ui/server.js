const express = require('express')
const app = express()
const port = 3000
var os = require("os");

app.get('/', (req, res) => {
  res.sendFile(__dirname+'/index.html')
})

app.get('/ping', (req, res) => {
    res.json({
        message: "pong"
    })
})

app.get('/info', (req, res) => {
    const p = require('./package.json')
    res.json({
        application: {
            name: p.name,
            version: p.version
        },
        hostname: os.hostname()
    })
})

const PORT = process.env.SERVER_PORT | 3000;
const HOST = '0.0.0.0';

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);