querystring = require "querystring"

class SingletonModel
  get: (uuid, scb, ecb)->
    if @entity
      scb @entity
    Usergrid.ApiClient.logInAppUser "tester", "tester", (response, user) ->
      entity = new Usergrid.Entity @collection, "472cd43a-39b5-11e2-87fc-02e81ac5a17b"
      entity.fetch =>
        @entity = entity
      scb(entity)
    return
    query = new Usergrid.Query "GET", "/users/#{uuid}/#{@collection}/", null, null, (response) =>
      data = response.entities[0]
      if not data
        ecb()
        return 
      entity = new Usergrid.Entity @collection, data.uuid
      entity._data = data
      @entity = entity
      scb(@entity)
    , ->
      ecb()
    Usergrid.ApiClient.runAppQuery query
  create: (uuid, data, scb, ecb)->
    entity = new Usergrid.Entity @collection
    entity._data = data
    entity._data.verified = "unverified"
    entity.save ->
      buuid = business.get "uuid"
      query = new Usergrid.Query "POST", "/users/#{uuid}/#{@collection}/#{buuid}", null, null, (response) =>
        @entity = entity
        scb()
      , ->
        ecb()
      Usergrid.ApiClient.runAppQuery query
    , ecb
  constructor: (@collection,@http,@rootScope)->

module.exports = SingletonModel
  