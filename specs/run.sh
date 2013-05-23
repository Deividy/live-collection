#!/bin/bash

SPECS=`dirname $0`
MOCHA=$SPECS/../node_modules/mocha/bin/mocha

$MOCHA --reporter spec --require should --compilers coffee:coffee-script $SPECS/*.spec.coffee
