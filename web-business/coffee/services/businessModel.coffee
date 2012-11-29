# Order Status: Ordered, Confirmed, Completed
querystring = require "querystring"
# claimBusiness= (uuid, scb, ecb)->
#   params = querystring.stringify
#     locuid: locuid
#   req = @http.get "#{backendurl}/api/v1/claimBusiness?#{params}"
#   req.success (response)->
#     scb()
#   req.error ->
#     ecb()

class BusinessModel
  getBusiness: (uuid, scb, ecb)->
    # req = @http.post "#{backendurl}/api/v1/login",
    #   username: "tester"
    #   password: "tester"
    # Usergrid.ApiClient.logInAppUser "tester", "tester", (response, user) ->
    #   business = new Usergrid.Entity "businesses"
    #   business.set "uuid", "db5a66ad-3983-11e2-87fc-02e81ac5a17b"
    #   business.fetch ->
    #     scb(business)
    # return
    query = new Usergrid.Query "GET", "/users/#{uuid}/businesses/", null, null, (response) ->
      business = response.entities[0]
      console.log "business", business
      if not business
        ecb()
        return 
      entity = new Usergrid.Entity "businesses", business.uuid
      entity._data = business
      @business = entity
      scb(@business)
    , ->
      ecb()
    Usergrid.ApiClient.runAppQuery query
  createBusiness: (uuid, data, scb, ecb)->
    business = new Usergrid.Entity "businesses"
    business._data = data
    business._data.verified = "unverified"
    business.save ->
      buuid = business.get "uuid"
      query = new Usergrid.Query "POST", "/users/#{uuid}/businesses/#{buuid}", null, null, (response) ->
        business = response.entities[0]
        entity = new Usergrid.Entity "businesses", business.uuid
        entity._data = business
        @business = entity
        scb()
      , ->
        ecb()
      Usergrid.ApiClient.runAppQuery query
    , ecb
  completeOrder: (order, scb, ecb)->
    # order is an entity
    order.set "status", "completed"
    order.save scb, ecb
  getOrders: (type, scb, ecb)->
    # Get complete/incomplete orders
    # Return collection
    params = querystring.stringify
      "filter":"status='#{type}'"
    collection = new usergrid.Collection "/businesses/#{@business.get('uuid')}/orders?#{params}"
    collection.fetch ->
      scb collection
    , ecb
  constructor: (@http,@rootScope)->
    @business = null
  logIn: (username, password ,cb)->
    async.parallel [ (cb)=>
      Usergrid.ApiClient.logInAppUser username, password, ((response, user) ->
        cb?(null)
      ), ->
        cb?("error")      
    , (cb)->
      req = @http.post "#{url}/api/v1/login",
        username: username
        password: password
      req.success ->
        cb?(null)
      req.error ->
        cb?("error")
    ], (err, result)->
      cb?(null)
    , ->
      cb?("error")
  logOut: ->
    async.parallel [ (cb)->
      Usergrid.ApiClient.logoutAppUser()
    , (cb)=>
      req = @http.get "#{url}/api/v1/logout"
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
      appUser.save (->      
        #new user is created, so set their values in the login form and call login
        login(username,password,cb)
      ), ->
        cb "error"
        #error create
    
BusinessModel.$inject = ["$http", "$rootScope"]
app.service "BusinessModel", BusinessModel