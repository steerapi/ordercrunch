Usergrid = require('../usergrid')

email = require "emailjs"
server = email.server.connect
  user: "support@ordercrunchapp.com"
  password: "support1234"
  host: "smtp.gmail.com"
  ssl: true

randpass = require('randpass')

sendPassword = (email, password, cb)->
  server.send
    text: "Your new password is #{password}."
    from: "OrderCrunch Support <support@ordercrunchapp.com>"
    to: "#{email}"
    subject: "Your OrderCrunch Password Reset"
  , cb

exports.register = (app,requiresLogin)->

  # 1. Login
  app.post "/api/v1/login", (req,res)->
    Usergrid.ApiClient.logInAppUser req.body.username, req.body.password, (output, user) ->
      #just for kicks, we will save a timestamp in the session, so you can see how to do it
      timestamp = new Date().getTime()
      Usergrid.session.setItem "useless_timestamp", timestamp
      #this login call pulled back a user object and a token, so we need to save the session
      # res.send 200
      Usergrid.session.save_session res, (->
      
        # console.log res
        res.send 200
          # cookie:res.getHeader "Set-Cookie"
        console.log "Session saved..."
      ), ->
        res.send 404
        console.log "Could not save session..."
      , true
    , (output) ->
      res.send 404

  # 2. Logout
  app.get "/api/v1/logout", requiresLogin, (req,res)->
    Usergrid.ApiClient.enableClientSecretAuth()
    Usergrid.ApiClient.logoutAppUser()
    Usergrid.session.kill_session()
    res.send 200

  # Set Password
  app.post "/api/v1/setpw", requiresLogin, (req,res)->
    user = Usergrid.ApiClient.getLoggedInUser()
    useruuid = user.get "uuid"
    newpass = randpass()
    query = new Usergrid.Query "POST", "/users/#{useruuid}/password", 
      newpassword: newpass
    , null, (output) ->
      sendPassword email, newpass, (err)->
        if err
          res.send 404
        else
          res.send 200
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query

  # Reset Password
  app.post "/api/v1/resetpw", requiresLogin, (req,res)->
    email = req.body.email
    newpass = randpass()
    query = new Usergrid.Query "POST", "/users/#{email}/password", 
      newpassword: newpass
    , null, (output) ->
      sendPassword email, newpass, (err)->
        if err
          res.send 404
        else
          res.send 200
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query
  