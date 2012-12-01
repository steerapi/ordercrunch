SingletonModel = require "../../../shared/coffee/services/singletonModel"

app.factory "CustomerModel", ($http, $rootScope)->
  return new SingletonModel("customers",$http, $rootScope,true)

# Usergrid.ApiClient.logInAppUser "tester", "tester", (response, user) =>
#   uuid = response.user.uuid
#   collection = new Usergrid.Collection "users/#{uuid}/#{@collection}"
#   collection.fetch (response)=>
#     @entity = response.entities[0]
#     scb(@entity)
# return