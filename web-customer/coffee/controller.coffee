DateUtils = require('date-utils')
graphs = require './graphs'
moment = require 'moment'
# console.log moment
format = require "../../backend/apis/format"
formatTime = format.formatTime
formatDate = format.formatDate
formatDateTime = format.formatDateTime

t2i = (time)->
  day = moment(time,formatTime)
  hr = day.hours()
  min = day.minutes()
  return (hr*4)+(Math.floor min/15)

i2t = (interval)->
  a = moment().sod()
  a.add('minutes', interval*15)
  a.format(formatTime)

class EatCtrl
  searchNearby: ->
    #TODO
  search: ->
    # @scope.error = ""
    # if @scope.searchTxt == ""
    #   @searchNearby()
    # day = @scope.moment
    # hr = day.hours()
    # min = day.minutes()
    # interval = (hr*4)+(Math.floor min/15)
    # params = querystring.stringify
    #   name: @scope.searchTxt
    #   interval: interval
    # req = @http.get "#{backendurl}/api/v1/discounts?#{params}"
    # req.success (discounts)=>
    #   @scope.businesses = discounts
    # req.error =>
    #   @scope.error = "search error"

class EatNowCtrl extends EatCtrl
  search: =>
    @scope.moment = moment()
    @scope.error = ""
    if @scope.searchTxt == ""
      @searchNearby()
    day = @scope.moment
    hr = day.hours()
    min = day.minutes()
    interval = (hr*4)+(Math.floor min/15)
    @scope.interval = interval
    @scope.time = i2t(interval)
    params = querystring.stringify
      name: @scope.searchTxt
      interval: interval
    req = @http.get "#{backendurl}/api/v1/discounts?#{params}"
    req.success (discounts)=>
      @scope.businesses = discounts
    req.error =>
      @scope.error = "search error"

    # super.search()
  select: (business)=>
    @model.selected = business
    @model.selected.time = @scope.time
    @model.selected.interval = @scope.interval
    $.mobile.changePage "#pageMenu"
  constructor: (@scope,@model,@http)->
    @scope.search = _.throttle @search, 1000
    @scope.select = @select
    @scope.$on "pageEatNow", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @model.get uuid, (customer)=>
        console.log customer
EatNowCtrl.$inject = ["$scope", "CustomerModel", "$http"]
app.controller("EatNowCtrl", EatNowCtrl)
  
class EatLaterCtrl extends EatCtrl
  search: =>
    if not @scope.time
      @scope.error = "Please select time"
      return
    @scope.moment = moment(@scope.time,formatTime)
    @scope.error = ""
    if @scope.searchTxt == ""
      @searchNearby()
    day = @scope.moment
    hr = day.hours()
    min = day.minutes()
    interval = (hr*4)+(Math.floor min/15)
    @scope.interval = interval
    @scope.time = i2t(interval)
    params = querystring.stringify
      name: @scope.searchTxt
      interval: interval
    req = @http.get "#{backendurl}/api/v1/discounts?#{params}"
    req.success (discounts)=>
      @scope.businesses = discounts
    req.error =>
      @scope.error = "search error"

    # super.search()
  select: (business)=>
    @model.selected = business
    @model.selected.time = @scope.time
    @model.selected.interval = @scope.interval
    $.mobile.changePage "#pageMenu"
  constructor: (@scope,@model,@http)->
    # console.log "SEARCH FUNC", @search
    @scope.search = _.throttle @search, 1000
    @scope.select = @select
    @scope.$on "pageEatNow", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @model.get uuid, (customer)=>
        console.log customer
EatLaterCtrl.$inject = ["$scope", "CustomerModel", "$http"]
app.controller("EatLaterCtrl", EatLaterCtrl)

