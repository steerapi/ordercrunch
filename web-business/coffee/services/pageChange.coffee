class PageChange
  constructor: (@rootScope)->
    $(document).bind "pagechange", (e, obj)=>
      @rootScope.$broadcast obj.toPage[0].id
      @rootScope.$apply()
PageChange.$inject = ["$rootScope"]
app.service "PageChange", PageChange