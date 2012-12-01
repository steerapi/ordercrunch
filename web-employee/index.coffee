# $ ->
#   $.extend $.mobile.datebox.prototype.options,
#     dateFormat: "dd/YYYY"
#     headerFormat: "dd/YYYY"
$ ->
  $.extend $.mobile.datebox::options,
    overrideTimeFormat: "HH.mm"

$("#pageLogin").on "pageinit", ->
  console.log "init"
  $("#popupReset iframe").attr("width", 0).attr "height", 0
  $("#popupReset").on
    popupbeforeposition: ->
      size = scale(497, 298, 15, 1)
      w = size.width
      h = size.height
      $("#popupReset iframe").attr("width", w).attr "height", h
    popupafterclose: ->
      $("#popupReset iframe").attr("width", 0).attr "height", 0

# Usergrid stuff
Usergrid.ApiClient.init('ordercrunch', 'ordercrunch');
# Backend url
window.backendurl = "http://backend.ordercrunchapp.com"
# window.backendurl = "http://localhost:3000"
# Angular
window.app = angular.module "app", []

require "./coffee/directives.coffee"

require "./coffee/services/employeeModel.coffee"
require "./coffee/services/auth.coffee"
require "./coffee/services/pageChange.coffee"
require "./coffee/services/model.coffee"

require "./coffee/controller.coffee"
