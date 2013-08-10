
require! quinn.controller
require! quinn.config
require! quinn.respond

module.exports = (app) ->
  app.all '*', controller 'hello#main',
    params: (req) -> req.query

  app.get '/', controller 'hello#main'
  app.get '/hello/:name', controller 'hello#main'
  app.get '/fwd', controller 'hello#forward'

  app.get '/config', (req) -> respond.json config.current
