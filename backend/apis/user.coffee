Usergrid = require "../usergrid"
async = require "async"
postOrders = (collection,uuid, orderuuid, cb)->
  query = new Usergrid.Query "POST", "/#{collection}/#{uuid}/orders/#{orderuuid}", null, null, (output) ->
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
  app.post "/api/v1/orders", (req,res)->
    query = new Usergrid.Query "POST", "orders", req.body, null, (response) ->
      order = response.entities[0]
      async.parallel [ (cb)->
        postOrders "customers",req.body.from.uuid, order.uuid, ->
          cb()            
      , (cb)->
        postOrders "businesses",req.body.to.uuid, order.uuid, ->
          cb()
      ], ->
        res.send order
    , ->
      res.send 404
    Usergrid.ApiClient.runAppQuery query

    
    
