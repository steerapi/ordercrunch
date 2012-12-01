querystring = require "querystring"

class SingletonModel
  get: (uuid, scb, ecb)->
    if @entity
      scb @entity
    query = new Usergrid.Query "GET", "/users/#{uuid}/#{@collection}/", null, null, (response) =>
      data = response.entities[0]
      if not data
        if @allowCreate
          @create uuid, {}, scb, ecb
        else
          ecb?()
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
    entity.save =>
      buuid = entity.get "uuid"
      query = new Usergrid.Query "POST", "/users/#{uuid}/#{@collection}/#{buuid}", null, null, (response) =>
        @entity = entity
        scb @entity
      , ->
        ecb()
      Usergrid.ApiClient.runAppQuery query
    , ecb
  constructor: (@collection,@http,@rootScope,@allowCreate=false)->
    console.log @collection

module.exports = SingletonModel
  