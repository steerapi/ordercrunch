class SuperAccount
  proceed: =>
    @scope.username = ""
    @scope.password = ""
    @scope.email = ""
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

module.exports = SuperAccount
