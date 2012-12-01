SingletonModel = require "./singletonModel"

app.factory "CustomerModel", ($http, $rootScope)->
  return new SingletonModel("customers",$http, $rootScope)

