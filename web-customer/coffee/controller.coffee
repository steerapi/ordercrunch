DateUtils = require('date-utils')
# graphs = require './graphs'
moment = require 'moment'
querystring = require "querystring"
_ = require "underscore"
async = require "async"
format = require "../../backend/apis/format"
formatTime = format.formatTime
formatDate = format.formatDate
formatDateTime = format.formatDateTime

tiit = require "../../backend/apis/tiit"
t2i = tiit.t2i
i2t = tiit.i2t

class EatCtrl
  searchNearby: ->
    #TODO
  search: ->
    @scope.error = ""
    if @scope.searchTxt == ""
      @searchNearby()
    day = @scope.moment
    hr = day.hours()
    min = day.minutes()
    interval = (hr*4)+(Math.floor(min/15))
    @scope.interval = interval
    @scope.time = i2t(interval)
    # console.log "interval", interval
    params = querystring.stringify
      name: @scope.searchTxt
      interval: ""+interval
    req = @http.get "#{backendurl}/api/v1/discounts?#{params}"
    req.success (discounts)=>
      @scope.businesses = discounts
    req.error =>
      @scope.error = "search error"
      @scope.$apply()
  select: (business)->
    console.log "BUSINESS SELECTED", business
    console.log "@scope SELECTED", @scope
    @model.selected = business
    @model.selected.time = @scope.time
    @model.selected.interval = @scope.interval
    $.mobile.changePage "#pageMenu"
    
class EatNowCtrl extends EatCtrl
  search: =>
    @scope.moment = moment()
    super()
  select: (business)=>
    super(business)
  constructor: (@scope,@model,@http)->
    $.extend @scope,@
    @scope.search = _.throttle @search, 1000
    @scope.$on "pageEatNow", =>
      @scope.searchTxt = ""
      @scope.businesses = []
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @model.get uuid, (customer)=>
        console.log customer
EatNowCtrl.$inject = ["$scope", "CustomerModel", "$http"]
app.controller("EatNowCtrl", EatNowCtrl)
  
class EatLaterCtrl extends EatCtrl
  selectTime: =>
    @scope.searchTxt = ""
    @scope.businesses = []    
  search: =>
    if not @scope.time
      @scope.error = "Please select time"
      return
    @scope.moment = moment(@scope.time,formatTime)
    super()
  select: (business)=>
    super(business)
  constructor: (@scope,@model,@http)->
    $.extend @scope,@
    @scope.search = _.throttle @search, 1000
    @scope.$on "pageEatLater", =>
      @scope.searchTxt = ""
      @scope.businesses = []
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @model.get uuid, (customer)=>
        console.log customer

EatLaterCtrl.$inject = ["$scope", "CustomerModel", "$http"]
app.controller("EatLaterCtrl", EatLaterCtrl)

class MenuCtrl
  back: =>
    # @scope.order = []
    @clear()
    $.mobile.changePage "#pageHome"
  confirm: =>
    $.mobile.loading "show"
    # now = moment()
    # time = now.format(formatTime)
    # interval = t2i(time)
    # console.log "time", time
    time = @model.selected.time
    interval = @model.selected.interval
    
    user = Usergrid.ApiClient.getLoggedInUser()
    @scope.order = []
    items = []
    for k,v of @scope.carts
      items.push v
    customer = @model.entity
    if not customer
      @scope.error = "Error processing your order. Please try again"
      return
    @scope.order.push
      from:
        customerName: customer._data.customerName
        name: user._data.name
        uuid: customer._data.uuid
        phone: customer._data.phone
        username: user._data.username
        email: user._data.email
      to:
        businessName: @model.selected.businessName
        uuid: @model.selected.uuid
      interval: interval
      pickupAt: time
      items: items
      orderedAt: moment().unix()
      total: @scope.total
      discount: @model.selected.discount
      status: "ordered"
    req = @http.post "#{backendurl}/api/v1/orders", @scope.order[0]
    req.success (order)=>
      @scope.order = [order]
      $.mobile.changePage "#pageConfirm"
      $.mobile.loading "hide"
    req.error =>
      $.mobile.loading "hide"
      @scope.error = "Error processing your order. Please try again"
  checkout: =>
    $.mobile.changePage "#pageReview"
  selectMenu: (menu)=>
    @scope.menu=menu
    @scope.sections = []
    $.mobile.changePage "#pageSectionSelect"
  clear: =>
    @scope.menu = null
    @scope.section = null
    @scope.carts = {}
    @scope.order = []
    @scope.totalCount = 0
    @scope.total = 0
    @scope.sections = []
  selectSection: (section)=>
    @scope.section=section
    @scope.items = []
    $.mobile.changePage "#pageSection"
  removeItem: (item)=>
    console.log @scope.carts
    @scope.carts[item.uuid].qty--
    if @scope.carts[item.uuid].qty==0
      delete @scope.carts[item.uuid]
    @scope.totalCount--
    @scope.total = (parseFloat(@scope.total)-parseFloat(item.price)).toFixed(2)
  addItem: (item)=>
    @scope.carts?={}
    if @scope.carts[item.uuid]
      item = @scope.carts[item.uuid]
    else
      item = $.extend true, {}, item
      @scope.carts[item.uuid] = item
    item.qty?=0
    item.qty++
    @scope.totalCount++
    @scope.total= (parseFloat(@scope.total)+parseFloat(item.price)).toFixed(2)
    console.log item
  constructor: (@scope,@model,@http,CModel)->
    $.extend @scope, @
    @scope.totalCount = 0
    @scope.total = 0
    # @scope.addItem = @addItem
    # @scope.selectSection = @selectSection
    # @scope.selectMenu = @selectMenu
    @scope.$on "pageSection", =>
      
      suuid = @scope.section.uuid
      query = new Usergrid.Query "GET", "sections/#{suuid}/items", null, null, (response) =>
        @scope.items = response.entities
        response.entities.forEach (entity)=>
          if entity.price
            entity.price = (entity.price*(1-@model.selected.discount/100)).toFixed(2)
        @scope.$apply()
      , ->
      Usergrid.ApiClient.runAppQuery query
      
    @scope.$on "pageSectionSelect", =>
      # @scope.sections = []
      muuid = @scope.menu.uuid
      query = new Usergrid.Query "GET", "menus/#{muuid}/sections", null, null, (response) =>
        @scope.sections = response.entities
        @scope.$apply()
      , ->
      Usergrid.ApiClient.runAppQuery query
    @scope.$on "pageMenu", =>
      if @scope.businessName != @model.selected.businessName
        @clear()
        @scope.businessName = @model.selected.businessName
      buuid = @model.selected.uuid
      @scope.businessName = @model.selected.businessName
      query = new Usergrid.Query "GET", "businesses/#{buuid}/menus", null, null, (response) =>
        @scope.menus = response.entities
        @scope.$apply()
      , ->
      Usergrid.ApiClient.runAppQuery query

