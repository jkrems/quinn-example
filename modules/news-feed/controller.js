'use strict'; // otherwise `let` will not work

let /* quinn: the web framework we are using */
    quinn   = require('quinn'),
    /* `action` injects dependencies from a request context. A request
       handler is defined as `(req, params) -> result`. We still have
       to return a result (e.g. "render a page"), but we can specifiy
       cleanly what we need to create that result. */
    action  = quinn.inject.action,

    lazyMap = require('quinn/harmony').lazyMap,

    /* `authenticated` is a request handler decorator (like `action`).
       It will check if the current user is properly authenticated,
       redirect to the proper Facebook auth url, do the whole "exchange
       code for access token"-thing and finally store the token in the
       session so it can be used in graphApi calls. */
    authenticated = require('../../lib/facebook/authenticated');

/* Our controller exports an index action. Whenever we don't specify the
   action anywhere else (e.g. in config/routes), `index` will be assumed.
   P.S.: `this.index` is shorthand for `module.exports.index`. */
this.index = authenticated(action(function* (service, render, page) {
  /* `service` lets you quickly get nice rest clients for different services.
     In this case we are getting a client for the Facebook graph API. The
     configuration was done in config/bootstrap, some magic for injecting
     the current access_token is in lib/facebook/graph-api. */
  let graphApi = service('graphApi');

  /* We make a call to /me/home and parse the body as json. homeStream is
     a promise to the parsed body. Since we don't want to do anything in
     terms of application logic with that data, we can just pass it
     directly into the page model. The renderer will render as much of the
     page as possible and will then wait if necessary until the home stream
     data becomes available. */
  let homeStream = graphApi('/me/home').asJson.get('data');

  /* We make a second call (in parallel) to /me, fetching information about
     the current user. The access token will be injected by the service
     configuration in lib/facebook/graph-api. */
  let fields = 'id,name,first_name,last_name,gender,cover,picture',
      user   = graphApi('/me', { qs: { fields: fields } }).asJson;

  /* If we want to stop until certain data is available, we can use yield.
     In case you didn't notice: This function is declared as a `function*`,
     meaning it's returning a generator. The `action` decorator is clever
     enough to detect this and will continue this function with the proper
     resolved value of the promise.
     If the promise is rejected, we will get an exception that we can handle
     using normal try/catch blocks. */
  let gender = yield user.get('gender');
  page.backgroundColor = gender === 'female' ? '#f2f7fc' : '#ddeacf';

  /*  Semantics of async.queue using promises and generators. The idea is
      the following:
      1.) lazyMap takes a collection, a function and a buffer size
      2.) lazyMap returns an iterator over the mapped results
      3.) lazyMap will pre-call the function according to the buffer size
      4.) lazyMap will only fetch more data when the iterator is continued
          via .next() - so if the outer function (this one) yields the
          promise, the will never be more than n concurrent requests */
  let friends = graphApi('/me/friends?fields=id').asJson.get('data').invoke('slice', 0, 10);
  let loadFriendName = function (friend) {
    return graphApi('/' + friend.id + '?fields=name').asJson.get('name');
  };
  let iterator = lazyMap(yield friends, loadFriendName, 5),
      current;
  while (current = iterator.next()) {
    if (current.done) break;
    console.log('One friend name:', yield current.value);
  }

  /* It's time to set data on our page model. This exports the data to our
     template. Look out for {% when x %} in the template. Those blocks mark
     sections that depend on a promise being resolved. This allows the
     renderer to greedily render as much of the template as possible, even
     before all our api calls are done. */
  page.user  = user;
  page.posts = homeStream;

  /* Unfortunately the home-stream can take a while to load. But 10 sec
     should be safe. The first argument normally is the name of a template,
     in our case 'news-feed/index'. Since we are currently in the
     'news-feed.index'-action, this is already the default value. If we
     wouldn't need to specifiy a longer timeout (default is 2000), this
     could be a short as `return render();` */
  return render(page, { timeout: 10000 });
}));
