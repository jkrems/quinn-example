module.exports = (config) ->
  {load-config-file, app-path, extend} = config

  extend services:
    graphApi: require '../lib/facebook/graph-api'

  load-config-file (app-path 'config', 'local'), true