class MenuCtrl
  back: =>
    @scope.order = []
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
        customerName: customer._data.name
        uuid: customer._data.uuid
        phone: customer._data.phone
        email: customer._data.email
      to:
        businessName: @model.selected.businessName
        uuid: @model.selected.uuid
      interval: interval
      pickupAt: time
      items: items
      orderedAt: moment.unix()
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
  back: =>
    $.mobile.changePage "#pageHome"
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
  constructor: (@scope,@model,@http, CModel)->
    @scope.complete = @complete
    @scope.archive = @archive
    @scope.$on "pageOrders", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @model.get uuid, (customer)=>
        cuuid = customer.get "uuid"
        query = new Usergrid.Query "GET", "customers/#{cuuid}/orders", null, null, (response) =>
          @scope.orders = response.entities
          @scope.$apply()
        , ->
        Usergrid.ApiClient.runAppQuery query

OrdersCtrl.$inject = ["$scope", "CustomerModel", "$http", "CollectionModel"]
app.controller("OrdersCtrl", OrdersCtrl)

class AccountCtrl
  proceed: =>
    user = Usergrid.ApiClient.getLoggedInUser()
    uuid = user?.get "uuid"
    @scope.username = ""
    @scope.password = ""
    @scope.email = ""
    $.mobile.changePage "#pageHome"

  constructor: (@scope,@model,@http,@auth)->
    @scope.login = =>
      @scope.error = ""
      @auth.logIn @scope.username, @scope.password, (err)=>
        if err
          @scope.error = "Cannot login. Please try again."
        else
          @proceed()
    @scope.signup = =>
      @scope.error = ""
      @auth.signUp @scope.username, @scope.email, @scope.password, (err)=>
        if err
          @scope.error = "Cannot signup. Please try again."
          @scope.$apply()
        else
          @proceed()
    @scope.forgot = =>
      $.mobile.loading "show",
        text: "Reseting..."
        textVisible: true
        theme: "z"
        html: ""
      @scope.error = ""
      req = @http.post "#{backendurl}/api/v1/resetpw",
        email: @scope.email
      req.success =>
        $.mobile.loading "hide"
        @scope.resetSent='true'
        $.mobile.changePage "#pageResetSent"
      req.error =>
        $.mobile.loading "hide"
        @scope.error = "Error reseting password. Please try again."
    @scope.$on "pageResetSent", =>
      @scope.error = ""
      @scope.resetSent='false'

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

querystring = require "querystring"
_ = require "underscore"
async = require "async"

class JoinCtrl
  search: =>
    @scope.error = ""
    params = querystring.stringify
      ql: "select * where businessName contains '#{@scope.searchTxt}'"
    req = @http.get "#{backendurl}/apigee/api/v1/businesses?#{params}"
    req.success (response)=>
      @scope.businesses = response.entities
    req.error =>
      @scope.error = "search error"
  link: (col1,id1,col2,id2,cb)=>
    req = @http.post "#{backendurl}/apigee/api/v1/#{col1}/#{id1}/#{col2}/#{id2}"
    req.success =>
      cb()
    req.error =>
      cb("error")  
  join: (business)=>
    req = @http.post "#{backendurl}/apigee/api/v1/employees",
      obj:
        businessName: business.businessName
    @scope.error = ""
    req.success (response)=>
      employeeData = response.entities[0]
      employeeUUID = employeeData.uuid
      linkEB = (donecb)=>        
        @link "employees", employeeUUID, "businesses", business.uuid, (err)=>
          donecb err
      linkBE = (donecb)=>        
        @link "businesses", business.uuid, "employees", employeeUUID, (err)=>
          donecb err
      linkUE = (donecb)=>
        user = Usergrid.ApiClient.getLoggedInUser()
        uuid = user.get "uuid"
        @link "users", uuid, "employees", employeeUUID, (err)=>
          donecb err
      async.parallel [linkUE, linkEB, linkBE], (err)->
        if err
          @scope.error = "Error trying to join the business. Please try again."
        else
          $.mobile.changePage "#pageHome"
    req.error =>
      @scope.error = "Error trying to join the business. Please try again."

  constructor: (@scope,@smodel,@http, @model)->
    @scope.search = _.throttle @search, 1000
    @scope.join = @join
    @scope.$on "pageJoin", =>

JoinCtrl.$inject = ["$scope", "CustomerModel", "$http", "Model"]
app.controller("JoinCtrl", JoinCtrl)

