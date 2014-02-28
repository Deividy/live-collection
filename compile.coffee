#!/usr/bin/env coffee

fs = require('fs')
{ exec } = require('child_process')

src = "src"
file = "../live-collection.js"

source = [ 'wrapper', 'model', 'collection', 'render' ]
files = ("#{src}/#{f}.coffee" for f in source)

console.log("Compiling: \n#{files.join('\n')}\n To: \n#{file}")

exec("coffee -cj src/#{file} #{files.join(' ')}", (err) ->
    throw new Error(err) if err?
)
