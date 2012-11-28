Usergrid = require "../usergrid"
_s = require "underscore.string"
async = require "async"
http = require("http")

getBusiness = (businessUUID, cb)->
  entity = new Usergrid.Entity("businesses")
  entity.set "uuid", businessUUID
  entity.fetch (response)->
    cb null, entity
  , (response)->
    cb "error"

saveSection = (section, cb)->
  toSave =
    sectionName: section.section_name
    text: ""
  section.subsections[0].contents.forEach (item)->
    if item.type == 'SECTION_TEXT'
      toSave.text += item.text + " "
  entity = new Usergrid.Entity "sections"
  entity._data = toSave
  entity.save ->
    cb null, entity.get "uuid"
  , ->
    cb "error"
saveMenu = (menu, cb)->
  toSave =
    menuName: menu.menu_name
  entity = new Usergrid.Entity "menus"
  entity._data = toSave
  entity.save ->
    cb null, entity.get "uuid"
  , ->
    cb "error"

saveBusiness = (businessObj, cb)->
  entity = new Usergrid.Entity "businesses"
  clone = require('clone')
  tmp = clone businessObj
  if tmp.open_hours
    for day,hours in tmp.open_hours
      sps = hours.split("-")
      open = _s(sps[0]).trim()
      close = _s(sps[1]).trim()
      hours.splice 0, hours.length
      hours.push open
      hours.push close
  tmp.businessName = tmp.name
  delete tmp.name
  delete tmp.menus
  entity._data = tmp
  entity.save ->
    cb null, entity
  , ->
    cb "error"

postBusinessMenu = (businessid,menuid, cb)->
  query = new Usergrid.Query "POST", "/businesses/#{businessid}/menus/#{menuid}", null, null, (output) ->
    cb null
  , ->
    cb "error"
  Usergrid.ApiClient.runAppQuery query

postSectionItem = (sectionid,itemid, cb)->
  query = new Usergrid.Query "POST", "/sections/#{sectionid}/items/#{itemid}", null, null, (output) ->
    cb null
  , ->
    cb "error"
  Usergrid.ApiClient.runAppQuery query

postMenuSection = (menuid, sectionid, cb)->
  query = new Usergrid.Query "POST", "/menus/#{menuid}/sections/#{sectionid}", null, null, (output) ->
    cb null
  , ->
    cb "error"
  Usergrid.ApiClient.runAppQuery query


destroyCollection = (path, innercb, donecb)->
  collection = new Usergrid.Collection path
  collection.fetch (response)->
    collection.resetEntityPointer()
    while collection.hasNextEntity()
      entity = collection.getNextEntity()
      if innercb
        innercb entity, ->
          collection.destroyEntity entity
      else
        collection.destroyEntity entity
    if collection.hasNextPage()
      collection.getNextPage()
    else
      donecb?()
  , ->
    donecb? "error"

destroyItems = (sectionid, cb, donecb)->
  destroyCollection "sections/#{sectionid}/items", cb, donecb
 
destroySections = (menuid, cb, donecb)->
  destroyCollection "menus/#{menuid}/sections", cb, donecb

destroyMenus = (businessid, cb, donecb)->
  destroyCollection "businesses/#{businessid}/menus", cb, donecb

destroyBusiness = (businessid, donecb)->
  destroyMenus businessid, (menu, menucb)->
    menuid = menu.get "uuid"
    destroySections menuid, (section, sectioncb)->
      sectionid = section.get "uuid"
      destroyItems sectionid, (item, itemcb)->
        itemcb()
      , ->
        sectioncb()
    , ->
      menucb()
  , ->
    donecb?()

locuKey = "a231808077ef79fabb66e7f7fd315263278f8d99"

importLocu = (locuid, responsecb)->
  req = http.request
    method:"GET"
    host:"api.locu.com"
    path: "http://api.locu.com/v1_0/venue/#{locuid}/?api_key=#{locuKey}"
  , (httpres)->
    buffer = ""
    httpres.on "data", (chunk)->
      buffer+=chunk
    httpres.on "end", (chunk)->
      obj = JSON.parse buffer
      businessObj = obj.objects[0]
      menus = businessObj.menus
      businessObj.verified = "unverified"
      saveBusiness businessObj, (err, business)->
        if err
          responsecb 404
          return
        else
          responsecb business._data
        businessid = business.get "uuid"
        async.forEachSeries menus, (menu, cb)->
          saveMenu menu, (err, menuid)->
            if err
              cb err
              return
            postBusinessMenu businessid, menuid, (err)->
              if err
                cb err
                return
              async.forEachSeries menu.sections, (section, cb)->
                saveSection section, (err, sectionid)->
                  if err
                    cb err
                    return
                  postMenuSection menuid, sectionid, (err)->
                    if err
                      cb err
                      return
                    async.forEachSeries section.subsections[0].contents, (item, cb)->
                      if item.id
                        item.locuid = item.id
                        item.itemName = item.name
                        delete item.name
                        delete item.id
                        entity = new Usergrid.Entity "items"
                        entity._data = item
                        entity.save ->
                          uuid = entity.get "uuid"
                          postSectionItem sectionid, uuid, (err)->
                            if err
                              cb err
                              return
                            cb()
                        , ->
                          cb "error"
                      else
                        cb()
                    , cb
              , cb
        , (err)->
          if err 
            responsecb 404
            return
  req.end()

postUserBusiness = (useruuid, businessuuid, cb)->
  destroyCollection "/users/#{useruuid}/businesses/", (entity, cb)->
    uuid = entity.get "uuid"
    destroyBusiness uuid, ->
    cb()
  ,->
    query = new Usergrid.Query "POST", "/users/#{useruuid}/businesses/#{businessuuid}", null, null, (output) ->
      cb null
    , ->
      cb "error"
    Usergrid.ApiClient.runAppQuery query

postManagerBusiness = (manageruuid, businessuuid, cb)->
  query = new Usergrid.Query "POST", "/managers/#{manageruuid}/businesses/#{businessuuid}", null, null, (output) ->
    cb null
  , ->
    cb "error"
  Usergrid.ApiClient.runAppQuery query

# Right now take first manager
getManager = (businessUUID, cb)->
  collection = new Usergrid.Collection("managers")
  collection.fetch ->
    # try
    entity = collection.getNextEntity()
    entity.fetch (response)->
      uuid = entity.get "uuid"
      cb null, entity, uuid
    , (response)->
      cb "error"
    # catch err
    #   cb err
  , ->
    cb "error"

exports.register = (app, requiresLogin)->
  app.get "/api/v1/claimBusiness", requiresLogin, (req,res)->
    locuid = req.query.locuid
    importLocu locuid, (response)->
      if response?.uuid
        businessUUID = response.uuid
        user = Usergrid.ApiClient.getLoggedInUser()
        userUUID = user.get "uuid"
        postUserBusiness userUUID, businessUUID, ->
          getManager businessUUID, (err, manager, managerUUID)->
            if err 
              res.send 404
            postManagerBusiness managerUUID, businessUUID, (responserv)->
              res.send response
            , ->
              res.send 404
        , ->
          res.send 404
      else
        res.send 404
  app.get "/api/v1/deleteBusiness", requiresLogin, (req,res)->
    businessUUID = req.query.businessuuid
    # TODO: Check permission
    # getManager businessUUID, (err, manager, managerUUID)->
    destroyBusiness businessUUID, ->
      res.send 200
    , ->
      res.send 404