class NavigatorCtrl
  constructor: (@scope,@model,@http, @auth)->
    req = @http.post "#{backendurl}/api/v1/login",
      username: "tester"
      password: "tester"
    Usergrid.ApiClient.logInAppUser "tester", "tester", (response, user) ->

    @scope.logout = =>
      slidemenu($("#slidemenu"), true);
      @auth.logOut()
    # @scope.$on "pageHome", =>
    #   user = Usergrid.ApiClient.getLoggedInUser()
    #   uuid = user.get "uuid"
    #   @employeesCModel?.unbind()
    #   @employeesCModel = new CModel("#{backendurl}/api/v1", "users", uuid, "employees")
    #   @employeesCModel.bind @scope,"employees"

NavigatorCtrl.$inject = ["$scope", "Model", "$http", "Auth"]
app.controller("NavigatorCtrl", NavigatorCtrl)

class SettingsCtrl
  setPassword: =>
    @scope.passwordSetStatus = ""
    user = Usergrid.ApiClient.getLoggedInUser()
    useruuid = user.get "uuid"
    query = new Usergrid.Query "PUT", "/users/#{useruuid}/password", 
      newpassword: @scope.password
      oldpassword: @scope.oldpassword
    , null, (output) =>
      @scope.passwordSetStatus = "Success"
    , =>
      @scope.passwordSetStatus = "Error"
    Usergrid.ApiClient.runAppQuery query
    @scope.password = ""
    @scope.oldpassword = ""
    
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

class EmployeesCtrl
  newShift: =>
    if @scope.tap == 'default'
      @scope.regularHours[@scope.dayOfWeek]?=[]
      @scope.regularHours[@scope.dayOfWeek].splice 0,0,["",""]
    else
      @scope.specialHours[@scope.dateOfYear]?=[]
      @scope.specialHours[@scope.dateOfYear].splice 0,0,["",""]
  cleanData: (obj)=>
    for k,hours of obj
      if not k
        delete obj[k]
        continue
      for i in [hours.length-1..0]
        v = hours[i]
        if (not v?[0]) or (not v?[1])
          hours.splice i,1
      if hours.length <= 0
        delete obj[k]
        continue
    return
  deleteEmployee: (index)=>
    @scope.employees.splice index,1
  constructor: (@scope,@smodel,@http,@model,CModel)->
    @scope.deleteEmployee = @deleteEmployee
    @scope.$on "pageEmployees", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @employeesCModel?.unbind()
      @employeesCModel = new CModel("#{backendurl}/api/v1", "users", uuid, "employees", null)
      @employeesCModel.bind @scope,"employees"

    d = new Date()
    @scope.regularHours = {}
    @scope.specialHours = {}
    @scope.days = ["Sunday", "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @scope.newShift = @newShift
    @scope.dayOfWeek = d.toFormat("DDDD")
    @scope.dateOfYear = d.toFormat("MM/DD/YYYY")
    @scope.$on "pageShiftCalendar", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @scope.deregfn1?()
      @scope.deregfn2?()
      deregcb1 = (deregfn)=>
        @scope.deregfn1 = deregfn
      deregcb2 = (deregfn)=>
        @scope.deregfn2 = deregfn
      @model.bind @scope,"regularHours","#{backendurl}/api/v1/employees/#{uuid}/$.regularHours", {}, (obj)=>
        @cleanData(obj)            
      ,deregcb1
      @model.bind @scope,"specialHours","#{backendurl}/api/v1/employees/#{uuid}/$.specialHours", {}, (obj)=>
        @cleanData(obj)
      ,deregcb2
    @scope.newInterval = @newInterval

EmployeesCtrl.$inject = ["$scope", "CustomerModel", "$http", "Model", "CollectionModel"]
app.controller("EmployeesCtrl", EmployeesCtrl)

class OpenShiftsCtrl
  constructor: (@scope,@smodel,@http,@model,CModel)->

OpenShiftsCtrl.$inject = ["$scope", "CustomerModel", "$http", "Model", "CollectionModel"]
app.controller("OpenShiftsCtrl", OpenShiftsCtrl)

