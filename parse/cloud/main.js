var c = require('cloud/config.js');

// Import the opentok library from the subdirectory
var opentok = require('cloud/opentok/opentok.js').createOpenTokSDK(c.OT_API_KEY, c.OT_API_SECRET);


// Every Broadcast object should "own" an OpenTok Session
Parse.Cloud.beforeSave("Broadcast", function(request, response) {
  var broadcast = request.object;

  // If this Broadcast already has a sessionId, we are done
  if (broadcast.get("sessionId")) { response.success(); return; }

  // Otherwise, we create a Session now...
  opentok.createSession(function(err, sessionId) {
    // Handle any errors
    if (err) { response.error("could not create opentok session for broadcast: " + broadcast.id); return; }

    // ... and now save the sessionId in the Broadcast object
    broadcast.set("sessionId", sessionId);
    response.success();
  });
});


// This function can be called by any user who wants to connect to a Broadcast and a Token with the
// corresponding `role` will be generated. (Publisher for the Broadcast owner, Subscriber for anyone else)
Parse.Cloud.define("getBroadcastToken", function(request, response) {
  // Retrieve the Broadcast object for which the token is being requested
  var broadcastId = request.params.broadcast;
  if (!broadcastId) response.error("you must provide a broadcast object id");
  var broadcastQuery = new Parse.Query("Broadcast");
  broadcastQuery.get(broadcastId, {

    // When the Broadcast object is found...
    success: function(broadcast) {
      // Get the appropriate role according to the user who is calling this function
      var role = roleForUser(broadcast, request.user);
      // Create a Token
      var token = opentok.generateToken(broadcast.get("sessionId"), { "role" : role });
      // Return the token as long as it exists
      if (token) {
        response.success(token);
      // Handle errors
      } else {
        response.error("could not generate token for broadcast id: " + broadcastId + " for role: " + role);
      }
    },

    // When the Broadcast object is not found, respond with error
    error: function(broadcast, error) {
      response.error("cannot find broadcast with id: " + broadcastId);
    }
  });
});

// Helper function to figure out the OpenTok role a user should get based on the Boradcast object
var roleForUser = function(broadcast, user) {
  // A Broadcast owner gets a Publisher token
  if (broadcast.get("owner").id === user.id) {
    return opentok.ROLE.PUBLISHER;
  // Anyone else gets a Subscriber token
  } else {
    return opentok.ROLE.SUBSCRIBER;
  }
};
