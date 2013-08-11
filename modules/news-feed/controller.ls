
require! {
  quinn.config
  quinn.respond
  Q: q
  Url: url
  querystring
  QHttp: 'q-io/http'
}

facebook-url = (subdomain, pathname, query) -->
  Url.format {
    pathname, query,
    protocol: 'https'
    hostname: "#{subdomain}.facebook.com"
  }

graph-api-url = facebook-url 'graph'

access-token-url = (redirect_uri, code) ->
  graph-api-url '/oauth/access_token', {
    client_id: config.get 'facebook.key'
    client_secret: config.get 'facebook.secret'
    redirect_uri
    code
  }

load-user-from-token = (access_token) ->
  url = graph-api-url '/me', {access_token, fields: 'id,name,first_name,last_name' }
  QHttp.read(url).then JSON.parse

get-user = ({absoluteUrl, query, session}) ->
  if session.fb_token?
    load-user-from-token session.fb_token
  else if query.code?
    url = access-token-url absoluteUrl, query.code
    QHttp.read(url).then (encoded) ->
      {access_token} = querystring.parse encoded.toString!
      session.fb_token = access_token

      load-user-from-token access_token
  else
    Q.reject new Error 'User not found'

login-redirect-url = (req) ->
  facebook-url 'www', '/dialog/oauth', {
    client_id: config.get 'facebook.key'
    redirect_uri: req.absoluteUrl
    response_type: 'code'
    scope: <[ read_stream friends_online_presence read_friendlists ]> .join ','
  }

authenticated = (handler) ->
  (req, ...args) ->
    get-user req .then(
      (user) ->
        handler req <<< {user}, ...args
    , (err) ->
        console.log err.stack
        login-url = login-redirect-url req
        respond.redirect login-url
    )

module.exports =
  main: authenticated (req) ->
    respond.json req.user
