const express = require('express')
const app = express()
const port = 3000

app.get('/ping', (req, res) => {
    res.json({
        message: "pong"
    })
})

app.get('/env',(req,res) => {
    res.json(process.env)
})

app.get('/properties',(req,res, next) => {
    var propertiesReader = require('properties-reader');
    var r=propertiesReader(__dirname+'/prop/application.properties');
    res.json(r.getAllProperties())
})

const HOST= "http://0.0.0.0"
const PORT= 3000 | process.env.SERVER_PORT


app.use(function (err, req, res, next) {
    console.error(err.stack)
    res.status(500).json({
        message: err.message
    })
})

app.listen(PORT, () => {
  console.log(`Application listening at http://${HOST}:${PORT}`)
})