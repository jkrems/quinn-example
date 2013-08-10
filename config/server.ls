
module.exports = (server) ->
  server.on 'listening', ->
    {address, port} = @address!
    console.log "Listening on http://#{address}:#{port}"
