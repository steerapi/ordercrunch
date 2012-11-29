# app.directive "ngSwipe", ->
#   (scope, element, attrs)->
#     element.swipeDelete 
#       click: (e) ->
#         e.stopPropagation()
#         e.preventDefault()
#         element.remove()
#         return false