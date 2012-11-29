SingletonModel = require "./singletonModel"

app.factory "EmployeeModel", ($http, $rootScope)->
  return new SingletonModel("employees",$http, $rootScope)

