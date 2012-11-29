http = require("http")
Usergrid = require "./usergrid"
async = require "async"

exports.register = (app,requiresLogin)->
  app.get "/businesses/api/v1/venue/search/", requiresLogin, (req,res)->
    params = 
      ql : "select * where businessName contains '#{req.query.name}'"
    query = new Usergrid.Query "GET", "/businesses/", null, params, (response) ->
      res.send response.entities
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query
  # app.post "/api/v1/linkEmployeeBusiness", requiresLogin, (req,res)->
  #   user = Usergrid.ApiClient.getLoggedInUser()
  #   employeeUUID = res.body.employeeUUID
  #   businessUUID = res.body.businessUUID 
  #   async.parallel [ (cb)->
  #     query = new Usergrid.Query "POST", "/employees/#{employeeUUID}/businesses", null, params, (response) ->
  #       cb()
  #     , ->
  #       cb "error"
  #     Usergrid.ApiClient.runAppQuery query
  #   , (cb)->
  #     query = new Usergrid.Query "POST", "/businesses/#{businessUUID}/employees", null, params, (response) ->
  #       cb()
  #     , ->
  #       cb "error"
  #     Usergrid.ApiClient.runAppQuery query
  #   ], (err)->
  #     if err
  #       res.send 404
  #     else
  #       res.send 200
  # 
  # app.delete "/api/v1/unlinkEmployeeBusiness", requiresLogin, (req,res)->
  #   user = Usergrid.ApiClient.getLoggedInUser()
  #   employeeUUID = res.body.employeeUUID
  #   businessUUID = res.body.businessUUID 
  #   async.parallel [ (cb)->
  #     query = new Usergrid.Query "DELETE", "/employees/#{employeeUUID}/businesses", null, params, (response) ->
  #       cb()
  #     , ->
  #       cb "error"
  #     Usergrid.ApiClient.runAppQuery query
  #   , (cb)->
  #     query = new Usergrid.Query "DELETE", "/businesses/#{businessUUID}/employees", null, params, (response) ->
  #       cb()
  #     , ->
  #       cb "error"
  #     Usergrid.ApiClient.runAppQuery query
  #   ], (err)->
  #     if err
  #       res.send 404
  #     else
  #       res.send 200
