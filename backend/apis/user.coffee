Usergrid = require "../usergrid"
postOrders = (businessuuid, orderuuid, cb)->
  query = new Usergrid.Query "POST", "/businesses/#{businessuuid}/orders/#{orderuuid}", null, null, (output) ->
    cb null
  , ->
    cb "error"
  Usergrid.ApiClient.runAppQuery query

createOrder = (data, cb)->
  entity = new Usergrid.Entity "orders"
  entity._data = data
  entity.save ->
    uuid = entity.get "uuid"
    postOrders "1a370b02-3983-11e2-87fc-02e81ac5a17b",uuid,->
      cb?()

# createOrder 
#   total: "20.00"
#   "status": "ordered"
#   from: 
#     "uuid": ""
#     "name": "Adam Lu"
#     "email": "tester@foodcrunchapp.com"
#     "phone": "xxx-xxx-xxxx"
#   items: [
#     "itemName": "Lobster"
#     "price": "20.00"
#     "qty": 2
#   ]

exports.register = (app,requiresLogin)->
  # 6. Post Orders to businesses
  app.post "/api/v1/orders", requiresLogin, (req,res)->
    orderUUID = req.body.order.uuid
    businessUUID = req.body.business.uuid
    postOrders businessUUID, orderUUID, ->
      res.send 200