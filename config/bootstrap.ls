module.exports = (config) ->
  {load-config-file, app-path, extend} = config

  extend auth:
    paths:
      login: '/login'

  load-config-file (app-path 'config', 'local'), true
