const express = require('express')
const app = express()
const port = 3000

app.get('/env', (req, res) => {
    res.json({
        env: {
            one: process.env.ENV_1,
            two: process.env.ENV_2
        },
        secret: {
            one: process.env.SECRET_1,
            two: process.env.SECRET_2
        },
    })
})

app.listen(port, () => {
  console.log(`env-reader listening at http://localhost:${port}`)
})