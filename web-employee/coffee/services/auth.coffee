async = require "async"

class Auth
  constructor: (@http)->
  logIn: (username, password ,cb)->
    async.parallel [ (cb)->
      Usergrid.ApiClient.logInAppUser username, password, ((response, user) ->
        user = Usergrid.ApiClient.getLoggedInUser()
        user.fetch ->
          cb?(null)
        , ->
          cb?("error")
      ), ->
        cb?("error")      
    , (cb)=>
      req = @http.post "#{backendurl}/api/v1/login",
        username: username
        password: password
      req.success (data,status,headers)=>
        # console.log data.cookie
        # @http.defaults.headers.common['cookie']=data.cookie
        cb?(null)
      req.error ->
        cb?("error")
    ], (err, result)->
      if err
        cb?("error")
        return
      cb?(null)

  logOut: ->
    async.parallel [ (cb)->
      Usergrid.ApiClient.logoutAppUser()
    , (cb)=>
      req = @http.get "#{backendurl}/api/v1/logout"
    ]
  signUp: (username, email, password,cb)->
    if Usergrid.validation.validateUsername(username, ->
    #error username
      cb "username"
    ) and Usergrid.validation.validateEmail(email, ->    
    #error validataion
      cb "email"
    ) and Usergrid.validation.validatePassword(password, ->
    #error validataion
      cb "password"
    )
      # make sure we have a clean user, and then add the data
      appUser = new Usergrid.Entity("users")
      appUser.set
        username: username
        email: email
        password: password
      appUser.save =>
        #new user is created, so set their values in the login form and call login
        @logIn(username,password,cb)
      , ->
        cb "error"
        #error create

Auth.$inject = ["$http"]
app.service "Auth", Auth