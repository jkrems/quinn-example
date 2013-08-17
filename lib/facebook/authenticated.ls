
require! {
  Q: q
  Url: url
  querystring
}
require! quinn.inject.action
require! quinn.respond

login-redirect-url = (req, config) ->
  Url.format {
    pathname: '/dialog/oauth'
    protocol: 'https'
    hostname: "www.facebook.com"
    query: {
      client_id: config.get 'facebook.key'
      redirect_uri: req.absolute-url
      response_type: 'code'
      scope: <[ read_stream friends_online_presence read_friendlists ]> .join ','
    }
  }

access-token-from-code = (redirect_uri, code, config, graph-api) ->
  token = graph-api '/oauth/access_token', qs: {
    client_id: config.get 'facebook.key'
    client_secret: config.get 'facebook.secret'
    redirect_uri
    code
  }

  token.then ({body}) ->
    {access_token} = querystring.parse body.toString!

get-access-token = Q.promised ({absoluteUrl, query, session}, config, graph-api) ->
  if session.fb_token?
    { access_token: session.fb_token }
  else if query.code?
    access-token-from-code absolute-url, query.code, config, graph-api
  else
    throw new Error 'User not found'

user-from-token = (graph-api, access_token) ->
  graph-api '/me', qs: { fields: 'id,name,first_name,last_name' } .asJson

module.exports = authenticated = (handler) ->
  action (req, params, config, service) ->
    graph-api = service('graphApi')
    get-access-token req, config, graph-api .then(
      ({access_token}) ->
        req.session.fb_token = access_token
        user = user-from-token graph-api, access_token
        req.quinn-ext <<< {user}
        handler req, params
    , (err) ->
        login-url = login-redirect-url req, config
        respond.redirect login-url
    )
