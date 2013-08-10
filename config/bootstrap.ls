module.exports = (config) ->
  {load-config-file, app-path} = config

  load-config-file (app-path 'config', 'local'), true
