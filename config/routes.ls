
require! quinn.controller
require! quinn.config
require! quinn.respond

module.exports = (app) ->
  app.get '/', controller 'news-feed'

  app.get '/config', (req) -> respond.json config.current
  app.get '/cookies', (req) ->
    respond.json req{cookies, session}
