
require! quinn.respond

module.exports =
  main: (req, {name}) ->
    name ?= 'World'
    "Hello #{name}!"

  forward: (req, {name}) ->
    respond.redirect '/'
