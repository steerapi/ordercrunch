class AccountCtrl
  proceed: =>
    user = Usergrid.ApiClient.getLoggedInUser()
    uuid = user?.get "uuid"
    @scope.username = ""
    @scope.password = ""
    @scope.email = ""
    @model.getBusiness uuid, (business)->
      # console.log business
      # verified = business.get "verified"
      # if verified != "verified"
      $.mobile.changePage "#pageHome"
      # switch verified
      #   when "verified"
      #     $.mobile.changePage "#pageHome"
      #   # when "verifying"
      #   #   $.mobile.changePage "#pageVerifying"
      #   else
      #     $.mobile.changePage "#pageClaim"
    , =>
      # @scope.error = "Cannot login. Please try again."
      # @scope.$apply()
      $.mobile.changePage "#pageClaim"

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
AccountCtrl.$inject = ["$scope", "BusinessModel", "$http", "Auth", "PageChange"]
app.controller("AccountCtrl", AccountCtrl)

querystring = require "querystring"
_ = require "underscore"
class ClaimCtrl
  search: =>
    @scope.error = ""
    params = querystring.stringify
      name: @scope.searchTxt
    req = @http.get "#{backendurl}/locu/api/v1/venue/search/?#{params}"
    req.success (response)=>
      console.log @scope.businesses
      @scope.businesses = response.objects
    req.error =>
      @scope.error = "search error"
  
  cancelClaim: =>
    user = Usergrid.ApiClient.getLoggedInUser()
    req = @http.get "#{backendurl}/api/v1/cancelClaimBusiness"
    req.success (response)=>
    req.error ->
    $.mobile.changePage "#pageClaim"

  claim: (business)=>
    $.mobile.loading "show",
      text: "Importing..."
      textVisible: true
      theme: "z"
      html: ""
    @scope.error = ""
    params = querystring.stringify
      locuid: business.id
    req = @http.get "#{backendurl}/api/v1/claimBusiness?#{params}"
    req.success (response)=>
      $.mobile.loading "hide"
      # $.mobile.changePage "#pageVerifying"
      $.mobile.changePage "#pageHome"
    req.error =>
      $.mobile.loading "hide"
      @scope.error = "Error trying to import your business. Please try again."
  
  constructor: (@scope,@bmodel,@http, @model)->
    @scope.search = _.throttle @search, 1000
    @scope.claim = @claim
    @scope.cancelClaim = @cancelClaim

    @scope.$on "pageVerifying", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        @scope.business = business._data
        uuid = business._data.uuid
        @scope.deregfn?()
        deregcb = (deregfn)=>
          @scope.deregfn = deregfn
        @model.bind(@scope,"phone2","#{backendurl}/api/v1/businesses/#{uuid}/$.phone2", "", null, deregcb)
      , ->

ClaimCtrl.$inject = ["$scope", "BusinessModel", "$http", "Model"]
app.controller("ClaimCtrl", ClaimCtrl)

class CreateBusinessCtrl
  createBusiness: =>
    user = Usergrid.ApiClient.getLoggedInUser()
    @model.createBusiness user.get("uuid"), @scope.data, ->
      $.mobile.changePage "#pageHome"
    , ->
      @scope.error = "Error trying to create business."
  constructor: (@scope,@model,@http)->
    @scope.data = {}
    @scope.createBusiness = @createBusiness

CreateBusinessCtrl.$inject = ["$scope", "BusinessModel", "$http"]
app.controller("CreateBusinessCtrl", CreateBusinessCtrl)

DateUtils = require('date-utils')

