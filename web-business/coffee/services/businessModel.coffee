SingletonModel = require "../../../shared/coffee/services/singletonModel"

app.factory "BusinessModel", ($http, $rootScope)->
  return new SingletonModel("businesses",$http, $rootScope)
