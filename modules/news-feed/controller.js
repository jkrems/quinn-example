'use strict';

let quinn   = require('quinn'),
    respond = quinn.respond,
    action  = quinn.inject.action;

let authenticated = require('../../lib/facebook/authenticated');

this.index = authenticated(action(function* (service, render, page, user) {
  let graphApi = service('graphApi');
  let homeStream = graphApi('/me/home').asJson;

  page.user  = user;
  page.posts = homeStream.get('data');

  /* Unfortunately the home-stream can take a while to load.
     But 10 sec should be safe. */
  return render(page, { timeout: 10000 });
}));