MenuCtrl.$inject = ["$scope", "CustomerModel", "$http", "CollectionModel"]
app.controller("MenuCtrl", MenuCtrl)

class ConfirmCtrl
  constructor: (@scope,@model,@http,@auth)->
ConfirmCtrl.$inject = ["$scope", "CustomerModel", "$http"]
app.controller("ConfirmCtrl", ConfirmCtrl)

class OrdersCtrl
  archive: (order, index)=>
    order.status = "archived"
    # order = @scope.completed.splice index,1
  constructor: (@scope,@model,@http, CModel)->
    @scope.complete = @complete
    @scope.archive = @archive
    @scope.$on "pageOrders", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @model.get uuid, (customer)=>
        cuuid = customer.get "uuid"
        @ordersCModel?.unbind()
        @ordersCModel = new CModel("#{backendurl}/api/v1", "customers", cuuid, "orders", "select * where status='ordered' order by created desc")
        @ordersCModel.bind @scope,"orders"
        # query = new Usergrid.Query "GET", "customers/#{cuuid}/orders", null, null, (response) =>
        #   @scope.orders = response.entities
        #   @scope.$apply()
        # , ->
        # Usergrid.ApiClient.runAppQuery query

OrdersCtrl.$inject = ["$scope", "CustomerModel", "$http", "CollectionModel"]
app.controller("OrdersCtrl", OrdersCtrl)

SuperAccount = require "../../shared/coffee/controller/SuperAccount"
class AccountCtrl extends SuperAccount
  proceed: =>
    super()
    $.mobile.changePage "#pageHome"
  constructor: (@scope,@model,@http,@auth)->
    super arguments...

#Inject PageChange just to have it initialize
AccountCtrl.$inject = ["$scope", "CustomerModel", "$http", "Auth", "PageChange"]
app.controller("AccountCtrl", AccountCtrl)

class HomeCtrl
  constructor: (@scope,@model,@http)->
    @scope.$on "pageHome", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user.get "uuid"
      # @employeesCModel?.unbind()
      # @employeesCModel = new CModel("#{backendurl}/api/v1", "users", uuid, "employees")
      # @employeesCModel.bind @scope,"employees"
      @scope.username = user.get "username"

HomeCtrl.$inject = ["$scope", "Model", "$http"]
app.controller("HomeCtrl", HomeCtrl)

class NavigatorCtrl
  constructor: (@scope,@model,@http, @auth)->
    @scope.logout = =>
      slidemenu($("#slidemenu"), true);
      @auth.logOut()

NavigatorCtrl.$inject = ["$scope", "Model", "$http", "Auth"]
app.controller("NavigatorCtrl", NavigatorCtrl)

SuperSettings = require "../../shared/coffee/controller/SuperSettings"  
class SettingsCtrl extends SuperSettings
  setPassword: =>
    super(@scope)    
  constructor: (@scope,@http,@model)->
    @scope.setPassword = @setPassword
    # @scope.$on "pageSettings", =>
    #   user = Usergrid.ApiClient.getLoggedInUser()
    #   uuid = user?.get("uuid")
    #   @scope.deregfn?()
    #   deregcb = (deregfn)=>
    #     @scope.deregfn = deregfn
    #   @model.bind(@scope,"user","#{backendurl}/api/v1/users/#{uuid}/", "", null, deregcb)

SettingsCtrl.$inject = ["$scope", "$http", "Model"]
app.controller("SettingsCtrl", SettingsCtrl)