class TimeCtrl
  newInterval: =>
    if @scope.tap == 'default'
      @scope.openHours[@scope.dayOfWeek]?=[]
      @scope.openHours[@scope.dayOfWeek].splice 0,0,["",""]
    else
      @scope.specialHours[@scope.dateOfYear]?=[]
      @scope.specialHours[@scope.dateOfYear].splice 0,0,["",""]
  cleanData: (obj)=>
    console.log obj
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

  constructor: (@scope,@bmodel,@http,@model)->
    @scope.openHours = {}
    @scope.specialHours = {}
    @scope.days = ["Sunday", "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    # @scope.$watch "dayOfWeek", =>
    #   console.log @scope.dayOfWeek
    # , true
    d = new Date()
    @scope.dayOfWeek = d.toFormat("DDDD")
    @scope.dateOfYear = d.toFormat("MM/DD/YYYY")
    @scope.$on "pageTime", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        @scope.business = business._data
        uuid = business._data.uuid
        @scope.deregfn1?()
        @scope.deregfn2?()
        deregcb1 = (deregfn)=>
          @scope.deregfn1 = deregfn
        deregcb2 = (deregfn)=>
          @scope.deregfn2 = deregfn
        @model.bind @scope,"openHours","#{backendurl}/api/v1/businesses/#{uuid}/$.open_hours", {}, (obj)=>
          @cleanData(obj)            
        ,deregcb1
        @model.bind @scope,"specialHours","#{backendurl}/api/v1/businesses/#{uuid}/$.specialHours", {}, (obj)=>
          @cleanData(obj)
        ,deregcb2
      , ->
    @scope.newInterval = @newInterval

TimeCtrl.$inject = ["$scope", "BusinessModel", "$http", "Model"]
app.controller("TimeCtrl", TimeCtrl)

class HomeCtrl
  constructor: (@scope,@model,@http)->
    @scope.$on "pageHome", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @model.getBusiness uuid, (business)=>
        console.log business.get "businessName"
        @scope.businessName = business.get "businessName"
        @scope.$apply()
        
HomeCtrl.$inject = ["$scope", "BusinessModel", "$http"]
app.controller("HomeCtrl", HomeCtrl)

class NavigatorCtrl
  constructor: (@scope,@model,@http, @auth)->
    @scope.logout = =>
      slidemenu($("#slidemenu"), true);
      @auth.logOut()

NavigatorCtrl.$inject = ["$scope", "BusinessModel", "$http", "Auth"]
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
    
  constructor: (@scope,@bmodel,@http,@model)->
    @scope.setPassword = @setPassword
    @scope.$on "pageSettings", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        @scope.business = business._data
        uuid = business._data.uuid
        @scope.deregfn?()
        deregcb = (deregfn)=>
          @scope.deregfn = deregfn
        @model.bind(@scope,"business","#{backendurl}/api/v1/businesses/#{uuid}/", "", null, deregcb)
SettingsCtrl.$inject = ["$scope", "BusinessModel", "$http", "Model"]
app.controller("SettingsCtrl", SettingsCtrl)

class OrdersCtrl
  archive: (order, index)=>
    order.status = "archived"
    # order = @scope.completed.splice index,1
  complete: (order, index)=>
    order.status = "completed"
    order = @scope.incoming.splice index,1
    @scope.completed.push order
  constructor: (@scope,@bmodel,@http, CModel)->
    @scope.complete = @complete
    @scope.archive = @archive
    @scope.$on "pageOrders", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        buuid = business.get "uuid"
        @ordersCModel?.unbind()
        @ordersCModel = new CModel("#{backendurl}/api/v1", "businesses", buuid, "orders", "select * where status='ordered' order by created desc")
        @ordersCModel.bind @scope,"incoming"
        @completedCModel?.unbind()
        @completedCModel = new CModel("#{backendurl}/api/v1", "businesses", buuid, "orders", "select * where status='completed' order by created desc")
        @completedCModel.bind @scope,"completed"
        @scope.$apply()

OrdersCtrl.$inject = ["$scope", "BusinessModel", "$http", "CollectionModel"]
app.controller("OrdersCtrl", OrdersCtrl)

class EmployeesCtrl
  newShift: =>
    if @scope.tap == 'default'
      @scope.regularHours[@scope.dayOfWeek]?=[]
      @scope.regularHours[@scope.dayOfWeek].splice 0,0,["",""]
    else
      @scope.specialHours[@scope.dateOfYear]?=[]
      @scope.specialHours[@scope.dateOfYear].splice 0,0,["",""]
  cleanData: (obj)=>
    console.log obj
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
  newEmployee: =>
    @scope.employees.push {}
  constructor: (@scope,@bmodel,@http,@model,CModel)->

    @scope.newEmployee = @newEmployee
    @scope.deleteEmployee = @deleteEmployee
    @scope.$on "pageEmployees", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        buuid = business.get "uuid"
        @employeesCModel?.unbind()
        @employeesCModel = new CModel("#{backendurl}/api/v1", "businesses", buuid, "employees")
        @employeesCModel.bind @scope,"employees"
        @scope.$apply()

    d = new Date()
    @scope.regularHours = {}
    @scope.specialHours = {}
    @scope.days = ["Sunday", "Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @scope.newShift = @newShift
    @scope.dayOfWeek = d.toFormat("DDDD")
    @scope.dateOfYear = d.toFormat("MM/DD/YYYY")
    @scope.$on "pageShiftCalendar", =>
      uuid = @scope.employee.uuid
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

EmployeesCtrl.$inject = ["$scope", "BusinessModel", "$http", "Model", "CollectionModel"]
app.controller("EmployeesCtrl", EmployeesCtrl)

class MenuCtrl
  deleteMenu: (index)=>
    @scope.menus.splice index,1
  deleteSection: (index)=>
    @scope.sections.splice index,1
  deleteItem: (index)=>
    @scope.items.splice index,1
  newMenu: =>
    @scope.menus.push {}
  newSection: =>
    @scope.sections.push {}
  newItem: =>
    @scope.items.push {}
  constructor: (@scope,@bmodel,@http, @model, CModel)->
    @scope.deleteMenu = @deleteMenu
    @scope.deleteSection = @deleteSection
    @scope.deleteItem = @deleteItem
    
    @scope.newMenu = @newMenu
    @scope.newSection = @newSection
    @scope.newItem = @newItem
    @scope.$on "pageSection", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        suuid = @scope.section.uuid
        @itemsCModel?.unbind()
        @itemsCModel = new CModel("#{backendurl}/api/v1", "sections", suuid, "items")
        @itemsCModel.bind @scope,"items"
        @scope.$apply()

    @scope.$on "pageSectionSelect", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        muuid = @scope.menu.uuid
        @sectionsCModel?.unbind()
        @sectionsCModel = new CModel("#{backendurl}/api/v1", "menus", muuid, "sections")
        @sectionsCModel.bind @scope,"sections"
        @scope.$apply()

    @scope.$on "pageMenu", =>
      user = Usergrid.ApiClient.getLoggedInUser()
      uuid = user?.get("uuid")
      @bmodel.getBusiness uuid, (business)=>
        buuid = business.get "uuid"
        @menusCModel?.unbind()
        @menusCModel = new CModel("#{backendurl}/api/v1", "businesses", buuid, "menus")
        @menusCModel.bind @scope,"menus"
        @scope.$apply()

MenuCtrl.$inject = ["$scope", "BusinessModel", "$http", "Model", "CollectionModel"]
app.controller("MenuCtrl", MenuCtrl)
