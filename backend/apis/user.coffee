Usergrid = require "../usergrid"
postOrders = (businessuuid, orderuuid, cb)->
  query = new Usergrid.Query "POST", "/businesses/#{businessuuid}/orders/#{orderuuid}", null, null, (output) ->
    cb null
  , ->
    cb "error"
  Usergrid.ApiClient.runAppQuery query

exports.register = (app,requiresLogin)->

  # 6. Post Orders to businesses
  app.post "/api/v1/orders", requiresLogin, (req,res)->
    orderUUID = req.body.order.uuid
    businessUUID = req.body.business.uuid
    postOrders businessUUID, orderUUID, ->
      res.send 200