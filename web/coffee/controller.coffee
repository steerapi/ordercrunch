BusinessSlideCtrl = ($scope, $timeout)->
  $scope.current = 0
  $scope.ids = [1,9].concat([2,3,4]).concat([10..12]).concat([8])
  repeat = ->
    $scope.current = ($scope.current + 1) % $scope.ids.length
    setTimeout repeat,2000
    $scope.$apply()
  setTimeout repeat,2000

app.controller "BusinessSlideCtrl", BusinessSlideCtrl

EmployeeSlideCtrl = ($scope, $timeout)->
  $scope.current = 0
  $scope.ids = [1..5]
  repeat = ->
    $scope.current = ($scope.current + 1) % $scope.ids.length
    setTimeout repeat,2000
    $scope.$apply()
  setTimeout repeat,2000

app.controller "EmployeeSlideCtrl", EmployeeSlideCtrl

CustomerSlideCtrl = ($scope, $timeout)->
  $scope.current = 0
  $scope.ids = [1..9]
  repeat = ->
    $scope.current = ($scope.current + 1) % $scope.ids.length
    setTimeout repeat,2000
    $scope.$apply()
  setTimeout repeat,2000

app.controller "CustomerSlideCtrl", CustomerSlideCtrl