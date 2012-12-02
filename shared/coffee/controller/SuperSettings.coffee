class SuperSettings
  setPassword: ->
    @scope.passwordSetStatus = "Setting..."
    user = Usergrid.ApiClient.getLoggedInUser()
    useruuid = user.get "uuid"
    query = new Usergrid.Query "PUT", "/users/#{useruuid}/password", 
      newpassword: @scope.password
      oldpassword: @scope.oldpassword
    , null, (output) =>
      @scope.passwordSetStatus = "Success"
      @scope.password = ""
      @scope.oldpassword = ""
      @scope.$apply()
    , =>
      @scope.passwordSetStatus = "Error"
      @scope.password = ""
      @scope.oldpassword = ""
      @scope.$apply()
    Usergrid.ApiClient.runAppQuery query
  constructor: (@scope,@http,@model)->

module.exports = SuperSettings