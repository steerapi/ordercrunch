Usergrid = require "../usergrid"

# Apigee proxy
# TODO: need to restrict permission
querystring = require "querystring"

exports.register = (app,requiresLogin)->
  app.get "/apigee/api/v1/*", (req,res)->
    params =
      ql: req.query.ql
    query = new Usergrid.Query "GET", req.params[0], req.body.obj, params, (response) ->
      res.send response
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query
  app.delete "/apigee/api/v1/*", (req,res)->
    query = new Usergrid.Query "DELETE", req.params[0], req.body.obj, req.body.params, (response) ->
      res.send response
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query
  app.post "/apigee/api/v1/*", (req,res)->
    query = new Usergrid.Query "POST", req.params[0], req.body.obj, req.body.params, (response) ->
      res.send response
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query
  app.put "/apigee/api/v1/*", (req,res)->
    query = new Usergrid.Query "PUT", req.params[0], req.body.obj, req.body.params, (response) ->
      res.send response
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query
