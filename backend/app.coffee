express = require("express")
app = express()
app.configure ->
  app.set "port", process.env.VCAP_APP_PORT || 3000
  app.use express.favicon()
  app.use(express.json())
  app.use(express.logger())
  # app.use(express.cookieParser('superfood'))
  # app.use express.session()

app.all "/*", (req, res, next) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "Content-Type, X-Requested-With"
  res.header "Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"
  next()

app.options "*", (req, res, next) ->
  res.send 200

Usergrid = require "./usergrid"
Usergrid.ApiClient.init('ordercrunch', 'ordercrunch')
Usergrid.ApiClient.setClientSecretCombo('b3U6IDfwTzmAEeKH_ALoGsWhew', 'b3U6inRBAXM1Lew2s1kah7vLGVv_9DA')
Usergrid.ApiClient.enableClientSecretAuth()

# Usergrid.ApiClient.runAppQuery(new Usergrid.Query('DELETE', "items", null, filter:"*"));

Usergrid.session.garbage_collection()

requiresLogin = (req,res,next)->
  # next()
  Usergrid.ApiClient.enableClientSecretAuth()
  Usergrid.session.setItem null
  Usergrid.session.start_session req, res, (->
    if Usergrid.ApiClient.isLoggedInAppUser()
      # Usergrid.ApiClient.enableUserAuth()
      next()
    else
      console.log "Please logged in"
      res.send 401
  ), ->
    console.log "No session could be established. Please try again."
    res.send 404

AccountAPI = require "./apis/account"
AccountAPI.register app, requiresLogin

BusinessAPI = require "./apis/business"
BusinessAPI.register app, requiresLogin

ModelAPI = require "./apis/model"
ModelAPI.register app, requiresLogin

LocuAPI = require "./apis/locu"
LocuAPI.register app, requiresLogin

UserAPI = require "./apis/user"
UserAPI.register app, requiresLogin

ApigeeAPI = require "./apis/apigee"
ApigeeAPI.register app, requiresLogin

# 
# req = http.request 
#   method:"GET"
#   host:"api.locu.com"
#   path: "http://api.locu.com/v1_0/venue/search/?api_key=a231808077ef79fabb66e7f7fd315263278f8d99"
# , (httpres)->
#   buffer = ""
#   httpres.on "data", (chunk)->
#     buffer+=chunk
#   httpres.on "end", (chunk)->
#     obj = JSON.parse buffer
#     console.log obj
# req.end()

#getBusiness "848cc9f4-3657-11e2-a065-02e81ae640dc", ->


# createBusinessReviews = (useruuid, businessuuid, cb)->
#   entity = new Usergrid.Entity("businessreviews")
#   entity.save (response)->
#     cb null, entity
#     uuid = entity.get "uuid"
#     async.parallel [ (cb)->
#       query = new Usergrid.Query "POST", "/businessreviews/#{uuid}/users/#{useruuid}", null, null, (output) ->
#         cb null
#       , ->
#         cb "error"
#       Usergrid.ApiClient.runAppQuery query
#     , (cb)->
#       query = new Usergrid.Query "POST", "/businessreviews/#{uuid}/businesses/#{businessuuid}", null, null, (output) ->
#         cb null
#       , ->
#         cb "error"
#       Usergrid.ApiClient.runAppQuery query
#     ], (err,results)->
#       cb null, entity
#   , (response)->
#     cb "error"
# 
# postBusinessReviews = (manageruuid, businessreviewuuid, cb)->
#   query = new Usergrid.Query "POST", "/managers/#{manageruuid}/businessreviews/#{businessreviewuuid}", null, null, (output) ->
#     cb null
#   , ->
#     cb "error"
#   Usergrid.ApiClient.runAppQuery query
# 
# postUserEmployee  = (useruuid, employeeuuid, cb)->
#   destroyCollection "/users/#{useruuid}/employees/", (entity, cb)->
#     cb()  
#   ,->
#     query = new Usergrid.Query "POST", "/users/#{useruuid}/employees/#{employeeuuid}", null, null, (output) ->
#       cb null
#     , ->
#       cb "error"
#     Usergrid.ApiClient.runAppQuery query
#   , ->
#     cb "error"

# Usergrid.ApiClient.logInAppUser "tester", "tester", (output, user) ->
#   user = Usergrid.ApiClient.getLoggedInUser()
#   getBusiness "848cc9f4-3657-11e2-a065-02e81ae640dc", (err, business)->
#     getManager business, (err, manager)->
#       createBusinessReviews user, business, (err, businessreview)->
#         postBusinessReviews manager, businessreview, (err)->

