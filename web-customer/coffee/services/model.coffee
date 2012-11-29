backoff = require "backoff"
_ = require "underscore"

EntityModelFactory = ($http, $parse)->
  class EntityModel
    constructor: (@idprop="uuid")->
    bind: (scope, prop, url, initValue={}, precb, deregcb)=>
      console.log "called"
      req = $http.get url
      getter = $parse(prop)
      setter = getter.assign
      lastest = null
    
      fibonacciBackoff = backoff.fibonacci(
        randomisationFactor: 0
        initialDelay: 1
        maxDelay: 3600000
      )
      fibonacciBackoff.failAfter 1000
    
      fibonacciBackoff.on "backoff", (number, delay) ->
        # console.log number + " " + delay + "ms"
      fibonacciBackoff.on "ready", (number, delay) =>
        # console.log "retrying"
        req = $http.put url,
          content: lastest
        req.success ->
          fibonacciBackoff.reset()
        req.error ->
          fibonacciBackoff.backoff()
      fibonacciBackoff.on "fail", ->
        # console.log "fail"

      change = _.throttle ->
        fibonacciBackoff.reset()
        fibonacciBackoff.backoff()
      , 1000

      startWatch = =>
        deregfn = scope.$watch prop, (newValue, oldValue)=>
          if newValue
            lastest = newValue
            change()
        , true
        deregcb? deregfn
      req.success (response)=>
        # console.log arguments
        if response.content == false
          req = $http.put url,
            content: initValue
          req.success ->
            setter scope, initValue
            startWatch()
          req.error ->
            console.log arguments
        else
          setter scope, response.content
          precb? getter scope
          startWatch()
      req.error ->
        console.log arguments
        # startWatch()
    
  return new EntityModel()

EntityModelFactory.$inject = ["$http", "$parse"]
app.service "Model", EntityModelFactory
async = require "async"
CollectionModelFactory = ($http, $parse, $entity)->
  class CollectionModel
    constructor: (@baseurl, @fromCollection, @fromId, @toCollection, @ql, @idprop="uuid")->
      if @fromId and @toCollection
        @path = "/#{@fromCollection}/#{@fromId}/#{@toCollection}"
      else
        @path = "/#{@fromCollection}"
      if not @toCollection
        @toCollection = @fromCollection
      @cursors = []
      @cacheuuid = []
      @deregs = []
      @pageIdx = 0
    addEntity: ->
      # console.log "ADDEntity"
      # idxs = []
      news = @getter(@scope).filter (item, i)=>
        # console.log item
        # console.log @cacheuuid
        if item?[@idprop]
          val = not (item[@idprop] in @cacheuuid)
        else
          val = true
        # if val
        #   idxs.push i
        return val
      # console.log "FILTER",idxs
      # console.log "NEWS",news
      
      async.forEachSeries news, (newItem, cb)=>
        query = new Usergrid.Query "POST", "/#{@toCollection}", newItem, null, (response) =>
          data = response.entities[0]
          $.extend newItem, data
          toId = data[@idprop]
          # console.log "/#{@fromCollection}/#{@fromId}/#{@toCollection}/#{toId}"
          query = new Usergrid.Query "POST", "/#{@fromCollection}/#{@fromId}/#{@toCollection}/#{toId}/", null, null, (response)=>
            console.log "ADDED"
            cb null
          , ->
            cb "error"
            console.log arguments
          Usergrid.ApiClient.runAppQuery query
          # $entity.bind @scope, "#{@prop}[#{idxs[i]}]", "#{@baseurl}/#{@toCollection}/#{toId}/", {}, null, (fn)=>
          #   @deregs.splice idxs[i], 0, fn
          # @cacheuuid.splice idxs[i], 0, toId
          
        , ->
          cb "error"
          console.log arguments
        Usergrid.ApiClient.runAppQuery query
      , =>
        @watch()

    removeEntity: ->
      # console.log "RMEntity"
      items = @getter(@scope)
      ids = _.pluck items, @idprop
      # idxs = []
      toRemoves = @cacheuuid.filter (uuid, i)=>
        val = not (uuid in ids)
        # if val
        #   idxs.push i
        return val
      # console.log "toRemoves",toRemoves
      # Reverse splice
      # console.log idxs
      # for i in [idxs.length - 1..0] by -1
      #   fn = @deregs.splice idxs[i], 1
      #   # console.log fn
      #   fn[0]?()
      #   @cacheuuid.splice idxs[i], 1
      #TODO: Actually we should unbind befor removing from elements to avoid error. It's ok for now.
      @watch()
      toRemoves.forEach (uuid, i)=>
        # query = new Usergrid.Query "DELETE", "/#{@fromCollection}/#{@fromId}/#{@toCollection}/#{uuid}/", null, null, (response) =>
        query = new Usergrid.Query "DELETE", "/#{@toCollection}/#{uuid}/", null, null, (response) ->
          console.log "DELETED"
        , ->
          console.log arguments
        Usergrid.ApiClient.runAppQuery query
        # ,->
          # console.log arguments
        # Usergrid.ApiClient.runAppQuery query
    bind: (scope, prop)->
      # Get data
      @prop = prop
      @scope = scope
      @getter = $parse(prop)
      @setter = @getter.assign
      @getPage null
    watch: ->
      @unbind()
      entities = @getter(@scope)
      console.log "Entities", entities
      entities.forEach (entity,i)=>
        #Watch element
        uuid = entity[@idprop]
        $entity.bind @scope, "#{@prop}[#{i}]", "#{@baseurl}/#{@toCollection}/#{uuid}/", {}, null, (fn)=>
          @deregs.push fn
        @cacheuuid = _.pluck entities, @idprop
        #Watch array length
      old = @getter(@scope).length
      fn = @scope.$watch "#{@prop}.length", (newValue, oldValue)=>
        # console.log "length change"
        if newValue > old
          @addEntity()
        else if newValue< old
          @removeEntity()
        old = newValue
        #otherwise not supported yet
      @deregs.push fn      
    getPage: (cursor)->
      params = {}
      console.log @ql
      if @ql
        params.ql = @ql
      params.cursor = cursor
      query = new Usergrid.Query "GET", @path, null, params, (response) =>
        console.log response

        entities = response.entities
        @cursors.push response.cursor
        @setter @scope, entities
        @watch()
      , ->
      Usergrid.ApiClient.runAppQuery query
    reset: ->
      @cursors = []
      @pageIdx = 0
    hasPrevPage: ->
      @cursors[@pageIdx-1]
    hasNextPage: ->
      @cursors[@pageIdx+1]
    getNextPage: ->
      @pageIdx++
      getPage @cursors[@pageIdx]
    getPrevPage: ->
      @pageIdx--
      getPage @cursors[@pageIdx]
    unbind: ->
      @deregs?.forEach (fn)->
        console.log fn
        fn()
      @deregs = []
      @cacheduuid = []
  return CollectionModel

CollectionModelFactory.$inject = ["$http", "$parse", "Model"]
app.factory "CollectionModel", CollectionModelFactory
