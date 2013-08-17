
require! quinn.respond
require! quinn.inject.action

module.exports = (app) ->
  app.get '/', -> respond.redirect '/news-feed'
  app.get '/news-feed', 'news-feed'

  app.get '/config', action (config) -> respond.json config.current
  app.get '/cookies', action (cookies, session) ->
    respond.json {cookies, session}