# 4. Post BusinessReviews to managers
# app.post "/api/v1/businessreviews", requiresLogin, (req,res)->
#   # arguments
#   user = Usergrid.ApiClient.getLoggedInUser()
#   businessUUID = req.body.business.uuid
#   postBusinessReviewsManagers user, businessUUID, (response)->
#     res.send response
#     
# postBusinessReviewsManagers = (user, businessUUID, responsescb)->
#   userUUID = user.get "uuid"
#   getBusiness businessUUID, (err, business)->
#     getManager business, (err, manager)->
#       managerUUID = manager.get "uuid"
#       createBusinessReviews userUUID, businessUUID, (err, businessreview)->
#         businessreviewUUID = businessreview.get "uuid"
#         postBusinessReviews managerUUID, businessreviewUUID, (err)->
#           # user.set "verifiedBusiness", "verifying"
#           user.save ->
#             responsescb 200
# 
# getEmployee = (uuid, cb)->
#   entity = new Usergrid.Entity("employees")
#   entity.set "uuid", uuid
#   entity.fetch (response)->
#     cb null, entity
#   , (response)->
#     cb "error"
# 
# createEmployeeReviews = (useruuid, employeeuuid, cb)->
#   entity = new Usergrid.Entity("employeereviews")
#   entity.save (response)->
#     cb null, entity
#     uuid = entity.get "uuid"
#     async.parallel [ (cb)->
#       query = new Usergrid.Query "POST", "/employeereviews/#{uuid}/users/#{useruuid}", null, null, (output) ->
#         cb null
#       , ->
#         cb "error"
#       Usergrid.ApiClient.runAppQuery query
#     , (cb)->
#       query = new Usergrid.Query "POST", "/employeereviews/#{uuid}/employees/#{employeeuuid}", null, null, (output) ->
#         cb null
#       , ->
#         cb "error"
#       Usergrid.ApiClient.runAppQuery query
#     ], (err,results)->
#       cb null, entity
#   , (response)->
#     cb "error"

# postEmployeeReviews = (businessuuid, reviewuuid, cb)->
#   query = new Usergrid.Query "POST", "/businesses/#{businessuuid}/employeereviews/#{reviewuuid}", null, null, (output) ->
#     cb null
#   , ->
#     cb "error"
#   Usergrid.ApiClient.runAppQuery query

# 5. Post EmployeeReviews to businesses
# app.post "/api/v1/employeereviews", requiresLogin, (req,res)->
#   # arguments
#   employeeUUID = req.body.employee.uuid
#   businessUUID = req.body.business.uuid
#   user = Usergrid.ApiClient.getLoggedInUser()
#   userUUID = user.get "uuid"
#   createEmployeeReviews userUUID, employeeUUID, (err, review)->
#     reviewUUID = review.get "uuid"
#     postEmployeeReviews businessUUID, reviewUUID, (err)->
#       # user.set "verifiedEmployee", "verifying"
#       user.save ->
#         res.send 200

# Usergrid.ApiClient.logInAppUser "tester", "tester", (output, user) ->
#   user = Usergrid.ApiClient.getLoggedInUser()
#   userUUID = user.get "uuid"
#   employeeUUID = "60b6d829-365d-11e2-a065-02e81ae640dc"
#   businessUUID = "848cc9f4-3657-11e2-a065-02e81ae640dc"
#   createEmployeeReviews userUUID, employeeUUID, (err, review)->
#     reviewUUID = review.get "uuid"
#     postEmployeeReviews businessUUID, reviewUUID, (err)->

# orderUUID = "d36dfdbc-365f-11e2-a065-02e81ae640dc"
# businessUUID = "848cc9f4-3657-11e2-a065-02e81ae640dc"
# postOrders businessUUID, orderUUID, ->

# 
# # 8. Reject business
# app.get "/api/v1/rejectBusiness", requiresLogin, (req,res)->
#   reviewuuid = req.query.reviewuuid
#   businessuuid = req.query.businessuuid
#   user = Usergrid.ApiClient.getLoggedInUser()
#   entity = new Usergrid.Entity "businessreviews"
#   entity.set "uuid", businessuuid
#   entity.destroy ->
#     destroyBusiness businessuuid, ->
#       user.set "verifiedBusiness", null
#       user.save ->
#         res.send 200
#       , ->
#         res.send 404        
#   , ->
#     res.send 404
# 
# # 9. Reject employee
# app.get "/api/v1/rejectEmployee", requiresLogin, (req,res)->
#   reviewuuid = req.query.reviewuuid
#   employeeuuid = req.query.employeeuuid
#   user = Usergrid.ApiClient.getLoggedInUser()
#   entity = new Usergrid.Entity "businessreviews"
#   entity.set "uuid", businessuuid
#   entity.destroy ->
#     destroyEmployee employeeuuid, ->
#       user.set "verifiedEmployee", null
#       user.save ->
#         res.send 200
#       , ->
#         res.send 404        
#   , ->
#     res.send 404
# 
# destroySchedules = (employeeid, cb, donecb)->
#   destroyCollection "employees/#{employeeid}/schedules", cb, donecb
#   
# # destroyBusiness "848cc9f4-3657-11e2-a065-02e81ae640dc"
# destroyEmployee = (employeeid, donecb)->
#   destroySchedules employeeid, (schedule, schedulecb)->
#     schedulecb()
#   , ->
#     donecb?()

app.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")
