#!/usr/bin/env node
var path = require('path');
module.exports = require('quinn/boot-server')(
  path.join(__dirname, '..')
);
