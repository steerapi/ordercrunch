DateUtils = require('date-utils')
querystring = require "querystring"
_ = require "underscore"
async = require "async"

SuperAccount = require "../../shared/coffee/controller/SuperAccount"
class AccountCtrl extends SuperAccount
  proceed: =>
    super()
    $.mobile.changePage "#pageHome"
  constructor: (@scope,@model,@http,@auth)->
    super arguments...
#Inject PageChange just to have it initialize
AccountCtrl.$inject = ["$scope", "EmployeeModel", "$http", "Auth", "PageChange"]
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

class JoinCtrl
  search: =>
    @scope.error = ""
    params = querystring.stringify
      ql: "select * where businessName contains '#{@scope.searchTxt}*'"
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
    user = Usergrid.ApiClient.getLoggedInUser()
    uuid = user.get "uuid"
    req = @http.post "#{backendurl}/apigee/api/v1/employees",
      obj:
        businessName: business.businessName
        employeeName: user.get("name") || user.get("username")
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

JoinCtrl.$inject = ["$scope", "EmployeeModel", "$http", "Model"]
app.controller("JoinCtrl", JoinCtrl)

class NavigatorCtrl
  constructor: (@scope,@model,@http, @auth)->
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

EmployeesCtrl.$inject = ["$scope", "EmployeeModel", "$http", "Model", "CollectionModel"]
app.controller("EmployeesCtrl", EmployeesCtrl)

class OpenShiftsCtrl
  constructor: (@scope,@smodel,@http,@model,CModel)->

OpenShiftsCtrl.$inject = ["$scope", "EmployeeModel", "$http", "Model", "CollectionModel"]
app.controller("OpenShiftsCtrl", OpenShiftsCtrl)

