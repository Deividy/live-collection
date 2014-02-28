#!/usr/bin/env coffee

fs = require('fs')
{ exec } = require('child_process')

src = "#{__dirname}/src"
file = "#{__dirname}/live-collection.js"

source = [ 'wrapper', 'model', 'collection', 'render' ]
files = ("#{src}/#{f}.coffee" for f in source)

console.log("Compiling: \n#{files.join('\n')}\nTo: \n#{file}")

exec("coffee -cj #{file} #{files.join(' ')}", (err) ->
    throw new Error(err) if err?
)
