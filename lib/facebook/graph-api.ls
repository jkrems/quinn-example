
module.exports = graph-api =
  map-args: (uri, options, req, i18n) ->
    {config} = req.app
    {session} = req

    {path} = require('url').parse uri
    base = 'https://graph.facebook.com'
    if session?.fb_token
      options.qs ?= {}
      options.qs.access_token ?= session.fb_token

    { uri: "#{base}#{path}", options }
