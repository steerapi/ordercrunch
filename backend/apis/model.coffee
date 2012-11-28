jsonpath = require('../jsonpath')
Usergrid = require('../usergrid')

extract = (data, path)->
  # try
  if not path
    return data
  val = jsonpath.eval(data, path)
  return val
  # catch err
  #   return false

# jsonpath = new JSONPath()
# val = jsonpath.eval
#   a: "20"
# ,"$.a"

# console.log val

exports.register = (app, requiresLogin)->
  app.put "/api/v1/:collection/:id/*", (req,res)->
    collection = req.params.collection
    id = req.params.id 
    path = req.params[0]
    entity = new Usergrid.Entity(collection)
    entity.set "uuid", id
    entity.fetch (response)->
      if not path
        entity._data = req.body.content
        entity.save()
        res.send 200      
        return
      jsonpath.eval(entity._data, path, null, req.body.content)
      entity.save()
      res.send 200
    , (response)->
      if response.error == "service_resource_not_found"
        entity.set "name", id
        if path
          jsonpath.eval(entity._data, path, null, req.body)
        entity.save()
        res.send 200
      else
        res.send 404

  app.get "/api/v1/:collection/:id/*", (req,res)->
    collection = req.params.collection
    id = req.params.id 
    path = req.params[0]
    # [collection,id,reqs] = getCollectionAndId(req.params)
    entity = new Usergrid.Entity(collection)
    entity.set "uuid", id
    entity.fetch (response)->
      val = extract(entity._data, path)
      res.send 
        content: val
    , (response)->
      res.send 404
