'use strict';

require('bulma/css/bulma.css');
require('./complaint.css');

// Require index.html so it gets copied to dist
require('./index.html');

var Elm = require('./Main.elm');
var mountNode = document.getElementById('main');

// .embed() can take an optional second argument. This would be an object describing the data we need to start a program, i.e. a userID or some token
console.log("Starting app with session = " + localStorage.session);
var app = Elm.Main.embed(mountNode, localStorage.session || null);

app.ports.storeSession.subscribe(function(session) {
  localStorage.session = session;
});

window.addEventListener("storage", function(event) {
  if (event.storageArea == localStorage && event.key == session) {
    app.ports.onSessionChange.send(event.newValue);
  }
}, false);
