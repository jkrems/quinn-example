#!/usr/bin/env lsc
appRoot = process.cwd!
quinn =
  try require "#{appRoot}/node_modules/quinn"
  catch e then require 'quinn'

require! path
require! http.create-server
require! fs.readdirSync

{controller, create-app} = quinn

routes = require "#{appRoot}/config/routes"
serverInit = try require "#{appRoot}/config/server"

moduleBaseDirectory = path.join appRoot, 'modules'
modules = readdirSync moduleBaseDirectory .map (name) ->
  { name, directory: path.join moduleBaseDirectory, name }

console.log 'Found modules:', modules.map ({name}) -> name

found-controllers = controller.discover-controllers modules
console.log 'Found controllers:', found-controllers

app = create-app!
routes app

server = create-server!
serverInit server
server.on 'request', app.handle-request
server.listen 4000, ->
  console.log 'SERVER TIME!', 'http://localhost:4000'
  process.send? 'online'

process.on 'message', (message) ->
  if message == 'shutdown'
    process.exit 0
